import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/hall_service.dart';
import '../main_navigation.dart';

class HallSelectionPage extends StatefulWidget {
  const HallSelectionPage({super.key});

  @override
  State<HallSelectionPage> createState() => _HallSelectionPageState();
}

class _HallSelectionPageState extends State<HallSelectionPage> {
  List<dynamic> halls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHalls();
  }

  Future<void> _fetchHalls() async {
    try {
      final res = await HallService.getAllHalls();
      if (!mounted) return;

      if (res is List) {
        final hallList = res.map((hall) {
          return {
            'hall_id': hall['hall_id'] is int
                ? hall['hall_id']
                : int.tryParse(hall['hall_id'].toString()) ?? 0,
            'name': hall['name'] ?? '',
            'address': hall['address'] ?? '',
          };
        }).toList();

        setState(() {
          halls = hallList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load halls")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _selectHall(int hallId, String hallName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("hall_id", hallId);       // ✅ fixed key
    await prefs.setString("hall_name", hallName); // ✅ fixed key

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  void _redirectToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Hall"),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: "Login",
            onPressed: _redirectToLogin,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : halls.isEmpty
          ? const Center(child: Text("No halls available"))
          : ListView.builder(
        itemCount: halls.length,
        itemBuilder: (context, index) {
          final hall = halls[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                hall['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(hall['address']),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _selectHall(hall['hall_id'], hall['name']),
            ),
          );
        },
      ),
    );
  }
}
