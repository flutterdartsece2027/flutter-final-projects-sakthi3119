import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class TransactionSummary extends StatelessWidget {
  final String? userId;
  final VoidCallback? onViewAll;

  const TransactionSummary({
    Key? key,
    this.userId,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingSummary(context);
        }

        double income = 0.0;
        double expense = 0.0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0.0).toDouble();
          
          if (data['type'] == 'income') {
            income += amount;
          } else {
            expense += amount;
          }
        }

        final savings = income - expense;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    context,
                    title: 'Income',
                    amount: income,
                    color: AppTheme.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  _buildDivider(),
                  _buildSummaryItem(
                    context,
                    title: 'Expense',
                    amount: expense,
                    color: AppTheme.error,
                    icon: Icons.arrow_upward_rounded,
                  ),
                  _buildDivider(),
                  Column(
                    children: [
                      Text(
                        'Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(savings),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: savings >= 0 ? AppTheme.success : AppTheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Builder(
      builder: (context) => Container(
        width: 1,
        height: 40,
        color: Theme.of(context).dividerColor.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
