// Stub: Replace with real Claude / Gemini API calls
class AiService {
  final List<Map<String, String>> _history = [];

  List<Map<String, String>> get history => List.unmodifiable(_history);

  Future<String> sendMessage(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});

    // TODO: call Claude/Gemini API with society context + history
    await Future.delayed(const Duration(milliseconds: 700));

    const reply =
        'Is baare mein aur jaankari ke liye admin se contact karein ya Rules section check karein. Koi aur sawaal ho toh poochein!';
    _history.add({'role': 'assistant', 'content': reply});
    return reply;
  }

  void clearHistory() => _history.clear();
}
