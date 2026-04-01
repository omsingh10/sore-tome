import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Resident fields
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Admin fields
  final _adminUserCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showAdminPass = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  // ── Resident Login ────────────────────────────────────────────────────────
  Future<void> _loginResident() async {
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (phone.isEmpty || pass.isEmpty) return;

    setState(() => _loading = true);
    try {
      final result = await AuthService.login(
        phone: '+91$phone',
        password: pass,
      );
      if (!mounted) return;
      final role = result['user']?['role'] ?? 'resident';
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'admin' ? '/admin' : '/home',
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Map ? e['error'] : e.toString();
      _showError(msg ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Admin Login ───────────────────────────────────────────────────────────
  Future<void> _loginAdmin() async {
    final user = _adminUserCtrl.text.trim();
    final pass = _adminPassCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() => _loading = true);
    try {
      final result = await AuthService.login(phone: user, password: pass);
      if (!mounted) return;
      final role = result['user']?['role'] ?? 'resident';
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'admin' ? '/admin' : '/home',
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is Map ? e['error'] : e.toString();
      _showError(msg ?? 'Admin login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // ── Brand ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SocietyApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your society, connected.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ── White card with tabs ────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: kPrimaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF5A5A5A),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: '🏠  Resident'),
                        Tab(text: '🛡️  Admin'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab content
                  SizedBox(
                    height: 230,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _residentForm(),
                        _adminForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resident form ─────────────────────────────────────────────────────────
  Widget _residentForm() {
    return Column(
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixText: '+91  ',
            hintText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: !_showPass,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _loginResident,
            style: _btnStyle(),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Login'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          child: const Text(
            "Don't have an account? Register →",
            style: TextStyle(color: kPrimaryGreen, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Admin form ────────────────────────────────────────────────────────────
  Widget _adminForm() {
    return Column(
      children: [
        TextField(
          controller: _adminUserCtrl,
          decoration: const InputDecoration(
            hintText: 'Admin username',
            prefixIcon: Icon(Icons.admin_panel_settings_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adminPassCtrl,
          obscureText: !_showAdminPass,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showAdminPass ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showAdminPass = !_showAdminPass),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _loginAdmin,
            style: _btnStyle(),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Admin Login'),
          ),
        ),
      ],
    );
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
