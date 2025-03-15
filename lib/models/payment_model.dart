import 'package:flutter/material.dart';
import '../models/plan.dart';

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
  int getDistributionTypeColorValue() {
    switch (distributionType) {
      case PaymentDistribution.monthly:
        return 0xFF3F51B5; // Indigo
      case PaymentDistribution.quarterly:
        return 0xFF4CAF50; // Green
      case PaymentDistribution.semiannual:
        return 0xFFFFC107; // Amber
      case PaymentDistribution.annual:
        return 0xFFF44336; // Red
      case PaymentDistribution.exit:
        return 0xFF9C27B0; // Purple
      //default:
      //  return 0xFF3F51B5; // Default to Indigo
    }
  }

  /// Get a label for the distribution type
  String get distributionTypeLabel {
    return distributionType.displayName;
  }
}