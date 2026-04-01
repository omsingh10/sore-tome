import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/issues/issues_screen.dart';
import '../screens/rules/rules_screen.dart';
import '../screens/funds/funds_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/admin/admin_home.dart';

/// Main scaffold with bottom navigation bar — shown after login.
class MainShell extends StatefulWidget {
  final bool isAdmin;
  const MainShell({super.key, this.isAdmin = false});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> get _pages => [
        const HomeScreen(),
        const IssuesScreen(),
        const RulesScreen(),
        const FundsScreen(),
        const AiChatScreen(),
        if (widget.isAdmin) const AdminHome(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Issues',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Rules',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Funds',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Help',
            ),
            if (widget.isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
          ],
        ),
      ),
    );
  }
}
