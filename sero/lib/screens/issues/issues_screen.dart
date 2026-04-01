import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreService();
  List<Issue> _all = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  List<Issue> get _resolved =>
      _all.where((i) => i.status == 'resolved').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          TabBar(
            controller: _tabController,
            labelColor: kPrimaryGreen,
            unselectedLabelColor: const Color(0xFF8A8A8A),
            indicatorColor: kPrimaryGreen,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'All (${_all.length})'),
              Tab(text: 'Open (${_open.length})'),
              Tab(text: 'Resolved (${_resolved.length})'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_all),
                      _buildList(_open),
                      _buildList(_resolved),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/post-issue'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: kPrimaryGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issues',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Report & track society problems',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Issue> issues) {
    if (issues.isEmpty) {
      return const Center(
        child: Text('No issues', style: TextStyle(color: Color(0xFF8A8A8A))),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: issues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => IssueCard(issue: issues[i]),
      ),
    );
  }
}
