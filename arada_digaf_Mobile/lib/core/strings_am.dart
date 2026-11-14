// TODO verify with native speaker
// Amharic localization strings for Arada Digaf

const Map<String, String> stringsAm = {
  // App & General
  'app_name': 'አራዳ ድጋፍ',
  'tagline': 'ሪፖርት ያድርጉ። ይከታተሉ። ይፍቱ።',
  'it_support': 'የአይቲ ድጋፍ',
  'reliable': 'አስተማማኝ',
  'for_better_arada': 'ለተሻለ አራዳ',
  'confirm': 'አረጋግጥ',
  'cancel': 'ሰርዝ',
  'close': 'ዝጋ',
  'continue': 'ቀጥል',
  'next': 'ቀጣይ',
  'back': 'ተመለስ',
  'save': 'አስቀምጥ',
  'search': 'ፈልግ...',
  'empty': 'ምንም መረጃ የለም',

  // Language Select
  'select_language': 'ቋንቋ ይምረጡ',
  'amharic': 'አማርኛ',
  'english': 'English',

  // Authentication
  'employee': 'ሰራተኛ',
  'technician': 'ቴክኒሻን',
  'username': 'የተጠቃሚ ስም',
  'password': 'የይለፍ ቃል',
  'login': 'ግባ',
  'forgot_password': 'የይለፍ ቃል ረሱ?',
  'demo_accounts_hint': 'የማሳያ አካውንቶች: ሰራተኛ selam / 1234, ቴክኒሻን abel / 1234',
  'not_available_demo': 'በዚህ ማሳያ ላይ አይገኝም',
  'invalid_credentials': 'የተሳሳተ የተጠቃሚ ስም ወይም የይለፍ ቃል',

  // Employee Home
  'hello': 'ሰላም',
  'how_can_we_help': 'ዛሬ ምን እንርዳዎ?',
  'new_ticket': 'አዲስ ጥያቄ',
  'quick_services': 'ፈጣን አገልግሎቶች',

  // Categories & Devices
  'computer': 'ኮምፒውተር',
  'printer': 'ፕሪንተር',
  'network': 'ኔትወርክ',
  'software': 'ሶፍትዌር',
  'maintenance': 'ጥገና',
  'antivirus': 'አንቲ ቫይረስ',
  'technical': 'ቴክኒካል ድጋፍ',
  'other': 'ሌላ',
  'copy_machine': 'ኮፒ ማሽን',

  // New Ticket Flow
  'step_service_details': 'የአገልግሎት ዝርዝር',
  'step_problem_desc': 'የችግሩ መግለጫ',
  'step_review_submit': 'ይገምግሙና ያስገቡ',
  'service_category': 'የአገልግሎት ዓይነት',
  'select_device': 'መሣሪያ ይምረጡ',
  'problem_description': 'የችግሩ መግለጫ',
  'problem_desc_hint': 'ችግሩን በዝርዝር ይግለጹ (ቢያንስ 10 ፊደላት)...',
  'min_10_chars': 'ቢያንስ 10 ፊደላት መጻፍ አለብዎት',
  'department': 'ክፍል / ቢሮ',
  'office_location': 'የቢሮ ቦታ / ክፍል ቁጥር',
  'phone_number': 'ስልክ ቁጥር',
  'date': 'ቀን',
  'select_date': 'ቀን ይምረጡ',
  'review_request': 'ጥያቄዎን ይመልከቱ',
  'confirm_accurate': 'የሰጠሁት መረጃ ትክክል መሆኑን አረጋግጣለሁ።',
  'submit_request': 'ጥያቄውን ላክ',
  'service': 'አገልግሎት',

  // Request Submitted
  'request_submitted_title': 'ጥያቄዎ ተላከ!',
  'ticket_id': 'የጥያቄ መለያ',
  'track_ticket_hint': 'ጥያቄዎትን ከ\'የእኔ ጥያቄዎች\' መከታተል ይችላሉ።',
  'view_my_tickets': 'የእኔ ጥያቄዎችን እይ',

  // My Tickets
  'my_tickets': 'የእኔ ጥያቄዎች',
  'search_tickets_hint': 'ጥያቄዎችን ይፈልጉ...',
  'all': 'ሁሉም',
  'status_submitted': 'የቀረበ',
  'status_in_progress': 'በሂደት ላይ',
  'status_resolved': 'የተፈታ',
  'status_not_resolved': 'ያልተፈታ',
  'status_referred': 'የተላለፈ',
  'no_tickets_found': 'ምንም ጥያቄዎች አልተገኙም',

  // Ticket Details
  'ticket_details': 'የጥያቄ ዝርዝር',
  'timeline': 'የሂደት ቅደም ተከተል',
  'request_submitted': 'ጥያቄው ቀርቧል',
  'in_progress': 'በሂደት ላይ',
  'waiting_technician': 'ቴክኒሻን በመጠባበቅ ላይ',
  'technician_assigned': 'ቴክኒሻን ተመድቧል',
  'outcome_pending': 'ውጤት በመጠባበቅ ላይ',
  'rate_service': 'አገልግሎቱን ይገምግሙ',
  'rate_service_hint': 'ደረጃ መስጠት የሚቻለው ስራው ሲጠናቀቅ ነው',
  'your_rating': 'የሰጡት ግምገማ',

  // Rating Screen
  'rate_our_service': 'አገልግሎታችንን ይገምግሙ',
  'quality': 'ከጥራት አንጻር',
  'speed': 'ከፍጥነት አንጻር',
  'very_high': 'በጣም ከፍተኛ (>90)',
  'high': 'ከፍተኛ (70-89)',
  'medium': 'መካከለኛ (51-69)',
  'low': 'ዝቅተኛ (<50)',
  'submit_rating': 'ግምገማውን ላክ',
  'rating_success': 'አገልግሎታችንን ስለገመገሙ እናመሰግናለን!',

  // Technician Role
  'technician_portal': 'የቴክኒሻን ፖርታል',
  'tab_new': 'አዳዲስ',
  'tab_my_work': 'የእኔ ስራ',
  'tab_done': 'የተጠናቀቁ',
  'start_work': 'ስራ ጀምር',
  'record_work': 'የስራ መዝገብ',
  'device_info': 'የመሣሪያ መረጃ',
  'device_type': 'የመሣሪያ ዓይነት',
  'model_optional': 'ሞዴል (አማራጭ)',
  'serial_optional': 'መለያ ቁጥር (አማራጭ)',
  'tools_materials': 'ጥቅም ላይ የዋሉ ዕቃዎች (አማራጭ)',
  'solution_datetime': 'የመፍትሄ ቀንና ሰዓት',
  'outcome': 'ውጤት',
  'solution_given': 'መፍትሄ ተሰጥቷል',
  'solution_not_given': 'መፍትሄ አልተሰጠም',
  'referred_externally': 'ወደ ውጭ ተመርቷል',
  'submit_work': 'ስራውን አስገባ',
  'work_submitted_success': 'የስራ መዝገብ በተሳካ ሁኔታ ገብቷል',

  // Notifications
  'notifications': 'ማሳወቂያዎች',
  'no_notifications': 'ምንም ማሳወቂያዎች የሉም',

  // Profile
  'profile': 'መገለጫ',
  'language': 'ቋንቋ',
  'about_app': 'ስለ አራዳ ድጋፍ',
  'help_support': 'እርዳታና ድጋፍ',
  'logout': 'ውጣ',
  'demo_offline_switch': 'ማሳያ: ኦፍላይን አስመስል',
  'about_desc': 'አራዳ ድጋፍ - የአራዳ ክፍለ ከተማ አስተዳደር የመረጃ ቴክኖሎጂ ድጋፍ አገልግሎት መተግበሪያ። ሥሪት 0.1.0',
  'support_contact': 'የአይቲ ድጋፍ ክፍል\nስልክ: 8080 / +251 11 123 4567\nኢሜይል: support@aradasubcity.gov.et',

  // Offline Screen
  'you_are_offline': 'ከኢንተርኔት ጋር አልተገናኙም',
  'offline_draft_saved': 'ረቂቅዎ ተቀምጧል፣ ነገር ግን እስካሁን አልተላከም።',
  'try_again': 'ደግመው ይሞክሩ',

  // Bottom Nav
  'nav_home': 'መነሻ',
  'nav_my_tickets': 'የእኔ ጥያቄዎች',
  'nav_profile': 'መገለጫ',
};

