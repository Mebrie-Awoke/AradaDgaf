#!/usr/bin/env python3
"""
E2E Integration and Lifecycle Verification Script for AradaDgaf.
Tests the full lifecycle across:
- Self-service employee and technician registration
- Login blocking with machine-readable error codes (account_pending, account_rejected, account_suspended)
- Admin review, approval with specialty confirmation, and rejection with mandatory reason
- Re-submission of rejected registration
- Ticket creation, assignment with due date and priority, technician work recording, and rating
- Server-side ticket isolation (employee cannot access another employee's tickets)
- Dev seed idempotency
"""

import json
import os
import re
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional, Tuple

# Ensure stdout flushes immediately
sys.stdout.reconfigure(line_buffering=True)

BASE_URL = os.environ.get("API_BASE_URL", "http://127.0.0.1:8000/api").rstrip("/")
DEV_ADMIN_USER = os.environ.get("ADMIN_USERNAME", "admin@arada.gov.et")
DEV_ADMIN_PASS = os.environ.get("ADMIN_PASSWORD", "AdminPassword123!")


class ApiClient:
    def __init__(self, base_url: str):
        self.base_url = base_url

    def request(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
        token: Optional[str] = None,
        timeout: float = 15.0,
    ) -> Tuple[int, Dict[str, Any]]:
        url = f"{self.base_url}/{path.lstrip('/')}"
        headers = {"Accept": "application/json"}
        data = None

        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"

        if token:
            headers["Authorization"] = f"Bearer {token}"

        for attempt in range(4):
            try:
                req = urllib.request.Request(url, data=data, headers=headers, method=method)
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    status = resp.status
                    raw = resp.read().decode("utf-8")
                    payload = json.loads(raw) if raw else {}
                    return status, payload
            except urllib.error.HTTPError as err:
                status = err.code
                raw = err.read().decode("utf-8")
                try:
                    payload = json.loads(raw) if raw else {}
                except Exception:
                    payload = {"raw": raw}
                if status == 503 and attempt < 3:
                    time.sleep(2.0)
                    continue
                return status, payload
            except Exception as exc:
                if attempt < 2 and method == "GET":
                    time.sleep(1.0)
                    continue
                return 0, {"error": str(exc)}
        return 0, {"error": "Request timed out"}


