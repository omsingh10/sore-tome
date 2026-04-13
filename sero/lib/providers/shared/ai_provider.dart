import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:sero/services/api_service.dart';

final aiRulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService.get('/ai/rules');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['rules'] ?? []);
  }
  return [];
});

final aiStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get('/ai/stats');
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  throw Exception('Failed to load AI stats');
});

final financeAnalysisProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get('/ai/finance-analysis');
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  throw Exception('Failed to load financial analysis');
});

final aiJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // V3.12: Fetch active background indexing jobs
  final res = await ApiService.get('/ai/digest'); // Reuse digest which includes activeIndexing
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['activeIndexing'] ?? []);
  }
  return [];
});



