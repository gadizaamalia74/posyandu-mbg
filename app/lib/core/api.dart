import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Klien HTTP ke backend (folder backend/). Alamat server bisa diubah dari layar login.
class Api {
  // Emulator Android -> 10.0.2.2 ; HP asli -> IP komputer, mis. http://192.168.1.10:8080
  static String baseUrl = 'https://posyandu-mbg-production.up.railway.app';
  static String? token;
  static String type = ''; // 'staff' | 'ibu'
  static Map<String, dynamic> user = {};
  static final ValueNotifier<bool> loggedIn = ValueNotifier(false);

  static bool get isIbu => type == 'ibu';
  static bool get isAdmin => user['role'] == 'admin';

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    baseUrl = p.getString('baseUrl') ?? baseUrl;
    token = p.getString('token');
    type = p.getString('type') ?? '';
    final u = p.getString('user');
    if (u != null) user = jsonDecode(u) as Map<String, dynamic>;
    loggedIn.value = token != null && type.isNotEmpty;
  }

  static Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString('baseUrl', baseUrl);
  }

  static Future<void> _saveSession() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token ?? '');
    await p.setString('type', type);
    await p.setString('user', jsonEncode(user));
  }

  static Future<void> clearSession() async {
    token = null;
    type = '';
    user = {};
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('type');
    await p.remove('user');
    loggedIn.value = false;
  }

  static Future<void> loginStaff(String nk, String password) async {
    final r = await post('/api/auth/login', {'nk': nk, 'password': password}, auth: false);
    await _applyLogin(r);
  }

  static Future<void> loginIbu(String email, String password) async {
    final r = await post('/api/auth/login-ibu', {'email': email, 'password': password}, auth: false);
    await _applyLogin(r);
  }

  static Future<void> _applyLogin(dynamic r) async {
    token = r['token'] as String;
    type = r['type'] as String;
    user = Map<String, dynamic>.from(r['user'] as Map);
    await _saveSession();
    loggedIn.value = true;
  }

  static Future<void> logout() async {
    try {
      await post('/api/auth/logout', {});
    } catch (_) {}
    await clearSession();
  }

  static Future<dynamic> get(String path, [Map<String, String>? q]) => _send('GET', path, null, q: q);
  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) =>
      _send('POST', path, body, auth: auth);
  static Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body);
  static Future<dynamic> delete(String path) => _send('DELETE', path, null);

  static Future<dynamic> _send(String method, String path, Map<String, dynamic>? body,
      {Map<String, String>? q, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: q);
    final headers = <String, String>{'content-type': 'application/json'};
    if (auth && token != null) headers['authorization'] = 'Bearer $token';
    try {
      late http.Response res;
      final enc = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
        case 'POST':
          res = await http.post(uri, headers: headers, body: enc).timeout(const Duration(seconds: 15));
        case 'PUT':
          res = await http.put(uri, headers: headers, body: enc).timeout(const Duration(seconds: 15));
        default:
          res = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      }
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? null : jsonDecode(text);
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      if (res.statusCode == 401 && auth) await clearSession();
      final msg = data is Map && data['error'] != null ? data['error'].toString() : 'Error ${res.statusCode}';
      throw ApiException(msg, res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server ($baseUrl). Periksa alamat server & koneksi.');
    }
  }
}
