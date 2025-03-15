import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../utils/date_util.dart';
import '../services/forex_service.dart';

/// A unified dashboard screen that shows calendar, investments, and projects
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ForexService _forexService = ForexService();
  
  // Calendar state
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  
  // Currency state
  String _selectedCurrency = 'NIS';
  bool _convertToSingleCurrency = false;
  final List<String> _availableCurrencies = ForexService.commonCurrencies;
  
  // Map to store payment events by date
  Map<DateTime, List<PaymentInfo>> _paymentsByDate = {};
  
  @override
  void initState() {
    super.initState();
    // Pre-fetch exchange rates
    _forexService.preloadCommonRates();
    
    // Set selected day to today
    _selectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: _databaseService.getUserProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final projects = snapshot.data ?? [];
          final activeProjects = projects.where((p) => !p.isArchived).toList();
          
          if (activeProjects.isEmpty) {
            return const Center(
              child: Text('No projects yet. Add your first investment project!'),
            );
          }
          
          // Fetch all plans for all projects to calculate payments
          return FutureBuilder<Map<DateTime, List<PaymentInfo>>>(
            future: _calculateAllPaymentDates(activeProjects),
            builder: (context, paymentsSnapshot) {
              if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              _paymentsByDate = paymentsSnapshot.data ?? {};
              
              // Calculate currency totals for charts
              final currencyTotals = _calculateCurrencyTotals(activeProjects);
              
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. Calendar Section
                    _buildCalendarSection(),
                    
                    const SizedBox(height: 24.0),
                    
                    // 2. Investments Section (Currency Aggregation)
                    _buildInvestmentsSection(currencyTotals),
                    
                    const SizedBox(height: 24.0),
                    
                    // 3. Projects Section
                    _buildProjectsSection(activeProjects),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Calculate all payment dates for all projects
  Future<Map<DateTime, List<PaymentInfo>>> _calculateAllPaymentDates(List<Project> projects) async {
    Map<DateTime, List<PaymentInfo>> paymentsByDate = {};
    
    for (final project in projects) {
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
    
    return paymentsByDate;
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
  
  // Calculate currency totals for investments chart
  Map<String, double> _calculateCurrencyTotals(List<Project> projects) {
    Map<String, double> totals = {};
    
    for (var project in projects) {
      if (!project.isArchived) {
        if (!totals.containsKey(project.currency)) {
          totals[project.currency] = 0.0;
        }
        totals[project.currency] = (totals[project.currency] ?? 0.0) + project.investmentAmount;
      }
    }
    
    return totals;
  }

  // SECTION 1: Calendar
  Widget _buildCalendarSection() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Currency dropdown
                DropdownButton<String>(
                  value: _selectedCurrency,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                    }
                  },
                  items: _availableCurrencies
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 8.0),
            
            // Day of week headers
            Row(
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
            
            const SizedBox(height: 8.0),
            
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: _getDaysInMonth(_selectedMonth.year, _selectedMonth.month) + 
                        _getFirstWeekdayOfMonth(_selectedMonth.year, _selectedMonth.month),
              itemBuilder: (context, index) {
                // Skip days before the first day of month
                final firstDayOffset = _getFirstWeekdayOfMonth(_selectedMonth.year, _selectedMonth.month);
                if (index < firstDayOffset) {
                  return const SizedBox();
                }
                
                final day = index - firstDayOffset + 1;
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
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
            
            const SizedBox(height: 16.0),
            
            // Selected day payments
            if (_selectedDay != null) _buildSelectedDayPayments(),
          ],
        ),
      ),
    );
  }
  
  // Display payments for selected day
  Widget _buildSelectedDayPayments() {
    final payments = _paymentsByDate[_selectedDay!] ?? [];
    
    return Column(
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
                  return FutureBuilder<double>(
                    future: _forexService.convertCurrency(
                      payment.amount, 
                      payment.currency, 
                      _selectedCurrency
                    ),
                    builder: (context, snapshot) {
                      final displayAmount = snapshot.data ?? payment.amount;
                      
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
                                displayAmount, 
                                currencyCode: _selectedCurrency,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getColorForDistributionType(payment.distributionType),
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
  
  // SECTION 2: Investments (Currency Aggregation)
  Widget _buildInvestmentsSection(Map<String, double> currencyTotals) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Investment by Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Toggle switch
                Row(
                  children: [
                    const Text('Convert to single currency'),
                    Switch(
                      value: _convertToSingleCurrency,
                      onChanged: (value) {
                        setState(() {
                          _convertToSingleCurrency = value;
                        });
                      },
                      activeColor: AssetFlowColors.primary,
                    ),
                  ],
                ),
              ],
            ),
            
            Text(
              _convertToSingleCurrency 
                  ? 'Showing all investments in $_selectedCurrency' 
                  : 'Showing investments in original currencies',
              style: const TextStyle(
                color: AssetFlowColors.textSecondary,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Chart
            SizedBox(
              height: 250,
              child: _convertToSingleCurrency
                  ? _buildSingleCurrencyView(currencyTotals)
                  : _buildMultiCurrencyChart(currencyTotals),
            ),
          ],
        ),
      ),
    );
  }
  
  // Multi-currency bar chart
  Widget _buildMultiCurrencyChart(Map<String, double> currencyTotals) {
    if (currencyTotals.isEmpty) {
      return const Center(child: Text('No investment data available'));
    }
    
    // Convert map to list for easier processing
    final data = currencyTotals.entries.toList();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        gridData: FlGridData(drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  data[value.toInt()].key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.grey, width: 1),
            left: BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index].value,
                color: AssetFlowColors.chartColors[index % AssetFlowColors.chartColors.length],
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  // Single currency view with total and breakdown
  Widget _buildSingleCurrencyView(Map<String, double> currencyTotals) {
    if (currencyTotals.isEmpty) {
      return const Center(child: Text('No investment data available'));
    }
    
    return FutureBuilder<double>(
      future: _calculateTotalInSingleCurrency(currencyTotals),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final totalInSelectedCurrency = snapshot.data ?? 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Total amount
            Text(
              FormatterUtil.formatCurrency(totalInSelectedCurrency, currencyCode: _selectedCurrency),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AssetFlowColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Total Investment Value',
              style: TextStyle(
                fontSize: 16,
                color: AssetFlowColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Breakdown of original currencies
            ...currencyTotals.entries.map((entry) {
              final currency = entry.key;
              final amount = entry.value;
              
              return FutureBuilder<double>(
                future: _forexService.convertCurrency(amount, currency, _selectedCurrency),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  
                  final convertedAmount = snapshot.data ?? amount;
                  final percentage = totalInSelectedCurrency > 0
                      ? (convertedAmount / totalInSelectedCurrency * 100).toStringAsFixed(1)
                      : "0.0";
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AssetFlowColors.chartColors[
                              currencyTotals.keys.toList().indexOf(currency) % 
                              AssetFlowColors.chartColors.length
                            ],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currency,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${FormatterUtil.formatCurrency(amount, currencyCode: currency)} ($percentage%)',
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
  
  // Calculate total in selected currency
  Future<double> _calculateTotalInSingleCurrency(Map<String, double> currencyTotals) async {
    double total = 0.0;
    
    for (final entry in currencyTotals.entries) {
      final convertedAmount = await _forexService.convertCurrency(
        entry.value, 
        entry.key, 
        _selectedCurrency
      );
      total += convertedAmount;
    }
    
    return total;
  }
  
  // SECTION 3: Projects list
  Widget _buildProjectsSection(List<Project> projects) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ...projects.map((project) => _buildProjectListItem(project)).toList(),
          ],
        ),
      ),
    );
  }
  
  // Project list item
  Widget _buildProjectListItem(Project project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Navigate to project details
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AssetDetailScreen(projectId: project.id),
          //   ),
          // );
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    FormatterUtil.formatCurrency(
                      project.investmentAmount, 
                      currencyCode: project.currency
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AssetFlowColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                project.company,
                style: const TextStyle(
                  color: AssetFlowColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Started: ${DateUtil.formatShortDate(project.startDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AssetFlowColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Duration: ${FormatterUtil.formatDuration(project.projectLengthMonths)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AssetFlowColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper methods
  
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