import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../services/forex_service.dart';
import '../models/payment_model.dart';

/// Investments section of the dashboard
class InvestmentsSection extends StatelessWidget {
  final Map<String, double> currencyTotals;
  final String selectedCurrency;
  final bool convertToSingleCurrency;
  final ForexService forexService;
  final Function(bool) onConvertToggled;

  const InvestmentsSection({
    Key? key,
    required this.currencyTotals,
    required this.selectedCurrency,
    required this.convertToSingleCurrency,
    required this.forexService,
    required this.onConvertToggled,
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
            
            Text(
              convertToSingleCurrency 
                  ? 'Showing all investments in $selectedCurrency' 
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
              child: convertToSingleCurrency
                  ? _buildSingleCurrencyView()
                  : _buildMultiCurrencyChart(),
            ),
          ],
        ),
      ),
    );
  }

  // Header with title and toggle
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            'Investment by Currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Toggle switch
        Row(
          mainAxisSize: MainAxisSize.min, // Important: take only needed space
          children: [
            const Flexible(
              child: Text(
                'Convert',
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: convertToSingleCurrency,
              onChanged: onConvertToggled,
              activeColor: AssetFlowColors.primary,
              // Make switch smaller
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  // Multi-currency bar chart
  Widget _buildMultiCurrencyChart() {
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
  Widget _buildSingleCurrencyView() {
    if (currencyTotals.isEmpty) {
      return const Center(child: Text('No investment data available'));
    }
    
    return FutureBuilder<double>(
      future: _calculateTotalInSingleCurrency(),
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
              FormatterUtil.formatCurrency(totalInSelectedCurrency, currencyCode: selectedCurrency),
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
            Expanded(
              child: ListView(
                children: currencyTotals.entries.map((entry) {
                  final currency = entry.key;
                  final amount = entry.value;
                  
                  return FutureBuilder<double>(
                    future: forexService.convertCurrency(amount, currency, selectedCurrency),
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
                                color: CurrencyCalculator.getCurrencyColor(
                                  currency, 
                                  currencyTotals.keys.toList()
                                ),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Calculate total in selected currency
  Future<double> _calculateTotalInSingleCurrency() async {
    double total = 0.0;
    
    for (final entry in currencyTotals.entries) {
      final convertedAmount = await forexService.convertCurrency(
        entry.value, 
        entry.key, 
        selectedCurrency
      );
      total += convertedAmount;
    }
    
    return total;
  }
}