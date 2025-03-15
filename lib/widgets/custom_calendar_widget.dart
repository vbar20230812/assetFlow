import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_util.dart';
import '../utils/theme_colors.dart';
import '../models/payment_model.dart'; // Import the correct file

/// A custom calendar widget that doesn't require external packages
class CustomCalendarWidget extends StatefulWidget {
  final Map<DateTime, List<PaymentEvent>> events;
  final Function(DateTime) onDaySelected;
  final DateTime focusedDay;
  final DateTime? selectedDay;

  const CustomCalendarWidget({
    super.key,
    required this.events,
    required this.onDaySelected,
    required this.focusedDay,
    this.selectedDay,
  });

  @override
  _CustomCalendarWidgetState createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {
  late DateTime _currentMonth;
  late List<DateTime> _daysInMonth;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month);
    _generateDaysInMonth();
  }
  
  @override
  void didUpdateWidget(CustomCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay.month != widget.focusedDay.month || 
        oldWidget.focusedDay.year != widget.focusedDay.year) {
      _currentMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month);
      _generateDaysInMonth();
    }
  }
  
  void _generateDaysInMonth() {
    // Get first day of the month
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Get the weekday of the first day (0 = Monday, 6 = Sunday in DateTime)
    int firstWeekday = firstDay.weekday % 7;
    
    // Get last day of the month
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Generate days from previous month to fill the first week
    List<DateTime> daysInMonth = [];
    for (int i = 0; i < firstWeekday; i++) {
      daysInMonth.add(firstDay.subtract(Duration(days: firstWeekday - i)));
    }
    
    // Add all days in the current month
    for (int i = 0; i < lastDay.day; i++) {
      daysInMonth.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }
    
    // Add days from next month to complete the grid (6 rows x 7 columns)
    int remainingDays = 42 - daysInMonth.length;
    for (int i = 0; i < remainingDays; i++) {
      daysInMonth.add(lastDay.add(Duration(days: i + 1)));
    }
    
    _daysInMonth = daysInMonth;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _generateDaysInMonth();
    });
    
    // Notify parent about the month change
    widget.onDaySelected(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _generateDaysInMonth();
    });
    
    // Notify parent about the month change
    widget.onDaySelected(_currentMonth);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month navigation header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Day of week headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (String day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: _daysInMonth.length,
          itemBuilder: (context, index) {
            final day = _daysInMonth[index];
            final isCurrentMonth = day.month == _currentMonth.month;
            final isToday = DateUtil.isSameDay(day, DateTime.now());
            final isSelected = widget.selectedDay != null && DateUtil.isSameDay(day, widget.selectedDay!);
            
            // Check if this day has events
            final normalizedDay = DateTime(day.year, day.month, day.day);
            final hasEvents = widget.events.containsKey(normalizedDay) && 
                             widget.events[normalizedDay]!.isNotEmpty;
            
            return GestureDetector(
              onTap: () {
                widget.onDaySelected(day);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AssetFlowColors.primary
                      : isToday 
                          ? AssetFlowColors.primaryLight.withOpacity(0.3)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(color: AssetFlowColors.primary, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: !isCurrentMonth
                            ? Colors.grey.withOpacity(0.5)
                            : isSelected
                                ? Colors.white
                                : AssetFlowColors.textPrimary,
                        fontWeight: isToday || isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    if (hasEvents)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
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
        ),
      ],
    );
  }
}