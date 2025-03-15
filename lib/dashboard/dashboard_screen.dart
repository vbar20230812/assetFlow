import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../services/forex_service.dart';
import '../services/preferences_service.dart';
import '../widgets/payment_celebration.dart';
import 'calendar_section.dart';
import 'investments_section.dart';
import 'projects_section.dart';
import '../models/payment_model.dart';

/// A unified dashboard screen that shows calendar, investments, and projects
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ForexService _forexService = ForexService();
  final PreferencesService _preferencesService = PreferencesService();
  
  // Currency state
  String _selectedCurrency = 'NIS';
  bool _convertToSingleCurrency = false;
  final List<String> _availableCurrencies = ForexService.commonCurrencies;
  
  // Calendar state
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  
  // Cache for payment calculations - key is year-month
  final Map<String, Map<DateTime, List<PaymentEvent>>> _paymentCache = {};
  
  // Cache for currency totals calculations
  Map<String, double>? _currencyTotalsCache;
  List<Project>? _lastProjects;
  
  // Flag to track if celebration has been checked
  bool _hasCelebrationBeenChecked = false;
  
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
  
  // Get cache key for a month
  String _getCacheKeyForMonth(DateTime month) {
    return '${month.year}-${month.month}';
  }
  
  // Get payments for a specific month with caching
  Future<Map<DateTime, List<PaymentEvent>>> _getPaymentsForMonth(
    List<Project> projects,
    DateTime month
  ) async {
    final cacheKey = _getCacheKeyForMonth(month);
    
    // Return cached data if available
    if (_paymentCache.containsKey(cacheKey)) {
      return _paymentCache[cacheKey]!;
    }

   
    // Fetch payments for this month with date range to improve performance
    final payments = await PaymentCalculator.calculateAllPaymentDates(
      projects, 
      _databaseService,
    );
    
    // Cache the result - limit cache size to avoid memory issues
    if (_paymentCache.length > 12) {
      // Remove oldest entries if cache gets too large
      final oldestKey = _paymentCache.keys.first;
      _paymentCache.remove(oldestKey);
    }
    
    _paymentCache[cacheKey] = payments;
    return payments;
  }
  
  // Calculate currency totals with caching
  Map<String, double> _calculateCurrencyTotals(List<Project> projects) {
    // If projects haven't changed, return cached result
    if (_currencyTotalsCache != null && 
        _lastProjects != null &&
        _listEquals(_lastProjects!, projects)) {
      return _currencyTotalsCache!;
    }
    
    // Calculate fresh results
    final totals = CurrencyCalculator.calculateCurrencyTotals(projects);
    
    // Update cache
    _currencyTotalsCache = totals;
    _lastProjects = List.from(projects);
    
    return totals;
  }
  
  // Helper to compare two lists of projects
  bool _listEquals(List<Project> list1, List<Project> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].updatedAt != list2[i].updatedAt) {
        return false;
      }
    }
    
    return true;
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
              setState(() {
                // Clear caches on manual refresh
                _paymentCache.clear();
                _currencyTotalsCache = null;
                _lastProjects = null;
                _hasCelebrationBeenChecked = false;
              });
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
          
          // Calculate currency totals with caching
          final currencyTotals = _calculateCurrencyTotals(activeProjects);
          
          // Fetch payments for current month
          return FutureBuilder<Map<DateTime, List<PaymentEvent>>>(
            future: _getPaymentsForMonth(activeProjects, _selectedMonth),
            builder: (context, paymentsSnapshot) {
              if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final paymentsByDate = paymentsSnapshot.data ?? {};
              
              // Check for payments celebration only once
              if (!_hasCelebrationBeenChecked) {
                _checkAndShowPaymentCelebration(context, paymentsByDate);
                _hasCelebrationBeenChecked = true;
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    // Clear caches on pull-to-refresh
                    _paymentCache.clear();
                    _currencyTotalsCache = null;
                    _lastProjects = null;
                  });
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. Calendar Section
                    CalendarSection(
                      selectedMonth: _selectedMonth,
                      selectedDay: _selectedDay,
                      paymentsByDate: paymentsByDate,
                      selectedCurrency: _selectedCurrency,
                      availableCurrencies: _availableCurrencies,
                      forexService: _forexService,
                      onMonthChanged: (DateTime month) {
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                      onDaySelected: (DateTime day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                      onCurrencyChanged: (String currency) {
                        setState(() {
                          _selectedCurrency = currency;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24.0),
                    
                    // 2. Investments Section (Currency Aggregation)
                    InvestmentsSection(
                      currencyTotals: currencyTotals,
                      selectedCurrency: _selectedCurrency,
                      convertToSingleCurrency: _convertToSingleCurrency,
                      forexService: _forexService,
                      onConvertToggled: (bool value) {
                        setState(() {
                          _convertToSingleCurrency = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24.0),
                    
                    // 3. Projects Section
                    ProjectsSection(projects: activeProjects),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  /// Check and show payment celebration popup if today has a payment
  Future<void> _checkAndShowPaymentCelebration(
    BuildContext context, 
    Map<DateTime, List<PaymentEvent>> paymentsByDate
  ) async {
    // Get today's date (normalized)
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    // Get payments for today
    final todayPayments = paymentsByDate[today] ?? [];
    
    // If there are payments today, check if we've shown celebration
    if (todayPayments.isNotEmpty) {
      // Process each payment
      for (final payment in todayPayments) {
        // For simplicity, we're using project name as ID - in a real app, use the actual project ID
        final paymentId = payment.projectName.replaceAll(' ', '-').toLowerCase();
        
        // Check if we've already shown celebration for this payment
        final hasShown = await _preferencesService.hasPaymentCelebrationBeenShown(
          paymentId, 
          today
        );
        
        // Only show celebration if we haven't shown it before
        if (!hasShown) {
          // Mark as shown immediately to prevent multiple popups
          await _preferencesService.markPaymentCelebrationAsShown(
            paymentId, 
            today
          );
          
          // Show the celebration dialog after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => PaymentCelebrationDialog(
                  amount: payment.formattedAmount,
                  currency: payment.currency,
                  projectName: payment.projectName,
                ),
              );
            }
          });
          
          // Only show one celebration at a time
          break;
        }
      }
    }
  }
}