import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/notice.dart';
import 'package:sero/services/firestore_service.dart';

final noticesStreamProvider = StreamProvider<List<Notice>>((ref) {
  return FirestoreService().getNoticesStream();
});

final noticesProvider = StateNotifierProvider<NoticesNotifier, AsyncValue<List<Notice>>>((ref) {
  return NoticesNotifier();
});

class NoticesNotifier extends StateNotifier<AsyncValue<List<Notice>>> {
  NoticesNotifier() : super(const AsyncValue.loading()) {
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.get('/notices');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notices'] as List).map((x) => Notice.fromMap(x)).toList();
        state = AsyncValue.data(list);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch notices';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNotice(String title, String body, String type) async {
    try {
      final res = await ApiService.post('/notices', {
        'title': title,
        'body': body,
        'type': type,
      });
      if (res.statusCode == 201) {
        fetchNotices();
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to post notice';
      }
    } catch (e) {
      rethrow;
    }
  }
}



