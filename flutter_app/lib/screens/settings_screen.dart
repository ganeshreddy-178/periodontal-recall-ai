import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode      = false;
  bool _notifications = true;
  bool _autoBackup    = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ---- Appearance ----
          _sectionHeader('Appearance'),
          SwitchListTile(
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          const Divider(height: 1),
          // ---- Notifications ----
          _sectionHeader('Notifications'),
          SwitchListTile(
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            title: const Text('Recall Reminders'),
            subtitle: const Text('Get notified about upcoming recalls'),
            secondary: const Icon(Icons.notifications_outlined),
          ),
          const Divider(height: 1),
          // ---- Data ----
          _sectionHeader('Data & Privacy'),
          SwitchListTile(
            value: _autoBackup,
            onChanged: (v) => setState(() => _autoBackup = v),
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup patient data'),
            secondary: const Icon(Icons.backup_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Clear Local Cache'),
            subtitle: const Text('Remove cached images and data'),
            onTap: () => _clearCache(),
          ),
          const Divider(height: 1),
          // ---- About ----
          _sectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.health_and_safety_outlined),
            title: Text('Periodontal Recall AI'),
            subtitle: Text('AI-Powered Dental Risk Prediction'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0))),
  );

  void _clearCache() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all cached data. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
