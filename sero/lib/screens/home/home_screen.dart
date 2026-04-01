import 'package:flutter/material.dart';
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
      color: kPrimaryGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, ${user?.name ?? ""}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sunset Valley Society · Flat ${user?.flatNumber ?? ""}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
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
          child: _StatCard(value: '$openCount', label: 'Open issues'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(value: '${_notices.length}', label: 'New notices'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8A8A8A),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}
