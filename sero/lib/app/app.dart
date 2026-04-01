import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/issues/post_issue_screen.dart';
import '../screens/admin/post_notice_screen.dart';
import '../screens/admin/manage_issues_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

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
        '/home':              (_) => const MainShell(),
        '/admin':             (_) => const MainShell(),
        '/post-issue':        (_) => const PostIssueScreen(),
        '/admin/post-notice': (_) => const PostNoticeScreen(),
        '/admin/manage-issues': (_) => const ManageIssuesScreen(),
      },
    );
  }
}

class _SplashRoute extends ConsumerStatefulWidget {
  const _SplashRoute();

  @override
  ConsumerState<_SplashRoute> createState() => _SplashRouteState();
}

class _SplashRouteState extends ConsumerState<_SplashRoute> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user != null) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
        return _splashBody();
      },
      loading: () => _splashBody(),
      error: (err, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return _splashBody();
      },
    );
  }

  Widget _splashBody() {
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
