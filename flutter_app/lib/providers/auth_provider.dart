import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool       _loading  = false;
  String?    _error;

  UserModel? get user      => _user;
  bool       get loading   => _loading;
  String?    get error     => _error;
  bool       get loggedIn  => _user != null;

  // Role helpers
  String get role      => _user?.role ?? 'dentist';
  bool   get isAdmin   => role == 'admin';
  bool   get isStaff   => role == 'staff';
  bool   get isDentist => role == 'dentist';

  // ------------------------------------------------------------------ Init
  Future<void> tryAutoLogin() async {
    try {
      final stored = await ApiService.getSavedUserJson();
      if (stored != null) {
        _user = UserModel.fromJson(jsonDecode(stored) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------------ Login
  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await ApiService.saveAuth(
          accessToken:  data['access_token']  as String,
          refreshToken: data['refresh_token'] as String,
          userJson:     jsonEncode(_user!.toJson()),
        );
        _loading = false; notifyListeners();
        return true;
      }
      _error = res['message'] as String? ?? 'Login failed.';
    } catch (e) {
      _error = e.toString().contains('TimeoutException')
          ? 'Connection timed out. Is the backend running?'
          : 'Network error. Check your connection.';
    }
    _loading = false; notifyListeners();
    return false;
  }

  // ------------------------------------------------------------------ Register
  Future<bool> register(Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.register(data);
      if (res['success'] == true) {
        final d = res['data'] as Map<String, dynamic>;
        _user = UserModel.fromJson(d['user'] as Map<String, dynamic>);
        await ApiService.saveAuth(
          accessToken:  d['access_token']  as String,
          refreshToken: d['refresh_token'] as String,
          userJson:     jsonEncode(_user!.toJson()),
        );
        _loading = false; notifyListeners();
        return true;
      }
      _error = res['message'] as String? ?? 'Registration failed.';
    } catch (e) {
      _error = e.toString().contains('TimeoutException')
          ? 'Connection timed out. Is the backend running?'
          : 'Network error.';
    }
    _loading = false; notifyListeners();
    return false;
  }

  // ------------------------------------------------------------------ Logout
  Future<void> logout() async {
    await ApiService.clearAuth();
    _user = null;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
