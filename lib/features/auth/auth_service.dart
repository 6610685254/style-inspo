import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<User?> login(String input, String password) async {
    String email = input;

    if (!input.contains('@')) {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Username not found',
        );
      }

      email = query.docs.first['email'];
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user;
  }

  Future<User?> register(String username, String email, String password) async {
    // Check if username exists
    final existing = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (existing.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-taken',
        message: 'Username already taken',
      );
    }

    // Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save username in Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
  
}
