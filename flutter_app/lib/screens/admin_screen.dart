import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool    _loading = true;
  String? _error;

  int    _totalUsers       = 0;
  int    _totalPatients    = 0;
  int    _totalPredictions = 0;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminStats(),
        ApiService.getAdminUsers(),
      ]);

      final statsRes = results[0];
      final usersRes = results[1];

      if (statsRes['success'] == true) {
        final data        = statsRes['data'] as Map<String, dynamic>;
        _totalUsers       = (data['total_users']       as num).toInt();
        _totalPatients    = (data['total_patients']    as num).toInt();
        _totalPredictions = (data['total_predictions'] as num).toInt();
      }
      if (usersRes['success'] == true) {
        _users = (usersRes['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {
      _error = 'Failed to load admin data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('admin_screen'),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ---- System stats ----
                      const Text('System Overview',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0))),
                      const SizedBox(height: 12),
                      Row(children: [
                        _StatCard(label: 'Users',       value: _totalUsers,
                            icon: Icons.people,          color: Colors.blue),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Patients',    value: _totalPatients,
                            icon: Icons.personal_injury, color: Colors.green),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Predictions', value: _totalPredictions,
                            icon: Icons.analytics,       color: Colors.purple),
                      ]),

                      const SizedBox(height: 24),
                      // ---- Role legend ----
                      Row(children: const [
                        _LegendChip(label: 'Admin',   color: Colors.blue),
                        SizedBox(width: 8),
                        _LegendChip(label: 'Dentist', color: Colors.green),
                        SizedBox(width: 8),
                        _LegendChip(label: 'Staff',   color: Colors.orange),
                      ]),
                      const SizedBox(height: 16),

                      // ---- Users list ----
                      const Text('All Users',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_users.isEmpty)
                        const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No users found.'),
                            ))
                      else
                        ..._users.map((u) => _UserTile(user: u)),
                    ],
                  ),
                ),
    );
  }
}

// ---- Stat card ----
class _StatCard extends StatelessWidget {
  final String  label;
  final int     value;
  final IconData icon;
  final Color   color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    ),
  );
}

// ---- Legend chip ----
class _LegendChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5))),
    child: Text(label, style: TextStyle(
        color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

// ---- User tile ----
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':   return Colors.blue;
      case 'dentist': return Colors.green;
      case 'staff':   return Colors.orange;
      default:        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role     = (user['role']      as String?) ?? 'dentist';
    final fullName = (user['full_name'] as String?) ?? '—';
    final email    = (user['email']     as String?) ?? '—';
    final isActive = (user['is_active'] as bool?)   ?? true;
    final clinic   = (user['clinic_name'] as String?);
    final color    = _roleColor(role);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Row(children: [
          Expanded(child: Text(fullName,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Text(capitalize(role),
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 12)),
            if (clinic != null && clinic.isNotEmpty)
              Text(clinic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (!isActive)
              const Text('Inactive',
                  style: TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
