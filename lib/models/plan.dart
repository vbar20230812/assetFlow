import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum defining possible participation types in a plan
enum ParticipationType {
  limitedPartner,
  lender,
  development,
  other
}

/// Enum defining payment distribution frequencies
enum PaymentDistribution {
  quarterly,
  halfYearly,
  annual,
  exit
}

/// Extension to convert enum values to strings for display and storage
extension ParticipationTypeExtension on ParticipationType {
  String get displayName {
    switch (this) {
      case ParticipationType.limitedPartner:
        return 'Limited Partner';
      case ParticipationType.lender:
        return 'Lender';
      case ParticipationType.development:
        return 'Development';
      case ParticipationType.other:
        return 'Other';
    }
  }

  static ParticipationType fromString(String value) {
    return ParticipationType.values.firstWhere(
      (type) => type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ParticipationType.other,
    );
  }
}

/// Extension to convert enum values to strings for display and storage
extension PaymentDistributionExtension on PaymentDistribution {
  String get displayName {
    switch (this) {
      case PaymentDistribution.quarterly:
        return 'Quarterly';
      case PaymentDistribution.halfYearly:
        return 'Half Yearly';
      case PaymentDistribution.annual:
        return 'Annual';
      case PaymentDistribution.exit:
        return 'Exit';
    }
  }

  static PaymentDistribution fromString(String value) {
    return PaymentDistribution.values.firstWhere(
      (type) => type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentDistribution.exit,
    );
  }
}

/// Model class representing an investment plan within a project
class Plan {
  final String id;
  final String projectId;
  final ParticipationType participationType;
  final double minimalAmount;
  final int lengthMonths;
  final double annualInterest;
  final PaymentDistribution paymentDistribution;
  final double exitInterest;
  final bool isSelected;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.projectId,
    required this.participationType,
    required this.minimalAmount,
    required this.lengthMonths,
    required this.annualInterest,
    required this.paymentDistribution,
    this.exitInterest = 0,
    this.isSelected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new plan with default values
  factory Plan.create({
    required String projectId,
    required ParticipationType participationType,
    required double minimalAmount,
    required int lengthMonths,
    required double annualInterest,
    required PaymentDistribution paymentDistribution,
    double exitInterest = 0,
    bool isSelected = false,
  }) {
    return Plan(
      id: '',
      projectId: projectId,
      participationType: participationType,
      minimalAmount: minimalAmount,
      lengthMonths: lengthMonths,
      annualInterest: annualInterest,
      paymentDistribution: paymentDistribution,
      exitInterest: exitInterest,
      isSelected: isSelected,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a Plan object from a Firestore document
  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Plan(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      participationType: ParticipationTypeExtension.fromString(data['participationType'] ?? ''),
      minimalAmount: (data['minimalAmount'] ?? 0).toDouble(),
      lengthMonths: data['lengthMonths'] ?? 0,
      annualInterest: (data['annualInterest'] ?? 0).toDouble(),
      paymentDistribution: PaymentDistributionExtension.fromString(data['paymentDistribution'] ?? ''),
      exitInterest: (data['exitInterest'] ?? 0).toDouble(),
      isSelected: data['isSelected'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert this Plan object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'participationType': participationType.displayName,
      'minimalAmount': minimalAmount,
      'lengthMonths': lengthMonths,
      'annualInterest': annualInterest,
      'paymentDistribution': paymentDistribution.displayName,
      'exitInterest': exitInterest,
      'isSelected': isSelected,
      'createdAt': createdAt.isAfter(DateTime(2020)) 
        ? Timestamp.fromDate(createdAt) 
        : Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Create a copy of this Plan with the given fields replaced with new values
  Plan copyWith({
    String? id,
    String? projectId,
    ParticipationType? participationType,
    double? minimalAmount,
    int? lengthMonths,
    double? annualInterest,
    PaymentDistribution? paymentDistribution,
    double? exitInterest,
    bool? isSelected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plan(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      participationType: participationType ?? this.participationType,
      minimalAmount: minimalAmount ?? this.minimalAmount,
      lengthMonths: lengthMonths ?? this.lengthMonths,
      annualInterest: annualInterest ?? this.annualInterest,
      paymentDistribution: paymentDistribution ?? this.paymentDistribution,
      exitInterest: exitInterest ?? this.exitInterest,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}