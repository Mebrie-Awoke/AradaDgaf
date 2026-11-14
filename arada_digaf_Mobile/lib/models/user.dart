enum UserRole {
  employee,
  technician;

  String get labelEn => this == UserRole.employee ? 'Employee' : 'Technician';
  String get labelAm => this == UserRole.employee ? 'ሰራተኛ' : 'ቴክኒሻን';
}

class User {
  final String username;
  final String fullName;
  final UserRole role;
  final String department;
  final String officeLocation;
  final String phoneNumber;

  const User({
    required this.username,
    required this.fullName,
    required this.role,
    required this.department,
    required this.officeLocation,
    required this.phoneNumber,
  });
}

