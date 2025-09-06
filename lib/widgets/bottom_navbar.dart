import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int) onTabSelected;
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    required this.onTabSelected,
    required this.selectedIndex,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String _role = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
    });
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_role == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manage'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Details'),
      ];
    } else if (_role == 'manager') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Details'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Gallery'),
        BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Facilities'),
        BottomNavigationBarItem(icon: Icon(Icons.contact_phone), label: 'Contact'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: widget.onTabSelected,
      items: _getNavItems(),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    );
  }
}
