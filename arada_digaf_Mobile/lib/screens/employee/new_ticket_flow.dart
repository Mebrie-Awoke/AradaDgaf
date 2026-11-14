import 'package:flutter/material.dart';
import '../../core/ethiopian_date.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../common/offline_screen.dart';
import 'ethiopian_date_picker_dialog.dart';
import 'request_submitted_screen.dart';

class NewTicketFlow extends StatefulWidget {
  final ServiceCategory? initialCategory;
  final DeviceType? initialDeviceType;
  final VoidCallback onViewMyTickets;

  const NewTicketFlow({
    super.key,
    this.initialCategory,
    this.initialDeviceType,
    required this.onViewMyTickets,
  });

  @override
  State<NewTicketFlow> createState() => _NewTicketFlowState();
}

class _NewTicketFlowState extends State<NewTicketFlow> {
  int _currentStep = 0;

  late ServiceCategory _category;
  DeviceType? _deviceType;

  late TextEditingController _problemController;
  late TextEditingController _departmentController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;

  late EthiopianDate _selectedEthDate;
  bool _confirmChecked = false;
  String? _step2Error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? ServiceCategory.maintenance;
    _deviceType = widget.initialDeviceType ??
        (_category == ServiceCategory.maintenance ? DeviceType.computer : null);

    _problemController = TextEditingController();
    _departmentController = TextEditingController(text: 'IT Office');
    _locationController =
        TextEditingController(text: 'Building B, 2nd Floor, Room 204');
    _phoneController = TextEditingController(text: '+251 91 123 4567');

