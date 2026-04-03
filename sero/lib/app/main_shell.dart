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

    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Channels'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Issues'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Rules'),
      if (role == 'resident' || role == 'main_admin' || role == 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Funds'),
      if (role != 'treasurer') const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'AI Help'),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index >= pages.length ? 0 : _index, children: pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kPrimaryGreen.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ColorFilter.mode(
                Colors.white.withOpacity(0.05),
                BlendMode.srcOver,
              ),
              child: BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                currentIndex: _index >= items.length ? 0 : _index,
                selectedItemColor: kPrimaryGreen,
                unselectedItemColor: const Color(0xFF94A3B8),
                selectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
                onTap: (i) => setState(() => _index = i),
                items: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