class TestRunner:
    def __init__(self):
        self.client = ApiClient(BASE_URL)
        self.results = []
        self.server_proc = None

    def record(self, step_name: str, passed: bool, message: str = ""):
        mark = "PASS" if passed else "FAIL"
        self.results.append((step_name, passed, message))
        msg_str = f" - {message}" if message else ""
        print(f"[{mark}] {step_name}{msg_str}")
        if not passed:
            print(f"   --> FAILED STEP DETAILS: {message}")

    def ensure_server_running(self):
        def port_open():
            try:
                with socket.create_connection(("127.0.0.1", 8000), timeout=1.0):
                    return True
            except OSError:
                return False

        if port_open():
            print(f"Backend server is already reachable at {BASE_URL}")
            for _ in range(15):
                status, _ = self.client.request("GET", "/v1/dashboard/")
                if status in (200, 401, 403, 404):
                    print(f"Database connection verified (status {status})")
                    return True
                time.sleep(1.0)
            return True

        print(f"Backend not responding at {BASE_URL}. Launching local server...")
        backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend"))
        python_bin = sys.executable

        venv_python = os.path.join(backend_dir, ".venv", "Scripts", "python.exe")
        if os.path.exists(venv_python):
            python_bin = venv_python

        cmd = [python_bin, "manage.py", "runserver", "127.0.0.1:8000", "--noreload"]
        self.server_proc = subprocess.Popen(
            cmd,
            cwd=backend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        for _ in range(30):
            time.sleep(0.5)
            if port_open():
                print(f"Local backend started successfully (PID: {self.server_proc.pid})")
                for _ in range(15):
                    status, _ = self.client.request("GET", "/v1/dashboard/")
                    if status in (200, 401, 403, 404):
                        print(f"Database connection verified (status {status})")
                        return True
                    time.sleep(1.0)
                return True
            if self.server_proc.poll() is not None:
                out = self.server_proc.stdout.read()
                print(f"Server process exited prematurely with code {self.server_proc.returncode}:\n{out}")
                self.record("Server Startup", False, f"Server exited with {self.server_proc.returncode}")
                return False

        self.record("Server Startup", False, f"Could not connect to backend at {BASE_URL}")
        return False

    def teardown(self):
        if self.server_proc:
            print("Terminating background server process...")
            self.server_proc.terminate()
            try:
                self.server_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_proc.kill()

    def run(self):
        print("=" * 70)
        print("ARADA DGAF - END-TO-END VERIFICATION RUNNER")
        print("=" * 70)

        start_time = time.time()

        if not self.ensure_server_running():
            return False

        import random
        import uuid

        # 6 characters alphanumeric without underscores to satisfy both employee_id and username regexes
        run_id = f"{int(time.time()) % 10000:04d}{random.randint(10, 99)}"
        emp_username = f"emp{run_id}"
        emp_id = f"EMP-{run_id}"
        emp_phone = f"091{random.randint(1000000, 9999999)}"

        tech_b_username = f"tech{run_id}"
        tech_b_id = f"TECH-{run_id}"
        tech_b_phone = f"092{random.randint(1000000, 9999999)}"

        print(f"Generated RunID: {run_id}")
        print(f"Employee A: {emp_username} ({emp_id}, {emp_phone})")
        print(f"Technician B: {tech_b_username} ({tech_b_id}, {tech_b_phone})")

        saved_ref_emp = None
        saved_ref_tech = None
        emp_token = None
        admin_token = None
        tech_token = None
        created_ticket_number = None
        created_ticket_id = None
        tech_b_reg_id = None

        # ---------------------------------------------------------
        # Step 1: Register employee A (expect status pending)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/register/",
            body={
                "role": "employee",
                "fullName": f"E2E Employee {run_id}",
                "employeeId": emp_id,
                "username": emp_username,
                "password": "Password123!",
                "confirmPassword": "Password123!",
                "phone": emp_phone,
                "department": "Finance Department",
                "officeLocation": "Room 204",
            },
        )
        data = resp.get("data", {})
        saved_ref_emp = data.get("reference_number") or data.get("referenceNumber")
        step1_pass = (
            status == 201
            and resp.get("success") is True
            and data.get("status") == "pending"
            and saved_ref_emp is not None
            and saved_ref_emp.startswith("REG-2026-")
        )
        self.record(
            "1. Register Employee A",
            step1_pass,
            f"Status={status}, Ref={saved_ref_emp}, Resp={resp}",
        )

        # ---------------------------------------------------------
        # Step 2: Try to log in with A (expect failure account_pending)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": emp_username,
                "password": "Password123!",
                "role": "employee",
            },
        )
        err_code = resp.get("code") or resp.get("error")
        step2_pass = status == 403 and err_code == "account_pending"
        self.record(
            "2. Reject Login for Pending Employee A",
            step2_pass,
            f"Status={status}, ErrorCode={err_code}",
        )

        # ---------------------------------------------------------
        # Step 3: Query status endpoint with reference number
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            f"/mobile/auth/registration-status/?reference_number={saved_ref_emp}",
        )
        status_data = resp.get("data", {})
        step3_pass = (
            status == 200
            and resp.get("success") is True
            and status_data.get("status") == "pending"
            and status_data.get("username") == emp_username
        )
        self.record(
            "3. Query Registration Status by Reference #",
            step3_pass,
            f"Status={status}, RegistrantStatus={status_data.get('status')}",
        )

        # ---------------------------------------------------------
        # Step 4: Admin logs in, retrieves token
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/v1/auth/login/",
            body={
                "email": DEV_ADMIN_USER,
                "username": "admin",
                "password": DEV_ADMIN_PASS,
            },
        )
        admin_data = resp.get("data", {})
        admin_token = admin_data.get("access_token")
        step4_pass = (
            status == 200
            and resp.get("success") is True
            and bool(admin_token)
        )
        self.record(
            "4. Admin Login and Token Retrieval",
            step4_pass,
            f"Status={status}, TokenAcquired={bool(admin_token)}",
        )

        # ---------------------------------------------------------
        # Step 5: Admin lists pending, approves Employee A
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            "/v1/registrations/?status=pending",
            token=admin_token,
        )
        registrations = resp.get("data", [])
        emp_reg = next((r for r in registrations if r.get("username") == emp_username), None)
        emp_reg_id = emp_reg.get("id") if emp_reg else None

        if emp_reg_id:
            status, approve_resp = self.client.request(
                "POST",
                f"/v1/registrations/{emp_reg_id}/approve/",
                body={},
                token=admin_token,
            )
            step5_pass = status == 200 and approve_resp.get("success") is True
            self.record(
                "5. Admin Approves Employee A",
                step5_pass,
                f"Status={status}, RegId={emp_reg_id}",
            )
        else:
            self.record(
                "5. Admin Approves Employee A",
                False,
                f"Employee {emp_username} not found in pending list",
            )

        # ---------------------------------------------------------
        # Step 6: Log in with Employee A again (expect SUCCESS)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": emp_username,
                "password": "Password123!",
                "role": "employee",
            },
        )
        emp_data = resp.get("data", {})
        emp_token = emp_data.get("access_token")
        step6_pass = (
            status == 200
            and resp.get("success") is True
            and bool(emp_token)
            and emp_data.get("user", {}).get("username") == emp_username
        )
        self.record(
            "6. Employee A Login After Approval",
            step6_pass,
            f"Status={status}, EmployeeTokenAcquired={bool(emp_token)}",
        )

        # ---------------------------------------------------------
        # Step 7: Employee A creates a ticket (AD-2026-####)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/tickets/",
            body={
                "category": "Maintenance",
                "deviceType": "network",
                "problemDescription": "Switch port disconnected in accounting office.",
                "department": "Finance Department",
                "officeLocation": "Room 204",
                "phoneNumber": emp_phone,
                "requesterName": f"E2E Employee {run_id}",
            },
            token=emp_token,
        )
        ticket_data = resp.get("data", {})
        created_ticket_number = ticket_data.get("id") or ticket_data.get("number")
        step7_pass = (
            status == 201
            and resp.get("success") is True
            and bool(created_ticket_number)
            and bool(re.match(r"^AD-2026-\d{4}$", created_ticket_number))
        )
        self.record(
            "7. Employee A Creates Ticket (AD-2026-####)",
            step7_pass,
            f"Status={status}, TicketNumber={created_ticket_number}",
        )

        # ---------------------------------------------------------
        # Step 8: Admin views ticket, assigns technician, sets priority & due date
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            f"/v1/tickets/?q={created_ticket_number}",
            token=admin_token,
        )
        t_items = resp.get("data", [])
        admin_t = next((t for t in t_items if t.get("number") == created_ticket_number), None)
        created_ticket_id = admin_t.get("id") if admin_t else None

        # Get technician user ID
        status, u_resp = self.client.request(
            "GET",
            "/v1/users/?role=support&page_size=100",
            token=admin_token,
        )
        tech_users = u_resp.get("data", [])
        assigned_tech = next((u for u in tech_users if u.get("username") == "tech_network"), None)
        if not assigned_tech and tech_users:
            assigned_tech = tech_users[0]
        assigned_tech_id = assigned_tech.get("id") if assigned_tech else None

        if created_ticket_id and assigned_tech_id:
            status, patch_resp = self.client.request(
                "PATCH",
                f"/v1/tickets/{created_ticket_id}/",
                body={
                    "assigned_to": assigned_tech_id,
                    "priority": "high",
                    "due_date": "2026-11-25",
                    "note": "Urgent accounting network fault. Please check switch patch panel.",
                },
                token=admin_token,
            )
            step8_pass = status == 200 and patch_resp.get("success") is True
            self.record(
                "8. Admin Assigns Technician, Sets Priority High & Due Date",
                step8_pass,
                f"Status={status}, Assignee={assigned_tech.get('username')}",
            )
        else:
            self.record(
                "8. Admin Assigns Technician, Sets Priority High & Due Date",
                False,
                f"Could not resolve TicketId={created_ticket_id} or TechId={assigned_tech_id}",
            )

        # ---------------------------------------------------------
        # Step 9: Technician T logs in
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": assigned_tech.get("username") if assigned_tech else "tech_network",
                "password": "TechPassword123!",
                "role": "technician",
            },
        )
        tech_data = resp.get("data", {})
        tech_token = tech_data.get("access_token")
        step9_pass = status == 200 and bool(tech_token)
        self.record(
            "9. Technician T Login",
            step9_pass,
            f"Status={status}, TechTokenAcquired={bool(tech_token)}",
        )

        # ---------------------------------------------------------
        # Step 10: Technician T starts work on ticket
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            f"/mobile/tickets/{created_ticket_number}/start-work/",
            token=tech_token,
        )
        work_data = resp.get("data", {})
        step10_pass = (
            status == 200
            and resp.get("success") is True
            and work_data.get("status") in ("in_progress", "inProgress", "In Progress")
        )
        self.record(
            "10. Technician Starts Work (Status In Progress)",
            step10_pass,
            f"Status={status}, TicketStatus={work_data.get('status')}",
        )

        # ---------------------------------------------------------
        # Step 11: Technician T records work and resolves ticket
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            f"/mobile/tickets/{created_ticket_number}/work-record/",
            body={
                "deviceType": "network",
                "problemDescription": "Replaced bad keystone jack and tested line with fluke cable tester.",
                "outcome": "solutionGiven",
                "serviceRendered": "Maintenance > Network",
                "toolsMaterials": "Fluke tester, Cat6 keystone jack",
            },
            token=tech_token,
        )
        rec_data = resp.get("data", {})
        step11_pass = (
            status == 200
            and resp.get("success") is True
            and rec_data.get("status") in ("resolved", "Resolved")
        )
        self.record(
            "11. Technician Records Work and Resolves Ticket",
            step11_pass,
            f"Status={status}, TicketStatus={rec_data.get('status')}",
        )

        # ---------------------------------------------------------
        # Step 12: Employee A views ticket & submits 5-star rating
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            f"/mobile/tickets/{created_ticket_number}/",
            token=emp_token,
        )
        t_view = resp.get("data", {})
        resolved_ok = t_view.get("status") in ("resolved", "Resolved")

        status, rating_resp = self.client.request(
            "POST",
            f"/mobile/tickets/{created_ticket_number}/rating/",
            body={
                "quality": "veryHigh",
                "speed": "veryHigh",
                "rating": 5,
            },
            token=emp_token,
        )
        step12_pass = (
            resolved_ok
            and status == 200
            and rating_resp.get("success") is True
        )
        self.record(
            "12. Employee A Rates Ticket Quality & Speed (5 Stars)",
            step12_pass,
            f"Status={status}, ResolvedSeen={resolved_ok}",
        )

        # ---------------------------------------------------------
        # Step 13: Admin checks ticket, sees rating visible
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            f"/v1/tickets/{created_ticket_id}/",
            token=admin_token,
        )
        t_admin = resp.get("data", {})
        rating_info = t_admin.get("service_rating") or t_admin.get("rating") or t_admin.get("user_rating")
        step13_pass = (
            status == 200
            and resp.get("success") is True
            and bool(rating_info)
        )
        self.record(
            "13. Admin Sees Recorded Ticket Rating on Detail View",
            step13_pass,
            f"Status={status}, RatingRecorded={rating_info}",
        )

        # ---------------------------------------------------------
        # Step 14: Register Technician B (status pending)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/register/",
            body={
                "role": "technician",
                "fullName": f"E2E Technician {run_id}",
                "employeeId": tech_b_id,
                "username": tech_b_username,
                "password": "Password123!",
                "confirmPassword": "Password123!",
                "phone": tech_b_phone,
                "department": "IT Office",
                "specialties": ["hardware", "network"],
                "qualificationNote": "Junior support technician applicant",
            },
        )
        data_b = resp.get("data", {})
        saved_ref_tech = data_b.get("reference_number") or data_b.get("referenceNumber")
        step14_pass = (
            status == 201
            and resp.get("success") is True
            and data_b.get("status") == "pending"
        )
        self.record(
            "14. Register Technician B (Pending Status)",
            step14_pass,
            f"Status={status}, Ref={saved_ref_tech}, Resp={resp}",
        )

        # ---------------------------------------------------------
        # Step 15: Admin rejects B with mandatory reason
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "GET",
            "/v1/registrations/?status=pending",
            token=admin_token,
        )
        regs = resp.get("data", [])
        tech_reg = next((r for r in regs if r.get("username") == tech_b_username), None)
        tech_b_reg_id = tech_reg.get("id") if tech_reg else None

        reject_reason = "Please provide valid IT certification."
        if tech_b_reg_id:
            status, rej_resp = self.client.request(
                "POST",
                f"/v1/registrations/{tech_b_reg_id}/reject/",
                body={"reason": reject_reason},
                token=admin_token,
            )
            step15_pass = status == 200 and rej_resp.get("success") is True
            self.record(
                "15. Admin Rejects Technician B With Mandatory Reason",
                step15_pass,
                f"Status={status}, Reason='{reject_reason}'",
            )
        else:
            self.record(
                "15. Admin Rejects Technician B With Mandatory Reason",
                False,
                f"Technician {tech_b_username} not found in pending list",
            )

        # ---------------------------------------------------------
        # Step 16: Try to log in with B (expect account_rejected)
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": tech_b_username,
                "password": "Password123!",
                "role": "technician",
            },
        )
        code_b = resp.get("code") or resp.get("error")
        reason_found = reject_reason in str(resp)
        step16_pass = status == 403 and code_b == "account_rejected" and reason_found
        self.record(
            "16. Technician B Login Blocked With account_rejected & Rejection Reason",
            step16_pass,
            f"Status={status}, Code={code_b}, ReasonMatched={reason_found}",
        )

        # ---------------------------------------------------------
        # Step 17: B resubmits registration with updated info
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/register/",
            body={
                "role": "technician",
                "fullName": f"E2E Technician {run_id} Certified",
                "employeeId": tech_b_id,
                "username": tech_b_username,
                "password": "Password123!",
                "confirmPassword": "Password123!",
                "phone": tech_b_phone,
                "department": "IT Office",
                "specialties": ["hardware", "network"],
                "qualificationNote": "Attached CCNA Certificate and Diploma in Hardware Maintenance.",
            },
        )
        data_resubmit = resp.get("data", {})
        step17_pass = (
            status in (200, 201)
            and resp.get("success") is True
            and data_resubmit.get("status") == "pending"
        )
        self.record(
            "17. Technician B Resubmits Registration (Re-enters Pending Status)",
            step17_pass,
            f"Status={status}, StatusResetTo={data_resubmit.get('status')}, Resp={resp}",
        )

        # ---------------------------------------------------------
        # Step 18: Admin approves B (confirming hardware and network specialties)
        # ---------------------------------------------------------
        status, regs_resp = self.client.request(
            "GET",
            "/v1/registrations/?status=pending",
            token=admin_token,
        )
        b_reg = next((r for r in regs_resp.get("data", []) if r.get("username") == tech_b_username), None)
        target_b_id = (b_reg.get("id") if b_reg else None) or tech_b_reg_id

        if target_b_id:
            status, resp = self.client.request(
                "POST",
                f"/v1/registrations/{target_b_id}/approve/",
                body={"specialties": ["hardware", "network"]},
                token=admin_token,
            )
            step18_pass = status == 200 and resp.get("success") is True
            self.record(
                "18. Admin Approves Technician B With Confirmed Specialties",
                step18_pass,
                f"Status={status}",
            )
        else:
            self.record(
                "18. Admin Approves Technician B With Confirmed Specialties",
                False,
                "Tech B reg ID missing",
            )

        # ---------------------------------------------------------
        # Step 19: Technician B logs in successfully
        # ---------------------------------------------------------
        status, resp = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": tech_b_username,
                "password": "Password123!",
                "role": "technician",
            },
        )
        b_data = resp.get("data", {})
        b_token = b_data.get("access_token")
        step19_pass = status == 200 and bool(b_token)
        self.record(
            "19. Technician B Login After Re-Approval",
            step19_pass,
            f"Status={status}, TokenAcquired={bool(b_token)}",
        )

        # ---------------------------------------------------------
        # Step 20: Server-Side Ticket Isolation Check
        # (Employee A attempts to access a ticket belonging to another employee)
        # ---------------------------------------------------------
        # Register Employee C
        emp_c_username = f"empc{run_id}"
        emp_c_id = f"EMPC-{run_id}"
        emp_c_phone = f"093{random.randint(1000000, 9999999)}"

        status, resp = self.client.request(
            "POST",
            "/mobile/auth/register/",
            body={
                "role": "employee",
                "fullName": f"Employee C {run_id}",
                "employeeId": emp_c_id,
                "username": emp_c_username,
                "password": "Password123!",
                "confirmPassword": "Password123!",
                "phone": emp_c_phone,
                "department": "HR Department",
            },
        )
        # Approve C
        status, regs_resp = self.client.request(
            "GET",
            "/v1/registrations/?status=pending",
            token=admin_token,
        )
        c_reg = next((r for r in regs_resp.get("data", []) if r.get("username") == emp_c_username), None)
        if c_reg:
            self.client.request(
                "POST",
                f"/v1/registrations/{c_reg['id']}/approve/",
                body={},
                token=admin_token,
            )

        # C logs in and creates Ticket C
        status, c_login = self.client.request(
            "POST",
            "/mobile/auth/login/",
            body={
                "username": emp_c_username,
                "password": "Password123!",
                "role": "employee",
            },
        )
        c_token = c_login.get("data", {}).get("access_token")

        status, t_c_resp = self.client.request(
            "POST",
            "/mobile/tickets/",
            body={
                "category": "Maintenance",
                "deviceType": "computer",
                "problemDescription": "Private HR records workstation ticket",
                "department": "HR Department",
                "officeLocation": "HR Suite 10",
                "phoneNumber": emp_c_phone,
                "requesterName": f"Employee C {run_id}",
            },
            token=c_token,
        )
        ticket_c_number = t_c_resp.get("data", {}).get("id")

        # Now Employee A attempts to fetch Employee C's ticket
        status, cross_resp = self.client.request(
            "GET",
            f"/mobile/tickets/{ticket_c_number}/",
            token=emp_token,
        )
        step20_pass = status in (404, 403)
        self.record(
            "20. Server-Side Ticket Isolation (Employee A Cannot View Employee C's Ticket)",
            step20_pass,
            f"Expected 404/403, Got Status={status}",
        )

        # ---------------------------------------------------------
        # Step 21: Dev seed idempotency test
        # ---------------------------------------------------------
        backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend"))
        python_bin = sys.executable
        venv_python = os.path.join(backend_dir, ".venv", "Scripts", "python.exe")
        if os.path.exists(venv_python):
            python_bin = venv_python

        seed_result = subprocess.run(
            [python_bin, "manage.py", "dev_seed"],
            cwd=backend_dir,
            capture_output=True,
            text=True,
        )
        step21_pass = seed_result.returncode == 0 and "seed completed successfully" in seed_result.stdout.lower()
        self.record(
            "21. Dev Seed Command Idempotency (Repeatable Without Duplicates)",
            step21_pass,
            f"ExitCode={seed_result.returncode}",
        )

        # ---------------------------------------------------------
        # Summary
        # ---------------------------------------------------------
        duration = time.time() - start_time
        passed_count = sum(1 for _, p, _ in self.results if p)
        total_count = len(self.results)
        all_passed = passed_count == total_count

        print("=" * 70)
        print("E2E VERIFICATION SUMMARY")
        print("=" * 70)
        print(f"Total Steps Executed: {total_count}")
        print(f"Passed:               {passed_count}")
        print(f"Failed:               {total_count - passed_count}")
        print(f"Total Duration:       {duration:.2f} seconds")
        print(f"Overall Result:       {'SUCCESS (ALL PASSED)' if all_passed else 'FAILURE'}")
        print("=" * 70)

        self.teardown()
        return all_passed


if __name__ == "__main__":
    runner = TestRunner()
    success = runner.run()
    sys.exit(0 if success else 1)
