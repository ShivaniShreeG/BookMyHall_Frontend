import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _role = '';
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ✅ Check if user is logged in
  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn(); // implement in AuthService
    if (!loggedIn) {
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    } else {
      setState(() {
        _isLoggedIn = true;
      });
      await _loadUserData();
    }
    setState(() {
      _loading = false;
    });
  }

  /// ✅ Load user data from AuthService
  Future<void> _loadUserData() async {
    final name = await AuthService.getName();
    final email = await AuthService.getEmail();
    final phone = await AuthService.getPhone();
    final role = await AuthService.getRole();

    setState(() {
      _name = name ?? 'N/A';
      _email = email ?? 'N/A';
      _phone = phone ?? 'N/A';
      _role = role ?? 'N/A';
    });
  }

  /// ✅ Reusable profile info card
  Widget _buildProfileCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      // While redirecting, show empty scaffold
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ✅ Profile Avatar
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/profile_avatar.png', // default avatar
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Name
            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // ✅ Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _role.toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Profile Info Cards
            _buildProfileCard("Email", _email, Icons.email),
            _buildProfileCard("Phone", _phone, Icons.phone),
            _buildProfileCard("Role", _role, Icons.security),

            const SizedBox(height: 24),

            // ✅ Info Note
            const Text(
              "Your profile information cannot be edited.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
