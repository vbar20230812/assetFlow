// /home/user/myapp/lib/services/firebase_data_connect.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

// Define the required classes and enums
enum CallerSDKType {
  generated,
  manual,
}

class ConnectorConfig {
  final String region;
  final String namespace;
  final String projectId;

  ConnectorConfig(this.region, this.namespace, this.projectId);
}

class FirebaseDataConnect {
  final ConnectorConfig connectorConfig;
  final CallerSDKType sdkType;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('FirebaseDataConnect');

  FirebaseDataConnect({
    required this.connectorConfig,
    required this.sdkType,
  });

  static FirebaseDataConnect instanceFor({
    required ConnectorConfig connectorConfig,
    required CallerSDKType sdkType,
  }) {
    return FirebaseDataConnect(
      connectorConfig: connectorConfig,
      sdkType: sdkType,
    );
  }

  Future<DocumentReference> addDocument(
      String collectionPath, Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      return docRef;
    } catch (e) {
      _logger.severe('Error adding document: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(
      String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      _logger.severe('Error updating document: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      _logger.severe('Error deleting document: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getCollectionStream(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  Future<DocumentSnapshot> getDocument(
      String collectionPath, String docId) async {
    return await _firestore.collection(collectionPath).doc(docId).get();
  }
}