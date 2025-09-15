import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class HallService {
  static const String hallUrl = "${AppConfig.baseUrl}/halls";

  // 📌 Get all halls
  static Future<dynamic> getAllHalls() async {
    try {
      final res = await http.get(Uri.parse(hallUrl));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"success": false, "message": "Failed to load halls"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 📌 Get hall by ID
  static Future<dynamic> getHallById(int id) async {
    try {
      final res = await http.get(Uri.parse("$hallUrl/$id"));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"success": false, "message": "Hall not found"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 📌 Add hall
  static Future<dynamic> addHall(Map<String, dynamic> hall) async {
    try {
      final res = await http.post(
        Uri.parse(hallUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(hall),
      );
      if (res.statusCode == 201) {
        return json.decode(res.body);
      } else {
        return {"success": false, "message": "Failed to add hall"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 📌 Update hall
  static Future<dynamic> updateHall(int id, Map<String, dynamic> hall) async {
    try {
      final res = await http.put(
        Uri.parse("$hallUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(hall),
      );
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"success": false, "message": "Failed to update hall"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 📌 Delete hall
  static Future<dynamic> deleteHall(int id) async {
    try {
      final res = await http.delete(Uri.parse("$hallUrl/$id"));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"success": false, "message": "Failed to delete hall"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
