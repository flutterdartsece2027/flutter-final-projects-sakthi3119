import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';

class TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final bool showDate;
  
  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final icon = _getCategoryIcon(transaction.category);
    final category = _formatCategory(transaction.category);
    final amount = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(transaction.amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIncome 
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showDate) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(transaction.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Amount
              Text(
                '${isIncome ? '+' : '-'} $amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isIncome ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drinks':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight_takeoff;
      case 'gifts':
        return Icons.card_giftcard;
      case 'salary':
        return Icons.work;
      case 'business':
        return Icons.business_center;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
  
  String _formatCategory(String category) {
    return category.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
