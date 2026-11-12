import 'package:flutter/material.dart';
import '../../core/ethiopian_date.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';
import 'rate_service_screen.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final isAmharic = state.language.isAmharic;

    final ticket = state.tickets.firstWhere(
      (t) => t.id == widget.ticketId,
      orElse: () => state.tickets.first,
    );

    final ethDate = EthiopianDate.fromDateTime(ticket.createdAt);
    final hasOutcome = ticket.status == TicketStatus.resolved ||
        ticket.status == TicketStatus.notResolved ||
        ticket.status == TicketStatus.referred ||
        ticket.workRecord != null;

    final categoryDisplay = isAmharic
        ? ticket.fullCategoryDisplayAm
        : ticket.fullCategoryDisplayEn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('ticket_details')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticket.id,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ticket.status.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ticket.status.color.withAlpha(80)),
                          ),
                          child: Text(
                            isAmharic ? ticket.status.labelAm : ticket.status.labelEn,
                            style: TextStyle(
                              color: ticket.status.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      categoryDisplay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.problemDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${ethDate.formatFull(isAmharic: isAmharic)} (${ethDate.formatEC()})',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (ticket.assignedTechnician != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.engineering_outlined, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            '${s.get('technician')}: ${ticket.assignedTechnician}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Timeline
              Text(
                s.get('timeline'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildTimelineStep(
                      stepNumber: 1,
                      title: s.get('request_submitted'),
                      subtitle: '${ethDate.formatEC()} - ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                      isCompleted: true,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      stepNumber: 2,
                      title: s.get('in_progress'),
                      subtitle: ticket.assignedTechnician != null
                          ? '${s.get('technician_assigned')}: ${ticket.assignedTechnician}'
                          : s.get('waiting_technician'),
                      isCompleted: ticket.status != TicketStatus.submitted,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      stepNumber: 3,
                      title: s.get('outcome'),
                      subtitle: ticket.workRecord != null
                          ? '${isAmharic ? ticket.workRecord!.outcome.labelAm : ticket.workRecord!.outcome.labelEn}: ${ticket.workRecord!.problemDescription}'
                          : s.get('outcome_pending'),
                      isCompleted: hasOutcome,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rating Section
              if (ticket.rating != null) ...[
                // Already rated display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            s.get('your_rating'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${s.get('quality')}: ${isAmharic ? ticket.rating!.quality.labelAm : ticket.rating!.quality.labelEn}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.get('speed')}: ${isAmharic ? ticket.rating!.speed.labelAm : ticket.rating!.speed.labelEn}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Rate Service Button
                ElevatedButton(
                  onPressed: hasOutcome
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateServiceScreen(ticket: ticket),
                            ),
                          );
                          setState(() {});
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasOutcome ? AppColors.primaryGreen : Colors.grey.shade400,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        s.get('rate_service'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (!hasOutcome) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.get('rate_service_hint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.primaryGreen : Colors.white,
                border: Border.all(
                  color: isCompleted ? AppColors.primaryGreen : const Color(0xFFC5D6CF),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? AppColors.primaryGreen : const Color(0xFFD3E4DE),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
