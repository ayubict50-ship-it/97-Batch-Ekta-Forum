import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/sms_helper.dart';

class DueReminderDialog extends StatelessWidget {
  final String societyName;
  final List<dynamic> members;

  const DueReminderDialog({
    super.key,
    required this.societyName,
    required this.members,
  });

  Future<void> _sendReminderSms(
    BuildContext context,
    String name,
    String mobile,
    String message,
  ) async {
    await SmsHelper.openDirectSms(
      context: context,
      phoneNumber: mobile,
      message: message,
    );
  }

  String _buildReminderText(String name, double dueAmount, int dueMonthsCount) {
    return "[$societyName]\n"
        "প্রিয় $name,\n"
        "আপনার মাসিক কিস্তির বকেয়া রয়েছে: ৳${dueAmount.toStringAsFixed(2)} ($dueMonthsCount মাস)।\n"
        "অনুগ্রহ করে দ্রুত বকেয়া পরিশোধ করার জন্য অনুরোধ করা হলো।\n"
        "ধন্যবাদ।";
  }

  @override
  Widget build(BuildContext context) {
    final dueMembers = members
        .where((m) => ((m.dueAmount as num?)?.toDouble() ?? 0.0) > 0)
        .toList();
    final double totalDueAmount = dueMembers.fold(
      0.0,
      (sum, m) => sum + (((m.dueAmount as num?)?.toDouble() ?? 0.0)),
    );

    return AlertDialog(
      title: const Text("📢 বকেয়া রিমাইন্ডার ও নোটিশ"),
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
                "মোট বকেয়া সদস্য: ${dueMembers.length} জন | মোট বকেয়া: ৳${totalDueAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (dueMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text("বর্তমানে কোনো সদস্যের বকেয়া নেই।"),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dueMembers.length,
                  itemBuilder: (context, index) {
                    final m = dueMembers[index];
                    final String name = m.name.toString();
                    final String id = m.id.toString();
                    final String mobile = m.mobile.toString();
                    final double dueAmount =
                        ((m.dueAmount as num?)?.toDouble() ?? 0.0);
                    final int dueMonthsCount =
                        ((m.dueMonthsCount as num?)?.toInt() ?? 0);
                    final reminderText = _buildReminderText(
                      name,
                      dueAmount,
                      dueMonthsCount,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$name (ID: $id)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text("মোবাইল: $mobile"),
                            Text(
                              "বকেয়া: ৳${dueAmount.toStringAsFixed(2)} ($dueMonthsCount মাস)",
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
                                            "$name-এর নোটিশ কপি হয়েছে!",
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
                                    name,
                                    mobile,
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
