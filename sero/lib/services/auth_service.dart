import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

// Use localhost for Web/Desktop, 10.0.2.2 for Android Emulator
final String kBaseUrl = (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
    ? 'http://localhost:3000'
    : 'http://10.0.2.2:3000';

class AuthService {
  // ─── Register (resident) ──────────────────────────────────────────────────
  // Returns a success message string, or throws an error string.
  static Future<String> register({
    required String name,
    required String phone,
    required String password,
    required String flatNumber,
    String? blockName,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        'flatNumber': flatNumber,
        'blockName': blockName ?? '',
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['message'];
    } else {
      throw data['error'] ?? 'Registration failed';
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  // For residents : phone = phone number, password = their password
  // For admin     : phone = "admin",      password = "123123"
  // Saves token + user to SharedPreferences on success.
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));
      return data;
    } else if (response.statusCode == 403) {
      // pending or rejected — throw map so UI can show specific message
      throw {'error': data['error'], 'status': data['status']};
    } else {
      throw data['error'] ?? 'Login failed';
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ─── Token helper ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ─── Saved user helper ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  // ─── Role helper ──────────────────────────────────────────────────────────
  static Future<String> getRole() async {
    final user = await getSavedUser();
    return user?['role'] ?? 'resident';
  }

  // ─── Is logged in ─────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ─── Auth header helper ───────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Get my notifications ─────────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$kBaseUrl/auth/notifications'),
      headers: await authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['notifications'];
    throw data['error'] ?? 'Failed to load notifications';
  }
}
