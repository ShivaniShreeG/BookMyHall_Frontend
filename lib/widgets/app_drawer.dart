import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/public/login.dart';
import '../screens/public/profile.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.onLogout});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;
  String _name = "";
  String _role = "";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ✅ Check login state
  Future<void> _checkLoginStatus() async {
    bool loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      String? name = await AuthService.getName();
      String? role = await AuthService.getRole();
      setState(() {
        _isLoggedIn = true;
        _name = name ?? "";
        _role = role ?? "";
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _name = "";
        _role = "";
      });
    }
  }

  /// ✅ Logout function
  Future<void> _logout() async {
    await AuthService.logout();
    widget.onLogout();
    setState(() {
      _isLoggedIn = false;
      _name = "";
      _role = "";
    });
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  /// ✅ Navigate to profile page
  void _navigateProfile() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  /// ✅ Single default avatar
  Widget _buildAvatar() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile_avatar.png', // ✅ Default profile avatar
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ✅ Custom header with centered content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: _buildAvatar(),
                ),
                const SizedBox(height: 12),
                Text(
                  _isLoggedIn ? _name : "Guest User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _isLoggedIn ? "$_role account" : "Not logged in",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ✅ Drawer items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (!_isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.blue),
                    title: const Text(
                      "Login",
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ).then((_) => _checkLoginStatus());
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: const Text(
                      "Profile",
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: const Text("View your profile"),
                    onTap: _navigateProfile,
                  ),
                  const Divider(thickness: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading:
                    const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: const Text("Sign out from the app"),
                    onTap: _logout,
                  ),
                ],
              ],
            ),
          ),

          // ✅ Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "© 2025 Marriage Hall Booking",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
