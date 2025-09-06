import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_drawer.dart';
import '../widgets/bottom_navbar.dart';
import 'public/home.dart';
import 'public/gallery.dart';
import 'public/facilities.dart';
import 'public/contact.dart';
import 'admin/admin_dashboard.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  List<Widget> _getPages() {
    if (_role == 'admin') {
      return const [
        HomePage(),
        AdminDashboard(),
        Center(child: Text("Managers Page Coming Soon")),
      ];
    } else if (_role == 'manager') {
      return const [
        HomePage(),
        ManagerDashboard(),
        Center(child: Text("Booking Details Coming Soon")),
      ];
    } else {
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
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Hall Booking"),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        onLogout: _handleLogout,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        onTabSelected: _onTabSelected,
        selectedIndex: _selectedIndex,
      ),
    );
  }
}
