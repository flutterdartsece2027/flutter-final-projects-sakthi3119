import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/shared/widgets/transaction_item.dart';
import 'package:expense_tracker/shared/widgets/empty_state.dart';
import 'package:expense_tracker/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/screens/all_transactions_screen.dart';
import 'package:expense_tracker/shared/services/firebase_service.dart';
import 'package:expense_tracker/features/transactions/data/providers/transaction_provider.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/balance_card.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_summary.dart';
import 'package:expense_tracker/features/profile/presentation/screens/profile_screen.dart';
import 'package:expense_tracker/core/extensions/string_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  List<TransactionEntity> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      Query query;
      
      if (transactionProvider.filter == 'all') {
        query = FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true);
      } else {
        query = FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .where('type', isEqualTo: transactionProvider.filter)
            .orderBy('date', descending: true);
      }

      final snapshot = await query.get();
      
      if (mounted) {
        setState(() {
          _transactions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return TransactionEntity(
              id: doc.id,
              userId: data['userId'],
              amount: (data['amount'] as num).toDouble(),
              type: data['type'],
              category: data['category'],
              description: data['description'] ?? '',
              date: (data['date'] as Timestamp).toDate(),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('index')) {
            _error = 'Database index is being created. Please wait a few minutes and try again.';
          } else {
            _error = 'Failed to load transactions. Please try again.';
          }
          _isLoading = false;
        });
      }
      debugPrint('Error loading transactions: $e');
      
      // If it's an index error, try again after a delay
      if (e.toString().contains('index') && mounted) {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) _loadTransactions();
      }
    }
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

  // Calculate total income and expense from transactions
  Widget _buildTransactionSummary() {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const BalanceCard(
            balance: 0.0,
            income: 0.0,
            expense: 0.0,
          );
        }

        double totalIncome = 0.0;
        double totalExpense = 0.0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0.0).toDouble();
          
          if (data['type'] == 'income') {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }
        }

        final balance = totalIncome - totalExpense;
        
        // Update user's balance in Firestore
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'balance': balance,
                'income': totalIncome,
                'expense': totalExpense,
              });
        }

        return BalanceCard(
          balance: balance,
          income: totalIncome,
          expense: totalExpense,
        );
      },
    );
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload transactions when the filter changes
    final transactionProvider = Provider.of<TransactionProvider>(context);
    if (transactionProvider.shouldReload) {
      _loadTransactions();
      transactionProvider.markReloaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expensify - Budget Made Easy'),
        elevation: 0,
        centerTitle: false,
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
          // Balance Card with real calculations
          _buildTransactionSummary(),
          
          // Transaction Summary
          TransactionSummary(
            userId: user?.uid,
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllTransactionsScreen(),
                ),
              );
            },
          ),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                TransactionFilterChip(
                  label: 'All', 
                  isSelected: transactionProvider.filter == 'all', 
                  onSelected: (selected) => transactionProvider.setFilter('all'),
                ),
                const SizedBox(width: 8),
                TransactionFilterChip(
                  label: 'Income', 
                  isSelected: transactionProvider.filter == 'income', 
                  onSelected: (selected) => transactionProvider.setFilter('income'),
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                TransactionFilterChip(
                  label: 'Expense', 
                  isSelected: transactionProvider.filter == 'expense', 
                  onSelected: (selected) => transactionProvider.setFilter('expense'),
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.error,
                ),
              ],
            ),
          ),
          
          // Recent Transactions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTransactions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _transactions.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: transactionProvider.filter == 'all'
                                ? 'No Transactions'
                                : 'No ${transactionProvider.filter.capitalize()} Transactions',
                            message: transactionProvider.filter == 'all'
                                ? 'Start adding your expenses and income to see them here.'
                                : 'No ${transactionProvider.filter} transactions found. Add a new ${transactionProvider.filter} transaction to get started!',
                            action: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransactionScreen(
                                      initialType: transactionProvider.filter == 'all'
                                          ? null
                                          : transactionProvider.filter,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Add ${transactionProvider.filter == 'all' ? 'Transaction' : transactionProvider.filter.capitalize()}',
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              return TransactionItem(transaction: _transactions[index]);
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
