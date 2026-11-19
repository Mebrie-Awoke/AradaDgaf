import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../repository/api_ticket_repository.dart';
import '../state/app_scope.dart';
import 'registration_submitted_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const RegistrationScreen({super.key, this.initialData});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;

  UserRole _role = UserRole.employee;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _workUnitController = TextEditingController();
  final TextEditingController _officeLocationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _qualificationNoteController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _confirmChecked = false;
  bool _isSubmitting = false;

  final Set<String> _selectedSpecialties = {'Network'};

  static const List<String> _availableSpecialties = [
    'Network',
    'Hardware',
    'Software',
    'Printers & copiers',
    'Anti-virus & security',
  ];

  static const List<String> _departments = [
    'IT Office',
    'Finance Department',
    'HR Department',
    'Legal Affairs',
    'Planning Department',
    'Administration',
  ];

  String? _step1Error;
  String? _step2Error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['role'] == 'technician' || data['role'] == 'support') {
        _role = UserRole.technician;
      }
      _fullNameController.text = data['fullName'] ?? data['name'] ?? '';
      _employeeIdController.text = data['employeeId'] ?? data['employee_id'] ?? '';
      _usernameController.text = data['username'] ?? '';
      _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? data['phone_number'] ?? '';
      _emailController.text = data['email'] ?? '';
      _departmentController.text = data['department'] ?? '';
      _workUnitController.text = data['workUnit'] ?? data['work_unit'] ?? '';
      _officeLocationController.text = data['officeLocation'] ?? data['office_location'] ?? '';
      if (data['specialties'] is List) {
        _selectedSpecialties.clear();
        for (final item in data['specialties']) {
          _selectedSpecialties.add(item.toString());
        }
      }
      _qualificationNoteController.text = data['qualificationNote'] ?? data['qualification_note'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _workUnitController.dispose();
    _officeLocationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qualificationNoteController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password)) score++;
    if (password.length >= 12 || RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  bool _validateStep1() {
    final s = AppScope.of(context).s;
    final fullName = _fullNameController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (fullName.length < 3) {
      setState(() => _step1Error = s.get('name_min_chars'));
      return false;
    }

    final empIdRegex = RegExp(r'^[A-Za-z0-9\-\/]{3,20}$');
    if (!empIdRegex.hasMatch(employeeId)) {
      setState(() => _step1Error = s.get('employee_id_invalid'));
      return false;
    }

    final usernameRegex = RegExp(r'^[a-z0-9._]{4,20}$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() => _step1Error = s.get('username_invalid'));
      return false;
    }

    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      setState(() => _step1Error = s.get('password_invalid'));
      return false;
    }

    if (password != confirm) {
      setState(() => _step1Error = s.get('passwords_dont_match'));
      return false;
    }

    setState(() => _step1Error = null);
    return true;
  }

  bool _validateStep2() {
    final s = AppScope.of(context).s;
    final department = _departmentController.text.trim();
    final phone = _phoneController.text.trim();

    if (department.isEmpty) {
      setState(() => _step2Error = s.get('department_required'));
      return false;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(\+251|251|0)?[79]\d{8}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      setState(() => _step2Error = s.get('phone_invalid'));
      return false;
    }

    if (_role == UserRole.technician && _selectedSpecialties.isEmpty) {
      setState(() => _step2Error = s.get('specialties_required'));
      return false;
    }

    if (!_confirmChecked) {
      setState(() => _step2Error = s.get('confirm_required'));
      return false;
    }

    setState(() => _step2Error = null);
    return true;
  }

  Future<void> _submitRegistration() async {
    if (!_validateStep2() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _step2Error = null;
    });

    final state = AppScope.of(context);

    try {
      final res = await state.register(
        role: _role,
        fullName: _fullNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        department: _departmentController.text.trim(),
        workUnit: _workUnitController.text.trim().isNotEmpty ? _workUnitController.text.trim() : null,
        officeLocation: _officeLocationController.text.trim().isNotEmpty ? _officeLocationController.text.trim() : null,
        specialties: _role == UserRole.technician ? _selectedSpecialties.toList() : null,
        qualificationNote: _qualificationNoteController.text.trim().isNotEmpty ? _qualificationNoteController.text.trim() : null,
      );

      if (!mounted) return;

      final ref = res['referenceNumber']?.toString() ?? 'REG-2026-0000';
      final username = res['username']?.toString() ?? _usernameController.text.trim();
      final fullName = res['fullName']?.toString() ?? _fullNameController.text.trim();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationSubmittedScreen(
            referenceNumber: ref,
            username: username,
            fullName: fullName,
            role: _role == UserRole.employee ? 'employee' : 'technician',
            createdAt: DateTime.now(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _step2Error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _step2Error = 'Submission failed. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('create_account')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepperHeader(s),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _currentStep == 0 ? _buildStep1(s) : _buildStep2(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(dynamic s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          _buildStepItem(0, s.get('registration_step1'), _currentStep >= 0),
          _buildStepDivider(_currentStep >= 1),
          _buildStepItem(1, s.get('registration_step2'), _currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, bool isActive) {
    final isCurrent = _currentStep == stepIndex;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryGreen : const Color(0xFFD3E4DE),
            ),
            alignment: Alignment.center,
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? AppColors.darkGreen : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppColors.primaryGreen : const Color(0xFFD3E4DE),
    );
  }

  Widget _buildStep1(dynamic s) {
    final strength = _calculatePasswordStrength(_passwordController.text);
    Color strengthColor = Colors.grey;
    String strengthText = s.get('strength_weak');
    if (strength == 1) {
      strengthColor = Colors.red;
      strengthText = s.get('strength_weak');
    } else if (strength == 2) {
      strengthColor = Colors.orange;
      strengthText = s.get('strength_fair');
    } else if (strength >= 3) {
      strengthColor = AppColors.primaryGreen;
      strengthText = s.get('strength_strong');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector Toggle
        Text(
          s.get('service_category'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.employee,
                title: s.get('employee'),
                subtitle: s.getOther('employee'),
                icon: Icons.person_outline,
                isSelected: _role == UserRole.employee,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.technician,
                title: s.get('technician'),
                subtitle: s.getOther('technician'),
                icon: Icons.build_outlined,
                isSelected: _role == UserRole.technician,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Full Name
        TextField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: s.get('full_name'),
            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
            hintText: 'e.g. Abebe Bekele',
          ),
        ),
        const SizedBox(height: 14),

        // Employee ID
        TextField(
          controller: _employeeIdController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: s.get('employee_id'),
            prefixIcon: const Icon(Icons.tag, color: AppColors.textSecondary),
            hintText: 'e.g. EMP-1042',
          ),
        ),
        const SizedBox(height: 14),

        // Username
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: s.get('username'),
            prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textSecondary),
            hintText: 'e.g. abebe.b (4-20 chars)',
          ),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.get('password'),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            hintText: 'Min 8 chars, letters + numbers',
          ),
        ),

        // Password Strength Indicator
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${s.get('password_strength')}: ',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                strengthText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 3.0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Confirm Password
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: s.get('confirm_password'),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),

        if (_step1Error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.statusNotResolvedBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _step1Error!,
              style: const TextStyle(color: AppColors.statusNotResolved, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Next Button
        ElevatedButton(
          onPressed: () {
            if (_validateStep1()) {
              setState(() => _currentStep = 1);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.get('next'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.darkGreen : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Department Dropdown / Input
        DropdownButtonFormField<String>(
          initialValue: _departments.contains(_departmentController.text.trim())
              ? _departmentController.text.trim()
              : null,
          decoration: InputDecoration(
            labelText: s.get('department'),
            prefixIcon: const Icon(Icons.apartment_outlined, color: AppColors.textSecondary),
          ),
          items: _departments.map((dept) {
            return DropdownMenuItem<String>(
              value: dept,
              child: Text(dept, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _departmentController.text = val);
          },
        ),
        const SizedBox(height: 14),

        // Work Unit / Division
        TextField(
          controller: _workUnitController,
          decoration: InputDecoration(
            labelText: s.get('work_unit'),
            prefixIcon: const Icon(Icons.business_center_outlined, color: AppColors.textSecondary),
            hintText: 'e.g. Accounts Division',
          ),
        ),
        const SizedBox(height: 14),

        // Office Location
        TextField(
          controller: _officeLocationController,
          decoration: InputDecoration(
            labelText: s.get('office_location'),
            prefixIcon: const Icon(Icons.room_outlined, color: AppColors.textSecondary),
            hintText: 'e.g. Building B, Room 204',
          ),
        ),
        const SizedBox(height: 14),

        // Phone Number
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: s.get('phone_number'),
            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
            hintText: '0911223344 or +251911223344',
          ),
        ),
        const SizedBox(height: 14),

        // Email (Optional)
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: s.get('email_optional'),
            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
            hintText: 'username@aradasubcity.gov.et',
          ),
        ),

        // Technician Specialties & Notes
        if (_role == UserRole.technician) ...[
          const SizedBox(height: 18),
          Text(
            s.get('specialties'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _availableSpecialties.map((spec) {
              final isChosen = _selectedSpecialties.contains(spec);
              return FilterChip(
                label: Text(spec),
                selected: isChosen,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialties.add(spec);
                    } else {
                      if (_selectedSpecialties.length > 1) {
                        _selectedSpecialties.remove(spec);
                      }
                    }
                  });
                },
                selectedColor: AppColors.mintSurface,
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: isChosen ? AppColors.darkGreen : AppColors.textPrimary,
                  fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _qualificationNoteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.get('qualification_note'),
              prefixIcon: const Icon(Icons.school_outlined, color: AppColors.textSecondary),
              hintText: 'e.g. CCNA certified, 4 years computer repair experience',
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Confirmation Checkbox
        CheckboxListTile(
          value: _confirmChecked,
          onChanged: (val) => setState(() => _confirmChecked = val ?? false),
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primaryGreen,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            s.get('registration_confirm_declaration'),
            style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary),
          ),
        ),

        if (_step2Error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.statusNotResolvedBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _step2Error!,
              style: const TextStyle(color: AppColors.statusNotResolved, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons: Back & Submit
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(s.get('back'), style: const TextStyle(color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRegistration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting ? s.get('submitting_registration') : s.get('submit_registration'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
