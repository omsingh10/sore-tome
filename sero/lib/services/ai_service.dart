import 'dart:convert';
import 'api_service.dart';

class AiService {
  final List<Map<String, String>> _history = [];

  List<Map<String, String>> get history => List.unmodifiable(_history);

  Future<String> sendMessage(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});

    try {
      final res = await ApiService.post('/ai/chat', {
        'message': userMessage,
        'history': _history.sublist(0, _history.length - 1),
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['reply'] ?? 'No reply from server';
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      } else {
        final error = 'Server Error: ${res.body}';
        _history.add({'role': 'assistant', 'content': error});
        return error;
      }
    } catch (e) {
      final error = 'Connection Error: $e';
      _history.add({'role': 'assistant', 'content': error});
      return error;
    }
  }

  void clearHistory() => _history.clear();
}
