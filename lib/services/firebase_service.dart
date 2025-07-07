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
    final payment_status = {for (var payee in payees) payee:false};
    await firestore.collection('groups').doc(groupId).collection('purchases').add({
      'name':name,
      'payees':payees,
      'amounts':amounts,
      'splitMethod':splitMethod,
      'createdAt':FieldValue.serverTimestamp(),
      'paymentStatus': payment_status,
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

  Future<List<Map<String, dynamic>>> getGroupPurchases(String groupId) async {
  final snapshot = await firestore
      .collection('groups')
      .doc(groupId)
      .collection('purchases')
      .orderBy('createdAt', descending: true)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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


  Future<void> userPaymentStatus(
    String groupId,
    String purchaseId,
    String userId,
    bool isPaid
  ) async {
    await firestore
    .collection('groups')
    .doc(groupId)
    .collection('purchases')
    .doc(purchaseId)
    .update({'paymentStatus.$userId':isPaid,});
  }


  Future<List<Group>> getUserGroups(String userId) async {
  try {
    final memberQuery = await _firestore
        .collection(_groupsCollection)
        .where('members', arrayContains: userId)
        .get();

    final creatorQuery = await _firestore
        .collection(_groupsCollection)
        .where('createdBy', isEqualTo: userId)
        .get();

    final allDocs = [
      ...memberQuery.docs,
      ...creatorQuery.docs.where((doc) => !memberQuery.docs.any((d) => d.id == doc.id))
    ];

    return allDocs.map((doc) => Group.fromMap(doc.data(), doc.id)).toList();
  } catch (e) {
    throw Exception('Failed to get user groups: $e');
  }
}

  Stream<List<Group>> getUserGroupsStream(String userId) {
    final memberStream = _firestore
        .collection(_groupsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
        
    final creatorStream = _firestore
        .collection(_groupsCollection)
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
        
    return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((_) async {
      final memberDocs = await memberStream.first;
      final creatorDocs = await creatorStream.first;
      
      final allDocs = [
        ...memberDocs,
        ...creatorDocs.where((doc) => !memberDocs.any((d) => d.id == doc.id))
      ];
      
      return allDocs.map((doc) => Group.fromMap(doc.data(), doc.id)).toList();
    });
  }

}