import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/brand_logo.dart';

class AdminHomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminHomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 16,
          24,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1F2937),
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -1.5,
              ),
            ).animate().fade(duration: 600.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fade(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}
