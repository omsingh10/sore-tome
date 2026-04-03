import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/brand_logo.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  final _service = FirestoreService();
  List<Issue> _all = [];
  bool _loading = true;
  int _selectedFilter = 0; // 0=All, 1=Open, 2=Resolved

  final _filters = ['All', 'Open', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final issues = await _service.getIssues();
    if (!mounted) return;
    setState(() {
      _all = issues;
      _loading = false;
    });
  }

  List<Issue> get _open => _all.where((i) => i.status == 'open').toList();
  List<Issue> get _inProgress =>
      _all.where((i) => i.status == 'in_progress').toList();
  List<Issue> get _resolved =>
      _all.where((i) => i.status == 'resolved').toList();

  List<Issue> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _open;
      case 2:
        return _resolved;
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: kPrimaryGreen,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── TOP BAR ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
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
              ).animate().fade(duration: 300.ms),
            ),

            // ── HEADING ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATIONAL OVERVIEW',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Resident Issues',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── ACTION BUTTONS ────────────────────────────────────
                    Row(
                      children: [
                        _ActionButton(
                          label: 'My History',
                          icon: Icons.history_rounded,
                          outlined: true,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          label: '+ New Ticket',
                          icon: null,
                          outlined: false,
                          onTap: () =>
                              Navigator.pushNamed(context, '/post-issue'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 80.ms).slideY(begin: 0.06),
            ),

            // ── STATS ROW ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _loading
                    ? const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: kPrimaryGreen, strokeWidth: 2),
                        ),
                      )
                    : Column(
                        children: [
                          _StatRow(
                            label: 'UNASSIGNED',
                            value: _open.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFFEF4444),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _StatRow(
                            label: 'IN PROGRESS',
                            value:
                                _inProgress.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFF3B82F6),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _StatRow(
                            label: 'RESOLVED (TODAY)',
                            value: _resolved.length.toString().padLeft(2, '0'),
                            underlineColor: kAccentGreen,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _StatRow(
                            label: 'TOTAL TICKETS',
                            value: _all.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFF8B5CF6),
                            subtitle: 'Across all statuses',
                          ),
                        ],
                      ),
              ).animate().fade(delay: 150.ms),
            ),

            // ── ACTIVE TICKETS HEADER ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE TICKETS',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Filter chips: All / Open / Resolved
                    Row(
                      children: List.generate(_filters.length, (i) {
                        final selected = _selectedFilter == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected
                                  ? kPrimaryGreen
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filters[i],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms),
            ),

            // ── TICKET LIST ────────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryGreen, strokeWidth: 2)),
                ),
              )
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: IssueCard(issue: _filtered[i])
                          .animate()
                          .fade(delay: (i * 40).ms, duration: 250.ms)
                          .slideY(begin: 0.05, end: 0),
                    ),
                    childCount: _filtered.length,
                  ),
                ),
              ),

            // ── ARCHIVED LINK ─────────────────────────────────────────────
            if (!_loading && _all.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All Archived Tickets',
                        style: GoogleFonts.outfit(
                          color: kPrimaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: kPrimaryGreen,
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(delay: 300.ms),
              ),

            // bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 34,
              color: kPrimaryGreen.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'All clear!',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'No issues in this category',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

// ─── Stat Row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color underlineColor;
  final String? subtitle;

  const _StatRow({
    required this.label,
    required this.value,
    required this.underlineColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: underlineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : kPrimaryGreen,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined
                ? const Color(0xFFE2E8F0)
                : kPrimaryGreen,
            width: 1.5,
          ),
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: kPrimaryGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: outlined
                    ? const Color(0xFF374151)
                    : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: outlined ? const Color(0xFF374151) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
