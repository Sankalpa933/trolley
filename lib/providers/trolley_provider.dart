import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrolleyProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5000/api';

  List<dynamic> _items = [];
  String _selectedSupermarket = 'GENERAL';
  bool _isLoading = false;

  List<dynamic> get items => _items;
  String get selectedSupermarket => _selectedSupermarket;
  bool get isLoading => _isLoading;

  // 1. Helper to compile authorized headers automatically
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 2. Fetch the current unarchived trolley status from MongoDB
  Future<void> fetchActiveTrolley() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      // We send a request to the add-item route with empty text to fetch or initialize the list
      final res = await http.post(
        Uri.parse('$_baseUrl/shopping-list/add-item'),
        headers: headers,
        body: jsonEncode({'originalText': 'FETCH_INITIAL_LOAD'}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['list'] != null) {
          _selectedSupermarket =
              data['list']['selectedSupermarket'] ?? 'GENERAL';
          // Filter out our internal initial bootup loader flags
          _items = (data['list']['items'] as List? ?? [])
              .where((item) => item['originalText'] != 'FETCH_INITIAL_LOAD')
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching active trolley: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Post a new raw grocery string to the Gemini classification endpoint
  Future<void> addGroceryItem(String text, String quantity) async {
    if (text.trim().isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/shopping-list/add-item'),
        headers: headers,
        body: jsonEncode({
          'originalText': text,
          'quantity': quantity,
          'selectedSupermarket': _selectedSupermarket,
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _items = (data['list']['items'] as List? ?? [])
            .where((item) => item['originalText'] != 'FETCH_INITIAL_LOAD')
            .toList();
      }
    } catch (e) {
      debugPrint("❌ Error adding item to trolley: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Update the active supermarket context alignment rules
  void updateSupermarket(String? newStore) {
    if (newStore == null) return;
    _selectedSupermarket = newStore;
    notifyListeners();
  }
}
