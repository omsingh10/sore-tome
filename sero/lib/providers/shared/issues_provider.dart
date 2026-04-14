import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';

final issuesStreamProvider = StreamProvider<List<Issue>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return const Stream.empty();
  return FirestoreService().getIssuesStream(user.name); 
});

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

  Future<void> refresh() => fetchIssues();

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

  Future<void> resolveIssue(String id) async {
    try {
      final res = await ApiService.patch('/issues/$id', {'status': 'resolved'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to resolve issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignIssue(String id, String assignee) async {
    try {
      final res = await ApiService.patch('/issues/$id', {'assignedTo': assignee, 'status': 'in_progress'});
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to assign issue';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteIssue(String id) async {
    try {
      final res = await ApiService.delete('/issues/$id');
      if (res.statusCode == 200) {
        fetchIssues();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to delete issue';
      }
    } catch (e) {
      rethrow;
    }
  }
}



