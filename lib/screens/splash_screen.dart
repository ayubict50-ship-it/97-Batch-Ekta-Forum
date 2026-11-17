import 'package:flutter/material.dart';
import '../services/cloud_database_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await CloudDatabaseService.loadDataFromCloud().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("Startup Load Error: $e");
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 15),
            Text("ক্লাউড ব্যাকআপ থেকে লোড হচ্ছে...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
