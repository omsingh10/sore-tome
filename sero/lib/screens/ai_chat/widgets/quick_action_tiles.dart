import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';

class QuickActionTiles extends StatelessWidget {
  const QuickActionTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildListDelegate([
          const ActionCard(
            icon: Icons.campaign_rounded,
            title: 'Communication',
            subtitle: 'Draft notices &\nannouncements',
          ),
          const ActionCard(
            icon: Icons.insert_chart_rounded,
            title: 'Data Digest',
            subtitle: 'Analyze resident\ntrends',
          ),
          const ActionCard(
            icon: Icons.gavel_rounded,
            title: 'Rule Auditor',
            subtitle: 'Bylaw compliance\nchecks',
          ),
          const ActionCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Financials',
            subtitle: 'Budget & levy\ntracking',
          ),
        ]),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryGreen, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              height: 1.3,
            ),
          ),
        ],
      ),
    ).animate().fade().scale(delay: 200.ms);
  }
}
