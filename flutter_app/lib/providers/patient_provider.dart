import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../services/api_service.dart';

class PatientProvider extends ChangeNotifier {
  List<PatientModel> _patients  = [];
  bool               _loading   = false;
  String?            _error;
  int                _total     = 0;
  int                _page      = 1;

  List<PatientModel> get patients => _patients;
  bool               get loading  => _loading;
  String?            get error    => _error;
  int                get total    => _total;
  bool               get hasMore  => _patients.length < _total;

  Future<void> fetchPatients({String q = '', bool reset = true}) async {
    if (reset) { _page = 1; _patients = []; }
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.getPatients(page: _page, q: q);
      if (res['success'] == true) {
        final items = (res['data'] as List)
            .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _patients.addAll(items);
        _total = (res['pagination']?['total'] as int?) ?? items.length;
        _page++;
      } else {
        _error = res['message'] as String?;
      }
    } catch (e) {
      _error = 'Failed to load patients.';
    }
    _loading = false; notifyListeners();
  }

  Future<bool> createPatient(Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.createPatient(data);
      if (res['success'] == true) {
        await fetchPatients(reset: true);
        return true;
      }
      _error = res['message'] as String?;
    } catch (_) { _error = 'Error creating patient.'; }
    _loading = false; notifyListeners();
    return false;
  }

  Future<bool> updatePatient(int id, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.updatePatient(id, data);
      if (res['success'] == true) {
        await fetchPatients(reset: true);
        return true;
      }
      _error = res['message'] as String?;
    } catch (_) { _error = 'Error updating patient.'; }
    _loading = false; notifyListeners();
    return false;
  }

  Future<bool> deletePatient(int id) async {
    try {
      final res = await ApiService.deletePatient(id);
      if (res['success'] == true) {
        _patients.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
