import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final bool showDateHeader;
  final bool isLastItem;
  
  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onTap,
    this.showDateHeader = false,
    this.isLastItem = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final icon = _getCategoryIcon(transaction.category);
    final category = _formatCategory(transaction.category);
    final amount = '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(transaction.amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeader) ..._buildDateHeader(context),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isIncome 
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isIncome ? AppTheme.success : AppTheme.error,
                    size: 24,
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
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          transaction.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showDateHeader) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(transaction.date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isIncome 
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isIncome ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
        if (!isLastItem && !showDateHeader)
          const Divider(height: 1, indent: 72, thickness: 1),
      ],
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
  
  List<Widget> _buildDateHeader(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
        child: Text(
          _formatDate(transaction.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
      const Divider(height: 1, thickness: 1),
    ];
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (dateToCheck.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}
