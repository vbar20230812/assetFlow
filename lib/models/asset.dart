import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing an investment asset 
class Asset {
  final String id;
  final String projectId;
  final String planId;
  final String name;
  final double investmentAmount;
  final DateTime startDate;
  final DateTime firstPaymentDate;
  final double nonRefundableFee;
  final String nonRefundableFeeNote;
  final double refundableFee;
  final String refundableFeeNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.projectId,
    required this.planId,
    required this.name,
    required this.investmentAmount,
    required this.startDate,
    required this.firstPaymentDate,
    this.nonRefundableFee = 0,
    this.nonRefundableFeeNote = '',
    this.refundableFee = 0,
    this.refundableFeeNote = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an Asset object from a Firestore document
  factory Asset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Asset(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      planId: data['planId'] ?? '',
      name: data['name'] ?? '',
      investmentAmount: (data['investmentAmount'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      firstPaymentDate: (data['firstPaymentDate'] as Timestamp).toDate(),
      nonRefundableFee: (data['nonRefundableFee'] ?? 0).toDouble(),
      nonRefundableFeeNote: data['nonRefundableFeeNote'] ?? '',
      refundableFee: (data['refundableFee'] ?? 0).toDouble(),
      refundableFeeNote: data['refundableFeeNote'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert this Asset object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'planId': planId,
      'name': name,
      'investmentAmount': investmentAmount,
      'startDate': Timestamp.fromDate(startDate),
      'firstPaymentDate': Timestamp.fromDate(firstPaymentDate),
      'nonRefundableFee': nonRefundableFee,
      'nonRefundableFeeNote': nonRefundableFeeNote,
      'refundableFee': refundableFee,
      'refundableFeeNote': refundableFeeNote,
      'createdAt': createdAt.isAfter(DateTime(2020)) 
        ? Timestamp.fromDate(createdAt) 
        : Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Create a copy of this Asset with the given fields replaced with new values
  Asset copyWith({
    String? id,
    String? projectId,
    String? planId,
    String? name,
    double? investmentAmount,
    DateTime? startDate,
    DateTime? firstPaymentDate,
    double? nonRefundableFee,
    String? nonRefundableFeeNote,
    double? refundableFee,
    String? refundableFeeNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      startDate: startDate ?? this.startDate,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      nonRefundableFee: nonRefundableFee ?? this.nonRefundableFee,
      nonRefundableFeeNote: nonRefundableFeeNote ?? this.nonRefundableFeeNote,
      refundableFee: refundableFee ?? this.refundableFee,
      refundableFeeNote: refundableFeeNote ?? this.refundableFeeNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}