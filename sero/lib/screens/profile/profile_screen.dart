import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Loading user data...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('Status: ${user.status.toUpperCase()}', style: TextStyle(fontSize: 14, color: user.status == 'approved' ? Colors.green : Colors.orange)),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone Number'),
                  subtitle: Text(user.phone.isNotEmpty ? user.phone : 'Not provided'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Flat Number'),
                  subtitle: Text(user.flatNumber),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield),
                  title: const Text('Role Designation'),
                  subtitle: Text(user.role.toUpperCase()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: const Text('Resident Type'),
                  subtitle: Text(user.residentType.toUpperCase()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(authProvider.notifier).logout(); // Logout globally
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); // Erase stack and push login
              },
              icon: const Icon(Icons.logout),
              label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
