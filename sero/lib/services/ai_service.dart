import 'dart:convert';
import 'api_service.dart';

class AiService {
  final List<Map<String, String>> _history = [];

  List<Map<String, String>> get history => List.unmodifiable(_history);

  Future<Map<String, dynamic>> sendMessage(String userMessage, {String? base64Image, Map<String, dynamic>? context}) async {
    _history.add({'role': 'user', 'content': userMessage});

    try {
      final res = await ApiService.post('/ai/chat', {
        'message': userMessage,
        'base64Image': base64Image,
        'context': context,
        'history': _history.sublist(0, _history.length - 1),
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = data['reply'] ?? (data['type'] == 'draft' ? 'Draft generated' : 'No reply from server');
        _history.add({
          'role': 'assistant', 
          'content': reply,
          'type': data['type'] ?? 'text',
          ...data,
        });
        return data;
      } else {
        final error = 'Server Error: ${res.body}';
        final errorMap = {'type': 'text', 'reply': error};
        _history.add({'role': 'assistant', 'content': error});
        return errorMap;
      }
    } catch (e) {
      final error = 'Connection Error: $e';
      final errorMap = {'type': 'text', 'reply': error};
      _history.add({'role': 'assistant', 'content': error});
      return errorMap;
    }
  }


  Future<Map<String, dynamic>> executeAction(String actionId) async {
    try {
      final res = await ApiService.post('/ai/execute-tool', {
        'actionId': actionId,
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Action failed: ${res.body}');
      }
    } catch (e) {
      throw Exception('Execution Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getDigest() async {
    try {
      final res = await ApiService.get('/ai/digest');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  void clearHistory() => _history.clear();
}
