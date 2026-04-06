import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/brand_logo.dart';

class BrandingHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const BrandingHeader({
    super.key,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 16,
          24,
          0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF064E3B),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SocietyLogo(size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "The Sero",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF64748B),
              ),
              onPressed: onNotificationsTap,
            ),
          ],
        ),
      ).animate().fade(),
    );
  }
}

class ChannelSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ChannelSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1F2937),
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
    );
  }
}
