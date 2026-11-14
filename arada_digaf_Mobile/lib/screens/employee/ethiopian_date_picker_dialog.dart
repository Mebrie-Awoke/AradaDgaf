import 'package:flutter/material.dart';
import '../../core/ethiopian_date.dart';
import '../../core/theme.dart';
import '../../state/app_scope.dart';

class EthiopianDatePickerDialog extends StatefulWidget {
  final EthiopianDate initialDate;

  const EthiopianDatePickerDialog({
    super.key,
    required this.initialDate,
  });

  @override
  State<EthiopianDatePickerDialog> createState() =>
      _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<EthiopianDatePickerDialog> {
  late int _visibleYear;
  late int _visibleMonth;
  late EthiopianDate _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleYear = widget.initialDate.year;
    _visibleMonth = widget.initialDate.month;
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_visibleMonth == 1) {
        _visibleYear--;
        _visibleMonth = 13;
      } else {
        _visibleMonth--;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_visibleMonth == 13) {
        _visibleYear++;
        _visibleMonth = 1;
      } else {
        _visibleMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final isAmharic = state.language.isAmharic;

    final visibleDate = EthiopianDate(_visibleYear, _visibleMonth, 1);
    final monthName = visibleDate.monthName(isAmharic: isAmharic);
    final yearSuffix = isAmharic ? 'ዓ.ም' : 'EC';
    final headerTitle = '$monthName $_visibleYear $yearSuffix';

    final daysInMonth = visibleDate.maxDaysInMonth;
    // Weekday of 1st day (DateTime weekday: 1 = Mon ... 7 = Sun)
    final firstDayWeekday = visibleDate.weekday; // 1 to 7
    final leadingBlanks = firstDayWeekday % 7; // Sunday is 0, Monday is 1, etc.

    final weekdayHeaders = isAmharic
        ? const ['እሑድ', 'ሰኞ', 'ማክ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ']
        : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    s.get('select_date'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance back button
              ],
            ),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),

            // Month Navigator Header (< Month Year >)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintSurface.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.darkGreen),
                    onPressed: _goToPreviousMonth,
                    tooltip: 'Previous month',
                  ),
                  Text(
                    headerTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.darkGreen),
                    onPressed: _goToNextMonth,
                    tooltip: 'Next month',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Weekday Headers
            Row(
              children: weekdayHeaders
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingBlanks + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                if (index < leadingBlanks) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - leadingBlanks + 1;
                final isSelected = _selectedDate.year == _visibleYear &&
                    _selectedDate.month == _visibleMonth &&
                    _selectedDate.day == dayNumber;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate =
                          EthiopianDate(_visibleYear, _visibleMonth, dayNumber);
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),
            // Bottom Info: Selected Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.get('selected_date')}:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _selectedDate.formatEC(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Confirm Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedDate);
              },
              child: Text(
                s.get('confirm'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

