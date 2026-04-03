import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../models/fund.dart';
import '../../services/firestore_service.dart';
import '../../widgets/brand_logo.dart';

class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  final _service = FirestoreService();
  FundSummary? _summary;
  List<FundTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await _service.getFundSummary();
    final tx = await _service.getTransactions();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _transactions = tx;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimaryGreen,
        displacement: 40,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Branding Header
            const _BrandingHeader(),

            // 2. Hero Section
            const _HeroHeader(),

            // 3. Wealth Metrics Vertical Stack
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _FinancialCard(
                    title: 'Total Collections',
                    amount: '₹${_summary?.totalCollected.toStringAsFixed(2) ?? "0.00"}',
                    trend: '12.5% vs last month',
                    icon: Icons.account_balance_wallet_rounded,
                    isPositive: true,
                  ),
                  const SizedBox(height: 16),
                  _FinancialCard(
                    title: 'Outstanding Dues',
                    amount: '₹12,840.00',
                    trend: '14 Residents with overdue payments',
                    icon: Icons.assignment_late_rounded,
                    isNeutral: true,
                  ),
                  const SizedBox(height: 16),
                  _FinancialCard(
                    title: 'Recent Expenses',
                    amount: '₹${_summary?.totalSpent.toStringAsFixed(2) ?? "0.00"}',
                    trend: 'Maintenace, Security, & Landscaping',
                    icon: Icons.receipt_long_rounded,
                    isNeutral: true,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // 4. Cashflow Trend Chart
            const SliverToBoxAdapter(
              child: _CashflowChart(),
            ),

            // 5. Overdue Dues Section
            const SliverToBoxAdapter(
              child: _OverdueSection(),
            ),

            // 6. Recent Disbursements Table
            SliverToBoxAdapter(
              child: _DisbursementsSection(transactions: _transactions),
            ),

            // Bottom Spacing for Floating Navbar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 20,
          right: 20,
          bottom: 12,
        ),
        color: const Color(0xFFF8FAFC), // Matches screen background
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
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
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
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FINANCIAL INTELLIGENCE',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estate Treasury\nOverview',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ).animate().fade().slideY(begin: 0.1),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String title;
  final String amount;
  final String trend;
  final IconData icon;
  final bool isPositive;
  final bool isNeutral;

  const _FinancialCard({
    required this.title,
    required this.amount,
    required this.trend,
    required this.icon,
    this.isPositive = false,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (isPositive)
                Container(
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
              else
                Text(
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: const Color(0xFFCBD5E1), size: 32),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideX(begin: 0.1);
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Cashflow Trend',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'Monthly',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Quarterly', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('JAN', 0.4),
                _buildBar('FEB', 0.5),
                _buildBar('MAR', 0.8),
                _buildBar('APR', 0.6),
                _buildBar('MAY', 1.0, isDark: true),
                _buildBar('JUN', 0.35),
                _buildBar('JUL', 0.55),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildBar(String label, double heightPct, {bool isDark = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 140 * heightPct,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _OverdueSection extends StatelessWidget {
  const _OverdueSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overdue Dues',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _OverdueItem(name: 'Sebastian Vale', unit: 'Unit 402-B • 2 months', amount: '₹1,250', img: '1'),
          _OverdueItem(name: 'Elara Vance', unit: 'Unit 112-A • 1 month', amount: '₹625', img: '2'),
          _OverdueItem(name: 'Julian Thorne', unit: 'Penthouse 2 • 3 months', amount: '₹4,800', img: '3'),
          _OverdueItem(name: 'Marcella Reed', unit: 'Unit 805-C • 1 month', amount: '₹625', img: '4'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDBEAFE),
              foregroundColor: const Color(0xFF1E40AF),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
            child: const Text('Send Mass Reminders'),
          ),
        ],
      ),
    );
  }
}

class _OverdueItem extends StatelessWidget {
  final String name, unit, amount, img;
  const _OverdueItem({required this.name, required this.unit, required this.amount, required this.img});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$img')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(unit, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF991B1B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DisbursementsSection extends StatelessWidget {
  final List<FundTransaction> transactions;
  const _DisbursementsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    'Recent',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    'Disbursements',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Authorized expenses for the\nmonth of May',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Log New\nExpense',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VENDOR / CATEGORY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8))),
                    Text('TRANSACTION ID', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8))),
                    Text('DATE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8))),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFFF1F5F9)),
                _DisbursementRow(name: 'Evergreen Landscaping', cat: 'Estate Maintenance', id: '#TXN-88421', date: 'May 12, 2024'),
                _DisbursementRow(name: 'Titan Security Systems', cat: 'Security & Surveillance', id: '#TXN-88405', date: 'May 10, 2024'),
                _DisbursementRow(name: 'Metro Water & Sewage', cat: 'Utilities', id: '#TXN-88399', date: 'May 08, 2024'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisbursementRow extends StatelessWidget {
  final String name, cat, id, date;
  const _DisbursementRow({required this.name, required this.cat, required this.id, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E293B))),
                Text(cat, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(id, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(date, textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

