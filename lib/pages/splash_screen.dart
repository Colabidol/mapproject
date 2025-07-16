import 'package:flutter/material.dart';
import 'record.dart'; // import your main page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    // Simulate some loading process like:
    // - Database initialization
    // - Permissions check
    // - Reading settings
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading delay

    // Navigate to main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Recording()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map, size: 100, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text("Loading TakeAFish...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            )
          ],
        ),
      ),
    );
  }
}