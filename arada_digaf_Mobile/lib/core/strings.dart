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
  'demo_accounts_hint': 'Demo accounts: employee selam / 1234, technician abel / 1234',
  'not_available_demo': 'Not available in demo',
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
  'demo_offline_switch': 'Demo: simulate offline',
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
};

class S {
  final AppLanguage language;
  S(this.language);

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

