import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart'; // যদি থাকে, না থাকলে বাদ দিতে পারেন

import 'constants/app_constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }
  
  runApp(const SamobayApp());
}

class SamobayApp extends StatelessWidget {
  const SamobayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: globalSocietyName,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
