import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/users_provider.dart';
import '../../../widgets/brand_logo.dart';
import 'admin_users_screen.dart';
import 'admin_maintenance_screen.dart';
import '../post_notice_screen.dart';

class AdminMainHome extends ConsumerWidget {
  const AdminMainHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // --- CLEAN PREMIUM HEADER ---
          SliverToBoxAdapter(
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
                    "Admin\nDashboard",
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
                    "Estate status for Friday, Oct 24th.",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fade(delay: 200.ms),
                ],
              ),
            ),
          ),

          // --- HERO METRIC CARD (Live Activity Style) ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child:
                  Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "LIVE ACTIVITY",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "42",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1F2937),
                                    fontSize: 84,
                                    fontWeight: FontWeight.w800,
                                    height: 0.9,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      "Residents\nOn-Site",
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminUsersScreen(),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.remove_red_eye,
                                      size: 18,
                                    ),
                                    label: const Text("Manage Access"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF345D7E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: const Text("Access Logs"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      foregroundColor: const Color(0xFF1E40AF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(delay: 300.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
            ),
          ),

          // --- PENDING APPROVALS SECTION (Pending Requests Style) ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${pendingAsync.whenOrNull(data: (users) => users.length.toString().padLeft(2, '0')) ?? '00'}",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF991B1B),
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "PENDING APPROVALS",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF991B1B).withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PendingItemTile(
                      name: "Elevator B-4",
                      priority: "High",
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    _PendingItemTile(
                      name: "Pool Filtration",
                      priority: "Med",
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
            ),
          ),

          // --- RECENT UPDATES SECTION (Community Broadcasts Style) ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Updates",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1F2937),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PostNoticeScreen(),
                            ),
                          ),
                          child: Text(
                            "New Post",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF345D7E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const RecentUpdateTile(
                      category: "ESTATE EVENT",
                      title: "Annual Garden Gala Invitation",
                      subtitle:
                          "Residents are invited to join the management for a sunset dinner...",
                      time: "2 hours ago",
                      badgeColor: Color(0xFFDBEAFE),
                      textColor: Color(0xFF1E40AF),
                    ),
                    const Divider(height: 32, color: Color(0xFFF1F5F9)),
                    const RecentUpdateTile(
                      category: "MAINTENANCE",
                      title: "Emergency Water Pipe Repairs",
                      subtitle:
                          "Scheduled maintenance for Tower A water lines will commence...",
                      time: "Yesterday",
                      badgeColor: Color(0xFFE0E7FF),
                      textColor: Color(0xFF4338CA),
                    ),
                  ],
                ),
              ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
            ),
          ),

          // --- FINANCIAL OVERVIEW (Sinking Fund Style) ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            sliver: SliverToBoxAdapter(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminMaintenanceScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF345D7E),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "COLLECTION TOTAL",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\Rs142,850",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TARGET: \$200K",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "75% COLLECTED",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingItemTile extends StatelessWidget {
  final String name;
  final String priority;
  final Color color;

  const _PendingItemTile({
    required this.name,
    required this.priority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              priority,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentUpdateTile extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final String time;
  final Color badgeColor;
  final Color textColor;

  const RecentUpdateTile({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
