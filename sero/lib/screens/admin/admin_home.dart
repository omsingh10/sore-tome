import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _service = FirestoreService();
  List<Issue> _pendingIssues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final issues = await _service.getIssues();
    if (!mounted) return;
    setState(() {
      _pendingIssues =
          issues.where((i) => i.status != 'resolved').toList();
      _loading = false;
    });
  }

  Future<void> _resolve(String id) async {
    await _service.updateIssueStatus(id, 'resolved');
    setState(() {
      _pendingIssues.removeWhere((i) => i.id == id);
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
                        _sectionLabel('Quick actions'),
                        const SizedBox(height: 6),
                        _quickActions(),
                        const SizedBox(height: 12),
                        _sectionLabel('Pending issues'),
                        const SizedBox(height: 6),
                        ..._pendingIssues.map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: IssueCard(
                              issue: i,
                              showResolveButton: true,
                              onResolve: () => _resolve(i.id),
                            ),
                          ),
                        ),
                        if (_pendingIssues.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No pending issues 🎉',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A8A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _sectionLabel('Society stats'),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Expanded(child: _AdminStatCard(value: '142', label: 'Registered users')),
                            SizedBox(width: 8),
                            Expanded(child: _AdminStatCard(value: '94%', label: 'Dues collected')),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
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
            'Admin Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Sunset Valley Society · Admin',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      {'icon': '📢', 'label': 'Post notice', 'route': '/admin/post-notice'},
      {'icon': '🎉', 'label': 'Add event', 'route': '/admin/post-notice'},
      {'icon': '💰', 'label': 'Update funds', 'route': '/admin/post-notice'},
      {'icon': '👥', 'label': 'Manage users', 'route': '/admin/manage-issues'},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: actions
          .map(
            (a) => GestureDetector(
              onTap: () => Navigator.pushNamed(context, a['route']!),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(a['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        a['label']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
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

class _AdminStatCard extends StatelessWidget {
  final String value;
  final String label;
  const _AdminStatCard({required this.value, required this.label});

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
              fontSize: 20,
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
