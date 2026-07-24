import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../models/patient_model.dart';
import '../utils/helpers.dart';
import 'patient_form_screen.dart';
import 'image_upload_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().fetchPatients();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PatientProvider>();
    return Scaffold(
      key: const Key('patients_screen'),
      appBar: AppBar(
        title: const Text('Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              key: const Key('patients_search'),
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search patients…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                          pp.fetchPatients();
                        })
                    : null,
              ),
              onChanged: (v) {
                setState(() => _query = v);
                pp.fetchPatients(q: v);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('patients_add_fab'),
        heroTag: 'patients_fab',
        onPressed: () async {
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const PatientFormScreen()));
          if (ok == true) pp.fetchPatients();
        },
        child: const Icon(Icons.person_add),
      ),
      body: pp.loading && pp.patients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : pp.patients.isEmpty
              ? const Center(child: Text('No patients found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pp.patients.length,
                  itemBuilder: (_, i) => _PatientTile(patient: pp.patients[i]),
                ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
          child: Text(patient.firstName[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
        ),
        title: Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${capitalize(patient.gender)} · ${patient.age} yrs · ${formatDate(patient.createdAt)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'scan', child: Text('New Scan')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete',
                style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ImageUploadScreen(patient: patient))),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'scan':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ImageUploadScreen(patient: patient)));
        break;
      case 'edit':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PatientFormScreen(patient: patient)));
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) {
    // Staff are not allowed to delete patients
    if (context.read<AuthProvider>().isStaff) {
      showSnack(context, 'Staff cannot delete patients.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Remove ${patient.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<PatientProvider>().deletePatient(patient.id);
              if (context.mounted) showSnack(context, 'Patient deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
