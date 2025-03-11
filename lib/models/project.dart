import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String company;
  final int projectLengthMonths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final String currency;

  Project({
    required this.id,
    required this.name,
    required this.company,
    required this.projectLengthMonths,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.currency = 'USD',
  });

  /// Create a Project object from a Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      projectLengthMonths: data['projectLengthMonths'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isArchived: data['isArchived'] ?? false,
      currency: data['currency'] ?? 'USD',
    );
  }

  /// Convert this Project object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'projectLengthMonths': projectLengthMonths,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'currency': currency,
    };
  }

  /// Create a new Project with default values
  factory Project.create({
    required String name,
    required String company,
    required int projectLengthMonths,
    String currency = 'USD',
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
    );
  }
}