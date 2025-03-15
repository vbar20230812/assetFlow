import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../utils/formatter_util.dart';

/// Calendar tab for dashboard displaying payment dates
class CalendarTab extends StatefulWidget {
  final List<Project> projects;
  
  const CalendarTab({
    Key? key,
    required this.projects,
  }) : super(key: key);

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDay;
  
  // Map to store payment events by date
  Map<DateTime, List<PaymentInfo>> _paymentsByDate = {};
  
  @override
  void initState() {
    super.initState();
    _calculatePaymentDates();
  }
  
  @override
  void didUpdateWidget(CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      _calculatePaymentDates();
    }
  }
  
  // Calculate all payment dates for projects and plans
  void _calculatePaymentDates() async {
    Map<DateTime, List<PaymentInfo>> paymentsByDate = {};
    
    for (final project in widget.projects) {
      // Get plans for this project
      final plansStream = _databaseService.getProjectPlans(project.id);
      final plans = await plansStream.first;
      
      for (final plan in plans) {
        // Calculate payment dates based on distribution type
        final paymentDates = _calculateProjectPaymentDates(project, plan);
        
        // Add each payment to the map
        for (final entry in paymentDates.entries) {
          final date = entry.key;
          final amount = entry.value;
          
          // Normalize date (remove time component)
          final normalizedDate = DateTime(date.year, date.month, date.day);
          
          if (!paymentsByDate.containsKey(normalizedDate)) {
            paymentsByDate[normalizedDate] = [];
          }
          
          paymentsByDate[normalizedDate]!.add(
            PaymentInfo(
              projectName: project.name,
              planName: plan.name, 
              amount: amount,
              currency: project.currency,
              distributionType: plan.paymentDistribution,
            ),
          );
        }
      }
    }
    
    setState(() {
      _paymentsByDate = paymentsByDate;
    });
  }
  
  // Calculate payment dates for a specific project and plan
  Map<DateTime, double> _calculateProjectPaymentDates(Project project, Plan plan) {
    Map<DateTime, double> paymentDates = {};
    DateTime startDate = project.firstPaymentDate;
    int lengthMonths = plan.lengthMonths > 0 ? plan.lengthMonths : project.projectLengthMonths;
    double amount = project.investmentAmount * plan.interestRate;
    
    // Calculate payment frequency based on distribution type
    int intervalMonths;
    switch (plan.paymentDistribution) {
      case PaymentDistribution.monthly:
        intervalMonths = 1;
        break;
      case PaymentDistribution.quarterly:
        intervalMonths = 3;
        break;
      case PaymentDistribution.semiannual:
        intervalMonths = 6;
        break;
      case PaymentDistribution.annual:
        intervalMonths = 12;
        break;
      case PaymentDistribution.exit:
        // Only one payment at the end
        final exitDate = DateUtil.addMonths(startDate, lengthMonths);
        // Use exitInterest for exit payments
        paymentDates[exitDate] = project.investmentAmount * plan.exitInterest;
        return paymentDates;
    }
    
    // Calculate regular payments
    DateTime currentDate = startDate;
    // Adjust amount based on payment frequency
    double paymentAmount = amount / 12 * intervalMonths;
    
    while (DateUtil.monthDifference(startDate, currentDate) < lengthMonths) {
      paymentDates[currentDate] = paymentAmount;
      currentDate = DateUtil.addMonths(currentDate, intervalMonths);
    }
    
    return paymentDates;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous month button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                  });
                },
              ),
              
              // Current month display
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Next month button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ),
        
        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          ),
        ),
        
        const SizedBox(height: 8.0),
        
        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: _getDaysInMonth(_selectedDate.year, _selectedDate.month) + 
                      _getFirstWeekdayOfMonth(_selectedDate.year, _selectedDate.month),
            itemBuilder: (context, index) {
              // Skip days before the first day of month
              final firstDayOffset = _getFirstWeekdayOfMonth(_selectedDate.year, _selectedDate.month);
              if (index < firstDayOffset) {
                return const SizedBox();
              }
              
              final day = index - firstDayOffset + 1;
              final date = DateTime(_selectedDate.year, _selectedDate.month, day);
              final isToday = DateUtil.isSameDay(date, DateTime.now());
              final isSelected = _selectedDay != null && DateUtil.isSameDay(date, _selectedDay!);
              
              // Check if this date has payments
              final hasPayments = _paymentsByDate.containsKey(date);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                  });
                },
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
          ),
        ),
        
        // Selected day payments
        if (_selectedDay != null) _buildSelectedDayPayments(),
      ],
    );
  }
  
  // Display payments for selected day
  Widget _buildSelectedDayPayments() {
    final payments = _paymentsByDate[_selectedDay!] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments on ${DateUtil.formatLongDate(_selectedDay!)}',
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12.0,
                            height: 12.0,
                            decoration: BoxDecoration(
                              color: _getColorForDistributionType(payment.distributionType),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              '${payment.projectName} - ${payment.planName}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            FormatterUtil.formatCurrency(
                              payment.amount, 
                              currencyCode: payment.currency,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getColorForDistributionType(payment.distributionType),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
  
  // Helper method to get days in month
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
  
  // Helper method to get first weekday of month (0 = Sunday, 6 = Saturday)
  int _getFirstWeekdayOfMonth(int year, int month) {
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    // Convert from Monday = 1, ..., Sunday = 7 to Sunday = 0, ..., Saturday = 6
    return firstDayWeekday % 7;
  }
  
  // Get color for distribution type
  Color _getColorForDistributionType(PaymentDistribution distributionType) {
    switch (distributionType) {
      case PaymentDistribution.monthly:
        return AssetFlowColors.chartColors[0];
      case PaymentDistribution.quarterly:
        return AssetFlowColors.chartColors[1];
      case PaymentDistribution.semiannual:
        return AssetFlowColors.chartColors[2];
      case PaymentDistribution.annual:
        return AssetFlowColors.chartColors[3];
      case PaymentDistribution.exit:
        return AssetFlowColors.chartColors[4];
    }
  }
}

/// Simple class to hold payment information
class PaymentInfo {
  final String projectName;
  final String planName;
  final double amount;
  final String currency;
  final PaymentDistribution distributionType;
  
  PaymentInfo({
    required this.projectName,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.distributionType,
  });
}