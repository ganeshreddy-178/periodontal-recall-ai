import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../providers/patient_provider.dart';
import '../utils/helpers.dart';

class PatientFormScreen extends StatefulWidget {
  final PatientModel? patient;
  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _notesCtrl      = TextEditingController();
  final _riskFactorsCtrl = TextEditingController();

  String   _gender          = 'male';
  String   _smokingStatus   = 'never';
  String   _diabetesStatus  = 'none';
  bool     _familyHistory   = false;
  bool     _previousPerio   = false;
  DateTime? _dob;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    if (p != null) {
      _firstNameCtrl.text   = p.firstName;
      _lastNameCtrl.text    = p.lastName;
      _phoneCtrl.text       = p.phone ?? '';
      _emailCtrl.text       = p.email ?? '';
      _notesCtrl.text       = p.notes ?? '';
      _gender               = p.gender;
      _smokingStatus        = p.smokingStatus;
      _diabetesStatus       = p.diabetesStatus;
      _familyHistory        = p.familyHistory;
      _previousPerio        = p.previousPeriodontal;
      try { _dob = DateTime.parse(p.dateOfBirth); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _addressCtrl.dispose(); _notesCtrl.dispose();
    _riskFactorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context:      context,
      initialDate:  _dob ?? DateTime(now.year - 30),
      firstDate:    DateTime(now.year - 120),
      lastDate:     DateTime(now.year - 1),
    );
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) { showSnack(context, 'Select date of birth', error: true); return; }

    final data = {
      'first_name':              _firstNameCtrl.text.trim(),
      'last_name':               _lastNameCtrl.text.trim(),
      'date_of_birth':           _dob!.toIso8601String().split('T').first,
      'gender':                  _gender,
      'phone':                   _phoneCtrl.text.trim(),
      'email':                   _emailCtrl.text.trim(),
      'address':                 _addressCtrl.text.trim(),
      'smoking_status':          _smokingStatus,
      'diabetes_status':         _diabetesStatus,
      'family_history':          _familyHistory,
      'previous_periodontal':    _previousPerio,
      'additional_risk_factors': _riskFactorsCtrl.text.trim(),
      'notes':                   _notesCtrl.text.trim(),
    };

    final pp = context.read<PatientProvider>();
    bool ok;
    if (_isEditing) {
      ok = await pp.updatePatient(widget.patient!.id, data);
    } else {
      ok = await pp.createPatient(data);
    }

    if (!mounted) return;
    if (ok) {
      showSnack(context, _isEditing ? 'Patient updated!' : 'Patient added!');
      Navigator.of(context).pop(true);
    } else {
      showSnack(context, pp.error ?? 'Error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<PatientProvider>().loading;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Patient' : 'New Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Information'),
              Row(children: [
                Expanded(child: _field(_firstNameCtrl, 'First Name', Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastNameCtrl, 'Last Name', Icons.person_outline)),
              ]),
              const SizedBox(height: 14),
              _dropdownField('Gender', _gender, ['male', 'female', 'other'],
                      (v) => setState(() => _gender = v!)),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_dob != null
                      ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                      : 'Select date'),
                ),
              ),
              const SizedBox(height: 14),
              _field(_phoneCtrl, 'Phone', Icons.phone, required: false,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email', Icons.email_outlined, required: false,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _section('Risk Factors'),
              _dropdownField('Smoking Status', _smokingStatus, ['never', 'former', 'current'],
                      (v) => setState(() => _smokingStatus = v!)),
              const SizedBox(height: 14),
              _dropdownField('Diabetes Status', _diabetesStatus,
                  ['none', 'type1', 'type2', 'prediabetic'],
                      (v) => setState(() => _diabetesStatus = v!)),
              const SizedBox(height: 14),
              SwitchListTile(
                value: _familyHistory,
                onChanged: (v) => setState(() => _familyHistory = v),
                title: const Text('Family History of Periodontal Disease'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _previousPerio,
                onChanged: (v) => setState(() => _previousPerio = v),
                title: const Text('Previous Periodontal Disease'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _riskFactorsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Risk Factors',
                  prefixIcon: const Icon(Icons.warning_amber_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Clinical Notes',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Update Patient' : 'Add Patient')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
        color: Color(0xFF1565C0))),
  );

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool required = true, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _dropdownField(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options.map((o) => DropdownMenuItem(value: o,
          child: Text(capitalize(o)))).toList(),
      onChanged: onChanged,
    );
  }
}
