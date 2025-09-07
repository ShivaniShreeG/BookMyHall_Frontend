import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation.dart';
import 'screens/public/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw under system bars (edge-to-edge)…
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // …but make them transparent and readable.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marriage Hall Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // Wrap ALL routes in SafeArea so content won't be hidden by system bars.
      builder: (context, child) => SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: child ?? const SizedBox.shrink(),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigation(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
