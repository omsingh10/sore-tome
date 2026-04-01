import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/issue.dart';

final issuesProvider = StateNotifierProvider<IssuesNotifier, AsyncValue<List<Issue>>>((ref) {
  return IssuesNotifier();
});

class IssuesNotifier extends StateNotifier<AsyncValue<List<Issue>>> {
  IssuesNotifier() : super(const AsyncValue.loading()) {
    fetchIssues();
  }

  Future<void> fetchIssues() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.get('/issues');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['issues'] as List).map((x) => Issue.fromMap(x)).toList();
        state = AsyncValue.data(list);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch issues';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addIssue(String title, String description, String category) async {
    try {
      final res = await ApiService.post('/issues', {
        'title': title,
        'description': description,
        'category': category,
      });
      if (res.statusCode == 201) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to report issue';
      }
    } catch (e) {
      rethrow;
    }
  }
}
