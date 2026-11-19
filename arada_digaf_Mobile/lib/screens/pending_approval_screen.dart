import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../repository/api_ticket_repository.dart';
import '../state/app_scope.dart';
import 'login_screen.dart';
import 'registration_rejected_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String referenceNumber;
  final String username;

  const PendingApprovalScreen({
    super.key,
    required this.referenceNumber,
    required this.username,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final state = AppScope.of(context);
    final s = state.s;

    try {
      final res = await state.checkRegistrationStatus(
        referenceNumber: widget.referenceNumber,
        username: widget.username,
      );
      if (!mounted) return;
      final status = res['status']?.toString().toLowerCase();
      if (status == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text(s.get('status_approved_notice')),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (status == 'rejected') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationRejectedScreen(
              referenceNumber: widget.referenceNumber,
              username: widget.username,
              rejectionReason: res['rejectionReason']?.toString() ?? '',
              userData: res,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.get('status_pending_notice')),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify status. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.get('pending_approval_title')),
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

              // Pending Clock/Shield Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.statusInProgressBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.statusInProgress.withAlpha(100), width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_outlined,
                    color: AppColors.statusInProgress,
                    size: 46,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bilingual Heading
              Text(
                s.get('pending_approval_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              Text(
                s.getOther('pending_approval_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusInProgress,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 20),

              // Reference Number Card
              if (widget.referenceNumber.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.get('reference_number'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.referenceNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.1,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Text(
                s.get('pending_approval_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),

              const Spacer(flex: 3),

              // Check Status Button
              ElevatedButton(
                onPressed: _isChecking ? null : _checkStatus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isChecking)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.refresh, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isChecking ? 'Checking...' : s.get('check_status'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
