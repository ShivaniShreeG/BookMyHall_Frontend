import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
    if (!mounted) return; // ✅ check mounted
    if (loggedIn) {
      String? name = await AuthService.getName();
      String? role = await AuthService.getRole();
      if (!mounted) return; // ✅ check mounted
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

  /// ✅ Logout with confirmation
  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false, // must choose option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Do you really want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Capture navigator before async gaps
                final navigator = Navigator.of(context);
                navigator.pop(); // close dialog

                await AuthService.logout();
                widget.onLogout();

                if (!mounted) return; // ✅ check mounted

                setState(() {
                  _isLoggedIn = false;
                  _name = "";
                  _role = "";
                });

                navigator.pop(); // close drawer

                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  /// ✅ Navigate to profile page
  void _navigateProfile() {
    final navigator = Navigator.of(context);
    navigator.pop(); // close drawer
    navigator.pushNamed('/profile');
  }

  /// ✅ Single default avatar
  Widget _buildAvatar() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile_avatar.png', // Default profile avatar
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
                      final navigator = Navigator.of(context);
                      navigator.pop(); // close drawer
                      navigator.pushNamed('/login')
                          .then((_) => _checkLoginStatus());
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
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: const Text("Sign out from the app"),
                    onTap: _confirmLogout,
                  ),
                ],
              ],
            ),
          ),

          // ✅ Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "© BookMyHall",
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
