import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/project.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../services/forex_service.dart';

/// Investments tab for dashboard showing currency aggregation
class InvestmentsTab extends StatefulWidget {
  final List<Project> projects;
  
  const InvestmentsTab({
    super.key,
    required this.projects,
  });

  @override
  State<InvestmentsTab> createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  String _selectedCurrency = 'NIS';
  bool _convertToSingleCurrency = false;
  final ForexService _forexService = ForexService();
  final List<String> _availableCurrencies = ForexService.commonCurrencies;
  
  // Map to store conversion rates for currencies
  Map<String, double> _conversionRates = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
  }
  
  // Load exchange rates for currencies in projects
  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all unique currencies from projects
      final Set<String> currencies = widget.projects.map((p) => p.currency).toSet();
      
      // Load conversion rates for each currency to selected currency
      for (final currency in currencies) {
        if (currency != _selectedCurrency) {
          final rate = await _forexService.getExchangeRate(currency, _selectedCurrency);
          _conversionRates[currency] = rate;
        } else {
          _conversionRates[currency] = 1.0; // Same currency
        }
      }
    } catch (e) {
      debugPrint('Error loading exchange rates: $e');
      // Set fallback rates
      _initializeFallbackRates();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Initialize fallback rates if API fails
  void _initializeFallbackRates() {
    // Example rates to NIS - should update with more accurate values
    _conversionRates = {
      'USD': 3.65,
      'EUR': 4.03,
      'GBP': 4.75,
      'NIS': 1.0,
      'JPY': 0.025,
      'CAD': 2.70,
      'AUD': 2.45,
    };
  }
  
  // Convert amount between currencies using loaded rates
  double _convertCurrency(double amount, String fromCurrency) {
    if (_conversionRates.containsKey(fromCurrency)) {
      return amount * _conversionRates[fromCurrency]!;
    }
    return amount; // Return original if no conversion rate available
  }
  
  // Calculate total investments by currency
  Map<String, double> _calculateCurrencyTotals() {
    Map<String, double> totals = {};
    
    for (var project in widget.projects) {
      if (!project.isArchived) {
        if (!totals.containsKey(project.currency)) {
          totals[project.currency] = 0.0;
        }
        totals[project.currency] = (totals[project.currency] ?? 0.0) + project.investmentAmount;
      }
    }
    
    return totals;
  }
  
  // Calculate total in selected currency
  double _calculateTotalInSelectedCurrency(Map<String, double> currencyTotals) {
    double total = 0.0;
    
    for (var entry in currencyTotals.entries) {
      total += _convertCurrency(entry.value, entry.key);
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyTotals = _calculateCurrencyTotals();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
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
              Row(
                children: [
                  // Currency dropdown
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCurrency = newValue;
                          _loadExchangeRates();
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
                  const SizedBox(width: 8.0),
                  // Toggle switch
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
          
          // Explanation text
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
          
          // Chart or conversion view
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _convertToSingleCurrency
                    ? _buildSingleCurrencyView(currencyTotals)
                    : _buildMultiCurrencyChart(currencyTotals),
          ),
        ],
      ),
    );
  }
  
  // Build multi-currency bar chart
  Widget _buildMultiCurrencyChart(Map<String, double> currencyTotals) {
    if (currencyTotals.isEmpty) {
      return const Center(child: Text('No investment data available'));
    }
    
    // Convert map to list for easier processing
    final data = currencyTotals.entries.toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BarChart(
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
      ),
    );
  }
  
  // Build single currency view with total and breakdown
  Widget _buildSingleCurrencyView(Map<String, double> currencyTotals) {
    if (currencyTotals.isEmpty) {
      return const Center(child: Text('No investment data available'));
    }
    
    final totalInSelectedCurrency = _calculateTotalInSelectedCurrency(currencyTotals);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Total amount
            Text(
              FormatterUtil.formatCurrency(totalInSelectedCurrency, currencyCode: _selectedCurrency),
              style: const TextStyle(
                fontSize: 36,
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
            const SizedBox(height: 32),
            // Breakdown of original currencies
            ...currencyTotals.entries.map((entry) {
              final currency = entry.key;
              final amount = entry.value;
              final convertedAmount = _convertCurrency(amount, currency);
              final percentage = (convertedAmount / totalInSelectedCurrency * 100).toStringAsFixed(1);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
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
            }),
          ],
        ),
      ),
    );
  }
}