import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';

class RecordWorkScreen extends StatefulWidget {
  final Ticket ticket;

  const RecordWorkScreen({super.key, required this.ticket});

  @override
  State<RecordWorkScreen> createState() => _RecordWorkScreenState();
}

class _RecordWorkScreenState extends State<RecordWorkScreen> {
  late String _deviceType;
  late TextEditingController _modelController;
  late TextEditingController _serialController;
  late TextEditingController _problemController;
  late TextEditingController _toolsController;
  WorkOutcome _outcome = WorkOutcome.solutionGiven;
  bool _isSubmitting = false;

  final List<String> _deviceTypes = [
    'Computer',
    'Printer',
    'Network Device',
    'Copy machine',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _deviceType = widget.ticket.deviceType?.labelEn ?? 'Computer';
    _modelController = TextEditingController(text: widget.ticket.workRecord?.model ?? 'Dell OptiPlex');
    _serialController = TextEditingController(text: widget.ticket.workRecord?.serialNumber ?? 'SN12345');
    _problemController = TextEditingController(
      text: widget.ticket.workRecord?.problemDescription ?? widget.ticket.problemDescription,
    );
    _toolsController = TextEditingController(text: widget.ticket.workRecord?.toolsMaterials ?? '');
  }

  @override
  void dispose() {
    _modelController.dispose();
    _serialController.dispose();
    _problemController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final workRecord = WorkRecord(
      deviceType: _deviceType,
      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
      problemDescription: _problemController.text.trim(),
      toolsMaterials: _toolsController.text.trim().isEmpty ? null : _toolsController.text.trim(),
      outcome: _outcome,
      solutionDateTime: DateTime.now(),
    );

    final state = AppScope.of(context);
    await state.recordWork(widget.ticket.id, workRecord);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.s.get('work_submitted_success')),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.get('record_work'), style: const TextStyle(fontSize: 18)),
            Text(
              s.getOther('record_work'),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket reference card
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    Text(
                      widget.ticket.department,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Device Information
              Text(
                s.get('device_info'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Device Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _deviceType,
                decoration: InputDecoration(
                  labelText: s.get('device_type'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _deviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _deviceType = val);
                },
              ),

              const SizedBox(height: 14),

              // Model Optional
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: s.get('model_optional'),
                  prefixIcon: const Icon(Icons.devices, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 14),

              // Serial Number Optional
              TextField(
                controller: _serialController,
                decoration: InputDecoration(
                  labelText: s.get('serial_optional'),
                  prefixIcon: const Icon(Icons.qr_code, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Problem Description
              Text(
                s.get('problem_description'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _problemController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.get('problem_desc_hint'),
                ),
              ),

              const SizedBox(height: 16),

              // Tools / Materials used (optional)
              Text(
                s.get('tools_materials'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _toolsController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.handyman_outlined, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Outcome Radios
              Text(
                s.get('outcome'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              ...WorkOutcome.values.map((outcome) {
                final isSelected = _outcome == outcome;
                final text = isAmharic ? outcome.labelAm : outcome.labelEn;
                final subtext = isAmharic ? outcome.labelEn : outcome.labelAm;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _outcome = outcome),
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
                                  ),
                                ),
                                Text(
                                  subtext,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
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

              // Submit Work Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.get('submit_work'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            s.getOther('submit_work'),
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
