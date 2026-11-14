import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';

class RateServiceScreen extends StatefulWidget {
  final Ticket ticket;

  const RateServiceScreen({super.key, required this.ticket});

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  RatingLevel? _selectedQuality;
  RatingLevel? _selectedSpeed;
  bool _isSubmitting = false;

  void _handleSubmit() async {
    if (_selectedQuality == null || _selectedSpeed == null) return;

    setState(() => _isSubmitting = true);

    final rating = ServiceRating(
      quality: _selectedQuality!,
      speed: _selectedSpeed!,
      ratedAt: DateTime.now(),
    );

    final state = AppScope.of(context);
    await state.rateTicket(widget.ticket.id, rating);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.s.get('rating_success')),
        backgroundColor: AppColors.primaryGreen,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final isAmharic = state.language.isAmharic;

    final canSubmit = _selectedQuality != null && _selectedSpeed != null && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.get('rate_our_service'), style: const TextStyle(fontSize: 18)),
            Text(
              s.getOther('rate_our_service'),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket ID Reference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.ticket.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.ticket.status.labelEn,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.ticket.status.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group 1: Quality (ከጥራት አንጻር)
              Text(
                '${s.get('quality')} (${s.getOther('quality')})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ...RatingLevel.values.map((level) {
                final isSelected = _selectedQuality == level;
                final text = isAmharic ? level.labelAm : level.labelEn;
                final subtext = isAmharic ? level.labelEn : level.labelAm;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedQuality = level),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mintSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                Text(
                                  subtext,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Group 2: Speed (ከፍጥነት አንጻር)
              Text(
                '${s.get('speed')} (${s.getOther('speed')})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ...RatingLevel.values.map((level) {
                final isSelected = _selectedSpeed == level;
                final text = isAmharic ? level.labelAm : level.labelEn;
                final subtext = isAmharic ? level.labelEn : level.labelAm;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedSpeed = level),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mintSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                Text(
                                  subtext,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 28),

              // Submit Rating Button
              ElevatedButton(
                onPressed: canSubmit ? _handleSubmit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.get('submit_rating'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            s.getOther('submit_rating'),
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
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

