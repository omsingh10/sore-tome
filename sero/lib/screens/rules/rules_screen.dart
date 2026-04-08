import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../providers/ai_provider.dart';

// Modularized Widgets
import 'widgets/rules_widgets.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'General Conduct';

  final List<String> _categories = [
    'General Conduct',
    'Parking & Transit',
    'Pet Policy',
    'Facility Usage',
    'Waste & Eco',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const BrandingHeader(),
          HeroHeader(onRefresh: () => ref.invalidate(aiRulesProvider)),
          GovernanceSearchBar(controller: _searchCtrl),

          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    const MetricCard(
                      title: '42 Active',
                      subtitle: 'Rules currently in enforcement',
                      icon: Icons.gavel_rounded,
                      color: Color(0xFFBFDBFE),
                      iconColor: Color(0xFF1E40AF),
                    ),
                    const SizedBox(width: 12),
                    const MetricCard(
                      title: '3 Pending',
                      subtitle: 'Clauses awaiting committee review',
                      icon: Icons.update_rounded,
                      color: Colors.white,
                      iconColor: Color(0xFF64748B),
                      badgeText: 'UPDATED',
                    ),
                    const SizedBox(width: 12),
                    const MetricCard(
                      title: 'Draft New Rule',
                      subtitle: 'Create a new society protocol',
                      icon: Icons.add_rounded,
                      color: Colors.white,
                      iconColor: Color(0xFF64748B),
                      isCenter: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORIES',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF1F5F9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const ExportBylawsCard(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedCategory Protocols',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Sort by: Recently Added',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          ref.watch(aiRulesProvider).when(
            data: (rules) {
              if (rules.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No AI-extracted rules found.')),
                );
              }
              
              final filtered = rules.where((r) => 
                r['rule'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase())
              ).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final rule = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: RuleSheetCard(
                        title: 'Society Protocol',
                        section: 'AI V3.10 CLS',
                        lastUpdated: rule['date'] != null 
                          ? DateFormat('MMM dd, yyyy').format(DateTime.parse(rule['date']))
                          : 'Recent Knowledge Extraction',
                        content: rule['rule'],
                        penalty: 'Subject to committee sanctions as per standard bylaws.',
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
            ),
            error: (e, stack) => SliverFillRemaining(
              child: Center(child: Text('Extraction failed: $e')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
