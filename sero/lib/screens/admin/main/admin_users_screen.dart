import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/users_provider.dart';
import '../../../../models/user.dart';
import '../../../../widgets/brand_logo.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingUsersProvider);
    final allAsync = ref.watch(allUsersProvider);

    final totalUsers = allAsync.maybeWhen(
      data: (users) => users.length,
      orElse: () => 0,
    );
    final pendingUsers = pendingAsync.maybeWhen(
      data: (users) => users.length,
      orElse: () => 0,
    );
    final exemptUsers = allAsync.maybeWhen(
      data: (users) => users.where((u) => u.maintenanceExempt).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // --- CLEAN PREMIUM HEADER ---
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF064E3B),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SocietyLogo(size: 22, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "The Sero",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      Text(
                        "Residents",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Resident\nManagement",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1F2937),
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
            ),

            // --- HERO OVERVIEW CARD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOTAL RESIDENTS",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$totalUsers",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1F2937),
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SmallMetricRow(
                              label: "Pending",
                              value: "$pendingUsers",
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 12),
                            _SmallMetricRow(
                              label: "Exempt",
                              value: "$exemptUsers",
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- MODERN TAB SWITCHER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Color(0xFF1F2937),
                  unselectedLabelColor: Color(0xFF64748B),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: "Pending"),
                    Tab(text: "Residents List"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- LIST CONTENT ---
            Expanded(
              child: TabBarView(children: [_PendingTab(), _AllUsersTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PendingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return pendingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 64,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fade();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final u = users[index];
            return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF1E40AF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Flat: ${u.flatNumber} · ${u.phone}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.check_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => ref
                                .read(userOperationsProvider)
                                .approveUser(u.id),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.close_rounded,
                            color: const Color(0xFFEF4444),
                            onTap: () => ref
                                .read(userOperationsProvider)
                                .rejectUser(u.id, 'Rejected by admin'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fade(delay: (index * 100).ms)
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF345D7E)),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _AllUsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allUsersProvider);

    return allAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final u = users[index];
            final isExempt = u.maintenanceExempt;

            return InkWell(
              onTap: () => _showEditDialog(context, ref, u),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isExempt
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      child: Icon(
                        isExempt
                            ? Icons.no_accounts_rounded
                            : Icons.person_rounded,
                        color: isExempt
                            ? const Color(0xFFD97706)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Flat: ${u.flatNumber} · ${u.residentType}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isExempt
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExempt ? 'Exempt' : 'Paying',
                        style: GoogleFonts.outfit(
                          color: isExempt
                              ? const Color(0xFFD97706)
                              : const Color(0xFF1E40AF),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF345D7E)),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, UserModel u) {
    String selectedType = u.residentType;
    bool exempt = u.maintenanceExempt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Edit ${u.name}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: ['owner', 'tenant', 'guest']
                      .map(
                        (x) => DropdownMenuItem(
                          value: x,
                          child: Text(x.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedType = v ?? selectedType),
                  decoration: const InputDecoration(labelText: 'Resident Type'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Maintenance Exempt'),
                  value: exempt,
                  onChanged: (v) => setState(() => exempt = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(userOperationsProvider).updateUser(u.id, {
                    'residentType': selectedType,
                    'maintenanceExempt': exempt,
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
