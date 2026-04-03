import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/notice.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/issue_card.dart';

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
  List<Notice> _notices = [];
  List<Issue> _myIssues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notices = await _service.getNotices();
    final issues = await _service.getIssues();
    if (!mounted) return;
    setState(() {
      _notices = notices;
      _myIssues = issues.where((i) => i.postedBy == 'Rahul').toList();
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
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionLabel('Overview'),
                        const SizedBox(height: 6),
                        _statsRow(),
                        const SizedBox(height: 12),
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
                  Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Flat ${user?.flatNumber ?? ""}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
        border: Border.all(color: kSlateBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.04),
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
