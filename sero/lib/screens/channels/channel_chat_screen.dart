import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/channels_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ChannelChatScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelChatScreen({super.key, required this.channelId, required this.channelName});

  @override
  ConsumerState<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends ConsumerState<ChannelChatScreen> {
  final _msgCtrl = TextEditingController();

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    final user = ref.read(authProvider).value;
    
    try {
      await ApiService.post('/channels/${widget.channelId}/messages', {
        'text': text,
        'senderName': user?.name,
        'senderFlat': user?.flatNumber,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(channelMessagesProvider(widget.channelId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.channelName)),
      body: Column(
        children: [
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) return const Center(child: Text('No messages yet.'));
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ListTile(
                      title: Text('${msg.senderName} (${msg.senderFlat})'),
                      subtitle: Text(msg.text),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
