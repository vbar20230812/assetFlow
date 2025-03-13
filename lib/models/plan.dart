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
  final double interestRate; // This is the raw interest rate stored in DB
  final double minimalAmount;
  final PaymentDistribution paymentDistribution;
  final bool isSelected;
  final int lengthMonths;
  final double exitInterest; // Additional interest paid at exit

  const Plan({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.participationType,
    required this.interestRate,
    required this.minimalAmount,
    required this.paymentDistribution,
    required this.lengthMonths,
    this.exitInterest = 0.0,
    this.isSelected = false,
  });

  /// Create a new plan with default values
  factory Plan.create({
    String? id,
    required String projectId,
    String? name,
    String description = '',
    ParticipationType participationType = ParticipationType.limitedPartner,
    double interestRate = 0.0,
    double annualInterest = 0.0, // This is for convenience when input is in percentage
    double minimalAmount = 0.0,
    PaymentDistribution paymentDistribution = PaymentDistribution.quarterly,
    bool isSelected = false,
    int lengthMonths = 12,
    double exitInterest = 0.0,
  }) {
    // Use annualInterest parameter if provided, otherwise use interestRate
    // If annualInterest is provided, it's assumed to be in percentage (e.g., 15.0 for 15%)
    // So we convert it to decimal (0.15) for storage
    final double effectiveInterestRate = annualInterest > 0 ? annualInterest / 100 : interestRate;
    
    // For exit payment distribution, set exitInterest equal to interestRate
    final double effectiveExitInterest = paymentDistribution == PaymentDistribution.exit 
        ? effectiveInterestRate 
        : (exitInterest > 0 ? exitInterest : 0.0);
    
    // Generate default name if not provided
    final String planName = name ?? 
        '${participationType.displayName} ${(annualInterest > 0 ? annualInterest : (interestRate * 100)).toStringAsFixed(1)}%';
    
    return Plan(
      id: id ?? _generateId(),
      projectId: projectId,
      name: planName,
      description: description,
      participationType: participationType,
      interestRate: effectiveInterestRate,
      minimalAmount: minimalAmount,
      paymentDistribution: paymentDistribution,
      isSelected: isSelected,
      lengthMonths: lengthMonths,
      exitInterest: effectiveExitInterest,
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
    double? annualInterest, // Added parameter for direct percentage input
    double? minimalAmount,
    PaymentDistribution? paymentDistribution,
    bool? isSelected,
    int? lengthMonths,
    double? exitInterest,
  }) {
    // If annualInterest is provided, convert it from percentage to decimal
    final double effectiveInterestRate = annualInterest != null ? 
                                        annualInterest / 100 : 
                                        interestRate ?? this.interestRate;
    
    // For exit payment distribution, ensure exitInterest equals interestRate
    final PaymentDistribution effectivePaymentDistribution = paymentDistribution ?? this.paymentDistribution;
    double effectiveExitInterest = exitInterest ?? this.exitInterest;
    
    if (effectivePaymentDistribution == PaymentDistribution.exit) {
      effectiveExitInterest = effectiveInterestRate;
    }
    
    // Generate default name if empty or changing participation type or interest rate
    String effectiveName = name ?? this.name;
    if (effectiveName.isEmpty || participationType != null || annualInterest != null || interestRate != null) {
      final ParticipationType effectiveParticipationType = participationType ?? this.participationType;
      final double effectiveDisplayRate = annualInterest ?? (effectiveInterestRate * 100);
      effectiveName = '${effectiveParticipationType.displayName} ${effectiveDisplayRate.toStringAsFixed(1)}%';
    }
    
    return Plan(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: effectiveName,
      description: description ?? this.description,
      participationType: participationType ?? this.participationType,
      interestRate: effectiveInterestRate,
      minimalAmount: minimalAmount ?? this.minimalAmount,
      paymentDistribution: effectivePaymentDistribution,
      isSelected: isSelected ?? this.isSelected,
      lengthMonths: lengthMonths ?? this.lengthMonths,
      exitInterest: effectiveExitInterest,
    );
  }

  /// Get the annual interest rate as a percentage (e.g., 15.0 for 15%)
  double get annualInterest {
    // interestRate is stored as decimal (e.g., 0.15 for 15%)
    // Convert to percentage for display
    return interestRate * 100;
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
      'interestRate': interestRate, // Store as decimal in DB
      'minimalAmount': minimalAmount,
      'paymentDistribution': paymentDistribution.index,
      'isSelected': isSelected,
      'lengthMonths': lengthMonths,
      'exitInterest': exitInterest,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
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
      paymentDistribution: PaymentDistribution.values[map['paymentDistribution'] ?? 0],
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