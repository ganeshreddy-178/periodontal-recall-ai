import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---- Avatar + name + role badge ----
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(fontSize: 40,
                        color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.fullName ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _RoleBadge(role: user?.role ?? 'dentist'),
                const SizedBox(height: 4),
              ]),
            ),

            const SizedBox(height: 24),
            // ---- Info card ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _infoRow(Icons.email_outlined,          'Email',  user?.email       ?? '—'),
                  const Divider(height: 20),
                  _infoRow(Icons.local_hospital_outlined, 'Clinic', user?.clinicName  ?? '—'),
                  const Divider(height: 20),
                  _infoRow(Icons.phone_outlined,          'Phone',  user?.phone       ?? '—'),
                  const Divider(height: 20),
                  _infoRow(Icons.badge_outlined,          'Role',   capitalize(user?.role ?? 'dentist')),
                ]),
              ),
            ),

            const SizedBox(height: 16),
            // ---- Permissions card ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Permissions',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 14, color: Color(0xFF1565C0))),
                    const SizedBox(height: 12),
                    _permRow('Add Patients',    true),
                    _permRow('Edit Patients',   true),
                    _permRow('Delete Patients', auth.isAdmin || auth.isDentist),
                    _permRow('Run AI Scans',    true),
                    _permRow('View History',    true),
                    _permRow('Admin Panel',     auth.isAdmin),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // ---- Actions ----
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: Color(0xFF1565C0)),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editProfile(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline,
                      color: Color(0xFF1565C0)),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showSnack(context,
                      'Change password — connect to /auth/change-password'),
                ),
              ]),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 20, color: const Color(0xFF1565C0)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ])),
  ]);

  Widget _permRow(String label, bool allowed) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(allowed ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: allowed ? Colors.green : Colors.red[300]),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          color: allowed ? null : Colors.grey,
          fontSize: 13)),
    ]),
  );

  void _editProfile(BuildContext context) {
    final auth     = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.fullName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Colored role badge.
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'admin':   return Colors.blue;
      case 'dentist': return Colors.green;
      case 'staff':   return Colors.orange;
      default:        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    decoration: BoxDecoration(
        color: _color, borderRadius: BorderRadius.circular(20)),
    child: Text(capitalize(role),
        style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 14)),
  );
}
