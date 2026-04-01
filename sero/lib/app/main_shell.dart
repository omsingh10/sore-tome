import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/issues/issues_screen.dart';
import '../screens/rules/rules_screen.dart';
import '../screens/funds/funds_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/channels/channels_list_screen.dart';
// Admin panels
import '../screens/admin/main/admin_main_home.dart';
import '../screens/admin/treasury/treasury_home.dart';
import '../screens/admin/secretary/secretary_home.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  Widget _getHomeForRole(String role) {
    if (role == 'main_admin') return const AdminMainHome();
    if (role == 'treasurer') return const TreasuryHome();
    if (role == 'secretary') return const SecretaryHome();
    return const HomeScreen(); // Resident
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final role = user?.role ?? 'resident';

    final pages = [
      _getHomeForRole(role),
      if (role != 'treasurer') const ChannelsListScreen(),
      if (role != 'treasurer') const IssuesScreen(),
      if (role != 'treasurer') const RulesScreen(),
      if (role == 'resident' || role == 'main_admin' || role == 'treasurer') const FundsScreen(),
      if (role != 'treasurer') const AiChatScreen(),
    ];

    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Channels'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Issues'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Rules'),
      if (role == 'resident' || role == 'main_admin' || role == 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Funds'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'AI Help'),
    ];

    return Scaffold(
      body: IndexedStack(index: _index >= pages.length ? 0 : _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index >= items.length ? 0 : _index,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey.shade600,
          onTap: (i) => setState(() => _index = i),
          items: items,
        ),
      ),
    );
  }
}
