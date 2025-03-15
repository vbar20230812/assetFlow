import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/date_util.dart';
import '../utils/formatter_util.dart';
import '../utils/theme_colors.dart';

/// Model for a payment event
class PaymentEvent {
  final String projectId;
  final String projectName;
  final String planId;
  final String planName;
  final double amount;
  final String currency;
  final PaymentDistribution distributionType;
  final DateTime paymentDate;

  PaymentEvent({
    required this.projectId,
    required this.projectName,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.distributionType,
    required this.paymentDate,
  });

  /// Create a copy with updated fields
  PaymentEvent copyWith({
    String? projectId,
    String? projectName,
    String? planId,
    String? planName,
    double? amount,
    String? currency,
    PaymentDistribution? distributionType,
    DateTime? paymentDate,
  }) {
    return PaymentEvent(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      distributionType: distributionType ?? this.distributionType,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  /// Get color associated with the distribution type
  Color getDistributionColor() {
    switch (distributionType) {
      case PaymentDistribution.monthly:
        return AssetFlowColors.chartColors[0]; // Indigo
      case PaymentDistribution.quarterly:
        return AssetFlowColors.chartColors[1]; // Green
      case PaymentDistribution.semiannual:
        return AssetFlowColors.chartColors[2]; // Amber
      case PaymentDistribution.annual:
        return AssetFlowColors.chartColors[3]; // Red
      case PaymentDistribution.exit:
        return AssetFlowColors.chartColors[4]; // Purple
    }
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return FormatterUtil.formatCurrency(amount, currencyCode: currency);
  }

  /// Get a label for the distribution type
  String get distributionTypeLabel {
    return distributionType.displayName;
  }
}

/// Utility class for payment calculations
class PaymentCalculator {
  /// Calculate all payment dates for all projects
  static Future<Map<DateTime, List<PaymentEvent>>> calculateAllPaymentDates(
    List<Project> projects,
    DatabaseService databaseService
  ) async {
    Map<DateTime, List<PaymentEvent>> paymentsByDate = {};
    
    for (final project in projects) {
      // Get plans for this project
      final plansStream = databaseService.getProjectPlans(project.id);
      final plans = await plansStream.first;
      
      for (final plan in plans) {
        // Calculate payment dates based on distribution type
        final paymentDates = calculateProjectPaymentDates(project, plan);
        
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
            PaymentEvent(
              projectId: project.id,
              projectName: project.name,
              planId: plan.id,
              planName: plan.name, 
              amount: amount,
              currency: project.currency,
              distributionType: plan.paymentDistribution,
              paymentDate: date,
            ),
          );
        }
      }
    }
    
    return paymentsByDate;
  }
  
  /// Calculate payment dates for a specific project and plan
  static Map<DateTime, double> calculateProjectPaymentDates(Project project, Plan plan) {
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

  /// Calculate payment dates for projects (original method for backward compatibility)
  static Map<DateTime, List<PaymentEvent>> calculatePaymentDates(
    List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> plans,
  ) {
    Map<DateTime, List<PaymentEvent>> paymentsByDate = {};
    
    // Implementation for backward compatibility
    
    return paymentsByDate;
  }
}

/// Utility class for currency calculations
class CurrencyCalculator {
  // Calculate currency totals for investments chart
  static Map<String, double> calculateCurrencyTotals(List<Project> projects) {
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
  
  /// Get color for a currency based on its index
  static Color getCurrencyColor(String currency, List<String> allCurrencies) {
    final index = allCurrencies.indexOf(currency);
    if (index == -1) {
      return AssetFlowColors.chartColors[0]; // Default color
    }
    return AssetFlowColors.chartColors[index % AssetFlowColors.chartColors.length];
  }

  /// Calculate all payment dates for all projects within a date range
static Future<Map<DateTime, List<PaymentEvent>>> calculateAllPaymentDates(
  List<Project> projects,
  DatabaseService databaseService,
  {DateTime? startDate, DateTime? endDate}
) async {
  Map<DateTime, List<PaymentEvent>> paymentsByDate = {};
  
  // Set default date range if not provided (full year range)
  final effectiveStartDate = startDate ?? DateTime.now().subtract(const Duration(days: 30));
  final effectiveEndDate = endDate ?? DateTime.now().add(const Duration(days: 365));
  
  for (final project in projects) {
    // Get plans for this project
    final plansStream = databaseService.getProjectPlans(project.id);
    final plans = await plansStream.first;
    
    for (final plan in plans) {
      // Calculate payment dates based on distribution type
      final paymentDates = calculateProjectPaymentDates(
        project, 
        plan,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );
      
      // Add each payment to the map
      for (final entry in paymentDates.entries) {
        final date = entry.key;
        final amount = entry.value;
        
        // Skip dates outside our range
        if (date.isBefore(effectiveStartDate) || date.isAfter(effectiveEndDate)) {
          continue;
        }
        
        // Normalize date (remove time component)
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        if (!paymentsByDate.containsKey(normalizedDate)) {
          paymentsByDate[normalizedDate] = [];
        }
        
        paymentsByDate[normalizedDate]!.add(
          PaymentEvent(
            projectId: project.id,
            projectName: project.name,
            planId: plan.id,
            planName: plan.name, 
            amount: amount,
            currency: project.currency,
            distributionType: plan.paymentDistribution,
            paymentDate: date,
          ),
        );
      }
    }
  }
  
  return paymentsByDate;
}

/// Calculate payment dates for a specific project and plan within a date range
static Map<DateTime, double> calculateProjectPaymentDates(
  Project project, 
  Plan plan,
  {DateTime? startDate, DateTime? endDate}
) {
  Map<DateTime, double> paymentDates = {};
  DateTime projectStartDate = project.firstPaymentDate;
  int lengthMonths = plan.lengthMonths > 0 ? plan.lengthMonths : project.projectLengthMonths;
  double amount = project.investmentAmount * plan.interestRate;
  
  // Set default date range if not provided
  final effectiveRangeStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
  final effectiveRangeEnd = endDate ?? DateTime.now().add(const Duration(days: 365));
  
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
      final exitDate = DateUtil.addMonths(projectStartDate, lengthMonths);
      
      // Only add if within our range
      if (!exitDate.isBefore(effectiveRangeStart) && !exitDate.isAfter(effectiveRangeEnd)) {
        paymentDates[exitDate] = project.investmentAmount * plan.exitInterest;
      }
      return paymentDates;
  }
  
  // Calculate regular payments
  DateTime currentDate = projectStartDate;
  // Adjust amount based on payment frequency
  double paymentAmount = amount / 12 * intervalMonths;
  
  // Fast-forward to the first payment date that might be in our range
  while (currentDate.isBefore(effectiveRangeStart) && 
         DateUtil.monthDifference(projectStartDate, currentDate) < lengthMonths) {
    currentDate = DateUtil.addMonths(currentDate, intervalMonths);
  }
  
  // Add payments within our range
  while (!currentDate.isAfter(effectiveRangeEnd) && 
         DateUtil.monthDifference(projectStartDate, currentDate) < lengthMonths) {
    paymentDates[currentDate] = paymentAmount;
    currentDate = DateUtil.addMonths(currentDate, intervalMonths);
  }
  
  return paymentDates;
}
}

