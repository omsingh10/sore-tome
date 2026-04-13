import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import '../../shared/channels/channel_chat_screen.dart';
import 'package:sero/widgets/shared/branding_header.dart';

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
            data: (channels) {
              if (channels.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        "No channels found. Create one below!",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = channels[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChannelChatScreen(channel: c),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: ChannelPremiumCard(channel: c),
                        ),
                      );
                    },
                    childCount: channels.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF345D7E))),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),

          // Removed SocietyOperationsHub as requested

          // ModeratorsCard removed - managed via WhatsApp-style settings list

          const SliverToBoxAdapter(
            child: SizedBox(height: 48),
          ),
        ],
      ),
    );
  }
}









