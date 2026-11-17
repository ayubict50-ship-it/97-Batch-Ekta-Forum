import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/member.dart';
import '../services/pdf_service.dart';
import 'login_screen.dart';

class MemberDashboard extends StatelessWidget {
  final Member member;
  const MemberDashboard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${member.name} - ড্যাশবোর্ড'),
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
                    Text("সদস্যের নাম: ${member.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("আইডি: ${member.id}"),
                    Text("মোবাইল: ${member.mobile}"),
                    Text("পেশা: ${member.profession}"),
                    Text("ঠিকানা: ${member.address}"),
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
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("আমার তথ্য PDF ডাউনলোড করুন", style: TextStyle(fontSize: 16)),
              onPressed: () {
                String reportContent = "সদস্যের নাম: ${member.name}\nআইডি: ${member.id}\nমোবাইল: ${member.mobile}\nপেশা: ${member.profession}\nঠিকানা: ${member.address}";
                saveReportToFile(context, 'Member_${member.id}_Report.pdf', reportContent);
              },
            ),
          ],
        ),
      ),
    );
  }
}
