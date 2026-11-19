import 'package:flutter/material.dart';
import 'strings_am.dart';

enum AppLanguage {
  amharic,
  english;

  bool get isAmharic => this == AppLanguage.amharic;
}

const Map<String, String> stringsEn = {
  // App & General
  'app_name': 'Arada Digaf',
  'tagline': 'Report. Track. Resolve.',
  'it_support': 'IT Support',
  'reliable': 'Reliable',
  'for_better_arada': 'For a Better Arada',
  'confirm': 'Confirm',
  'cancel': 'Cancel',
  'close': 'Close',
  'continue': 'Continue',
  'next': 'Next ->',
  'back': 'Back',
  'save': 'Save',
  'search': 'Search...',
  'empty': 'No data available',

  // Language Select
  'select_language': 'Select Language',
  'amharic': 'አማርኛ',
  'english': 'English',

  // Authentication
  'employee': 'Employee',
  'technician': 'Technician',
  'username': 'Username',
  'password': 'Password',
  'login': 'Login',
  'forgot_password': 'Forgot password?',
  'invalid_credentials': 'Invalid username or password',

  // Employee Home
  'hello': 'Hello',
  'how_can_we_help': 'How can we help you today?',
  'new_ticket': '+ New Ticket',
  'quick_services': 'Quick Services',

  // Categories & Devices
  'computer': 'Computer',
  'printer': 'Printer',
  'network': 'Network',
  'software': 'Software',
  'maintenance': 'Maintenance',
  'antivirus': 'Anti-virus',
  'technical': 'Technical',
  'other': 'Other',
  'copy_machine': 'Copy machine',

  // New Ticket Flow
  'step_service_details': 'Service Details',
  'step_problem_desc': 'Problem Description',
  'step_review_submit': 'Review & Submit',
  'service_category': 'Service Category',
  'select_device': 'Select Device',
  'problem_description': 'Problem Description',
  'problem_desc_hint': 'Describe the problem in detail (min 10 characters)...',
  'min_10_chars': 'Must be at least 10 characters',
  'department': 'Department',
  'office_location': 'Office location / Room',
  'phone_number': 'Phone number',
  'date': 'Date',
  'select_date': 'Select Date',
  'review_request': 'Review Your Request',
  'confirm_accurate': 'I confirm the information is correct.',
  'submit_request': 'Submit Request',
  'service': 'Service',

  // Request Submitted
  'request_submitted_title': 'Request Submitted!',
  'ticket_id': 'Ticket ID',
  'track_ticket_hint': 'You can track your request from My Tickets.',
  'view_my_tickets': 'View My Tickets',

  // My Tickets
  'my_tickets': 'My Tickets',
  'search_tickets_hint': 'Search tickets...',
  'all': 'All',
  'status_submitted': 'Submitted',
  'status_in_progress': 'In Progress',
  'status_resolved': 'Resolved',
  'status_not_resolved': 'Not Resolved',
  'status_referred': 'Referred',
  'no_tickets_found': 'No tickets found',

  // Ticket Details
  'ticket_details': 'Ticket Details',
  'timeline': 'Timeline',
  'request_submitted': 'Request submitted',
  'in_progress': 'In progress',
  'waiting_technician': '(Waiting for technician)',
  'technician_assigned': 'Technician assigned',
  'outcome_pending': 'Outcome pending',
  'rate_service': 'Rate Service',
  'rate_service_hint': 'Rating available after service is completed',
  'your_rating': 'Your Rating',

  // Rating Screen
  'rate_our_service': 'Rate Our Service',
  'quality': 'Quality',
  'speed': 'Speed',
  'very_high': 'Very high (>90)',
  'high': 'High (70-89)',
  'medium': 'Medium (51-69)',
  'low': 'Low (<50)',
  'submit_rating': 'Submit Rating',
  'rating_success': 'Thank you for rating our service!',

  // Technician Role
  'technician_portal': 'Technician Portal',
  'tab_new': 'New',
  'tab_my_work': 'My Work',
  'tab_done': 'Done',
  'start_work': 'Start Work',
  'record_work': 'Record Work',
  'device_info': 'Device Information',
  'device_type': 'Device Type',
  'model_optional': 'Model (Optional)',
  'serial_optional': 'Serial Number (Optional)',
  'tools_materials': 'Tools/materials used (Optional)',
  'solution_datetime': 'Solution Date & Time',
  'outcome': 'Outcome',
  'solution_given': 'Solution given',
  'solution_not_given': 'Solution not given',
  'referred_externally': 'Referred externally',
  'submit_work': 'Submit Work',
  'work_submitted_success': 'Work record submitted successfully',

  // Notifications
  'notifications': 'Notifications',
  'no_notifications': 'No notifications',

  // Profile
  'profile': 'Profile',
  'language': 'Language',
  'about_app': 'About Arada Digaf',
  'help_support': 'Help & Support',
  'logout': 'Logout',
  'about_desc': 'Arada Digaf - IT Support Ticketing Application for Arada Subcity Administration. Version 0.1.0',
  'support_contact': 'IT Support Helpdesk\nPhone: 8080 / +251 11 123 4567\nEmail: support@aradasubcity.gov.et',

  // Offline Screen
  'you_are_offline': 'You\'re Offline',
  'offline_draft_saved': 'Your draft is saved locally, but not submitted yet.',
  'try_again': 'Try Again',

  // Bottom Nav
  'nav_home': 'Home',
  'nav_my_tickets': 'My Tickets',
  'nav_profile': 'Profile',

  // Registration & Account Approval
  'register': 'Register',
  'dont_have_account': 'Don\'t have an account? Register',
  'create_account': 'Create Account',
  'registration_step1': 'Account Credentials',
  'registration_step2': 'Work Details',
  'full_name': 'Full Name',
  'employee_id': 'Employee ID',
  'confirm_password': 'Confirm Password',
  'password_strength': 'Password strength',
  'strength_weak': 'Weak',
  'strength_fair': 'Fair',
  'strength_strong': 'Strong',
  'work_unit': 'Work Unit / Division',
  'email_optional': 'Email Address (Optional)',
  'specialties': 'Technician Specialties',
  'qualification_note': 'Qualification Note (Optional)',
  'registration_confirm_declaration': 'I confirm that all provided employment information is accurate and true.',
  'submit_registration': 'Submit Registration',
  'submitting_registration': 'Submitting registration...',
  'registration_submitted_title': 'Registration Submitted!',
  'registration_submitted_desc': 'Your registration has been submitted. Your account will become active once an administrator approves your request. Please note that SMS/push notifications are not sent; you can check your approval status using your reference number.',
  'reference_number': 'Reference Number',
  'registration_date': 'Registration Date',
  'check_status': 'Check Status',
  'back_to_login': 'Back to Login',
  'pending_approval_title': 'Registration Pending Approval',
  'pending_approval_desc': 'Your account registration is currently under review by an Arada Subcity administrator. Please check back later.',
  'registration_rejected_title': 'Registration Not Approved',
  'rejection_reason_label': 'Administrator\'s Reason',
  'edit_and_resubmit': 'Edit and Resubmit',
  'account_suspended_title': 'Account Suspended',
  'account_suspended_desc': 'This account has been deactivated or suspended. Please contact your system administrator.',
  'name_min_chars': 'Full name must be at least 3 letters.',
  'employee_id_invalid': 'Employee ID must be 3-20 characters (letters, digits, "-" or "/").',
  'username_invalid': 'Username must be 4-20 lowercase letters, digits, "." or "_".',
  'phone_invalid': 'Enter a valid Ethiopian phone number (e.g. 0911223344).',
  'password_invalid': 'Password must be at least 8 characters with a letter and a digit.',
  'passwords_dont_match': 'Passwords do not match.',
  'department_required': 'Department is required.',
  'specialties_required': 'Select at least one specialty.',
  'confirm_required': 'Please confirm the information is correct.',
  'status_pending_notice': 'Your registration is still awaiting administrator approval.',
  'status_approved_notice': 'Your account has been approved! You can now log in.',
};

class S {
  final AppLanguage language;
  S(this.language);

  bool get isAmharic => language.isAmharic;

  String get(String key) {
    if (language == AppLanguage.amharic) {
      return stringsAm[key] ?? stringsEn[key] ?? key;
    }
    return stringsEn[key] ?? stringsAm[key] ?? key;
  }

  String getOther(String key) {
    if (language == AppLanguage.amharic) {
      return stringsEn[key] ?? key;
    }
    return stringsAm[key] ?? key;
  }

  /// Helper for bilingual widget building
  Widget bilingual({
    required String key,
    TextStyle? primaryStyle,
    TextStyle? secondaryStyle,
    TextAlign textAlign = TextAlign.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final primary = get(key);
    final secondary = getOther(key);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          primary,
          textAlign: textAlign,
          style: primaryStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
        ),
        if (primary != secondary) ...[
          const SizedBox(height: 2),
          Text(
            secondary,
            textAlign: textAlign,
            style: secondaryStyle ??
                TextStyle(
                  fontSize: 12,
                  color: (primaryStyle?.color ?? Colors.black87).withAlpha(180),
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

