import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _groupsCollection = 'groups';

  Future<String> addGroup(Group group) async {
    try {
      final docRef = await _firestore.collection(_groupsCollection).add(group.toMap());
      
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add group: $e');
    }
  }

  Future<List<Group>> getAllGroups() async {
    try {
      final querySnapshot = await _firestore.collection(_groupsCollection).get();
      
      return querySnapshot.docs.map((doc) {
        return Group.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get groups: $e');
    }
  }

  Stream<List<Group>> getGroupsStream() {
    return _firestore.collection(_groupsCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Group.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}