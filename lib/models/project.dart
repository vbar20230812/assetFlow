import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a real estate project
class Project {
  final String id;
  final String name;
  final String company;
  final int projectLengthMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.company,
    required this.projectLengthMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new project with default values
  factory Project.create({
    required String name,
    required String company,
    required int projectLengthMonths,
  }) {
    return Project(
      id: '',
      name: name,
      company: company,
      projectLengthMonths: projectLengthMonths,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a Project object from a Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      projectLengthMonths: data['projectLengthMonths'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert this Project object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'projectLengthMonths': projectLengthMonths,
      'createdAt': createdAt.isAfter(DateTime(2020)) 
        ? Timestamp.fromDate(createdAt) 
        : Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Create a copy of this Project with the given fields replaced with new values
  Project copyWith({
    String? id,
    String? name,
    String? company,
    int? projectLengthMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      projectLengthMonths: projectLengthMonths ?? this.projectLengthMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}