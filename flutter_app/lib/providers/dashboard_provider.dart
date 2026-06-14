import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _data    = {};
  List<dynamic>        _trends  = [];
  bool                 _loading = false;

  Map<String, dynamic> get data    => _data;
  List<dynamic>        get trends  => _trends;
  bool                 get loading => _loading;

  Future<void> load() async {
    _loading = true; notifyListeners();
    try {
      final d = await ApiService.getDashboard();
      final t = await ApiService.getTrends();
      if (d['success'] == true) _data   = d['data'] as Map<String, dynamic>;
      if (t['success'] == true) _trends = (t['data']?['monthly_predictions'] as List?) ?? [];
    } catch (_) {}
    _loading = false; notifyListeners();
  }
}
