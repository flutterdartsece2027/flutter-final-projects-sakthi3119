import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'dart:async';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  factory SmsService() => _instance;
  
  SmsService._internal();
  
  // Check and request SMS permission
  Future<bool> _checkSmsPermission() async {
    final status = await Permission.sms.status;
    if (status.isDenied) {
      final result = await Permission.sms.request();
      return result.isGranted;
    }
    return status.isGranted;
  }
  
  // Start listening to incoming SMS
  Future<void> startListening() async {
    try {
      final hasPermission = await _checkSmsPermission();
      if (!hasPermission) return;
      
      // Listen for incoming SMS
      await SmsAutoFill().listenForCode();
      
    } catch (e) {
      print('Error initializing SMS listener: $e');
    }
  }
  
  // Stop listening to SMS
  Future<void> stopListening() async {
    await SmsAutoFill().unregisterListener();
  }
  
  // Process the received SMS and extract transaction details
  Future<void> _processSms(String message) async {
    try {
      // Example SMS format: "INR 1,000.00 debited from A/c XX1234 on 01-Jan-23"
      final regex = RegExp(r'(?<type>credited|debited).*?INR\s*([\d,]+(?:\.\d{2})?)');
      final match = regex.firstMatch(message.toLowerCase());
      
      if (match != null) {
        final type = match.namedGroup('type') == 'credited' ? 'income' : 'expense';
        final amount = double.parse(match.group(1)!.replaceAll(',', ''));
        
        // Add transaction to Firestore
        final user = _auth.currentUser;
        if (user != null) {
          // Add transaction
          await _firestore.collection('transactions').add({
            'userId': user.uid,
            'amount': amount,
            'type': type,
            'category': 'SMS Transaction',
            'description': 'Auto-detected from SMS',
            'date': DateTime.now(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Update user's balance
          final userRef = _firestore.collection('users').doc(user.uid);
          await _firestore.runTransaction((transaction) async {
            final userDoc = await transaction.get(userRef);
            if (userDoc.exists) {
              double currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
              double newBalance = type == 'income'
                  ? currentBalance + amount
                  : currentBalance - amount;
              transaction.update(userRef, {'balance': newBalance});
            }
          });
          print('Transaction added from SMS');
        }
      }
    } catch (e) {
      print('Error processing SMS: $e');
    }
  }
  
  // Extract transaction details from SMS
  Map<String, dynamic>? _extractTransactionDetails(String message) {
    try {
      // Check for credit transaction
      for (var pattern in AppConstants.creditPatterns) {
        if (message.toLowerCase().contains(pattern)) {
          final amount = _extractAmount(message);
          if (amount != null) {
            return {
              'amount': amount,
              'type': AppConstants.income,
              'category': 'Bank Transfer',
              'date': DateTime.now(),
            };
          }
        }
      }
      
      // Check for debit transaction
      for (var pattern in AppConstants.debitPatterns) {
        if (message.toLowerCase().contains(pattern)) {
          final amount = _extractAmount(message);
          if (amount != null) {
            return {
              'amount': amount,
              'type': AppConstants.expense,
              'category': 'Bank Transaction',
              'date': DateTime.now(),
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting transaction details: $e');
      return null;
    }
  }
  
  // Extract amount from SMS
  double? _extractAmount(String message) {
    try {
      // Match amounts like Rs. 1,000.00 or INR 1000 or ₹1,000.00
      final amountRegex = RegExp(
        r'(?:Rs\.?|INR|\u20B9|₹?)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      );
      
      final match = amountRegex.firstMatch(message);
      if (match != null && match.groupCount >= 1) {
        String amountStr = match.group(1)!.replaceAll(',', '');
        return double.tryParse(amountStr);
      }
      
      // Try to match numbers that might be amounts
      final numberRegex = RegExp(r'\b(\d+(?:\.\d{1,2})?)\b');
      final matches = numberRegex.allMatches(message);
      
      // Look for numbers that look like amounts (e.g., 1000.00, 1,000.00)
      for (var match in matches) {
        final number = match.group(0);
        if (number != null) {
          // Check if the number is likely an amount (e.g., not a year, phone number, etc.)
          if (double.tryParse(number.replaceAll(',', '')) != null) {
            return double.parse(number.replaceAll(',', ''));
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting amount: $e');
      return null;
    }
  }
}
