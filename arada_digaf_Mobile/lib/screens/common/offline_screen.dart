import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../state/app_scope.dart';
import '../employee/request_submitted_screen.dart';

class OfflineScreen extends StatefulWidget {
  final VoidCallback onViewMyTickets;

  const OfflineScreen({
    super.key,
    required this.onViewMyTickets,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _handleTryAgain() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final state = AppScope.of(context);
    final s = state.s;

    if (state.isOfflineSimulated) {
      setState(() {
        _isChecking = false;
        _statusMessage = s.get('offline_draft_saved');
      });
    } else {
      // Offline mode was turned off! Submit the pending draft
      final draft = state.pendingDraft;
      if (draft != null) {
        final ticket = await state.submitTicket(draft);
        if (!mounted) return;
        if (ticket != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RequestSubmittedScreen(
                ticket: ticket,
                onViewMyTickets: widget.onViewMyTickets,
              ),
            ),
          );
          return;
        }
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Wi-Fi Off Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.darkGreen,
                    size: 56,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title bilingual
              Text(
                s.get('you_are_offline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.getOther('you_are_offline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 20),

              // Subtitle
              Text(
                s.get('offline_draft_saved'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusInProgressBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.statusInProgress,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 3),

              // Try Again Button
              ElevatedButton(
                onPressed: _isChecking ? null : _handleTryAgain,
                child: _isChecking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.get('try_again'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s.getOther('try_again'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
