import 'package:flutter/material.dart';
import '../core/theme.dart';

enum TicketStatus {
  submitted,
  inProgress,
  resolved,
  notResolved,
  referred;

  String get labelEn {
    switch (this) {
      case TicketStatus.submitted:
        return 'Submitted';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.notResolved:
        return 'Not Resolved';
      case TicketStatus.referred:
        return 'Referred';
    }
  }

  String get labelAm {
    switch (this) {
      case TicketStatus.submitted:
        return 'የቀረበ';
      case TicketStatus.inProgress:
        return 'በሂደት ላይ';
      case TicketStatus.resolved:
        return 'የተፈታ';
      case TicketStatus.notResolved:
        return 'ያልተፈታ';
      case TicketStatus.referred:
        return 'የተላለፈ';
    }
  }

  Color get color {
    switch (this) {
      case TicketStatus.submitted:
        return AppColors.statusSubmitted;
      case TicketStatus.inProgress:
        return AppColors.statusInProgress;
      case TicketStatus.resolved:
        return AppColors.statusResolved;
      case TicketStatus.notResolved:
        return AppColors.statusNotResolved;
      case TicketStatus.referred:
        return AppColors.statusReferred;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TicketStatus.submitted:
        return AppColors.statusSubmittedBg;
      case TicketStatus.inProgress:
        return AppColors.statusInProgressBg;
      case TicketStatus.resolved:
        return AppColors.statusResolvedBg;
      case TicketStatus.notResolved:
        return AppColors.statusNotResolvedBg;
      case TicketStatus.referred:
        return AppColors.statusReferredBg;
    }
  }
}

enum ServiceCategory {
  maintenance,
  antivirus,
  software,
  technical,
  other;

  String get labelEn {
    switch (this) {
      case ServiceCategory.maintenance:
        return 'Maintenance';
      case ServiceCategory.antivirus:
        return 'Anti-virus';
      case ServiceCategory.software:
        return 'Software';
      case ServiceCategory.technical:
        return 'Technical';
      case ServiceCategory.other:
        return 'Other';
    }
  }

  String get labelAm {
    switch (this) {
      case ServiceCategory.maintenance:
        return 'ጥገና';
      case ServiceCategory.antivirus:
        return 'አንቲ ቫይረስ';
      case ServiceCategory.software:
        return 'ሶፍትዌር';
      case ServiceCategory.technical:
        return 'ቴክኒካል ድጋፍ';
      case ServiceCategory.other:
        return 'ሌላ';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.maintenance:
        return Icons.build_outlined;
      case ServiceCategory.antivirus:
        return Icons.shield_outlined;
      case ServiceCategory.software:
        return Icons.download_outlined;
      case ServiceCategory.technical:
        return Icons.support_agent_outlined;
      case ServiceCategory.other:
        return Icons.more_horiz_outlined;
    }
  }
}

enum DeviceType {
  computer,
  printer,
  network,
  copyMachine,
  other;

  String get labelEn {
    switch (this) {
      case DeviceType.computer:
        return 'Computer';
      case DeviceType.printer:
        return 'Printer';
      case DeviceType.network:
        return 'Network';
      case DeviceType.copyMachine:
        return 'Copy machine';
      case DeviceType.other:
        return 'Other';
    }
  }

  String get labelAm {
    switch (this) {
      case DeviceType.computer:
        return 'ኮምፒውተር';
      case DeviceType.printer:
        return 'ፕሪንተር';
      case DeviceType.network:
        return 'ኔትወርክ';
      case DeviceType.copyMachine:
        return 'ኮፒ ማሽን';
      case DeviceType.other:
        return 'ሌላ';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.printer:
        return Icons.print_outlined;
      case DeviceType.network:
        return Icons.wifi;
      case DeviceType.copyMachine:
        return Icons.scanner_outlined;
      case DeviceType.other:
        return Icons.devices_other;
    }
  }
}

enum WorkOutcome {
  solutionGiven,
  solutionNotGiven,
  referredExternally;

  String get labelEn {
    switch (this) {
      case WorkOutcome.solutionGiven:
        return 'Solution given';
      case WorkOutcome.solutionNotGiven:
        return 'Solution not given';
      case WorkOutcome.referredExternally:
        return 'Referred externally';
    }
  }

  String get labelAm {
    switch (this) {
      case WorkOutcome.solutionGiven:
        return 'መፍትሄ ተሰጥቷል';
      case WorkOutcome.solutionNotGiven:
        return 'መፍትሄ አልተሰጠም';
      case WorkOutcome.referredExternally:
        return 'ወደ ውጭ ተመርቷል';
    }
  }
}

enum RatingLevel {
  veryHigh,
  high,
  medium,
  low;

  String get labelEn {
    switch (this) {
      case RatingLevel.veryHigh:
        return 'Very high (>90)';
      case RatingLevel.high:
        return 'High (70-89)';
      case RatingLevel.medium:
        return 'Medium (51-69)';
      case RatingLevel.low:
        return 'Low (<50)';
    }
  }

  String get labelAm {
    switch (this) {
      case RatingLevel.veryHigh:
        return 'በጣም ከፍተኛ (>90)';
      case RatingLevel.high:
        return 'ከፍተኛ (70-89)';
      case RatingLevel.medium:
        return 'መካከለኛ (51-69)';
      case RatingLevel.low:
        return 'ዝቅተኛ (<50)';
    }
  }
}

class ServiceRating {
  final RatingLevel quality;
  final RatingLevel speed;
  final DateTime ratedAt;

  const ServiceRating({
    required this.quality,
    required this.speed,
    required this.ratedAt,
  });
}

class WorkRecord {
  final String deviceType;
  final String? model;
  final String? serialNumber;
  final String problemDescription;
  final String? toolsMaterials;
  final WorkOutcome outcome;
  final DateTime solutionDateTime;

  const WorkRecord({
    required this.deviceType,
    this.model,
    this.serialNumber,
    required this.problemDescription,
    this.toolsMaterials,
    required this.outcome,
    required this.solutionDateTime,
  });
}

class TimelineEvent {
  final String titleKey;
  final String subtitle;
  final DateTime timestamp;
  final bool isCompleted;

  const TimelineEvent({
    required this.titleKey,
    required this.subtitle,
    required this.timestamp,
    required this.isCompleted,
  });
}

class Ticket {
  final String id;
  final ServiceCategory category;
  final DeviceType? deviceType;
  final String problemDescription;
  final String department;
  final String officeLocation;
  final String phoneNumber;
  final DateTime createdAt;
  TicketStatus status;
  final String requesterName;
  String? assignedTechnician;
  final List<TimelineEvent> timeline;
  WorkRecord? workRecord;
  ServiceRating? rating;

  Ticket({
    required this.id,
    required this.category,
    this.deviceType,
    required this.problemDescription,
    required this.department,
    required this.officeLocation,
    required this.phoneNumber,
    required this.createdAt,
    required this.status,
    required this.requesterName,
    this.assignedTechnician,
    required this.timeline,
    this.workRecord,
    this.rating,
  });

  String get fullCategoryDisplayEn {
    if (category == ServiceCategory.maintenance && deviceType != null) {
      return 'Maintenance - ${deviceType!.labelEn}';
    }
    return category.labelEn;
  }

  String get fullCategoryDisplayAm {
    if (category == ServiceCategory.maintenance && deviceType != null) {
      return 'ጥገና - ${deviceType!.labelAm}';
    }
    return category.labelAm;
  }
}

