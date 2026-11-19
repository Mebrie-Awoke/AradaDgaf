"""DEV ONLY database seed command for AradaDgaf.

Populates initial administrative, technical, and employee accounts,
departments, paper-form service categories, and sample tickets.
Disabled unless DEV_SEED_ENABLED=true in environment or --force is supplied.
"""
import os
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandError

from core.db import get_database


def utcnow():
    return datetime.now(timezone.utc)


class Command(BaseCommand):
    help = "DEV ONLY: Seed AradaDgaf database with default demo accounts, departments, categories, and tickets."

    def add_arguments(self, parser):
        parser.add_argument(
            "--force",
            action="store_true",
            help="Force seeding even if DEV_SEED_ENABLED is not set to true.",
        )
        parser.add_argument(
            "--clean",
            action="store_true",
            help="Clear existing seeded collections before seeding.",
        )

    def handle(self, *args, **options):
        seed_enabled = os.getenv("DEV_SEED_ENABLED", "false").lower() == "true"
        if not seed_enabled and not options["force"]:
            raise CommandError(
                "DEV ONLY: dev_seed is disabled in this environment. "
                "Set DEV_SEED_ENABLED=true in your .env or pass --force to run."
            )

        self.stdout.write(self.style.WARNING("Running DEV ONLY database seed..."))
        database = get_database()

        if options["clean"]:
            self.stdout.write("Cleaning existing collections...")
            for col in ["users", "departments", "categories", "tickets", "ticket_comments", "ticket_audit", "notifications", "access_tokens"]:
                database[col].delete_many({})

        # 1. Departments
        departments_data = [
            {"name": "IT Office", "description": "Information Technology and Systems Office"},
            {"name": "Finance Department", "description": "Finance and Accounts Administration"},
            {"name": "HR Department", "description": "Human Resources and Staff Development"},
            {"name": "Legal Affairs", "description": "Legal Consultation and Regulatory Affairs"},
            {"name": "Planning Department", "description": "Strategic Planning and Budget Monitoring"},
            {"name": "Administration", "description": "General Executive Administration"},
        ]
        dept_map = {}
        for d in departments_data:
            existing = database.departments.find_one({"name": d["name"]})
            if existing:
                dept_map[d["name"]] = existing["_id"]
            else:
                doc = {**d, "is_active": True, "created_at": utcnow()}
                res = database.departments.insert_one(doc)
                dept_map[d["name"]] = res.inserted_id

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(dept_map)} departments."))

        # 2. Service Categories (Paper-form categories)
        categories_data = [
            {"name": "Maintenance > Network", "description": "Network cabling, switches, routers, and connectivity"},
            {"name": "Maintenance > Computer", "description": "Desktop PC, laptop hardware, and peripherals"},
            {"name": "Maintenance > Printer", "description": "Laser/inkjet printers, toner, and hardware paper jams"},
            {"name": "Maintenance > Copy machine", "description": "Heavy duty photocopiers and multi-function printers"},
            {"name": "Anti-virus install/renew", "description": "Antivirus installation, definition updates, and virus cleanup"},
            {"name": "New software install/renew", "description": "Operating systems, office software, and official government tools"},
            {"name": "Software fault repair", "description": "Software error debugging, driver issues, and crashes"},
            {"name": "Technical support", "description": "General user assistance, setup help, and consulting"},
            {"name": "Printer setup", "description": "Network printer configuration, shared printer drivers"},
            {"name": "Network fault", "description": "Internet outage, LAN disconnection, IP conflict"},
            {"name": "Other", "description": "Other IT technical requests and unclassified issues"},
        ]
        cat_map = {}
        for c in categories_data:
            existing = database.categories.find_one({"name": c["name"]})
            if existing:
                cat_map[c["name"]] = existing["_id"]
            else:
                doc = {**c, "is_active": True, "created_at": utcnow()}
                res = database.categories.insert_one(doc)
                cat_map[c["name"]] = res.inserted_id

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(cat_map)} categories."))

        # 3. Users
        # A. 1 Administrator
        # B. 3 Technicians (Network, Hardware, Software)
        # C. 3 Active Employees
        # D. Pending Registrations (2 Employees, 1 Technician)
        now = utcnow()
        users_to_seed = [
            # Administrator
            {
                "email": "admin@arada.gov.et",
                "username": "admin",
                "name": "System Administrator",
                "employee_id": "ADM-0001",
                "password": make_password("AdminPassword123!"),
                "role": "admin",
                "department_id": dept_map["IT Office"],
                "office_location": "Main Building, Room 301",
                "work_unit": "IT Administration",
                "phone_number": "+251911000001",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Technician 1: Network
            {
                "email": "tech.network@arada.gov.et",
                "username": "tech_network",
                "name": "Abebe Bekele",
                "employee_id": "TECH-0001",
                "password": make_password("TechPassword123!"),
                "role": "support",
                "department_id": dept_map["IT Office"],
                "office_location": "IT Building, Room 101",
                "work_unit": "Infrastructure & Networks",
                "phone_number": "+251911100001",
                "specialties": ["Network", "Anti-virus & security"],
                "qualification_note": "Certified Network Associate, 5 years LAN/WAN maintenance",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Technician 2: Hardware
            {
                "email": "tech.hardware@arada.gov.et",
                "username": "tech_hardware",
                "name": "Chala Tadesse",
                "employee_id": "TECH-0002",
                "password": make_password("TechPassword123!"),
                "role": "support",
                "department_id": dept_map["IT Office"],
                "office_location": "IT Building, Workshop Room 05",
                "work_unit": "Hardware Maintenance",
                "phone_number": "+251911100002",
                "specialties": ["Hardware", "Printers & copiers"],
                "qualification_note": "Hardware and Electronics Specialist, Certified Printer Tech",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Technician 3: Software
            {
                "email": "tech.software@arada.gov.et",
                "username": "tech_software",
                "name": "Tigist Alemu",
                "employee_id": "TECH-0003",
                "password": make_password("TechPassword123!"),
                "role": "support",
                "department_id": dept_map["IT Office"],
                "office_location": "IT Building, Room 102",
                "work_unit": "Software & Applications",
                "phone_number": "+251911100003",
                "specialties": ["Software", "Anti-virus & security"],
                "qualification_note": "Software Support Specialist, Windows/Linux Desktop Admin",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Active Employee 1: Finance
            {
                "email": "selam.worku@arada.gov.et",
                "username": "selam",
                "name": "Selam Worku",
                "employee_id": "EMP-0101",
                "password": make_password("EmpPassword123!"),
                "role": "employee",
                "department_id": dept_map["Finance Department"],
                "office_location": "Building B, Room 204",
                "work_unit": "Accounts Payable",
                "phone_number": "+251911223344",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Active Employee 2: HR
            {
                "email": "dawit.kebede@arada.gov.et",
                "username": "dawit",
                "name": "Dawit Kebede",
                "employee_id": "EMP-0102",
                "password": make_password("EmpPassword123!"),
                "role": "employee",
                "department_id": dept_map["HR Department"],
                "office_location": "Building A, Room 105",
                "work_unit": "Personnel Records",
                "phone_number": "+251922334455",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Active Employee 3: Legal
            {
                "email": "almaz.haile@arada.gov.et",
                "username": "almaz",
                "name": "Almaz Haile",
                "employee_id": "EMP-0103",
                "password": make_password("EmpPassword123!"),
                "role": "employee",
                "department_id": dept_map["Legal Affairs"],
                "office_location": "Building C, Room 301",
                "work_unit": "Legal Documentation",
                "phone_number": "+251933445566",
                "status": "active",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            },
            # Pending Employee 1: Planning
            {
                "email": "tariku.solomon@arada.gov.et",
                "username": "tariku",
                "name": "Tariku Solomon",
                "employee_id": "EMP-0201",
                "password": make_password("PendingEmp123!"),
                "role": "employee",
                "department_id": dept_map["Planning Department"],
                "office_location": "Building B, Room 110",
                "work_unit": "Budget Planning",
                "phone_number": "+251944556677",
                "status": "pending",
                "is_active": False,
                "registration_reference": "REG-2026-0001",
                "created_at": now,
                "updated_at": now,
            },
            # Pending Employee 2: Administration
            {
                "email": "marta.girma@arada.gov.et",
                "username": "marta",
                "name": "Marta Girma",
                "employee_id": "EMP-0202",
                "password": make_password("PendingEmp123!"),
                "role": "employee",
                "department_id": dept_map["Administration"],
                "office_location": "Main Building, Room 12",
                "work_unit": "General Logistics",
                "phone_number": "+251955667788",
                "status": "pending",
                "is_active": False,
                "registration_reference": "REG-2026-0002",
                "created_at": now,
                "updated_at": now,
            },
            # Pending Technician: IT Office
            {
                "email": "yohannes.kassa@arada.gov.et",
                "username": "yohannes",
                "name": "Yohannes Kassa",
                "employee_id": "EMP-0203",
                "password": make_password("PendingTech123!"),
                "role": "support",
                "department_id": dept_map["IT Office"],
                "office_location": "IT Building, Room 02",
                "work_unit": "Field Support",
                "phone_number": "+251966778899",
                "specialties": ["Network", "Hardware"],
                "qualification_note": "Cisco CCNA certified, 3 years network maintenance",
                "status": "pending",
                "is_active": False,
                "registration_reference": "REG-2026-0003",
                "created_at": now,
                "updated_at": now,
            },
        ]

        user_map = {}
        for u in users_to_seed:
            existing = database.users.find_one({"username": u["username"]})
            if existing:
                database.users.update_one({"_id": existing["_id"]}, {"$set": u})
                user_map[u["username"]] = existing["_id"]
            else:
                res = database.users.insert_one(u)
                user_map[u["username"]] = res.inserted_id

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(users_to_seed)} users (including 3 pending registrations)."))

        # 4. Sample Tickets
        # Ticket 1: Submitted (from Selam, Network issue, unassigned)
        t1_num = "AD-2026-0001"
        t1_created = now - timedelta(hours=3)
        t1_doc = {
            "number": t1_num,
            "title": "Maintenance > Network service request",
            "description": "Office network switch port is not giving IP address to workstation.",
            "category": "maintenance",
            "category_id": cat_map["Maintenance > Network"],
            "device_type": "network",
            "problem_description": "Office network switch port is not giving IP address to workstation.",
            "department": "Finance Department",
            "department_id": dept_map["Finance Department"],
            "office_location": "Building B, Room 204",
            "phone_number": "+251911223344",
            "status": "submitted",
            "mobile_status": "submitted",
            "priority": "high",
            "owner_id": user_map["selam"],
            "owner_name": "Selam Worku",
            "assigned_to": None,
            "assigned_technician": None,
            "timeline": [
                {
                    "titleKey": "request_submitted",
                    "subtitle": "Request submitted",
                    "timestamp": t1_created,
                    "isCompleted": True,
                },
                {
                    "titleKey": "in_progress",
                    "subtitle": "(Waiting for technician)",
                    "timestamp": t1_created,
                    "isCompleted": False,
                },
                {
                    "titleKey": "outcome_pending",
                    "subtitle": "Outcome pending",
                    "timestamp": t1_created,
                    "isCompleted": False,
                },
            ],
            "created_at": t1_created,
            "updated_at": t1_created,
            "version": 1,
        }

        # Ticket 2: In Progress (from Dawit, Computer repair, assigned to Chala Tadesse)
        t2_num = "AD-2026-0002"
        t2_created = now - timedelta(hours=2)
        t2_started = now - timedelta(hours=1)
        t2_doc = {
            "number": t2_num,
            "title": "Maintenance > Computer service request",
            "description": "Desktop PC power supply unit failed and machine will not turn on.",
            "category": "maintenance",
            "category_id": cat_map["Maintenance > Computer"],
            "device_type": "computer",
            "problem_description": "Desktop PC power supply unit failed and machine will not turn on.",
            "department": "HR Department",
            "department_id": dept_map["HR Department"],
            "office_location": "Building A, Room 105",
            "phone_number": "+251922334455",
            "status": "in_progress",
            "mobile_status": "inProgress",
            "priority": "medium",
            "owner_id": user_map["dawit"],
            "owner_name": "Dawit Kebede",
            "assigned_to": user_map["tech_hardware"],
            "assigned_technician": "Chala Tadesse",
            "started_at": t2_started,
            "timeline": [
                {
                    "titleKey": "request_submitted",
                    "subtitle": "Request submitted",
                    "timestamp": t2_created,
                    "isCompleted": True,
                },
                {
                    "titleKey": "in_progress",
                    "subtitle": "Assigned to Chala Tadesse",
                    "timestamp": t2_started,
                    "isCompleted": True,
                },
                {
                    "titleKey": "outcome_pending",
                    "subtitle": "Outcome pending",
                    "timestamp": t2_started,
                    "isCompleted": False,
                },
            ],
            "created_at": t2_created,
            "updated_at": t2_started,
            "version": 2,
        }

        # Ticket 3: Resolved & Rated (from Almaz, Printer setup, assigned to Chala Tadesse, completed)
        t3_num = "AD-2026-0003"
        t3_created = now - timedelta(days=1)
        t3_resolved = now - timedelta(hours=5)
        t3_doc = {
            "number": t3_num,
            "title": "Printer setup service request",
            "description": "Shared HP LaserJet network printer driver installation required.",
            "category": "technical",
            "category_id": cat_map["Printer setup"],
            "device_type": "printer",
            "problem_description": "Shared HP LaserJet network printer driver installation required.",
            "department": "Legal Affairs",
            "department_id": dept_map["Legal Affairs"],
            "office_location": "Building C, Room 301",
            "phone_number": "+251933445566",
            "status": "resolved",
            "mobile_status": "resolved",
            "priority": "low",
            "owner_id": user_map["almaz"],
            "owner_name": "Almaz Haile",
            "assigned_to": user_map["tech_hardware"],
            "assigned_technician": "Chala Tadesse",
            "resolution_note": "Installed HP LaserJet Universal PCL6 network driver and verified test page print.",
            "resolved_at": t3_resolved,
            "timeline": [
                {
                    "titleKey": "request_submitted",
                    "subtitle": "Request submitted",
                    "timestamp": t3_created,
                    "isCompleted": True,
                },
                {
                    "titleKey": "in_progress",
                    "subtitle": "Assigned to Chala Tadesse",
                    "timestamp": t3_created + timedelta(hours=1),
                    "isCompleted": True,
                },
                {
                    "titleKey": "outcome",
                    "subtitle": "solutionGiven: Installed network driver successfully",
                    "timestamp": t3_resolved,
                    "isCompleted": True,
                },
            ],
            "work_record": {
                "device_type": "printer",
                "model": "HP LaserJet Pro M404dn",
                "serial_number": "VNB3K12345",
                "problem_description": "Installed network driver successfully and printed test page.",
                "tools_materials": "LAN Cable, HP Universal Print Driver v7.0",
                "outcome": "solutionGiven",
                "solution_date_time": t3_resolved,
                "recorded_by": user_map["tech_hardware"],
            },
            "service_rating": {
                "quality": "veryHigh",
                "speed": "high",
                "rated_at": t3_resolved + timedelta(minutes=30),
            },
            "created_at": t3_created,
            "updated_at": t3_resolved,
            "version": 3,
        }

        for t_doc in [t1_doc, t2_doc, t3_doc]:
            database.tickets.update_one(
                {"number": t_doc["number"]},
                {"$set": t_doc},
                upsert=True,
            )

        # Counter sequence update
        database.counters.update_one(
            {"_id": f"mobile_ticket:{now.year}"},
            {"$max": {"sequence": 3}},
            upsert=True,
        )

        self.stdout.write(self.style.SUCCESS(f"Seeded 3 sample tickets (AD-2026-0001, 0002, 0003)."))
        self.stdout.write(self.style.SUCCESS("DEV ONLY seed completed successfully."))
