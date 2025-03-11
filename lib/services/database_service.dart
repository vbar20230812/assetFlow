// In /home/user/myapp/lib/services/database_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import files from the same directory
import 'firebase_data_connect.dart';
import 'default.dart'; // Import the local default.dart

import '../models/asset.dart';
import '../models/project.dart';
import '../models/plan.dart';

/// Service class to handle all Firestore database operations
class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('DatabaseService');
  final DefaultConnector _connector = DefaultConnector.instance;

  /// Get the current user ID or throw an exception if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// Create a new asset project
  Future<String> createProject(Project project) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Creating project for user: $userId');

      // Using the connector to add the project
      final docRef = await _connector.dataConnect.addDocument(
        'users/$userId/projects',
        project.toMap(),
      );

      _logger.info('Project created with ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      _logger.severe('Error creating project: $e');
      rethrow;
    }
  }

  /// Add a plan to an existing project
  Future<String> addPlanToProject(String projectId, Plan plan) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Adding plan to project $projectId for user: $userId');

      // Using the connector to add the plan
      final docRef = await _connector.dataConnect.addDocument(
        'users/$userId/projects/$projectId/plans',
        plan.toMap(),
      );

      _logger.info('Plan created with ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding plan to project: $e');
      rethrow;
    }
  }

  /// Update a project's data
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Updating project $projectId for user: $userId');

      await _connector.dataConnect.updateDocument(
        'users/$userId/projects',
        projectId,
        data,
      );

      _logger.info('Project updated successfully');
    } catch (e) {
      _logger.severe('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project and all its associated plans
  Future<void> deleteProject(String projectId) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Deleting project $projectId for user: $userId');

      // Get all plans for this project
      final plansSnapshot = await _connector.dataConnect.getCollectionStream(
        'users/$userId/projects/$projectId/plans',
      ).first;
      
      // Delete each plan
      for (var doc in plansSnapshot.docs) {
        await _connector.dataConnect.deleteDocument(
          'users/$userId/projects/$projectId/plans',
          doc.id,
        );
      }
      
      // Delete the project
      await _connector.dataConnect.deleteDocument(
        'users/$userId/projects',
        projectId,
      );

      _logger.info('Project and all its plans deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting project: $e');
      rethrow;
    }
  }

  /// Get all projects for the current user
  Stream<List<Project>> getUserProjects() {
  try {
    final userId = _getCurrentUserId();
    _logger.info('Getting projects for user: $userId');

    return _connector.dataConnect.getCollectionStream(
      'users/$userId/projects',
    ).map((snapshot) {
      final projects = snapshot.docs.map((doc) {
        return Project.fromFirestore(doc);
      }).toList();
      
      // Sort: non-archived first, then archived
      projects.sort((a, b) {
        if (a.isArchived == b.isArchived) {
          // If archive status is the same, sort by date (newest first)
          return b.updatedAt.compareTo(a.updatedAt);
        }
        // Non-archived comes before archived
        return a.isArchived ? 1 : -1;
      });
      
      return projects;
    });
  } catch (e) {
    _logger.severe('Error getting user projects: $e');
    rethrow;
  }
}

  /// Get a single project by ID
  Future<Project> getProject(String projectId) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Getting project $projectId for user: $userId');

      final docSnapshot = await _connector.dataConnect.getDocument(
        'users/$userId/projects',
        projectId,
      );

      if (!docSnapshot.exists) {
        throw Exception('Project not found');
      }

      return Project.fromFirestore(docSnapshot);
    } catch (e) {
      _logger.severe('Error getting project: $e');
      rethrow;
    }
  }

  /// Get all plans for a specific project
  Stream<List<Plan>> getProjectPlans(String projectId) {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Getting plans for project $projectId, user: $userId');

      return _connector.dataConnect.getCollectionStream(
        'users/$userId/projects/$projectId/plans',
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          return Plan.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      _logger.severe('Error getting project plans: $e');
      rethrow;
    }
  }

  /// Update a plan in a project
  Future<void> updatePlan(String projectId, String planId, Map<String, dynamic> data) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Updating plan $planId in project $projectId for user: $userId');

      await _connector.dataConnect.updateDocument(
        'users/$userId/projects/$projectId/plans',
        planId,
        data,
      );

      _logger.info('Plan updated successfully');
    } catch (e) {
      _logger.severe('Error updating plan: $e');
      rethrow;
    }
  }

  /// Delete a plan from a project
  Future<void> deletePlan(String projectId, String planId) async {
    try {
      final userId = _getCurrentUserId();
      _logger.info('Deleting plan $planId from project $projectId for user: $userId');

      await _connector.dataConnect.deleteDocument(
        'users/$userId/projects/$projectId/plans',
        planId,
      );

      _logger.info('Plan deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting plan: $e');
      rethrow;
    }
  }

  // Add these methods to the DatabaseService class

/// Archive a project
Future<void> archiveProject(String projectId) async {
  try {
    final userId = _getCurrentUserId();
    _logger.info('Archiving project $projectId for user: $userId');

    await _connector.dataConnect.updateDocument(
      'users/$userId/projects',
      projectId,
      {'isArchived': true, 'updatedAt': FieldValue.serverTimestamp()},
    );

    _logger.info('Project archived successfully');
  } catch (e) {
    _logger.severe('Error archiving project: $e');
    rethrow;
  }
}

/// Unarchive a project
Future<void> unarchiveProject(String projectId) async {
  try {
    final userId = _getCurrentUserId();
    _logger.info('Unarchiving project $projectId for user: $userId');

    await _connector.dataConnect.updateDocument(
      'users/$userId/projects',
      projectId,
      {'isArchived': false, 'updatedAt': FieldValue.serverTimestamp()},
    );

    _logger.info('Project unarchived successfully');
  } catch (e) {
    _logger.severe('Error unarchiving project: $e');
    rethrow;
  }
}

// Replace your existing getUserProjects method with this updated version


// Update the getUserProjects method to sort by isArchived

}