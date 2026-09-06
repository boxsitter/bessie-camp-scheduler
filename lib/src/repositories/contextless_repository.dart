import 'package:cloud_firestore/cloud_firestore.dart';

import '../ember_core.dart';



class ContextlessRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  // Don't use this unless debugging or database repair
  Future<void> push(String path, CoreObject object) async {
    try {
      await FirebaseFirestore.instance.doc(path).set(object.toJson());
      Debug.logInfo('Document pushed successfully to $path');
    } catch (e) {
      Debug.logInfo('Error pushing document to $path: $e');
    }
  }

  Future<bool> docExists(String path) async {
    try {
      final DocumentSnapshot doc = await _db.doc(path).get();
      return doc.exists;
    } catch (e) {
      Debug.logInfo('Error checking if document exists at $path: $e');
      return false; // Or rethrow the error if you want to handle it upstream
    }
  }

  Future<Map<String, dynamic>?> pull(String path) async {
    try {
      final DocumentSnapshot docSnapshot = await _db.doc(path).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>?;
      } else {
        Debug.logInfo('Document does not exist at path: $path');
        return null;
      }
    } catch (e) {
      Debug.logInfo('Error getting document at $path: $e');
      return null;
    }
  }
}
