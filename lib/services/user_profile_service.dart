import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future <void> createUserProfile(User user, {String? name, String? paymentPreference}){
    return users.doc(user.uid).set({
      'email':user.email,
      'name':name ?? '',
      'paymentPreference': paymentPreference ?? '',
    });
  }

  Future<DocumentSnapshot> getUserProfile(String uid){
    return users.doc(uid).get();
  }

  Future<void> updateUserProfile(String uid, {String? name, String? paymentPreference}){
    return users.doc(uid).update({
      if (name != null) 'name': name,
      if (paymentPreference != null) 'paymentPreference': paymentPreference, 
    });
  }
}