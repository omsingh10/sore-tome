import 'package:flutter/material.dart';
import '../services/rules_service.dart';

class RulesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _allRules = [];
  List<Map<String, dynamic>> _filteredRules = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<Map<String, dynamic>> get rules => _filteredRules;
  bool get isLoading => _isLoading;

  Future<void> fetchRules() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allRules = await RulesService.getRules();
      _applyFilter();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredRules = _allRules;
    } else {
      _filteredRules = _allRules.where((rule) {
        final text = (rule['rule'] ?? "").toString().toLowerCase();
        final source = (rule['source'] ?? "").toString().toLowerCase();
        return text.contains(_searchQuery.toLowerCase()) || 
               source.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  /// Groups rules by source or category (V5.2 Upgrade)
  Map<String, List<Map<String, dynamic>>> get groupedRules {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var rule in _filteredRules) {
      final source = rule['source'] ?? "General Rules";
      if (!groups.containsKey(source)) groups[source] = [];
      groups[source]!.add(rule);
    }
    return groups;
  }
}
