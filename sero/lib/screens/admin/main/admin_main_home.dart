import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/users_provider.dart';
import 'admin_users_screen.dart';
import 'admin_maintenance_screen.dart';
import '../post_notice_screen.dart';

// Modularized Widgets
import 'widgets/admin_home_widgets.dart';

class AdminMainHome extends ConsumerWidget {
  const AdminMainHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const AdminHomeHeader(
            title: "Admin\nDashboard",
            subtitle: "Estate status for Friday, Oct 24th.",
          ),

          LiveActivityHero(
            count: "42",
            label: "Residents\nOn-Site",
            onManageAccess: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            ),
            onAccessLogs: () {},
          ),

          PendingApprovalsHero(
            count: pendingAsync.whenOrNull(
                  data: (users) => users.length.toString().padLeft(2, '0'),
                ) ??
                '00',
            children: const [
              PendingItemTile(
                name: "Elevator B-4",
                priority: "High",
                color: Color(0xFFEF4444),
              ),
              SizedBox(height: 12),
              PendingItemTile(
                name: "Pool Filtration",
                priority: "Med",
                color: Color(0xFF3B82F6),
              ),
            ],
          ),

          RecentUpdatesSection(
            onNewPost: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostNoticeScreen()),
            ),
            children: const [
              RecentUpdateTile(
                category: "ESTATE EVENT",
                title: "Annual Garden Gala Invitation",
                subtitle:
                    "Residents are invited to join the management for a sunset dinner...",
                time: "2 hours ago",
                badgeColor: Color(0xFFDBEAFE),
                textColor: Color(0xFF1E40AF),
              ),
              Divider(height: 32, color: Color(0xFFF1F5F9)),
              RecentUpdateTile(
                category: "MAINTENANCE",
                title: "Emergency Water Pipe Repairs",
                subtitle:
                    "Scheduled maintenance for Tower A water lines will commence...",
                time: "Yesterday",
                badgeColor: Color(0xFFE0E7FF),
                textColor: Color(0xFF4338CA),
              ),
            ],
          ),

          FinancialOverviewCard(
            total: "Rs142,850",
            progress: 0.75,
            target: "\$200K",
            percentage: "75%",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
