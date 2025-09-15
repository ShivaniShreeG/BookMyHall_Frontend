import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class BookingService {
  static final String bookingsBaseUrl = "${AppConfig.baseUrl}/bookings";

  // 🔑 Helper: Get auth headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ✅ Create Booking
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/create");
      bookingData.removeWhere((key, value) => value == null || value == "");

      final response = await http.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(bookingData),
      );

      if (kDebugMode) {
        print("🌐 Create booking: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 201, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Create booking error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get Bookings for a Hall (hall_id is required)
  static Future<Map<String, dynamic>> getBookings(int hallId) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/hall/$hallId");

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (kDebugMode) {
        print("🌐 Get bookings: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Get bookings error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get Single Booking by ID
  static Future<Map<String, dynamic>> getBookingById(int id) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/$id");

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (kDebugMode) {
        print("🌐 Get booking by ID: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Get booking by ID error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get All Booking History (Admin)
  static Future<Map<String, dynamic>> getBookingHistory({int? hallId}) async {
    try {
      String url = "$bookingsBaseUrl/history";
      if (hallId != null) {
        url += "?hall_id=$hallId";
      }

      final uri = Uri.parse(url);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (kDebugMode) {
        print("🌐 Get booking history: $uri");
        print("📩 Status: ${response.statusCode}");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {
        "success": response.statusCode == 200,
        "status": response.statusCode,
        "data": data,
      };
    } catch (e) {
      if (kDebugMode) print("❌ Get booking history error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get Booking History for Specific User
  static Future<Map<String, dynamic>> getUserBookingHistory(int userId) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/history/user/$userId");

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (kDebugMode) {
        print("🌐 Get user booking history: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Get user booking history error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Update Booking
  static Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> updatedData) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/update/$id");
      updatedData.removeWhere((key, value) => value == null || value == "");

      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(updatedData),
      );

      if (kDebugMode) {
        print("🌐 Update booking: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Update booking error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Cancel Booking
  static Future<Map<String, dynamic>> cancelBooking(int id, {String? notes}) async {
    try {
      final uri = Uri.parse("$bookingsBaseUrl/cancel/$id");

      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode({"notes": notes ?? "Booking cancelled"}),
      );

      if (kDebugMode) {
        print("🌐 Cancel booking: $uri");
        print("📩 Response: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Cancel booking error: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }
}
