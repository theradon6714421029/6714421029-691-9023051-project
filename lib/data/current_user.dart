import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_role.dart';

UserRole currentUserRole = UserRole.customer;

bool get isAdmin {
  return currentUserRole == UserRole.admin;
}

Future<void> loadCurrentUserRole() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    currentUserRole = UserRole.customer;
    return;
  }

  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  final doc = await ref.get();

  if (!doc.exists) {
    await ref.set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    currentUserRole = UserRole.customer;
    return;
  }

  final data = doc.data();

  currentUserRole =
      data?['role'] == 'admin'
          ? UserRole.admin
          : UserRole.customer;
}