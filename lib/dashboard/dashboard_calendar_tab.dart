import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../services/forex_service.dart';
import '../models/payment_model.dart';
import '../utils/formatter_util.dart';

/// Optimized calendar section of the dashboard with performance improvements
class CalendarSection extends StatefulWidget {
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
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> with SingleTickerProviderStateMixin {
  // Cache for payment amounts converted to selected currency
  final Map<String, double> _convertedAmountCache = {};
  
  // Cached days in month to avoid recalculation
  late List<DateTime> _daysInMonth;
  late int _firstDayOffset;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _calculateCalendarDays();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(CalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only recalculate if the month changed
    if (oldWidget.selectedMonth.month != widget.selectedMonth.month || 
        oldWidget.selectedMonth.year != widget.selectedMonth.year) {
      _calculateCalendarDays();
      
      // Animate transition
      _animationController.reset();
      _animationController.forward();
    }
    
    // Clear currency conversion cache if currency changed
    if (oldWidget.selectedCurrency != widget.selectedCurrency) {
      _convertedAmountCache.clear();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Pre-calculate calendar days for current month
  void _calculateCalendarDays() {
    // Get first day of the month
    final firstDay = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    
    // Get the weekday of the first day (0 = Sunday, 6 = Saturday)
    _firstDayOffset = firstDay.weekday % 7;
    
    // Get last day of the month
    final lastDay = DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Create list of all days in this month
    _daysInMonth = List.generate(
      daysInMonth, 
      (index) => DateTime(widget.selectedMonth.year, widget.selectedMonth.month, index + 1)
    );
  }
  
  /// Get a cached converted amount or calculate if not cached
  Future<double> _getCachedConvertedAmount(PaymentEvent payment) async {
    // Create cache key
    final cacheKey = '${payment.currency}_${payment.amount}_${widget.selectedCurrency}';
    
    // Return cached value if exists
    if (_convertedAmountCache.containsKey(cacheKey)) {
      return _convertedAmountCache[cacheKey]!;
    }
    
    // Calculate and cache conversion
    final convertedAmount = await widget.forexService.convertCurrency(
      payment.amount, 
      payment.currency, 
      widget.selectedCurrency
    );
    
    _convertedAmountCache[cacheKey] = convertedAmount;
    return convertedAmount;
  }

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
            
            // Animated calendar grid
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildOptimizedCalendarGrid(),
            ),
            
            const SizedBox(height: 16.0),
            
            if (widget.selectedDay != null) _buildSelectedDayPayments(),
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
          value: widget.selectedCurrency,
          onChanged: (String? newValue) {
            if (newValue != null) {
              widget.onCurrencyChanged(newValue);
            }
          },
          items: widget.availableCurrencies
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
    // Cache the formatted date to avoid rebuilding
    final formattedMonth = DateFormat('MMMM yyyy').format(widget.selectedMonth);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prevMonth = DateTime(
              widget.selectedMonth.year,
              widget.selectedMonth.month - 1,
              1,
            );
            widget.onMonthChanged(prevMonth);
          },
        ),
        Text(
          formattedMonth,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final nextMonth = DateTime(
              widget.selectedMonth.year,
              widget.selectedMonth.month + 1,
              1,
            );
            widget.onMonthChanged(nextMonth);
          },
        ),
      ],
    );
  }

  // Weekday headers (S, M, T, W, T, F, S)
  Widget _buildWeekdayHeaders() {
    // Use const where possible to avoid rebuilds
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: AssetFlowColors.textSecondary,
    );
    
    return Row(
      children: days.map((day) => 
        Expanded(
          child: Center(
            child: Text(
              day,
              style: textStyle,
            ),
          ),
        ),
      ).toList(),
    );
  }

  // Optimized calendar grid using ListView for rows
  Widget _buildOptimizedCalendarGrid() {
    // Calculate how many rows we need (weeks)
    final numWeeks = ((_daysInMonth.length + _firstDayOffset) / 7).ceil();
    
    return Column(
      children: List.generate(numWeeks, (weekIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (dayIndex) {
            final index = weekIndex * 7 + dayIndex;
            final dayOffset = index - _firstDayOffset;
            
            // Return empty cell for days before the first of month
            if (dayOffset < 0 || dayOffset >= _daysInMonth.length) {
              return const Expanded(child: SizedBox());
            }
            
            final date = _daysInMonth[dayOffset];
            return Expanded(child: _buildDayCell(date));
          }),
        );
      }),
    );
  }

  // Single day cell - extracted for performance
  Widget _buildDayCell(DateTime date) {
    final isToday = DateUtil.isSameDay(date, DateTime.now());
    final isSelected = widget.selectedDay != null && 
                      DateUtil.isSameDay(date, widget.selectedDay!);
    
    // Check if this date has payments - this uses memory lookup which is fast
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final hasPayments = widget.paymentsByDate.containsKey(normalizedDate) && 
                       widget.paymentsByDate[normalizedDate]!.isNotEmpty;
    
    // Use const where possible
    const dayMargin = EdgeInsets.all(2.0);
    
    return GestureDetector(
      onTap: () {
        // Only update if truly changed
        if (!isSelected) {
          widget.onDaySelected(date);
        }
      },
      child: Container(
        margin: dayMargin,
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
              date.day.toString(),
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
  }

  // Selected day payments list with optimized rendering
  Widget _buildSelectedDayPayments() {
    // Normalized date for lookup
    final lookupDate = DateTime(
      widget.selectedDay!.year,
      widget.selectedDay!.month,
      widget.selectedDay!.day
    );
    
    final payments = widget.paymentsByDate[lookupDate] ?? [];
    
    // Format date once to avoid doing it in build
    final formattedDate = DateUtil.formatLongDate(widget.selectedDay!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payments on $formattedDate',
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
                  // Use cached conversion
                  return FutureBuilder<double>(
                    future: _getCachedConvertedAmount(payment),
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
                              flex: 2,
                              child: Text(
                                '${payment.projectName} - ${payment.planName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                FormatterUtil.formatCurrency(
                                  displayAmount, 
                                  currencyCode: widget.selectedCurrency,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                                textAlign: TextAlign.end,
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
}