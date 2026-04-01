import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/users_provider.dart';
import '../../../../models/user.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: const TabBar(tabs: [Tab(text: 'Pending'), Tab(text: 'All Residents')]),
        ),
        body: TabBarView(
          children: [
            _PendingTab(),
            _AllUsersTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return pendingAsync.when(
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No pending approvals'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            return ListTile(
              title: Text(u.name),
              subtitle: Text('Flat: ${u.flatNumber} | Phone: ${u.phone}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => ref.read(userOperationsProvider).approveUser(u.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => ref.read(userOperationsProvider).rejectUser(u.id, "Rejected by admin"),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _AllUsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allUsersProvider);

    return allAsync.when(
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No users found'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            return ListTile(
              title: Text('${u.name} (${u.role})'),
              subtitle: Text('Flat: ${u.flatNumber} | Type: ${u.residentType}'),
              trailing: Icon(u.maintenanceExempt ? Icons.money_off : Icons.attach_money, color: u.maintenanceExempt ? Colors.grey : Colors.green),
              onTap: () => _showEditDialog(context, ref, u),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
            title: Text('Edit ${u.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['owner', 'tenant', 'guest'].map((x) => DropdownMenuItem(value: x, child: Text(x.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: 'Resident Type'),
                ),
                SwitchListTile(
                  title: const Text('Maintenance Exempt (Flat is out)'),
                  value: exempt,
                  onChanged: (v) => setState(() => exempt = v),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
        }
      ),
    );
  }
}
