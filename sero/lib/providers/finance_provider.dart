import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/api_client.dart';

class FinanceProvider with ChangeNotifier {
  Map<String, dynamic>? _analysisCache;
  DateTime? _lastFetchTime;
  bool _isLoading = false;
  String _errorMessage = "";

  static const int _cacheTtlMinutes = 10; // ❗ V5.2 Requirement: Avoid AI spam

  Map<String, dynamic>? get analysis => _analysisCache;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchFinanceAnalysis({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid()) return;

    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      final res = await ApiClient.request('GET', '/ai/finance-analysis');
      if (res.statusCode == 200) {
        _analysisCache = jsonDecode(res.body);
        _lastFetchTime = DateTime.now();
      } else {
        _errorMessage = "Failed to load insights";
      }
    } catch (e) {
      _errorMessage = "Connection error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isCacheValid() {
    if (_analysisCache == null || _lastFetchTime == null) return false;
    final diff = DateTime.now().difference(_lastFetchTime!);
    return diff.inMinutes < _cacheTtlMinutes;
  }
}
