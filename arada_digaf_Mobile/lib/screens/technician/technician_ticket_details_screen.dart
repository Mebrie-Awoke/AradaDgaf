import 'package:flutter/material.dart';
import '../../core/ethiopian_date.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';
import 'record_work_screen.dart';

class TechnicianTicketDetailsScreen extends StatefulWidget {
  final String ticketId;

  const TechnicianTicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TechnicianTicketDetailsScreen> createState() =>
      _TechnicianTicketDetailsScreenState();
}

class _TechnicianTicketDetailsScreenState
    extends State<TechnicianTicketDetailsScreen> {
  bool _isActionLoading = false;

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
    final categoryText = isAmharic
        ? ticket.fullCategoryDisplayAm
        : ticket.fullCategoryDisplayEn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${s.get('ticket_details')} - ${ticket.id}'),
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
                      categoryText,
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
                    _buildInfoRow(Icons.person_outline, ticket.requesterName),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.business_outlined, ticket.department),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.room_outlined, ticket.officeLocation),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone_outlined, ticket.phoneNumber),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today_outlined, '${ethDate.formatFull(isAmharic: isAmharic)} (${ethDate.formatEC()})'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recorded Work Info if exists
              if (ticket.workRecord != null) ...[
                Text(
                  s.get('record_work'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
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
                            ticket.workRecord!.deviceType,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ticket.status.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAmharic ? ticket.workRecord!.outcome.labelAm : ticket.workRecord!.outcome.labelEn,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ticket.status.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ticket.workRecord!.model != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${s.get('model_optional')}: ${ticket.workRecord!.model}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (ticket.workRecord!.serialNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${s.get('serial_optional')}: ${ticket.workRecord!.serialNumber}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (ticket.workRecord!.toolsMaterials != null && ticket.workRecord!.toolsMaterials!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${s.get('tools_materials')}: ${ticket.workRecord!.toolsMaterials}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        ticket.workRecord!.problemDescription,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions according to status
              if (ticket.status == TicketStatus.submitted) ...[
                ElevatedButton(
                  onPressed: _isActionLoading
                      ? null
                      : () async {
                          setState(() => _isActionLoading = true);
                          await state.startWork(ticket.id);
                          setState(() => _isActionLoading = false);
                        },
                  child: _isActionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              s.get('start_work'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ] else if (ticket.status == TicketStatus.inProgress) ...[
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordWorkScreen(ticket: ticket),
                      ),
                    );
                    setState(() {});
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        s.get('record_work'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

