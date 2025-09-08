import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class BookingService {
  static final String bookingsBaseUrl = "${AppConfig.baseUrl}/bookings";

  // ✅ Create Booking
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/create");

      bookingData.removeWhere((key, value) => value == null || value == "");

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bookingData),
      );

      if (kDebugMode) {
        print("🌐 Create booking URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 201, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error creating booking: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get All Bookings (Admin)
  static Future<Map<String, dynamic>> getBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/list");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (kDebugMode) {
        print("🌐 Get bookings URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching bookings: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get Single Booking by ID (NEW)
  static Future<Map<String, dynamic>> getBookingById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/$id");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (kDebugMode) {
        print("🌐 Get booking details URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching booking details: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Get All Booking History (Admin)
  static Future<Map<String, dynamic>> getBookingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/history");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (kDebugMode) {
        print("🌐 Get booking history URL: $uri");
        print("📩 Status Code: ${response.statusCode}");
        print("📩 Response Body: ${response.body}");
      }

      final data = jsonDecode(response.body);

      // ✅ Return structured result
      return {
        "success": response.statusCode == 200,
        "status": response.statusCode,
        "data": data,
      };
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching booking history: $e");
      return {
        "success": false,
        "message": "Server error: $e",
      };
    }
  }


  // ✅ Get Booking History for Specific User (NEW)
  static Future<Map<String, dynamic>> getUserBookingHistory(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/history/user/$userId");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (kDebugMode) {
        print("🌐 Get user booking history URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching user booking history: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Update Booking
  static Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> updatedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/update/$id");

      updatedData.removeWhere((key, value) => value == null || value == "");

      final response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updatedData),
      );

      if (kDebugMode) {
        print("🌐 Update booking URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error updating booking: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }

  // ✅ Cancel Booking
  static Future<Map<String, dynamic>> cancelBooking(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final uri = Uri.parse("$bookingsBaseUrl/cancel/$id");

      final response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (kDebugMode) {
        print("🌐 Cancel booking URL: $uri");
        print("📩 Response body: ${response.body}");
      }

      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      if (kDebugMode) print("❌ Error cancelling booking: $e");
      return {"success": false, "message": "Server error: $e"};
    }
  }
}
