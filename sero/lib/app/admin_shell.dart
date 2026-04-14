import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';
import '../screens/admin/main/admin_main_home.dart';
import '../screens/admin/main/admin_channels_screen.dart';
import '../screens/admin/treasury/treasury_home.dart';
import '../screens/admin/secretary/secretary_home.dart';
import '../screens/admin/issues/admin_issues_screen.dart';
import '../screens/admin/rules/admin_rules_screen.dart';
import '../screens/admin/funds/admin_funds_screen.dart';
import '../screens/shared/ai_chat/ai_chat_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final role = user?.role ?? 'main_admin';

    // Build adaptive pages and nav items based on admin sub-role
    final List<Widget> pages = [];
    final List<NavItemData> navItems = [];

    // 1. Home Base
    pages.add(_getHomeForRole(role));
    navItems.add(NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ));

    // 2. Channels (Show for main_admin and secretary)
    if (role == 'main_admin' || role == 'secretary') {
      pages.add(const AdminChannelsScreen());
      navItems.add(NavItemData(
        icon: Icons.chat_outlined,
        activeIcon: Icons.chat_rounded,
        label: 'Channels',
      ));
    }

    // 3. Issues (Admin view - show for main_admin and secretary)
    if (role == 'main_admin' || role == 'secretary') {
      pages.add(const AdminIssuesScreen()); // Will be updated to AdminIssuesScreen
      navItems.add(NavItemData(
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt_rounded,
        label: 'Issues',
      ));
    }

    // 4. Rules (Show for main_admin and secretary)
    if (role == 'main_admin' || role == 'secretary') {
      pages.add(const AdminRulesScreen());
      navItems.add(NavItemData(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Rules',
      ));
    }

    // 5. Funds (Show for main_admin and treasurer)
    if (role == 'main_admin' || role == 'treasurer') {
      pages.add(const AdminFundsScreen());
      navItems.add(NavItemData(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Funds',
      ));
    }

    // 6. AI Help (Show for everyone in Admin shell)
    pages.add(const AiChatScreen(userRole: 'admin'));
    navItems.add(NavItemData(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
      label: 'AI Help',
    ));

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index >= pages.length ? 0 : _index,
        children: pages,
      ),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _getHomeForRole(String role) {
    if (role == 'treasurer') return const TreasuryHome();
    if (role == 'secretary') return const SecretaryHome();
    return const AdminMainHome();
  }
}



