import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';

class TransactionProvider with ChangeNotifier {
  String _filter = 'all';
  bool _shouldReload = true;
  List<TransactionEntity> _transactions = [];
  String? _currentUserId;
  
  String get filter => _filter;
  bool get shouldReload => _shouldReload;
  List<TransactionEntity> get transactions => _transactions;
  
  List<TransactionEntity> get filteredTransactions {
    if (_filter == 'all') {
      return _transactions;
    } else {
      return _transactions.where((t) => t.type == _filter).toList();
    }
  }
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize with current user
  void initialize(String? userId) {
    if (userId != _currentUserId) {
      _currentUserId = userId;
      _transactions = [];
      _shouldReload = true;
      notifyListeners();
    }
  }
  
  void markReloaded() {
    _shouldReload = false;
  }
  
  Future<void> loadTransactions() async {
    try {
      if (_currentUserId == null || _currentUserId!.isEmpty) return;
      
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('date', descending: true)
          .get();
          
      _transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionEntity.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      rethrow;
    }
  }
  
  void setFilter(String filter) {
    if (_filter == filter) return;
    
    _filter = filter;
    _shouldReload = true;
    notifyListeners();
  }
  
  // Get transactions stream from Firestore
  Stream<List<TransactionEntity>> getTransactionsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionEntity.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    });
  }
  
  // Get transactions for analytics (with optional date range)
  Future<List<TransactionEntity>> getTransactionsForAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        print('⚠️ No user ID available for fetching transactions');
        return [];
      }
      
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        print('⚠️ No user ID available');
        return [];
      }
      
      print('🔍 Fetching transactions for user: $_currentUserId');
      
      // Query the transactions collection directly and filter by userId
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _currentUserId);
      
      // Apply date filters if provided
      if (startDate != null) {
        print('   - Filtering from date: $startDate');
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        print('   - Filtering to date: $endDate');
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }
      
      print('   - Executing query...');
      final snapshot = await query.orderBy('date', descending: true).get();
      
      print('   - Found ${snapshot.docs.length} documents');
      
      _transactions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('   - Document ${doc.id} data: $data');
          
          final transaction = TransactionEntity.fromJson({
            ...data,
            'id': doc.id,
          });
          
          _transactions.add(transaction);
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
        }
      }
      
      print('✅ Successfully loaded ${_transactions.length} transactions');
      return _transactions;
      
    } catch (e, stackTrace) {
      print('❌ Error getting transactions for analytics:');
      print('   - Error: $e');
      print('   - Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Get monthly spending data
  Future<Map<String, double>> getMonthlySpending() async {
    try {
      print('📅 getMonthlySpending() called');
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      
      print('   - Date range: $sixMonthsAgo to $now');
      
      final transactions = await getTransactionsForAnalytics(
        startDate: sixMonthsAgo,
        endDate: now,
      );
      
      print('   - Found ${transactions.length} transactions for monthly spending');
      
      // Initialize last 6 months with zero values
      final monthlyData = <String, double>{};
      for (var i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthYear = '${_getMonthName(date.month)} ${date.year}';
        monthlyData[monthYear] = 0.0;
        print('   - Initialized month: $monthYear');
      }
      
      // Calculate monthly totals
      for (var transaction in transactions) {
        final monthYear = '${_getMonthName(transaction.date.month)} ${transaction.date.year}';
        if (monthlyData.containsKey(monthYear)) {
          monthlyData[monthYear] = (monthlyData[monthYear] ?? 0) + transaction.amount;
          print('   - Added ${transaction.amount} to $monthYear (${transaction.category})');
        }
      }
      
      print('✅ Monthly spending data: $monthlyData');
      return monthlyData;
      
    } catch (e, stackTrace) {
      print('❌ Error in getMonthlySpending:');
      print('   - Error: $e');
      print('   - Stack trace: $stackTrace');
      return {};
    }
  }
  
  // Get category-wise spending data
  Future<Map<String, double>> getCategorySpending() async {
    try {
      print('🏷️ getCategorySpending() called');
      final transactions = await getTransactionsForAnalytics();
      print('   - Found ${transactions.length} transactions for category analysis');
      
      final categoryData = <String, double>{};
      
      for (var transaction in transactions) {
        if (transaction.type == 'expense') {
          final currentAmount = categoryData[transaction.category] ?? 0;
          categoryData[transaction.category] = currentAmount + transaction.amount;
          print('   - Added ${transaction.amount} to category ${transaction.category}');
        }
      }
      
      print('✅ Category spending data: $categoryData');
      return categoryData;
      
    } catch (e, stackTrace) {
      print('❌ Error in getCategorySpending:');
      print('   - Error: $e');
      print('   - Stack trace: $stackTrace');
      return {};
    }
  }
  
  String _getMonthName(int month) {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }
}
