import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import '../models/asset.dart';
import '../models/project.dart';
import '../models/plan.dart';

/// Service class to handle all Firestore database operations
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('DatabaseService');

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

      // Add the project to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .add(project.toMap());

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

      // Add the plan to the plans subcollection
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('plans')
          .add(plan.toMap());

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

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update(data);

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

      // Delete all plans in the project first
      final plansSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('plans')
          .get();

      final batch = _firestore.batch();
      
      for (var doc in plansSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the project document
      batch.delete(_firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId));
      
      await batch.commit();

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

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return Project.fromFirestore(doc);
            }).toList();
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

      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .get();

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

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('plans')
          .snapshots()
          .map((snapshot) {
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

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('plans')
          .doc(planId)
          .update(data);

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

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('plans')
          .doc(planId)
          .delete();

      _logger.info('Plan deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting plan: $e');
      rethrow;
    }
  }
}