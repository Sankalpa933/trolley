import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Fixed: Added this missing import
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _userName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  bool get isAuthenticated => _userName != null;

  // Check login state on startup
  Future<void> checkInitialAuth() async {
    final token = await _apiService.getToken();
    if (token != null) {
      // Fixed: Removed the broken 'sh.' prefix reference completely
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name');
      notifyListeners();
    }
  }

  // Trigger login workflow from UI
  Future<bool> executeLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      _isLoading = false;

      if (result['token'] != null) {
        _userName = result['user']['name'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Authentication failed.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not establish connection to server.';
      notifyListeners();
      return false;
    }
  }

  Future<void> executeLogout() async {
    await _apiService.logout();
    _userName = null;
    notifyListeners();
  }
}
