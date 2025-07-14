class AppConstants {
  // App
  static const String appName = 'Expense Tracker';
  
  // Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  
  // Shared Preferences Keys
  static const String isFirstLaunch = 'is_first_launch';
  static const String isLoggedIn = 'is_logged_in';
  static const String userId = 'user_id';
  
  // SMS Patterns
  static const List<String> creditPatterns = [
    r'credited',
    r'credit',
    r'received',
    r'deposited',
    r'added',
  ];
  
  static const List<String> debitPatterns = [
    r'debited',
    r'debit',
    r'spent',
    r'paid',
    r'withdrawn',
  ];
  
  // Currency
  static const String defaultCurrency = '₹';
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  
  // Transaction Types
  static const String income = 'income';
  static const String expense = 'expense';
  
  // Categories
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food & Drinks', 'icon': '🍔'},
    {'name': 'Shopping', 'icon': '🛍️'},
    {'name': 'Transport', 'icon': '🚕'},
    {'name': 'Bills', 'icon': '💸'},
    {'name': 'Entertainment', 'icon': '🎬'},
    {'name': 'Health', 'icon': '🏥'},
    {'name': 'Education', 'icon': '📚'},
    {'name': 'Travel', 'icon': '✈️'},
    {'name': 'Gifts', 'icon': '🎁'},
    {'name': 'Others', 'icon': '📌'},
  ];
  
  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': '💼'},
    {'name': 'Business', 'icon': '💼'},
    {'name': 'Gifts', 'icon': '🎁'},
    {'name': 'Investments', 'icon': '📈'},
    {'name': 'Others', 'icon': '📌'},
  ];
}
