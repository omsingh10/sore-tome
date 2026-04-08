import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../models/issue.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';
import '../ai_chat/ai_chat_screen.dart';

// Modularized Widgets
import 'widgets/issues_widgets.dart';

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
            const BrandingHeader(),
            IssuesHero(
              onHistoryTap: () {},
              onNewTicketTap: () => Navigator.pushNamed(context, '/post-issue'),
            ),

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
                          StatRow(
                            label: 'UNASSIGNED',
                            value: _open.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFFEF4444),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          StatRow(
                            label: 'IN PROGRESS',
                            value:
                                _inProgress.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFF3B82F6),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          StatRow(
                            label: 'RESOLVED (TODAY)',
                            value: _resolved.length.toString().padLeft(2, '0'),
                            underlineColor: kAccentGreen,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          StatRow(
                            label: 'TOTAL TICKETS',
                            value: _all.length.toString().padLeft(2, '0'),
                            underlineColor: const Color(0xFF8B5CF6),
                            subtitle: 'Across all statuses',
                          ),
                        ],
                      ),
              ).animate().fade(delay: 150.ms),
            ),

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
              const SliverToBoxAdapter(child: IssuesEmptyState())
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

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatScreen(
                initialMessage: 'Summarize current complaints and suggest actions',
                initialContext: {'screen': 'issues'},
              ),
            ),
          );
        },
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }
}
