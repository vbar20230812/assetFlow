import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../services/forex_service.dart';
import '../models/payment_model.dart';
import '../utils/formatter_util.dart';

/// Calendar section of the dashboard
class CalendarSection extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, List<PaymentEvent>> paymentsByDate;
  final String selectedCurrency;
  final List<String> availableCurrencies;
  final ForexService forexService;
  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDaySelected;
  final Function(String) onCurrencyChanged;

  const CalendarSection({
    Key? key,
    required this.selectedMonth,
    required this.selectedDay,
    required this.paymentsByDate,
    required this.selectedCurrency,
    required this.availableCurrencies,
    required this.forexService,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onCurrencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            
            const SizedBox(height: 16.0),
            
            _buildMonthNavigation(),
            
            const SizedBox(height: 8.0),
            
            _buildWeekdayHeaders(),
            
            const SizedBox(height: 8.0),
            
            _buildCalendarGrid(),
            
            const SizedBox(height: 16.0),
            
            if (selectedDay != null) _buildSelectedDayPayments(),
          ],
        ),
      ),
    );
  }

  // Calendar header with title and currency dropdown
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            'Payment Calendar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Currency dropdown
        DropdownButton<String>(
          value: selectedCurrency,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onCurrencyChanged(newValue);
            }
          },
          items: availableCurrencies
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Month navigation with prev/next month buttons
  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prevMonth = DateTime(
              selectedMonth.year,
              selectedMonth.month - 1,
              1,
            );
            onMonthChanged(prevMonth);
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(selectedMonth),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final nextMonth = DateTime(
              selectedMonth.year,
              selectedMonth.month + 1,
              1,
            );
            onMonthChanged(nextMonth);
          },
        ),
      ],
    );
  }

  // Weekday headers (S, M, T, W, T, F, S)
  Widget _buildWeekdayHeaders() {
    return Row(
      children: [
        for (String day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
          Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Calendar grid with days
  Widget _buildCalendarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: _getDaysInMonth(selectedMonth.year, selectedMonth.month) + 
                _getFirstWeekdayOfMonth(selectedMonth.year, selectedMonth.month),
      itemBuilder: (context, index) {
        // Skip days before the first day of month
        final firstDayOffset = _getFirstWeekdayOfMonth(selectedMonth.year, selectedMonth.month);
        if (index < firstDayOffset) {
          return const SizedBox();
        }
        
        final day = index - firstDayOffset + 1;
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);
        final isToday = DateUtil.isSameDay(date, DateTime.now());
        final isSelected = selectedDay != null && DateUtil.isSameDay(date, selectedDay!);
        
        // Check if this date has payments
        final hasPayments = paymentsByDate.containsKey(date);
        
        return GestureDetector(
          onTap: () => onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AssetFlowColors.primary
                  : isToday
                      ? AssetFlowColors.primaryLight.withOpacity(0.2)
                      : null,
              border: Border.all(
                color: isSelected
                    ? AssetFlowColors.primary
                    : isToday
                        ? AssetFlowColors.primary
                        : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                if (hasPayments)
                  Container(
                    margin: const EdgeInsets.only(top: 2.0),
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AssetFlowColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Selected day payments list
  Widget _buildSelectedDayPayments() {
    final payments = paymentsByDate[selectedDay!] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payments on ${DateUtil.formatLongDate(selectedDay!)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 8.0),
        payments.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No payments on this day'),
                ),
              )
            : Column(
                children: payments.map((payment) {
                  return FutureBuilder<double>(
                    future: forexService.convertCurrency(
                      payment.amount, 
                      payment.currency, 
                      selectedCurrency
                    ),
                    builder: (context, snapshot) {
                      final displayAmount = snapshot.data ?? payment.amount;
                      final color = payment.getDistributionColor();
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12.0,
                              height: 12.0,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 2, // Give more space to the project/plan name
                              child: Text(
                                '${payment.projectName} - ${payment.planName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1, // Give less space to the amount but ensure it has room
                              child: Text(
                                FormatterUtil.formatCurrency(
                                  displayAmount, 
                                  currencyCode: selectedCurrency,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                                textAlign: TextAlign.end, // Right-align the text
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ],
    );
  }

  // Get days in month
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
  
  // Get first weekday of month (0 = Sunday, 6 = Saturday)
  int _getFirstWeekdayOfMonth(int year, int month) {
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    // Convert from Monday = 1, ..., Sunday = 7 to Sunday = 0, ..., Saturday = 6
    return firstDayWeekday % 7;
  }
}