import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;
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

  Future<void> updateGroup(Group group) async {
    await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id)
          .update({
            'name':group.name,
            'location':group.location,
            'numberOfPeople':group.numberOfPeople,
          });
  }

  Future<void> addUserToGroup(String groupId, String userId) async {
    await _firestore.collection(_groupsCollection).doc(groupId).update({
      'members':FieldValue.arrayUnion([userId])
    });
  }

  Future<void> removeUserFromGroup(String groupId, String userId) async {
    await _firestore.collection(_groupsCollection).doc(groupId).update({
      'members':FieldValue.arrayRemove([userId])
    });
  }


  Future<void> addPurchaseToGroup({
    required String groupId,
    required String name,
    required List<String> payees,
    required Map<String, double> amounts,
    required String splitMethod,
  }) async {
    await firestore.collection('groups').doc(groupId).collection('purchases').add({
      'name':name,
      'payees':payees,
      'amounts':amounts,
      'splitMethod':splitMethod,
      'createdAt':FieldValue.serverTimestamp(),
    });
  }



  Stream<List<Map<String, dynamic>>> getGroupPurchasesStream(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('purchases')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
}

  Future<void> deletePurchase(String groupId, String purchaseId) async {
    await firestore
      .collection('groups')
      .doc(groupId)
      .collection('purchases')
      .doc(purchaseId)
      .delete();
  }


  Stream<List<String>> getGroupMembersStream(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['members'] ?? []));
  }

  Future<void> updatePurchase({
  required String groupId,
  required String purchaseId,
  required String name,
  required List<String> payees,
  required Map<String, double> amounts,
  required String splitMethod,
}) async {
  await firestore
      .collection('groups')
      .doc(groupId)
      .collection('purchases')
      .doc(purchaseId)
      .update({
    'name': name,
    'payees': payees,
    'amounts': amounts,
    'splitMethod': splitMethod,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


}