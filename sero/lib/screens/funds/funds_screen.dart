import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/fund.dart';
import '../../services/firestore_service.dart';
import '../../widgets/fund_bar.dart';

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

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).round()}K';
    return '₹${v.round()}';
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
                        _buildStats(),
                        const SizedBox(height: 10),
                        _buildBalanceCard(),
                        const SizedBox(height: 12),
                        const Text(
                          'RECENT TRANSACTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A8A8A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._transactions.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransactionCard(
                                tx: t,
                                formatFn: _fmt,
                              ),
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
            'Society Funds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'October 2025 · Transparent ledger',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_summary == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(_summary!.totalCollected),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: kDarkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total collected',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(_summary!.totalSpent),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: kBadgeAmberText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total spent',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    if (_summary == null) return const SizedBox.shrink();
    final pct = (_summary!.percentRemaining * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly balance',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            FundBar(
              percent: _summary!.percentRemaining,
              label: '${_fmt(_summary!.remaining)} remaining',
              percentLabel: '$pct%',
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final FundTransaction tx;
  final String Function(double) formatFn;

  const _TransactionCard({required this.tx, required this.formatFn});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${tx.isCredit ? '+' : ''}${formatFn(tx.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tx.isCredit ? kBadgeGreenText : kBadgeRedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
