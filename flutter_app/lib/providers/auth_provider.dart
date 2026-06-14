import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

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

  Future<void> tryAutoLogin() async {
    final token  = await _storage.read(key: StorageKeys.accessToken);
    final stored = await _storage.read(key: StorageKeys.userJson);
    if (token != null && stored != null) {
      _user = UserModel.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await _storage.write(key: StorageKeys.accessToken,  value: data['access_token']  as String);
        await _storage.write(key: StorageKeys.refreshToken, value: data['refresh_token'] as String);
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.write(key: StorageKeys.userJson, value: jsonEncode(_user!.toJson()));
        _loading = false; notifyListeners();
        return true;
      }
      _error = res['message'] as String? ?? 'Login failed.';
    } catch (_) {
      _error = 'Network error. Check your connection.';
    }
    _loading = false; notifyListeners();
    return false;
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.register(data);
      if (res['success'] == true) {
        final d = res['data'] as Map<String, dynamic>;
        await _storage.write(key: StorageKeys.accessToken,  value: d['access_token']  as String);
        await _storage.write(key: StorageKeys.refreshToken, value: d['refresh_token'] as String);
        _user = UserModel.fromJson(d['user'] as Map<String, dynamic>);
        await _storage.write(key: StorageKeys.userJson, value: jsonEncode(_user!.toJson()));
        _loading = false; notifyListeners();
        return true;
      }
      _error = res['message'] as String? ?? 'Registration failed.';
    } catch (_) {
      _error = 'Network error.';
    }
    _loading = false; notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _user = null;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
