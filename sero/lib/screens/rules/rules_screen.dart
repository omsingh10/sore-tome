import 'package:flutter/material.dart';
import '../../app/theme.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Rules'),
              Tab(text: 'Documents'),
              Tab(text: 'Timings'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRules(),
                _buildDocuments(),
                _buildTimings(),
              ],
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
            'Rules & Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Society guidelines',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRules() {
    final rules = [
      {
        'title': 'Parking rules',
        'body':
            'Each flat gets 1 reserved spot. Visitors must use visitor parking near gate 2. No double parking.',
      },
      {
        'title': 'Noise policy',
        'body':
            'No loud music after 10 PM or before 7 AM. Events require written approval from admin 3 days in advance.',
      },
      {
        'title': 'Pet policy',
        'body':
            'Pets allowed. Must be on leash in common areas. Register your pet with the admin office.',
      },
    ];
    return _rulesList(rules);
  }

  Widget _buildDocuments() {
    final docs = [
      {
        'title': 'Society Bye-laws',
        'body': 'Official bye-laws of Sunset Valley Society residents.',
      },
      {
        'title': 'Maintenance Agreement',
        'body': 'Annual maintenance terms and payment schedule.',
      },
    ];
    return _rulesList(docs);
  }

  Widget _buildTimings() {
    final timings = [
      {
        'title': 'Gym timings',
        'body':
            'Mon–Sat: 6:00 AM – 10:00 AM & 5:00 PM – 9:00 PM\nSunday: Closed',
      },
      {
        'title': 'Swimming pool',
        'body':
            'Daily: 7:00 AM – 8:00 PM\nMaintenance: Every Tuesday 10 AM – 12 PM',
      },
      {
        'title': 'Clubhouse',
        'body': 'Daily: 8:00 AM – 10:00 PM\nBooking required for events.',
      },
    ];
    return _rulesList(timings);
  }

  Widget _rulesList(List<Map<String, String>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items[i]['title']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items[i]['body']!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
