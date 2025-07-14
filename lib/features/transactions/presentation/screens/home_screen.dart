import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/shared/widgets/transaction_item.dart';
import 'package:expense_tracker/shared/widgets/empty_state.dart';
import 'package:expense_tracker/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/shared/services/firebase_service.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/balance_card.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_summary.dart';
import 'package:expense_tracker/features/profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset < 400 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const BalanceCard(
                  balance: 0.0,
                  income: 0.0,
                  expense: 0.0,
                );
              }
              
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final balance = (userData?['balance'] ?? 0.0).toDouble();
              
              // In a real app, you would calculate income and expense from transactions
              // For now, we'll use placeholder values
              final income = 0.0;
              final expense = 0.0;
              
              return BalanceCard(
                balance: balance,
                income: income,
                expense: expense,
              );
            },
          ),
          
          // Transaction Summary
          const TransactionSummary(),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                TransactionFilterChip(
                  label: 'All', 
                  isSelected: _selectedFilter == 'all', 
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                TransactionFilterChip(
                  label: 'Income', 
                  isSelected: _selectedFilter == 'income', 
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'income');
                  },
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                TransactionFilterChip(
                  label: 'Expense', 
                  isSelected: _selectedFilter == 'expense', 
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'expense');
                  },
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.error,
                ),
              ],
            ),
          ),
          
          // Recent Transactions
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions',
                    message: 'Start adding your expenses and income to see them here.',
                    action: ElevatedButton(
                      onPressed: () {
                        // Navigate to add transaction screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTransactionScreen(),
                          ),
                        );
                      },
                      child: const Text('Add Transaction'),
                    ),
                  );
                }
                
                final transactions = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return TransactionEntity(
                    id: doc.id,
                    userId: data['userId'],
                    amount: (data['amount'] as num).toDouble(),
                    type: data['type'],
                    category: data['category'],
                    description: data['description'],
                    date: (data['date'] as Timestamp).toDate(),
                  );
                }).toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionItem(
                      transaction: transaction,
                      onTap: () {
                        // Navigate to transaction detail screen
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              backgroundColor: AppTheme.primaryColor,
            ),
    );
  }
}
