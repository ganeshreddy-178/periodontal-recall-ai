import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  // ------------------------------------------------------------------ Token
  static Future<String?> _token() =>
      _storage.read(key: StorageKeys.accessToken);

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _token();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ------------------------------------------------------------------ Auth
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.me),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.updateProfile),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------ Patients
  static Future<Map<String, dynamic>> getPatients(
      {int page = 1, String q = ''}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.patients)
        .replace(queryParameters: {
      'page': '$page',
      'per_page': '20',
      'q': q,
    });
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createPatient(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.patients),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePatient(
      int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deletePatient(int id) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}$id'),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPatientHistory(int id) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.patients}$id/history'),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------ Predict
  static Future<Map<String, dynamic>> predict({
    required int       patientId,
    required double    plaqueIndex,
    required double    bleedingOnProbing,
    required double    pocketDepth,
    required double    attachmentLoss,
    required double    oralHygieneScore,
    File?              imageFile,
    Uint8List?         webImageBytes,
    String?            webImageName,
  }) async {
    final token = await _token();
    final req   = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.baseUrl + ApiConstants.predict),
    );
    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    req.fields['patient_id']          = '$patientId';
    req.fields['plaque_index']        = '$plaqueIndex';
    req.fields['bleeding_on_probing'] = '$bleedingOnProbing';
    req.fields['pocket_depth']        = '$pocketDepth';
    req.fields['attachment_loss']     = '$attachmentLoss';
    req.fields['oral_hygiene_score']  = '$oralHygieneScore';

    // Attach image — web uses bytes, native uses file path
    if (kIsWeb && webImageBytes != null) {
      final fname = webImageName ?? 'image.jpg';
      req.files.add(http.MultipartFile.fromBytes(
        'image', webImageBytes,
        filename: fname,
      ));
    } else if (!kIsWeb && imageFile != null) {
      req.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamed = await req.send();
    final body     = await streamed.stream.bytesToString();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------ History
  static Future<Map<String, dynamic>> getPredictions({int page = 1}) async {
    final uri = Uri.parse(
            ApiConstants.baseUrl + ApiConstants.predictions)
        .replace(queryParameters: {'page': '$page', 'per_page': '20'});
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getReminders({int page = 1}) async {
    final uri = Uri.parse(
            ApiConstants.baseUrl + ApiConstants.reminders)
        .replace(queryParameters: {'page': '$page', 'per_page': '20'});
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------ Dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.dashboard),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTrends() async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.trends),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------ Forgot Password
  static Future<Map<String, dynamic>> requestOtp(String email) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.requestOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String resetToken, String newPassword) async {
    final res = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email':        email,
        'reset_token':  resetToken,
        'new_password': newPassword,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  static Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.adminStats),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminUsers() async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.adminUsers),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
