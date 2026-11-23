import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'main.dart';

class PdfReportGenerator {
  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _fileSafeDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _savePdfBytes(
    BuildContext context,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String cleanName = fileName.endsWith('.pdf')
          ? fileName
          : '${fileName.replaceAll(RegExp(r'\.+$'), '')}.pdf';
      final File file = File('${directory!.path}/$cleanName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF সেভ হয়েছে:\n${file.path}')),
        );
      }
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('PDF Save Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF সেভ করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  static Future<void> _renderWidgetToMultiPagePdf(
    BuildContext context,
    Widget contentWidget,
    String fileName,
  ) async {
    try {
      final GlobalKey key = GlobalKey();
      final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true) ??
          Overlay.maybeOf(context);

      if (overlay == null) {
        await _fallbackSimplePdf(context, fileName);
        return;
      }

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => Positioned(
          left: -10000,
          top: 0,
          child: Material(
            color: Colors.white,
            child: SizedBox(
              width: 794,
              child: RepaintBoundary(
                key: key,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: contentWidget,
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 120));

      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        entry.remove();
        await _fallbackSimplePdf(context, fileName);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      entry.remove();

      if (byteData == null) {
        throw Exception('PNG conversion failed');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image decodedImage = frameInfo.image;

      final int totalWidth = decodedImage.width;
      final int totalHeight = decodedImage.height;

      final pw.Document pdf = pw.Document();
      final double printableWidthPt = PdfPageFormat.a4.availableWidth;
      final double printableHeightPt = PdfPageFormat.a4.availableHeight - 24;
      final double scalePtPerPx = printableWidthPt / totalWidth;
      final int sliceHeightPx =
          (printableHeightPt / scalePtPerPx).round().clamp(1, totalHeight);

      final List<pw.MemoryImage> pages = [];
      int currentY = 0;

      while (currentY < totalHeight) {
        final int sliceH = (currentY + sliceHeightPx > totalHeight)
            ? (totalHeight - currentY)
            : sliceHeightPx;

        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);

        canvas.drawImageRect(
          decodedImage,
          Rect.fromLTWH(
              0, currentY.toDouble(), totalWidth.toDouble(), sliceH.toDouble()),
          Rect.fromLTWH(0, 0, totalWidth.toDouble(), sliceH.toDouble()),
          Paint(),
        );

        final ui.Image pageImg =
            await recorder.endRecording().toImage(totalWidth, sliceH);
        final ByteData? pageBytes =
            await pageImg.toByteData(format: ui.ImageByteFormat.png);
        if (pageBytes != null) {
          pages.add(pw.MemoryImage(pageBytes.buffer.asUint8List()));
        }
        pageImg.dispose();
        currentY += sliceH;
      }

      decodedImage.dispose();

      final int totalPages = pages.isEmpty ? 1 : pages.length;
      for (int i = 0; i < pages.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.topCenter,
                    child: pw.Image(pages[i], fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Page ${i + 1} of $totalPages | Printed: ${_formatDate(DateTime.now())}',
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final Uint8List pdfBytes = await pdf.save();
      if (context.mounted) {
        await _savePdfBytes(context, pdfBytes, fileName);
      }
    } catch (e) {
      debugPrint('Render PDF Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF তৈরি করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  static Future<void> _fallbackSimplePdf(
      BuildContext context, String fileName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Center(
          child: pw.Text('Report Generated: ${_formatDate(DateTime.now())}'),
        ),
      ),
    );
    await _savePdfBytes(context, await pdf.save(), fileName);
  }

  static Widget _headerBlock(
      String societyName, String title, String subtitle) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.green, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            societyName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> generateAllMembersReport(
    BuildContext context,
    String societyName,
    List<Member> members,
  ) async {
    double totalDep = members.fold(0.0, (s, m) => s + m.deposit);
    double totalProf = members.fold(0.0, (s, m) => s + m.profitEarned);
    double totalBal = members.fold(0.0, (s, m) => s + m.totalBalance);
    double totalDue = members.fold(0.0, (s, m) => s + m.dueAmount);

    final widget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(
          societyName,
          'সকল সদস্যের সার্বিক স্টেটমেন্ট',
          'মোট সদস্য: ${members.length} জন | মোট সঞ্চয়: ৳${totalDep.toStringAsFixed(2)} | মোট বকেয়া: ৳${totalDue.toStringAsFixed(2)}',
        ),
        Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(46),
            1: FlexColumnWidth(2.2),
            2: FlexColumnWidth(1.6),
            3: FlexColumnWidth(1.4),
            4: FlexColumnWidth(1.3),
            5: FlexColumnWidth(1.5),
            6: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.green.shade800),
              children: const [
                Padding(padding: EdgeInsets.all(6), child: Text('ID', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('সদস্যের নাম', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('মোবাইল', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('মূল জমা', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('অর্জিত লাভ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('মোট ব্যালেন্স', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(6), child: Text('বকেয়া / অগ্রিম', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            ...members.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final String dueAdv = m.dueAmount > 0
                  ? 'বকেয়া: ৳${m.dueAmount.toStringAsFixed(0)} (${m.dueMonthsCount} মা.)'
                  : (m.advanceAmount > 0 ? 'অগ্রিম: ৳${m.advanceAmount.toStringAsFixed(0)}' : '৳0.00');

              return TableRow(
                decoration: BoxDecoration(color: idx % 2 == 1 ? Colors.grey.shade100 : Colors.white),
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(m.id, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(m.mobile, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('৳${m.deposit.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('৳${m.profitEarned.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.blue))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('৳${m.totalBalance.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(dueAdv, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: m.dueAmount > 0 ? Colors.red : Colors.teal, fontWeight: FontWeight.bold))),
                ],
              );
            }),
            TableRow(
              decoration: BoxDecoration(color: Colors.green.shade50),
              children: [
                const Padding(padding: EdgeInsets.all(6), child: Text('')),
                const Padding(padding: EdgeInsets.all(6), child: Text('সর্বমোট হিসাব', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Padding(padding: EdgeInsets.all(6), child: Text('')),
                Padding(padding: const EdgeInsets.all(6), child: Text('৳${totalDep.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(6), child: Text('৳${totalProf.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue))),
                Padding(padding: const EdgeInsets.all(6), child: Text('৳${totalBal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
                Padding(padding: const EdgeInsets.all(6), child: Text('৳${totalDue.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))),
              ],
            ),
          ],
        ),
      ],
    );

    await _renderWidgetToMultiPagePdf(context, widget, 'All_Members_Report.pdf');
  }

  static Future<void> generateSingleMemberStatement(
    BuildContext context,
    String societyName,
    Member member,
  ) async {
    final String statusText = member.dueAmount > 0
        ? 'বকেয়া: ৳${member.dueAmount.toStringAsFixed(2)} (${member.dueMonthsCount} মাস)'
        : (member.advanceAmount > 0 ? 'অতিরিক্ত জমা: ৳${member.advanceAmount.toStringAsFixed(2)}' : 'বকেয়া: ৳0.00 (পরিশোধিত)');

    final widget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(
          societyName,
          'সদস্যের ব্যক্তিগত হিসাব বিবরণী',
          'নাম: ${member.name} | আইডি: ${member.id} | মোবাইল: ${member.mobile}',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• মূল সঞ্চয় (কিস্তি জমা): ৳${member.deposit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('• অর্জিত মোট লাভ: ৳${member.profitEarned.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('• সর্বমোট ব্যালেন্স: ৳${member.totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('• $statusText', style: TextStyle(fontSize: 13, color: member.dueAmount > 0 ? Colors.red : Colors.teal, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (member.transactions.isEmpty)
          const Text('কোনো লেনদেন রেকর্ড নেই।', style: TextStyle(fontSize: 13))
        else
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(42),
              1: FixedColumnWidth(90),
              2: FlexColumnWidth(2.4),
              3: FlexColumnWidth(1.4),
              4: FlexColumnWidth(1.4),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade800),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('ক্রম', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('তারিখ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('বিবরণ / মাধ্যম', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('TrxID / স্ট্যাটাস', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('টাকার পরিমাণ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...member.transactions.asMap().entries.map((entry) {
                final idx = entry.key;
                final tx = entry.value;
                return TableRow(
                  decoration: BoxDecoration(color: idx % 2 == 1 ? Colors.grey.shade100 : Colors.white),
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_formatDate(tx.date), style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(tx.paymentMethod, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(tx.trxId.isNotEmpty ? '${tx.trxId} (${tx.status})' : tx.status, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('৳${tx.amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: tx.isProfit ? Colors.blue : Colors.green, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),
      ],
    );

    await _renderWidgetToMultiPagePdf(context, widget, 'Member_${member.name}_Statement.pdf');
  }

  static Future<void> generateBusinessLedgerReport(
    BuildContext context,
    String societyName,
    List<BusinessRecord> records,
    double currentIncome,
    double currentExpense,
    double currentNetProfit,
  ) async {
    final widget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(
          societyName,
          'ব্যবসার লাভ-ক্ষতি খতিয়ান ও রিপোর্ট',
          'চলমান মুনাফা: ৳${currentIncome.toStringAsFixed(2)} | চলমান খরচ: ৳${currentExpense.toStringAsFixed(2)} | নিট লাভ: ৳${currentNetProfit.toStringAsFixed(2)}',
        ),
        if (records.isEmpty)
          const Text('কোনো ব্যবসায়িক পোস্টিং নেই।', style: TextStyle(fontSize: 13))
        else
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(42),
              1: FixedColumnWidth(90),
              2: FlexColumnWidth(2.6),
              3: FlexColumnWidth(1.1),
              4: FlexColumnWidth(1.1),
              5: FlexColumnWidth(1.4),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade800),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('ক্রম', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('তারিখ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('বিবরণ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('ধরন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('অবস্থা', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('টাকার পরিমাণ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...records.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                return TableRow(
                  decoration: BoxDecoration(color: idx % 2 == 1 ? Colors.grey.shade100 : Colors.white),
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_formatDate(r.date), style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(r.title, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(r.isIncome ? 'লাভ (+)' : 'খরচ (-)', style: TextStyle(fontSize: 12, color: r.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(r.isSettled ? 'বণ্টনকৃত' : 'চলমান', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('${r.isIncome ? '+' : '-'}৳${r.amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: r.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),
      ],
    );

    await _renderWidgetToMultiPagePdf(
      context,
      widget,
      'Business_Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateMonthlyReport({
    required BuildContext context,
    required String societyName,
    required String monthLabel,
    required int selectedMonth,
    required int selectedYear,
    required double monthlyDepositTotal,
    required int monthlyDepositCount,
    required double monthlyProfitTotal,
    required double monthlyBizIncome,
    required double monthlyBizExpense,
    required List<dynamic> memberMonthEntries,
    required List<BusinessRecord> monthBizRecords,
  }) async {
    final widget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(
          societyName,
          'মাসিক আয়-ব্যয় ও জমা রিপোর্ট — $monthLabel',
          'কিস্তি জমা: ৳${monthlyDepositTotal.toStringAsFixed(2)} ($monthlyDepositCountটি) | লাভ বণ্টন: ৳${monthlyProfitTotal.toStringAsFixed(2)}',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border.all(color: Colors.teal.shade200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• মোট কিস্তি জমা: ৳${monthlyDepositTotal.toStringAsFixed(2)} ($monthlyDepositCountটি)', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('• মোট লাভ বণ্টন: ৳${monthlyProfitTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('• ব্যবসায়িক আয়: ৳${monthlyBizIncome.toStringAsFixed(2)} | প্রজেক্ট খরচ: ৳${monthlyBizExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const Text('১. সদস্যদের লেনদেনসমূহ:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (memberMonthEntries.isEmpty)
          const Text('এই মাসে কোনো সদস্যের লেনদেন নেই।', style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(42),
              1: FixedColumnWidth(90),
              2: FlexColumnWidth(2.2),
              3: FlexColumnWidth(1.6),
              4: FlexColumnWidth(1.3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade800),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('ক্রম', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('তারিখ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('সদস্য (ID)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('মাধ্যম / ধরন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('টাকার পরিমাণ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...memberMonthEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final Member m = entry.value['member'];
                final TransactionHistory t = entry.value['tx'];
                return TableRow(
                  decoration: BoxDecoration(color: idx % 2 == 1 ? Colors.grey.shade100 : Colors.white),
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_formatDate(t.date), style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('${m.name} (${m.id})', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(t.isProfit ? 'লাভ বণ্টন' : t.paymentMethod, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('৳${t.amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),
        const SizedBox(height: 14),
        const Text('২. ব্যবসার আয়-ব্যয় পোস্টিং:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (monthBizRecords.isEmpty)
          const Text('এই মাসে কোনো ব্যবসায়িক পোস্টিং নেই।', style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(42),
              1: FixedColumnWidth(90),
              2: FlexColumnWidth(2.6),
              3: FlexColumnWidth(1.4),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.teal.shade800),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('ক্রম', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('তারিখ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('বিবরণ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6), child: Text('টাকার পরিমাণ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...monthBizRecords.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                return TableRow(
                  decoration: BoxDecoration(color: idx % 2 == 1 ? Colors.grey.shade100 : Colors.white),
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_formatDate(r.date), style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(r.title, style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('${r.isIncome ? '+' : '-'}৳${r.amount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: r.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),
      ],
    );

    await _renderWidgetToMultiPagePdf(context, widget, 'Monthly_Report_${selectedMonth}_${selectedYear}.pdf');
  }

  /// শুরুর তারিখ ও শেষ তারিখের ভিত্তিতে ইচ্ছামত সময়ের সার্বিক রিপোর্ট তৈরি করে
  static Future<void> generateCustomDateRangeSummaryReport({
    required BuildContext context,
    required String societyName,
    required DateTime startDate,
    required DateTime endDate,
    required List<Member> members,
    required List<BusinessRecord> businessRecords,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    try {
      scaffoldMessenger?.showSnackBar(
        const SnackBar(
          content: Text('PDF রিপোর্ট তৈরি হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...'),
          duration: Duration(seconds: 2),
        ),
      );

      final DateTime actualStart =
          startDate.isBefore(endDate) ? startDate : endDate;
      final DateTime actualEnd =
          startDate.isBefore(endDate) ? endDate : startDate;

      final DateTime rangeStart = DateTime(
          actualStart.year, actualStart.month, actualStart.day, 0, 0, 0);
      final DateTime rangeEnd = DateTime(
          actualEnd.year, actualEnd.month, actualEnd.day, 23, 59, 59);

      final String fileName =
          'Summary_${_fileSafeDate(rangeStart)}_to_${_fileSafeDate(rangeEnd)}.pdf';

      bool inRange(DateTime d) {
        return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
      }

      double depositTotal = 0.0;
      int depositCount = 0;
      double distributedProfit = 0.0;

      final Map<String, double> memberDepositMap = {};
      final Map<String, double> memberProfitMap = {};
      final List> profitEntries = [];

      for (final m in members) {
        memberDepositMap[m.id] = 0.0;
        memberProfitMap[m.id] = 0.0;

        for (final tx in m.transactions) {
          if (tx.status == 'approved' && inRange(tx.date)) {
            if (tx.isProfit) {
              distributedProfit += tx.amount;
              memberProfitMap[m.id] =
                  (memberProfitMap[m.id] ?? 0.0) + tx.amount;
              profitEntries.add({'member': m, 'tx': tx});
            } else {
              depositTotal += tx.amount;
              depositCount++;
              memberDepositMap[m.id] =
                  (memberDepositMap[m.id] ?? 0.0) + tx.amount;
            }
          }
        }
      }

      profitEntries.sort((a, b) {
        final DateTime da = (a['tx'] as TransactionHistory).date;
        final DateTime db = (b['tx'] as TransactionHistory).date;
        return da.compareTo(db);
      });

      final List<BusinessRecord> filteredBizRecords = businessRecords
          .where((r) => inRange(r.date))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      double bizIncome = 0.0;
      double bizExpense = 0.0;
      for (final r in filteredBizRecords) {
        if (r.isIncome) {
          bizIncome += r.amount;
        } else {
          bizExpense += r.amount;
        }
      }

      final double netBizAfterExpense = bizIncome - bizExpense;
      final double remainingUnsettledProfit =
          netBizAfterExpense - distributedProfit;
      final double totalInflowAfterExpense =
          depositTotal + bizIncome - bizExpense;

      final pw.Document pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          footer: (pw.Context ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount} | Generated: ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          build: (pw.Context ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    societyName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Period Summary Report (${_formatDate(rangeStart)} - ${_formatDate(rangeEnd)})',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '1. Total Member Savings / Deposits: BDT ${depositTotal.toStringAsFixed(2)} ($depositCount tx)',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '2. Business Income (+): BDT ${bizIncome.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '3. Business Expense (-): BDT ${bizExpense.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '4. Net Business Profit (After Expense): BDT ${netBizAfterExpense.toStringAsFixed(2)} | Distributed Profit: BDT ${distributedProfit.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '5. Unsettled Profit: BDT ${remainingUnsettledProfit.toStringAsFixed(2)} | Net Fund Inflow: BDT ${totalInflowAfterExpense.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            pw.Text(
              'A. Member-wise Savings & Distributed Profit',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'ID',
                'Member Name',
                'Period Deposit',
                'Profit Earned',
                'Total Added',
              ],
              data: [
                ...members.map((m) {
                  final double dep = memberDepositMap[m.id] ?? 0.0;
                  final double prof = memberProfitMap[m.id] ?? 0.0;
                  return [
                    m.id,
                    m.name,
                    dep.toStringAsFixed(2),
                    prof.toStringAsFixed(2),
                    (dep + prof).toStringAsFixed(2),
                  ];
                }),
                [
                  '',
                  'TOTAL',
                  depositTotal.toStringAsFixed(2),
                  distributedProfit.toStringAsFixed(2),
                  (depositTotal + distributedProfit).toStringAsFixed(2),
                ],
              ],
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9.5,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'B. Business Income & Expense Records',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (filteredBizRecords.isEmpty)
              pw.Text(
                'No business records in this period.',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Title', 'Type', 'Amount (BDT)'],
                data: filteredBizRecords
                    .map((r) => [
                          _formatDate(r.date),
                          r.title,
                          r.isIncome ? 'Income (+)' : 'Expense (-)',
                          '${r.isIncome ? '+' : '-'}${r.amount.toStringAsFixed(2)}',
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9.5,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.teal800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
              ),
            pw.SizedBox(height: 14),
            pw.Text(
              'C. Profit Distribution Entries',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (profitEntries.isEmpty)
              pw.Text(
                'No profit distribution entries in this period.',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Member (ID)', 'Details', 'Profit (BDT)'],
                data: profitEntries.map((entry) {
                  final Member m = entry['member'] as Member;
                  final TransactionHistory tx = entry['tx'] as TransactionHistory;
                  return [
                    _formatDate(tx.date),
                    '${m.name} (${m.id})',
                    tx.paymentMethod.isNotEmpty
                        ? tx.paymentMethod
                        : 'Profit Distribution',
                    tx.amount.toStringAsFixed(2),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9.5,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
              ),
          ],
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      if (context.mounted) {
        await _savePdfBytes(context, pdfBytes, fileName);
      }
    } catch (e) {
      debugPrint('Custom Date Range Report Error: $e');
      scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text('রিপোর্ট তৈরি করতে সমস্যা হয়েছে: $e')),
      );
    }
  }
}
