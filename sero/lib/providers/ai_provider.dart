import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AiMessage {
  final String role;
  final String content;

  AiMessage({required this.role, required this.content});
}

final aiProvider = StateNotifierProvider<AiNotifier, List<AiMessage>>((ref) {
  return AiNotifier();
});

class AiNotifier extends StateNotifier<List<AiMessage>> {
  AiNotifier() : super([]);

  Future<void> sendMessage(String text) async {
    state = [...state, AiMessage(role: 'user', content: text)];
    try {
      final res = await ApiService.post('/ai/chat', {
        'message': text,
        'history': state.where((m) => m.role != 'error').map((m) => {'role': m.role, 'content': m.content}).toList(),
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        state = [...state, AiMessage(role: 'ai', content: data['reply'])];
      } else {
        state = [...state, AiMessage(role: 'error', content: 'Connection Error')];
      }
    } catch (e) {
      state = [...state, AiMessage(role: 'error', content: 'Error: $e')];
    }
  }
}
