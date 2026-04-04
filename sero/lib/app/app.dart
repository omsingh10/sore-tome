import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/issues/post_issue_screen.dart';
import '../screens/admin/post_notice_screen.dart';
import '../screens/admin/manage_issues_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/auth_guard.dart'; // [NEW] Added for screen-level authorization

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
        '/splash':            (_) => const SplashScreen(),
        '/login':             (_) => const LoginScreen(),
        '/register':          (_) => const RegisterScreen(),
        
        // --- PROTECTED ROUTES ---
        '/home':              (_) => const AuthGuard(child: MainShell()),
        '/admin':             (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'treasurer', 'secretary'],
                                      child: MainShell(),
                                    ),
        '/post-issue':        (_) => const AuthGuard(child: PostIssueScreen()),
        '/admin/post-notice': (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'secretary'],
                                      child: PostNoticeScreen(),
                                    ),
        '/admin/manage-issues': (_) => const AuthGuard(
                                      allowedRoles: ['main_admin', 'secretary'],
                                      child: ManageIssuesScreen(),
                                    ),
      },
    );
  }
}


