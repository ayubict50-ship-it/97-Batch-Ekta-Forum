import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import '../constants/app_constants.dart';

Future<void> saveReportToFile(BuildContext context, String fileName, String content) async {
  try {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.hindSiliguriRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(globalSocietyName, style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(content, style: pw.TextStyle(font: ttf, fontSize: 12)),
            ],
          );
        },
      ),
    );

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final String actualFileName = fileName.endsWith('.pdf') ? fileName : '${fileName.replaceAll(RegExp(r'\.+$'), '')}.pdf';
    final File file = File('${directory?.path}/$actualFileName');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF ফাইল ডাউনলোড ফোল্ডারে সেভ হয়েছে:\n${file.path}')),
      );
    }

    await OpenFile.open(file.path);
  } catch (e) {
    debugPrint("PDF Save Error: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF সেভ করতে সমস্যা হয়েছে: $e')),
      );
    }
  }
}
