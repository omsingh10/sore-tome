import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelPremiumCard extends StatelessWidget {
  final dynamic channel;

  const ChannelPremiumCard({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.chat_bubble_outline_rounded;
    Color color = const Color(0xFF3B82F6);
    if (channel.name.toLowerCase().contains("announcement")) {
      icon = Icons.hub_rounded;
      color = const Color(0xFF345D7E);
    } else if (channel.name.toLowerCase().contains("security")) {
      icon = Icons.shield_outlined;
      color = const Color(0xFFEF4444);
    } else if (channel.name.toLowerCase().contains("maintenance")) {
      icon = Icons.handyman_outlined;
      color = const Color(0xFF8B5CF6);
    } else if (channel.name.toLowerCase().contains("social")) {
      icon = Icons.campaign_rounded;
      color = const Color(0xFF0EA5E9);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      channel.description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF345D7E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "12",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _LastMessageRow(),
        ],
      ),
    );
  }
}

class _LastMessageRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?u=sarah',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(
                "Sarah Jenkins: ",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Expanded(
                child: Text(
                  "\"Has the weekend gala schedule...\"",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          "2M AGO",
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class NetworkVitalityCard extends StatelessWidget {
  const NetworkVitalityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: NetworkImage(
            'https://www.transparenttextures.com/patterns/dark-matter.png',
          ),
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NETWORK VITALITY",
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NetworkBar(height: 40, active: false),
              _NetworkBar(height: 60, active: false),
              _NetworkBar(height: 80, active: true),
              _NetworkBar(height: 100, active: true),
              _NetworkBar(height: 60, active: false),
              _NetworkBar(height: 35, active: false),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "High Activity",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Peak engagement between 6 PM - 9 PM daily.",
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkBar extends StatelessWidget {
  final double height;
  final bool active;

  const _NetworkBar({
    required this.height,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: height,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF60A5FA) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class ModeratorsCard extends StatelessWidget {
  const ModeratorsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MODERATORS ONLINE",
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const _ModeratorItem(name: "Robert Fox", roles: "General, Security"),
          const SizedBox(height: 12),
          const _ModeratorItem(
            name: "Jane Cooper",
            roles: "Social, Maintenance",
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Manage Permissions",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeratorItem extends StatelessWidget {
  final String name;
  final String roles;

  const _ModeratorItem({
    required this.name,
    required this.roles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=$name',
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              roles,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NewChannelCTA extends StatelessWidget {
  final VoidCallback onTap;

  const NewChannelCTA({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFBFDBFE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 24),
          Text(
            "New Channel",
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E3A8A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a dedicated space for specific\ncommittee or resident groups.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E40AF).withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                "Launch Channel",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
