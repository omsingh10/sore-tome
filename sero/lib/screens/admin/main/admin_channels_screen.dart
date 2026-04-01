import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/channels_provider.dart';
import '../../../../services/api_service.dart';
import '../../channels/create_channel_screen.dart';

class AdminChannelsScreen extends ConsumerWidget {
  const AdminChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Chat Channels')),
      body: channelsAsync.when(
        data: (channels) {
          if (channels.isEmpty) return const Center(child: Text('No channels.'));
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final c = channels[index];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Delete ${c.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ApiService.delete('/channels/${c.id}');
                      ref.invalidate(channelsListProvider);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChannelScreen())).then((_) {
            ref.invalidate(channelsListProvider);
          });
        },
      ),
    );
  }
}
