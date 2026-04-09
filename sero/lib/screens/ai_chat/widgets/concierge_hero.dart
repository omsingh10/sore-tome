import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConciergeHero extends StatelessWidget {
  const ConciergeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Text(
              'SERO AI',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your premium architectural assistant for seamless\nestate administration and resident harmony.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ).animate().fade().slideY(begin: 0.1),
    );
  }
}
