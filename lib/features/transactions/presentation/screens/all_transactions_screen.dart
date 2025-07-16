import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/shared/widgets/transaction_item.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:expense_tracker/features/transactions/data/providers/transaction_provider.dart';
import 'package:expense_tracker/features/transactions/presentation/screens/add_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({Key? key}) : super(key: key);

  @override
  _AllTransactionsScreenState createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _error;
  List<TransactionEntity> _transactions = [];

  @override
  void initState() {
    super.initState();
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
      final user = Provider.of<TransactionProvider>(context, listen: false);
      final transactions = user.filteredTransactions;
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions. Please try again.';
          _isLoading = false;
        });
      }
      debugPrint('Error loading transactions: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TransactionFilterChip(
                    label: 'All',
                    isSelected: transactionProvider.filter == 'all',
                    onSelected: (selected) {
                      transactionProvider.setFilter('all');
                      _loadTransactions();
                    },
                  ),
                  const SizedBox(width: 8),
                  TransactionFilterChip(
                    label: 'Income',
                    isSelected: transactionProvider.filter == 'income',
                    onSelected: (selected) {
                      transactionProvider.setFilter('income');
                      _loadTransactions();
                    },
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  TransactionFilterChip(
                    label: 'Expense',
                    isSelected: transactionProvider.filter == 'expense',
                    onSelected: (selected) {
                      transactionProvider.setFilter('expense');
                      _loadTransactions();
                    },
                    icon: Icons.arrow_upward_rounded,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          // Transactions List
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Theme.of(context).hintColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add a new transaction to get started!',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              final showDateHeader = index == 0 ||
                                  !DateUtils.isSameDay(
                                    transaction.date,
                                    _transactions[index - 1].date,
                                  );
                              
                              return TransactionItem(
                                key: ValueKey(transaction.id),
                                transaction: transaction,
                                showDateHeader: showDateHeader,
                                isLastItem: index == _transactions.length - 1,
                                onTap: () {
                                  // TODO: Handle transaction tap (e.g., edit)
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
