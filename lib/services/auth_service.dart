import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ For kDebugMode
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // <-- Import base URL

class AuthService {
  static const String baseUrl = "${AppConfig.baseUrl}/auth";

  /// Login method (now requires hall_id)
  static Future<Map<String, dynamic>> login(
      String email, String password, String role, int hallId) async {
    try {
      final uri = Uri.parse("$baseUrl/login");

      if (kDebugMode) {
        print("🌐 Sending login request to $uri with email=$email, role=$role, hallId=$hallId");
      }

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
          "hall_id": hallId,   // ✅ Send hall_id
        }),
      );

      if (kDebugMode) {
        print("📩 Response status: ${response.statusCode}");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();

        // ✅ Save token and user details in SharedPreferences
        await prefs.setString("token", data['token']);
        await prefs.setString("userId", data['user']['id'].toString());
        await prefs.setString("name", data['user']['name']);
        await prefs.setString("email", data['user']['email']);
        await prefs.setString("phone", data['user']['phone'] ?? "");
        await prefs.setString("role", data['user']['role']);
        await prefs.setInt("hall_id", data['user']['hall_id']); // ✅ Save as int
        await prefs.setBool("isLoggedIn", true);

        return {
          "success": true,
          "token": data['token'],
          "user": data['user'],
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Invalid credentials"
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Exception during login: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  /// Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedIn") ?? false;
  }

  /// Get stored values
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("name");
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("email");
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("phone");
  }

  static Future<int?> getHallId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("hall_id"); // ✅ Read as int
  }
}
