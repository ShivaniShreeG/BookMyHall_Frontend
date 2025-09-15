import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_drawer.dart';
import '../widgets/bottom_navbar.dart';
import 'public/home.dart';
import 'public/gallery.dart';
import 'public/facilities.dart';
import 'public/contact.dart';
import 'public/hall_selection_page.dart'; // Hall selection page
import 'admin/admin_dashboard.dart';
import 'admin/admin_booking_history_page.dart';
import 'manager/manager_dashboard.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String _role = '';
  bool _isLoggedIn = false;
  int? _selectedHallId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final selectedHallId = prefs.getInt('hall_id'); // ✅ fixed key to match AuthService

    setState(() {
      _role = prefs.getString('role') ?? '';
      _isLoggedIn = isLoggedIn;
      _selectedHallId = selectedHallId;
    });

    // Redirect to hall selection if hall not selected
    if (selectedHallId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HallSelectionPage()),
        );
      });
    }
  }

  List<Widget> _getPages() {
    // If hall not selected, show a placeholder
    if (_selectedHallId == null) {
      return [
        const Center(
          child: Text(
            "Please select a hall first",
            style: TextStyle(fontSize: 18),
          ),
        )
      ];
    }

    // Logged-in users
    if (_role == 'admin') {
      return const [
        HomePage(),
        AdminDashboard(),
        AdminBookingHistoryPage(),
      ];
    } else if (_role == 'manager') {
      return const [
        HomePage(),
        ManagerDashboard(),
        Center(child: Text("Booking Details Coming Soon")),
      ];
    } else {
      // Guest or regular user
      return const [
        HomePage(),
        GalleryPage(),
        FacilitiesPage(),
        ContactPage(),
      ];
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _role = '';
      _isLoggedIn = false;
      _selectedHallId = null;
      _selectedIndex = 0;
    });

    // Redirect to hall selection page after logout
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HallSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Hall Booking"),
        centerTitle: true,
      ),
      drawer: (_selectedHallId != null) ? AppDrawer(onLogout: _handleLogout) : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: (_selectedHallId != null)
          ? BottomNavBar(onTabSelected: _onTabSelected, selectedIndex: _selectedIndex)
          : null,
    );
  }
}
