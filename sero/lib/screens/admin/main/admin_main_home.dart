import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/users_provider.dart';
import 'admin_users_screen.dart';
import 'admin_channels_screen.dart';
import 'admin_maintenance_screen.dart';
import '../post_notice_screen.dart';
import '../../profile/profile_screen.dart';

class AdminMainHome extends ConsumerWidget {
  const AdminMainHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardCard(
              title: 'Users & Authorizations',
              icon: Icons.people,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              badge: pendingAsync.whenOrNull(data: (users) => users.isNotEmpty ? users.length.toString() : null),
            ),
            _DashboardCard(
              title: 'Maintenance Tracking',
              icon: Icons.account_balance_wallet,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen())),
            ),
            _DashboardCard(
              title: 'Chat Channels',
              icon: Icons.forum,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChannelsScreen())),
            ),
            _DashboardCard(
              title: 'Post Notice/Event',
              icon: Icons.announcement,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostNoticeScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _DashboardCard({required this.title, required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: const Color(0xFF2E7D32)),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
