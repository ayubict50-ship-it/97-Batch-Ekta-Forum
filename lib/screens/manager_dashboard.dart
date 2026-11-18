import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/member.dart';
import '../services/cloud_database_service.dart';
import '../services/pdf_service.dart';
import 'login_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _isLoading = false;

  Future<void> _syncToCloud() async {
    setState(() { _isLoading = true; });
    try {
      await CloudDatabaseService.syncAllDataToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("সফলভাবে ক্লাউডে ডেটা সিঙ্ক করা হয়েছে!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("সিঙ্ক করতে সমস্যা হয়েছে: $e")),
        );
      }
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$globalSocietyName - ম্যানেজার প্যানেল'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("মোট সদস্য সংখ্যা: ${globalMembers.length} জন", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("সোসাইটি: $globalSocietyName"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.cloud_upload),
              label: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("ক্লাউডে সমস্ত ডেটা সিঙ্ক করুন", style: TextStyle(fontSize: 16)),
              onPressed: _isLoading ? null : _syncToCloud,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("সকল সদস্যের তালিকা PDF ডাউনলোড", style: TextStyle(fontSize: 16)),
              onPressed: () {
                String reportContent = globalMembers.map((m) => "নাম: ${m.name}, আইডি: ${m.id}, মোবাইল: ${m.mobile}, পেশা: ${m.profession}").join("\n\n");
                saveReportToFile(context, 'All_Members_Report.pdf', 'সকল সদস্যের তালিকা:\n\n$reportContent');
              },
            ),
          ],
        ),
      ),
    );
  }
}
