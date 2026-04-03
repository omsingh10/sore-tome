import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import '../../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/issues/issues_screen.dart';
import '../screens/rules/rules_screen.dart';
import '../screens/funds/funds_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/channels/channels_list_screen.dart';
// Admin panels
import '../screens/admin/main/admin_main_home.dart';
import '../screens/admin/main/admin_channels_screen.dart';
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
      if (role != 'treasurer')
        role == 'main_admin' ? const AdminChannelsScreen() : const ChannelsListScreen(),
      if (role != 'treasurer') const IssuesScreen(),
      if (role != 'treasurer') const RulesScreen(),
      if (role == 'resident' || role == 'main_admin' || role == 'treasurer') const FundsScreen(),
      if (role != 'treasurer') const AiChatScreen(),
    ];

    final navItems = [
      _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      if (role != 'treasurer')
        _NavItemData(icon: Icons.chat_outlined, activeIcon: Icons.chat_rounded, label: 'Channels'),
      if (role != 'treasurer')
        _NavItemData(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded, label: 'Issues'),
      if (role != 'treasurer')
        _NavItemData(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Rules'),
      if (role == 'resident' || role == 'main_admin' || role == 'treasurer')
        _NavItemData(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Funds'),
      if (role != 'treasurer')
        _NavItemData(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded, label: 'AI Help'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index >= pages.length ? 0 : _index,
        children: pages,
      ),
      bottomNavigationBar: _FloatingPillNavbar(
        currentIndex: _index,
        items: navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _FloatingPillNavbar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _FloatingPillNavbar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            final item = items[index];

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

