import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/channels_provider.dart';
import '../../channels/create_channel_screen.dart';

// Modularized Widgets
import 'widgets/admin_channels_widgets.dart';

class AdminChannelsScreen extends ConsumerWidget {
  const AdminChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          BrandingHeader(
            onNotificationsTap: () {},
          ),

          const ChannelSectionHeader(
            title: "COMMUNICATION HUB",
            subtitle: "Active Channels",
          ),

          channelsAsync.when(
            data: (channels) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final c = channels[index];
                  return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ChannelPremiumCard(channel: c),
                      )
                      .animate()
                      .fade(delay: (200 + index * 50).ms)
                      .slideX(begin: 0.05);
                }, childCount: channels.length),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: const NetworkVitalityCard()
                  .animate()
                  .fade(delay: 500.ms)
                  .slideY(begin: 0.1),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: ModeratorsCard(),
            ),
          ).animate().fade(delay: 600.ms).slideY(begin: 0.1),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: NewChannelCTA(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateChannelScreen(),
                    ),
                  ).then((_) {
                    ref.invalidate(channelsListProvider);
                  });
                },
              ),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.1),
          ),
        ],
      ),
    );
  }
}
