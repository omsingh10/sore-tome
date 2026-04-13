import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/widgets/shared/premium_navbar.dart';
import '../screens/resident/home/resident_home_screen.dart';

class ResidentShell extends ConsumerStatefulWidget {
  const ResidentShell({super.key});

  @override
  ConsumerState<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends ConsumerState<ResidentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // 1-Home, 2-Channels(P), 3-Issues(P), 4-Rules(P), 5-Funds(P), 6-AI(P)
    final pages = [
      const ResidentHomeScreen(), // Resident Home
      const _PlaceholderScreen(title: 'Channels'),
      const _PlaceholderScreen(title: 'Issues'),
      const _PlaceholderScreen(title: 'Rules'),
      const _PlaceholderScreen(title: 'Funds'),
      const _PlaceholderScreen(title: 'AI Help'),
    ];

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      NavItemData(icon: Icons.chat_outlined, activeIcon: Icons.chat_rounded, label: 'Channels'),
      NavItemData(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded, label: 'Issues'),
      NavItemData(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Rules'),
      NavItemData(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Funds'),
      NavItemData(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded, label: 'AI Help'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '$title feature coming soon',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}



