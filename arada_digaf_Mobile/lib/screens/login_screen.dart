import 'package:flutter/material.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../state/app_scope.dart';
import 'employee/employee_main_navigation.dart';
import 'technician/technician_main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.employee;
  final TextEditingController _usernameController =
      TextEditingController(text: 'selam');
  final TextEditingController _passwordController =
      TextEditingController(text: '1234');
  bool _obscurePassword = true;
  String? _errorMessage;

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      if (role == UserRole.employee) {
        _usernameController.text = 'selam';
        _passwordController.text = '1234';
      } else {
        _usernameController.text = 'abel';
        _passwordController.text = '1234';
      }
    });
  }

  void _handleLogin() {
    final state = AppScope.of(context);
    final success = state.login(
      _usernameController.text,
      _passwordController.text,
      _selectedRole,
    );

    if (success) {
      if (_selectedRole == UserRole.employee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeMainNavigation()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianMainNavigation()),
        );
      }
    } else {
      setState(() {
        _errorMessage = state.s.get('invalid_credentials');
      });
    }
  }

  void _showForgotPasswordDialog() {
    final s = AppScope.of(context).s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.get('forgot_password')),
        content: Text(
          '${s.get('not_available_demo')}\n\n${s.get('demo_accounts_hint')}',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Logo
              const Center(
                child: HeadsetScreenLogo(size: 76),
              ),
              const SizedBox(height: 16),
              // App Name & Tagline
              Center(
                child: Column(
                  children: [
                    Text(
                      s.get('app_name'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      s.getOther('app_name'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Report. Track. Resolve.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withAlpha(220),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Segmented Toggle: Employee | Technician
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onRoleChanged(UserRole.employee),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.employee
                                ? AppColors.darkGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.get('employee'),
                            style: TextStyle(
                              color: _selectedRole == UserRole.employee
                                  ? Colors.white
                                  : AppColors.darkGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onRoleChanged(UserRole.technician),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.technician
                                ? AppColors.darkGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.get('technician'),
                            style: TextStyle(
                              color: _selectedRole == UserRole.technician
                                  ? Colors.white
                                  : AppColors.darkGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: s.get('username'),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: s.get('password'),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.statusNotResolved, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _handleLogin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+ ${s.get('login')}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password?
              Center(
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    s.get('forgot_password'),
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Demo Accounts Hint Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface.withAlpha(140),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.get('demo_accounts_hint'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGreen,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

