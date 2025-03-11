import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Enum representing the distribution schedule of payments
enum PaymentDistribution {
  monthly,
  quarterly,
  semiannual,
  annual,
  exit;
  
  // Display name getter
  String get displayName {
    switch (this) {
      case PaymentDistribution.monthly:
        return 'Monthly';
      case PaymentDistribution.quarterly:
        return 'Quarterly';
      case PaymentDistribution.semiannual:
        return 'Semi-Annual';
      case PaymentDistribution.annual:
        return 'Annual';
      case PaymentDistribution.exit:
        return 'At Exit';
    }
  }
  
  // For backward compatibility
  static const halfYearly = PaymentDistribution.semiannual;
}

/// Enum representing the type of participation in the investment
enum ParticipationType {
  limitedPartner,
  lender,
  development,
  other;
  
  // Display name getter
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
}

/// Model representing an investment plan
class Plan {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final ParticipationType participationType;
  final double interestRate;
  final double minimalAmount;
  final double maximalAmount;
  final PaymentDistribution paymentDistribution;
  final bool hasGuarantee;
  final bool isSelected;
  final int lengthMonths;
  final double exitInterest; // Added property for exit interest

  const Plan({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.participationType,
    required this.interestRate,
    required this.minimalAmount,
    required this.maximalAmount,
    required this.paymentDistribution,
    required this.hasGuarantee,
    required this.lengthMonths,
    this.exitInterest = 0.0, // Default value
    this.isSelected = false,
  });

  /// Create a new plan with default values
  factory Plan.create({
    String? id,
    required String projectId,
    required String name,
    String description = '',
    ParticipationType participationType = ParticipationType.limitedPartner,
    double interestRate = 0.0,
    double annualInterest = 0.0, // Added parameter for convenience
    double minimalAmount = 0.0,
    double maximalAmount = 0.0,
    PaymentDistribution paymentDistribution = PaymentDistribution.quarterly,
    bool hasGuarantee = false,
    bool isSelected = false,
    int lengthMonths = 12,
    double exitInterest = 0.0,
  }) {
    // Use annualInterest parameter if provided, otherwise use interestRate
    final double effectiveInterestRate = annualInterest > 0 ? annualInterest : interestRate;
    
    return Plan(
      id: id ?? _generateId(),
      projectId: projectId,
      name: name,
      description: description,
      participationType: participationType,
      interestRate: effectiveInterestRate,
      minimalAmount: minimalAmount,
      maximalAmount: maximalAmount > 0 ? maximalAmount : minimalAmount,
      paymentDistribution: paymentDistribution,
      hasGuarantee: hasGuarantee,
      isSelected: isSelected,
      lengthMonths: lengthMonths,
      exitInterest: exitInterest,
    );
  }

  /// Create a copy of this plan with optional updated properties
  Plan copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    ParticipationType? participationType,
    double? interestRate,
    double? annualInterest, // Added parameter
    double? minimalAmount,
    double? maximalAmount,
    PaymentDistribution? paymentDistribution,
    bool? hasGuarantee,
    bool? isSelected,
    int? lengthMonths,
    double? exitInterest,
  }) {
    // Handle the annualInterest parameter specifically
    final double effectiveInterestRate = annualInterest ?? this.interestRate;
    
    return Plan(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      participationType: participationType ?? this.participationType,
      interestRate: effectiveInterestRate,
      minimalAmount: minimalAmount ?? this.minimalAmount,
      maximalAmount: maximalAmount ?? this.maximalAmount,
      paymentDistribution: paymentDistribution ?? this.paymentDistribution,
      hasGuarantee: hasGuarantee ?? this.hasGuarantee,
      isSelected: isSelected ?? this.isSelected,
      lengthMonths: lengthMonths ?? this.lengthMonths,
      exitInterest: exitInterest ?? this.exitInterest,
    );
  }

  /// Get the annual interest rate
  double get annualInterest {
    // For regular plans, the interestRate is already annual
    // For plans with distributions that are not annual, we calculate the annual equivalent
    switch (paymentDistribution) {
      case PaymentDistribution.monthly:
        // Convert monthly rate to annual rate: (1 + r)^12 - 1
        return (math.pow(1 + interestRate, 12) - 1) as double;
      case PaymentDistribution.quarterly:
        // Convert quarterly rate to annual rate: (1 + r)^4 - 1
        return (math.pow(1 + interestRate, 4) - 1) as double;
      case PaymentDistribution.semiannual:
        // Convert semi-annual rate to annual rate: (1 + r)^2 - 1
        return (math.pow(1 + interestRate, 2) - 1) as double;
      case PaymentDistribution.annual:
      case PaymentDistribution.exit:
        // Annual rate is already annual
        return interestRate;
    }
  }

  /// Get the name of the participation type
  String get participationTypeName => participationType.displayName;

  /// Get the name of the payment distribution
  String get paymentDistributionName => paymentDistribution.displayName;

  /// Convert plan to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
      'participationType': participationType.index,
      'interestRate': interestRate,
      'minimalAmount': minimalAmount,
      'maximalAmount': maximalAmount,
      'paymentDistribution': paymentDistribution.index,
      'hasGuarantee': hasGuarantee,
      'isSelected': isSelected,
      'lengthMonths': lengthMonths,
      'exitInterest': exitInterest,
    };
  }

  /// Create a plan from a map
  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      participationType: ParticipationType.values[map['participationType'] ?? 0],
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      minimalAmount: (map['minimalAmount'] ?? 0.0).toDouble(),
      maximalAmount: (map['maximalAmount'] ?? 0.0).toDouble(),
      paymentDistribution: PaymentDistribution.values[map['paymentDistribution'] ?? 0],
      hasGuarantee: map['hasGuarantee'] ?? false,
      isSelected: map['isSelected'] ?? false,
      lengthMonths: map['lengthMonths'] ?? 12,
      exitInterest: (map['exitInterest'] ?? 0.0).toDouble(),
    );
  }

  /// Create a plan from a Firestore document
  factory Plan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Plan.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  /// Generate a random ID
  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = math.Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }
}