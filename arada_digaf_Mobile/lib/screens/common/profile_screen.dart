import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    final s = AppScope.of(context).s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.get('about_app')),
        content: Text(
          s.get('about_desc'),
          style: const TextStyle(height: 1.45),
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

  void _showHelpSupportDialog(BuildContext context) {
    final s = AppScope.of(context).s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.get('help_support')),
        content: Text(
          s.get('support_contact'),
          style: const TextStyle(height: 1.45),
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
    final isAmharic = state.language.isAmharic;
    final user = state.currentUser ?? AppState.demoEmployee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('profile')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Avatar & User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Avatar Circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.mintSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // User Name
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Role Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                      ),
                      child: Text(
                        isAmharic ? user.role.labelAm : user.role.labelEn,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '${user.department} • ${user.officeLocation}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings Options Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Language Switcher
                    ListTile(
                      leading: const Icon(Icons.language, color: AppColors.primaryGreen),
                      title: Text(
                        s.get('language'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.language == AppLanguage.amharic ? 'አማርኛ' : 'English',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.swap_horiz, size: 20, color: AppColors.primaryGreen),
                        ],
                      ),
                      onTap: () {
                        state.toggleLanguage();
                      },
                    ),

                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),

                    // About App
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                      title: Text(
                        s.get('about_app'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => _showAboutDialog(context),
                    ),

                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),

                    // Help & Support
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: AppColors.primaryGreen),
                      title: Text(
                        s.get('help_support'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => _showHelpSupportDialog(context),
                    ),

                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),

                    // Demo: Simulate Offline Switch
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_off_outlined, color: AppColors.primaryGreen),
                      title: Text(
                        s.get('demo_offline_switch'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      activeTrackColor: AppColors.primaryGreen,
                      activeThumbColor: Colors.white,
                      value: state.isOfflineSimulated,
                      onChanged: (val) {
                        state.setSimulateOffline(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              InkWell(
                onTap: () {
                  state.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.statusNotResolved.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: AppColors.statusNotResolved, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        s.get('logout'),
                        style: const TextStyle(
                          color: AppColors.statusNotResolved,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
