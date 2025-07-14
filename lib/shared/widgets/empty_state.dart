import 'package:flutter/material.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final double? iconSize;
  final double? titleSize;
  final double? messageSize;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconSize = 64,
    this.titleSize = 20,
    this.messageSize = 14,
    this.spacing = 16,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: messageSize,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: spacing),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  factory EmptyState.loading({String message = 'Loading...'}) {
    return EmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: 'Loading',
      message: message,
    );
  }

  factory EmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message ?? 'An error occurred. Please try again.',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  factory EmptyState.noInternet({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            )
          : null,
    );
  }
}
