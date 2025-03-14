import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Project {
  final String id;
  final String name;
  final String company;
  final int projectLengthMonths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final String currency;
  
  // Amount stage fields
  final double investmentAmount;
  final DateTime startDate;
  final DateTime firstPaymentDate;
  final double nonRefundableFee;
  final String nonRefundableFeeNote;
  final double refundableFee;
  final String refundableFeeNote;

  Project({
    required this.id,
    required this.name,
    required this.company,
    required this.projectLengthMonths,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.currency = 'USD',
    this.investmentAmount = 0.0,
    DateTime? startDate,
    DateTime? firstPaymentDate,
    this.nonRefundableFee = 0.0,
    this.nonRefundableFeeNote = '',
    this.refundableFee = 0.0,
    this.refundableFeeNote = '',
  }) : 
    startDate = startDate ?? DateTime.now(),
    firstPaymentDate = firstPaymentDate ?? DateTime.now().add(const Duration(days: 30));

  /// Create a Project object from a Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to parse timestamp or use default
    DateTime parseTimestamp(dynamic value, DateTime defaultValue) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateFormat('dd/MM/yyyy\'T\'HH:mm:ss').parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
    
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      projectLengthMonths: data['projectLengthMonths'] ?? 0,
      createdAt: parseTimestamp(data['createdAt'], DateTime.now()),
      updatedAt: parseTimestamp(data['updatedAt'], DateTime.now()),
      isArchived: data['isArchived'] ?? false,
      currency: data['currency'] ?? 'USD',
      investmentAmount: (data['investmentAmount'] ?? 0.0).toDouble(),
      startDate: parseTimestamp(data['startDate'], DateTime.now()),
      firstPaymentDate: parseTimestamp(data['firstPaymentDate'], DateTime.now().add(const Duration(days: 30))),
      nonRefundableFee: (data['nonRefundableFee'] ?? 0.0).toDouble(),
      nonRefundableFeeNote: data['nonRefundableFeeNote'] ?? '',
      refundableFee: (data['refundableFee'] ?? 0.0).toDouble(),
      refundableFeeNote: data['refundableFeeNote'] ?? '',
    );
  }

  /// Convert this Project object to a Map for Firestore
  Map<String, dynamic> toMap() {
    // Format date as dd/MM/YYYYTHH:mm:ss
    String formatDate(DateTime date) {
      return DateFormat('dd/MM/yyyy\'T\'HH:mm:ss').format(date);
    }
    
    return {
      'name': name,
      'company': company,
      'projectLengthMonths': projectLengthMonths,
      'createdAt': formatDate(createdAt),
      'updatedAt': formatDate(updatedAt),
      'isArchived': isArchived,
      'currency': currency,
      'investmentAmount': investmentAmount,
      'startDate': formatDate(startDate),
      'firstPaymentDate': formatDate(firstPaymentDate),
      'nonRefundableFee': nonRefundableFee,
      'nonRefundableFeeNote': nonRefundableFeeNote,
      'refundableFee': refundableFee,
      'refundableFeeNote': refundableFeeNote,
    };
  }

  /// Create a new Project with default values
  factory Project.create({
    required String name,
    required String company,
    required int projectLengthMonths,
    String currency = 'USD',
    double investmentAmount = 0.0,
    DateTime? startDate,
    DateTime? firstPaymentDate,
    double nonRefundableFee = 0.0,
    String nonRefundableFeeNote = '',
    double refundableFee = 0.0,
    String refundableFeeNote = '',
  }) {
    final now = DateTime.now();
    return Project(
      id: '',
      name: name,
      company: company,
      projectLengthMonths: projectLengthMonths,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
      currency: currency,
      investmentAmount: investmentAmount,
      startDate: startDate,
      firstPaymentDate: firstPaymentDate,
      nonRefundableFee: nonRefundableFee,
      nonRefundableFeeNote: nonRefundableFeeNote,
      refundableFee: refundableFee,
      refundableFeeNote: refundableFeeNote,
    );
  }

  /// Create a copy of this Project with the given fields replaced with new values
  Project copyWith({
    String? id,
    String? name,
    String? company,
    int? projectLengthMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? currency,
    double? investmentAmount,
    DateTime? startDate,
    DateTime? firstPaymentDate,
    double? nonRefundableFee,
    String? nonRefundableFeeNote,
    double? refundableFee,
    String? refundableFeeNote,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      projectLengthMonths: projectLengthMonths ?? this.projectLengthMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      currency: currency ?? this.currency,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      startDate: startDate ?? this.startDate,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      nonRefundableFee: nonRefundableFee ?? this.nonRefundableFee,
      nonRefundableFeeNote: nonRefundableFeeNote ?? this.nonRefundableFeeNote,
      refundableFee: refundableFee ?? this.refundableFee,
      refundableFeeNote: refundableFeeNote ?? this.refundableFeeNote,
    );
  }
}