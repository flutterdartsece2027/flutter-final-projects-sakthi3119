import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  bool _isInitialized = false;
  bool _isToggling = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  bool get isToggling => _isToggling;

  ThemeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isInitialized = true;
      if (!_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      _isInitialized = true;
      if (!_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      }
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> toggleTheme(bool isOn) async {
    if (_isDarkMode == isOn || _isToggling) return;
    
    _isToggling = true;
    _isDarkMode = isOn;
    if (!_isDisposed) notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      _isDarkMode = !isOn;
      if (!_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) notifyListeners();
        });
      }
      rethrow;
    } finally {
      _isToggling = false;
    }
  }
}
