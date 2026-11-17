import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/member.dart';
import 'manager_dashboard.dart';
import 'member_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isAdmin = true;

  void _handleLogin() {
    String inputId = _idController.text.trim();
    String inputPin = _pinController.text.trim();

    if (_isAdmin) {
      if (inputId == globalAdminId && inputPin == globalAdminPassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ভুল ম্যানেজার আইডি বা পাসওয়ার্ড!")),
        );
      }
    } else {
      try {
        Member matchedMember = globalMembers.firstWhere(
          (m) => (m.mobile == inputId || m.id == inputId) && m.pin == inputPin,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemberDashboard(member: matchedMember),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("সঠিক সদস্য আইডি/মোবাইল এবং পিন দিন!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globalSocietyName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, size: 80, color: Colors.green),
                const SizedBox(height: 10),
                Text(
                  globalSocietyName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ToggleButtons(
                  isSelected: [_isAdmin, !_isAdmin],
                  onPressed: (index) {
                    setState(() {
                      _isAdmin = index == 0;
                    });
                  },
                  color: Colors.black,
                  selectedColor: Colors.white,
                  fillColor: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("ম্যানেজার (অ্যাডমিন)", style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("সাধারণ সদস্য", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: _isAdmin ? "ম্যানেজার আইডি" : "সদস্যের মোবাইল বা আইডি",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "পাসওয়ার্ড / পিন",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleLogin,
                    child: const Text("লগইন করুন", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
