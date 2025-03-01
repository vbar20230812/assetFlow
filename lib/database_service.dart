import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('DatabaseService');

  Future<void> createTask(String taskName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').doc(user.uid).collection('userTasks').add({
        'taskName': taskName,
        'isCompleted': false,
      });
      _logger.info('Task created: $taskName');
    } else {
      _logger.warning('User not logged in, cannot create task.');
    }
  }

  Stream<QuerySnapshot> getTasks() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('tasks').doc(user.uid).collection('userTasks').snapshots();
    } else {
      _logger.warning('User not logged in, cannot get tasks.');
      return const Stream.empty();
    }
  }

  Future<void> updateTask(String taskId, bool isCompleted) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').doc(user.uid).collection('userTasks').doc(taskId).update({
        'isCompleted': isCompleted,
      });
      _logger.info('Task updated: $taskId, isCompleted: $isCompleted');
    } else {
      _logger.warning('User not logged in, cannot update task.');
    }
  }

  Future<void> deleteTask(String taskId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').doc(user.uid).collection('userTasks').doc(taskId).delete();
      _logger.info('Task deleted: $taskId');
    } else {
      _logger.warning('User not logged in, cannot delete task.');
    }
  }
}