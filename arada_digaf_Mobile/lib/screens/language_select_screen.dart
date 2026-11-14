import 'package:flutter/material.dart';
import '../core/painters.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../state/app_scope.dart';
import 'login_screen.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late AppLanguage _selectedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage = AppScope.of(context).language;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Header
              Text(
                s.get('select_language'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.getOther('select_language'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 36),

              // Amharic Option Card
              _buildLanguageOptionCard(
                language: AppLanguage.amharic,
                title: 'አማርኛ',
                subtitle: 'Amharic',
                leading: const EthiopianFlag(width: 38, circular: true),
                isSelected: _selectedLanguage == AppLanguage.amharic,
                onTap: () {
                  setState(() => _selectedLanguage = AppLanguage.amharic);
                  state.setLanguage(AppLanguage.amharic);
                },
              ),

              const SizedBox(height: 16),

              // English Option Card
              _buildLanguageOptionCard(
                language: AppLanguage.english,
                title: 'English',
                subtitle: 'እንግሊዝኛ',
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBDD0E4), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'EN',
                    style: TextStyle(
                      color: Color(0xFF194A7A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                isSelected: _selectedLanguage == AppLanguage.english,
                onTap: () {
                  setState(() => _selectedLanguage = AppLanguage.english);
                  state.setLanguage(AppLanguage.english);
                },
              ),

              const Spacer(),

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  state.setLanguage(_selectedLanguage);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.get('continue'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        s.getOther('continue'),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required AppLanguage language,
    required String title,
    required String subtitle,
    required Widget leading,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : const Color(0xFFC5D6CF),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

