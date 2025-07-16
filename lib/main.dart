import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/shared/theme/app_theme.dart';
import 'package:expense_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:expense_tracker/features/core/presentation/screens/main_screen.dart';
import 'package:expense_tracker/features/splash/presentation/screens/splash_screen.dart';
import 'package:expense_tracker/shared/services/firebase_service.dart';
import 'package:expense_tracker/features/transactions/data/providers/transaction_provider.dart';
import 'package:expense_tracker/shared/providers/theme_provider.dart';

// Initialize Google Fonts
void _initializeGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeGoogleFonts();
  
  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        authDomain: "YOUR_AUTH_DOMAIN",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        appId: "YOUR_APP_ID",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        StreamProvider<User?>(
          initialData: null,
          create: (context) => FirebaseAuth.instance.authStateChanges(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          lazy: false, // Initialize immediately
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Show loading indicator until theme is initialized
          if (!themeProvider.isInitialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            );
          }

          // Create theme data
          final lightTheme = ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              secondary: AppTheme.secondaryColor,
              surface: Colors.white,
              background: Colors.grey.shade50,
              error: AppTheme.error,
            ),
            textTheme: GoogleFonts.oswaldTextTheme(
              ThemeData.light().textTheme,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          );

          final darkTheme = ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              secondary: AppTheme.secondaryColor,
              surface: Colors.grey.shade900,
              background: Colors.grey.shade900,
              error: AppTheme.error,
            ),
            textTheme: GoogleFonts.oswaldTextTheme(
              ThemeData.dark().textTheme,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
            ),
          );

          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add any initialization logic here
      await Future.delayed(const Duration(seconds: 1)); // Minimum splash time
    } catch (e) {
      debugPrint('Error initializing app: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSplashComplete() {
    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showSplash) {
      return SplashScreen(onComplete: _handleSplashComplete);
    }

    final user = context.watch<User?>();
    final transactionProvider = context.read<TransactionProvider>();
    
    // Initialize transaction provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionProvider.initialize(user?.uid);
    });

    // Return the appropriate screen based on auth state
    return user != null ? const MainScreen() : const LoginScreen();
  }
}
