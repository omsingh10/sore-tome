import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/notice.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/issue_card.dart';
import '../../services/ai_service.dart';
import '../ai_chat/ai_chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _service = FirestoreService();
  final _aiService = AiService();
  List<Notice> _notices = [];
  List<Issue> _myIssues = [];
  Map<String, dynamic>? _aiDigest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getNotices(),
      _service.getIssues(),
      _aiService.getDigest(),
    ]);

    if (!mounted) return;
    setState(() {
      _notices = results[0] as List<Notice>;
      _myIssues = (results[1] as List<Issue>).where((i) => i.postedBy == 'Rahul').toList();
      _aiDigest = results[2] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      children: [
                        _sectionLabel('Overview'),
                        const SizedBox(height: 6),
                        _statsRow(),
                        const SizedBox(height: 12),
                        if (_aiDigest != null) ...[
                          _buildAIDigest(),
                          const SizedBox(height: 12),
                        ],
                        _sectionLabel('Latest notices'),
                        const SizedBox(height: 6),
                        ..._notices.map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NoticeCard(notice: n),
                            )),
                        _sectionLabel('My recent issues'),
                        const SizedBox(height: 6),
                        ..._myIssues.map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: IssueCard(issue: i),
                            )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final user = ref.watch(authProvider).value;

    return Container(
      decoration: const BoxDecoration(
        gradient: kPremiumGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, ${user?.name ?? ""}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.7), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Flat ${user?.flatNumber ?? ""}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          )
        ],
      ),
    );
  }

  Widget _statsRow() {
    final openCount = _myIssues.where((i) => i.status == 'open').length;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$openCount', 
            label: 'Open issues',
            icon: Icons.error_outline,
            color: kAccentGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${_notices.length}', 
            label: 'New notices',
            icon: Icons.notifications_none,
            color: kAccentBlue,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAIDigest() {
    final summary = _aiDigest?['summary'] ?? "Ready to analyze your society.";
    final insights = _aiDigest?['insights'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: kPrimaryGreen),
                const SizedBox(width: 8),
                Text(
                  'SERO AI DIGEST',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryGreen,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: kPrimaryGreen, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const AiChatScreen(
                      initialMessage: "Explain my society digest and suggest improvements",
                      initialContext: {"screen": "home_digest"},
                    ))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DIVE DEEPER WITH SERO',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: kPrimaryGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value, 
    required this.label, 
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryGreen,
                  letterSpacing: -1,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12, 
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
