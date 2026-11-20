import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class DueReminderDialog extends StatelessWidget {
  const DueReminderDialog({super.key});

  Future<void> _sendReminderSms(
    BuildContext context,
    Member member,
    String message,
  ) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: member.mobile,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${member.name}-এর রিমাইন্ডার কপি হয়েছে। SMS অ্যাপ খুলে পেস্ট করুন।",
              ),
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("রিমাইন্ডার মেসেজটি ক্লিপবোর্ডে কপি করা হয়েছে।"),
          ),
        );
      }
    }
  }

  String _buildReminderText(Member member) {
    return "[$globalSocietyName]\n"
        "প্রিয় ${member.name},\n"
        "আপনার মাসিক কিস্তির বকেয়া রয়েছে: ৳${member.dueAmount.toStringAsFixed(2)} (${member.dueMonthsCount} মাস)।\n"
        "অনুগ্রহ করে দ্রুত বকেয়া পরিশোধ করার জন্য অনুরোধ করা হলো।\n"
        "ধন্যবাদ।";
  }

  @override
  Widget build(BuildContext context) {
    final dueMembers = globalMembers.where((m) => m.dueAmount > 0).toList();
    final double totalDueAmount =
        dueMembers.fold(0.0, (sum, m) => sum + m.dueAmount);

    return AlertDialog(
      title: const Text("📢 বকেয়া রিমাইন্ডার ও নোটিশ"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                "মোট বকেয়া সদস্য: ${dueMembers.length} জন | মোট বকেয়া: ৳${totalDueAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBoxhip(height: 10),
            if (dueMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text("বর্তমানে কোনো সদস্যের বকেয়া নেই।"),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dueMembers.length,
                  itemBuilder: (context, index) {
                    final m = dueMembers[index];
                    final reminderText = _buildReminderText(m);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${m.name} (ID: ${m.id})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text("মোবাইল: ${m.mobile}"),
                            Text(
                              "বকেয়া: ৳${m.dueAmount.toStringAsFixed(2)} (${m.dueMonthsCount} মাস)",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: reminderText),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${m.name}-এর নোটিশ কপি হয়েছে!",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 15),
                                  label: const Text(
                                    "কপি",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _sendReminderSms(
                                    context,
                                    m,
                                    reminderText,
                                  ),
                                  icon: const Icon(Icons.sms, size: 15),
                                  label: const Text(
                                    "SMS পাঠান",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("বন্ধ করুন"),
        ),
      ],
    );
  }
}
