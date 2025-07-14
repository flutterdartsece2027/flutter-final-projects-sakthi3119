import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Auth Methods
  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(loginMethod: 'email_password');
      await _analytics.logEvent(
        name: 'login',
        parameters: {'method': 'email_password'},
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'balance': 0.0,
      });
      
      await _analytics.logSignUp(signUpMethod: 'email_password');
      await _analytics.logEvent(
        name: 'sign_up',
        parameters: {'method': 'email_password'},
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore Methods
  static Future<DocumentSnapshot> getUserData(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  static Stream<DocumentSnapshot> getUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  static Future<void> addTransaction({
    required String userId,
    required double amount,
    required String type,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final transactionRef = _firestore.collection('transactions').doc();
    
    await _firestore.runTransaction((transaction) async {
      // Add transaction
      transaction.set(transactionRef, {
        'id': transactionRef.id,
        'userId': userId,
        'amount': amount,
        'type': type,
        'category': category,
        'description': description ?? '',
        'date': date,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user's balance
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
        double newBalance = type == 'income' 
            ? currentBalance + amount 
            : currentBalance - amount;
            
        transaction.update(userRef, {'balance': newBalance});
      }
    });
  }

  static Stream<QuerySnapshot> getUserTransactions(String userId, 
      {String? type, int? limit}) {
    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);
    
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  static Future<void> deleteTransaction(
      String userId, String transactionId, String type, double amount) async {
    await _firestore.runTransaction((transaction) async {
      // Delete transaction
      final transactionRef = _firestore.collection('transactions').doc(transactionId);
      transaction.delete(transactionRef);

      // Update user's balance
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
        double newBalance = type == 'income' 
            ? currentBalance - amount 
            : currentBalance + amount;
            
        transaction.update(userRef, {'balance': newBalance});
      }
    });
  }
}
