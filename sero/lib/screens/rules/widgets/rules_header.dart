import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../../../widgets/brand_logo.dart';

class BrandingHeaderWidget extends StatelessWidget {
  const BrandingHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SocietyLogo(size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'The Sero',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroHeaderWidget extends StatelessWidget {
  final VoidCallback onRefresh;
  const HeroHeaderWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GOVERNANCE CONSOLE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 14, color: kPrimaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rules & Bylaws',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI extracted regulations from society documents. Protocols are updated in real-time as bylaws are synced.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 50.ms).slideY(begin: 0.05);
  }
}

class GovernanceSearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  const GovernanceSearchBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: false,
                onChanged: (v) => (context as Element).markNeedsBuild(), // Force list filter on type
                decoration: InputDecoration(
                  hintText: 'Lookup clauses or protocols...',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.01, curve: Curves.easeOutQuad);
  }
}
