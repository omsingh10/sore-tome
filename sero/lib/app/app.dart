import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/issues/post_issue_screen.dart';
import '../screens/admin/post_notice_screen.dart';
import '../screens/admin/manage_issues_screen.dart';
import '../services/auth_service.dart';

class SocietyApp extends StatelessWidget {
  const SocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocietyApp',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash':            (_) => const _SplashRoute(),
        '/login':             (_) => const LoginScreen(),
        '/register':          (_) => const RegisterScreen(),
        '/home':              (_) => const MainShell(isAdmin: false),
        '/admin':             (_) => const MainShell(isAdmin: true),
        '/post-issue':        (_) => const PostIssueScreen(),
        '/admin/post-notice': (_) => const PostNoticeScreen(),
        '/admin/manage-issues': (_) => const ManageIssuesScreen(),
      },
    );
  }
}

/// Shown for ~1 second while we check SharedPreferences for a saved token.
/// Routes to /home, /admin, or /login based on saved role.
class _SplashRoute extends StatefulWidget {
  const _SplashRoute();

  @override
  State<_SplashRoute> createState() => _SplashRouteState();
}

class _SplashRouteState extends State<_SplashRoute> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 300)); // brief init
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final role = await AuthService.getRole();
      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? '/admin' : '/home',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SocietyApp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
