import 'package:flutter/material.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';

class TransactionFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final IconData? icon;
  final Color? color;
  final Color? selectedColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const TransactionFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.color,
    this.selectedColor,
    this.textColor,
    this.selectedTextColor,
    this.elevation,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? selectedTextColor ?? Colors.white
                  : textColor ?? AppTheme.textPrimary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? selectedTextColor ?? Colors.white
                  : textColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: color ?? Colors.grey[200],
      selectedColor: selectedColor ?? AppTheme.primaryColor,
      checkmarkColor: selectedTextColor ?? Colors.white,
      elevation: elevation ?? 0,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        side: isSelected
            ? BorderSide.none
            : BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
      ),
    );
  }
}
