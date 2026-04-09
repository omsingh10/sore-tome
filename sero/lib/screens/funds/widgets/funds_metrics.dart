import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';

class FinancialCard extends StatelessWidget {
  final String title;
  final String amount;
  final String trend;
  final IconData icon;
  final bool isPositive;
  final bool isNeutral;
  final bool isHero;

  const FinancialCard({
    super.key,
    required this.title,
    required this.amount,
    required this.trend,
    required this.icon,
    this.isPositive = false,
    this.isNeutral = false,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHero ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHero ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
          width: 1
        ),
        boxShadow: [
          if (isHero)
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isHero ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                amount,
                style: GoogleFonts.outfit(
                  fontSize: isHero ? 36 : 28,
                  fontWeight: FontWeight.w800,
                  color: isHero ? Colors.white : const Color(0xFF1E3A8A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 14),
              isHero 
                ? Text(
                    trend,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryGreen,
                    ),
                  )
                : isPositive
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, color: Color(0xFF059669), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            trend,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      trend,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHero ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isHero ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                icon, 
                color: isHero ? Colors.white : const Color(0xFFCBD5E1), 
                size: isHero ? 36 : 28
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpendingBreakdownCard extends StatelessWidget {
  final Map<String, double> breakdown;
  final double totalSpent;

  const SpendingBreakdownCard({
    super.key, 
    required this.breakdown, 
    required this.totalSpent
  });

  @override
  Widget build(BuildContext context) {
    // Sort categories by amount descending
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Top 4 categories
    final topItems = sorted.take(4).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Live Data',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Capital Allocation',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFFCBD5E1), size: 24),
            ],
          ),
          const SizedBox(height: 32),
          if (topItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No expenditure data tracked yet.',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ...topItems.map((item) {
              final pct = totalSpent > 0 ? item.value / totalSpent : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.key.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '₹${item.value.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.key == sorted.first.key ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.1);
  }
}
