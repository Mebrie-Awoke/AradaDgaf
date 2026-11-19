import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/app_scope.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class RegistrationRejectedScreen extends StatelessWidget {
  final String referenceNumber;
  final String username;
  final String rejectionReason;
  final Map<String, dynamic>? userData;

  const RegistrationRejectedScreen({
    super.key,
    required this.referenceNumber,
    required this.username,
    required this.rejectionReason,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.get('registration_rejected_title')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Red Alert Badge
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.statusNotResolvedBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.statusNotResolved.withAlpha(120), width: 2),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.statusNotResolved,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                s.get('registration_rejected_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              Text(
                s.getOther('registration_rejected_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusNotResolved,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 24),

              // Reference Number
              if (referenceNumber.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.get('reference_number')}: $referenceNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // Rejection Reason Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusNotResolvedBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.statusNotResolved.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.statusNotResolved),
                        const SizedBox(width: 8),
                        Text(
                          s.get('rejection_reason_label'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusNotResolved,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rejectionReason.isNotEmpty
                          ? rejectionReason
                          : 'No additional details provided by administrator.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F1D1D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Edit and Resubmit Button
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note, size: 22),
                label: Text(
                  s.get('edit_and_resubmit'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrationScreen(
                        initialData: userData ?? {
                          'username': username,
                          'referenceNumber': referenceNumber,
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Back to Login Button
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  s.get('back_to_login'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