    _selectedEthDate = EthiopianDate.fromDateTime(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AppScope.of(context).currentUser;
    if (user != null) {
      if (_departmentController.text.isEmpty) {
        _departmentController.text = user.department;
      }
      if (_locationController.text.isEmpty) {
        _locationController.text = user.officeLocation;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = user.phoneNumber;
      }
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openDatePicker() async {
    final picked = await showDialog<EthiopianDate>(
      context: context,
      builder: (ctx) => EthiopianDatePickerDialog(initialDate: _selectedEthDate),
    );

    if (picked != null) {
      setState(() {
        _selectedEthDate = picked;
      });
    }
  }

  void _goToStep2() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _goToStep3() {
    final problem = _problemController.text.trim();
    if (problem.length < 10) {
      final s = AppScope.of(context).s;
      setState(() {
        _step2Error = s.get('min_10_chars');
      });
      return;
    }
    setState(() {
      _step2Error = null;
      _currentStep = 2;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_confirmChecked) return;

    setState(() {
      _isSubmitting = true;
    });

    final state = AppScope.of(context);
    final draft = TicketDraft(
      category: _category,
      deviceType: _category == ServiceCategory.maintenance ? _deviceType : null,
      problemDescription: _problemController.text.trim(),
      department: _departmentController.text.trim(),
      officeLocation: _locationController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      date: _selectedEthDate.toDateTime(),
    );

    if (state.isOfflineSimulated) {
      state.savePendingDraft(draft);
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfflineScreen(
            onViewMyTickets: widget.onViewMyTickets,
          ),
        ),
      );
      return;
    }

    final ticket = await state.submitTicket(draft);
    setState(() => _isSubmitting = false);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('new_ticket')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper indicator
            _buildStepperHeader(s),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(dynamic s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildStepItem(0, s.get('step_service_details'), _currentStep >= 0),
          _buildStepDivider(_currentStep >= 1),
          _buildStepItem(1, s.get('step_problem_desc'), _currentStep >= 1),
          _buildStepDivider(_currentStep >= 2),
          _buildStepItem(2, s.get('step_review_submit'), _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, bool isActive) {
    final isCurrent = _currentStep == stepIndex;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryGreen : const Color(0xFFD3E4DE),
            ),
            alignment: Alignment.center,
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? AppColors.darkGreen : AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppColors.primaryGreen : const Color(0xFFD3E4DE),
    );
  }

  Widget _buildCurrentStepContent(dynamic s) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(s);
      case 1:
        return _buildStep2(s);
      case 2:
      default:
        return _buildStep3(s);
    }
  }

  // STEP 1: Service Category & Device Sub-choice
  Widget _buildStep1(dynamic s) {
    final isAmharic = AppScope.of(context).language.isAmharic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.get('service_category'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        Text(
          s.getOther('service_category'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        // Grid of Categories
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: ServiceCategory.values.map((cat) {
            final isSelected = _category == cat;
            return InkWell(
              onTap: () {
                setState(() {
                  _category = cat;
                  if (cat == ServiceCategory.maintenance && _deviceType == null) {
                    _deviceType = DeviceType.computer;
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.mintSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat.icon,
                      color: isSelected ? AppColors.primaryGreen : AppColors.darkGreen,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAmharic ? cat.labelAm : cat.labelEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      isAmharic ? cat.labelEn : cat.labelAm,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Device sub-choice if Maintenance selected
        if (_category == ServiceCategory.maintenance) ...[
          const SizedBox(height: 24),
          Text(
            s.get('select_device'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          Text(
            s.getOther('select_device'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DeviceType.network,
              DeviceType.computer,
              DeviceType.printer,
              DeviceType.copyMachine,
            ].map((device) {
              final isSelected = _deviceType == device;
              return ChoiceChip(
                selected: isSelected,
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        device.icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.darkGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAmharic ? device.labelAm : device.labelEn,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                selectedColor: AppColors.primaryGreen,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _deviceType = device);
                  }
                },
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 32),

        // Next Button
        ElevatedButton(
          onPressed: _goToStep2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.get('next'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: Problem Description, Department, Location, Phone, Date
  Widget _buildStep2(dynamic s) {
    final isAmharic = AppScope.of(context).language.isAmharic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Problem Description
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('problem_description'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_problemController.text.length}/500',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _problemController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (text) => setState(() {}),
          decoration: InputDecoration(
            hintText: s.get('problem_desc_hint'),
            counterText: '',
            errorText: _step2Error,
          ),
        ),
        const SizedBox(height: 16),

        // Office / Department
        Text(
          s.get('department'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _departmentController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.business_outlined, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Office Location
        Text(
          s.get('office_location'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.room_outlined, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Phone Number
        Text(
          s.get('phone_number'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Date Picker Field (Ethiopian Calendar)
        Text(
          s.get('date'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _openDatePicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedEthDate.formatFull(isAmharic: isAmharic),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _selectedEthDate.formatEC(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_calendar, color: AppColors.primaryGreen, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Buttons: Back and Next
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  s.get('back'),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goToStep3,
                child: Text(
                  s.get('next'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: Review Your Request & Submit
  Widget _buildStep3(dynamic s) {
    final isAmharic = AppScope.of(context).language.isAmharic;

    final serviceText = _category == ServiceCategory.maintenance && _deviceType != null
        ? '${isAmharic ? _category.labelAm : _category.labelEn} - ${isAmharic ? _deviceType!.labelAm : _deviceType!.labelEn}'
        : (isAmharic ? _category.labelAm : _category.labelEn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.get('review_request'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        Text(
          s.getOther('review_request'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        // Review Card
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
              _buildReviewRow(
                icon: Icons.business,
                label: s.get('department'),
                value: _departmentController.text.trim(),
              ),
              const Divider(height: 24, color: AppColors.border),
              _buildReviewRow(
                icon: Icons.design_services_outlined,
                label: s.get('service'),
                value: serviceText,
              ),
              const Divider(height: 24, color: AppColors.border),
              _buildReviewRow(
                icon: Icons.description_outlined,
                label: s.get('problem_description'),
                value: _problemController.text.trim(),
              ),
              const Divider(height: 24, color: AppColors.border),
              _buildReviewRow(
                icon: Icons.calendar_today_outlined,
                label: s.get('date'),
                value: '${_selectedEthDate.formatFull(isAmharic: isAmharic)} (${_selectedEthDate.formatEC()})',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Confirmation Checkbox
        InkWell(
          onTap: () {
            setState(() => _confirmChecked = !_confirmChecked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _confirmChecked,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() => _confirmChecked = val ?? false);
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      s.get('confirm_accurate'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit Request Button
        ElevatedButton(
          onPressed: (_confirmChecked && !_isSubmitting) ? _handleSubmit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.get('submit_request'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        s.getOther('submit_request'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

