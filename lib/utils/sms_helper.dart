import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsHelper {
  /// সরাসরি ডিফল্ট SMS অ্যাপ ওপেন করে (নম্বর + মেসেজ বডিসহ)
  static Future<void> openDirectSms({
    required BuildContext context,
    required String phoneNumber,
    required String message,
  }) async {
    final String cleanPhone =
        phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '').trim();

    if (cleanPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সদস্যের সঠিক মোবাইল নম্বর পাওয়া যায়নি।')),
        );
      }
      return;
    }

    final String encodedBody = Uri.encodeComponent(message);
    final Uri smsToUri = Uri.parse(
      message.trim().isNotEmpty
          ? 'smsto:$cleanPhone?body=$encodedBody'
          : 'smsto:$cleanPhone',
    );

    try {
      final bool launched = await launchUrl(
        smsToUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS অ্যাপ ওপেন হয়নি। মেসেজটি ক্লিপবোর্ডে কপি করা হয়েছে।',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS অ্যাপ ওপেন হয়নি। মেসেজটি ক্লিপবোর্ডে কপি করা হয়েছে।',
            ),
          ),
        );
      }
    }
  }
}
