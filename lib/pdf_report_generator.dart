import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'main.dart';

class PdfReportGenerator {
  static Future<pw.Font> _loadNikoshFont() async {
    final fontData = await rootBundle.load('assets/fonts/NikoshBAN.ttf');
    return pw.Font.ttf(fontData);
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static Future<void> _saveAndOpenPdf(
    BuildContext context,
    pw.Document pdf,
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
      await file.writeAsBytes(await pdf.save());

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

  static pw.Widget _buildHeader(
    pw.Font font,
    String societyName,
    String reportTitle,
    String subtitle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 1.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            societyName,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          if (subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font, pw.Context pdfContext) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'প্রিন্ট তারিখ: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Text(
            'পৃষ্ঠা ${pdfContext.pageNumber} / ${pdfContext.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    pw.Font font,
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10.5 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : PdfColors.black),
        ),
      ),
    );
  }

  static Future<void> generateAllMembersReport(
    BuildContext context,
    String societyName,
    List<Member> members,
  ) async {
    final font = await _loadNikoshFont();
    final pdf = pw.Document();

    double totalDep = members.fold(0.0, (s, m) => s + m.deposit);
    double totalProf = members.fold(0.0, (s, m) => s + m.profitEarned);
    double totalBal = members.fold(0.0, (s, m) => s + m.totalBalance);
    double totalDue = members.fold(0.0, (s, m) => s + m.dueAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(
          font,
          societyName,
          'সকল সদস্যের সার্বিক স্টেটমেন্ট',
          'মোট সদস্য: ${members.length} জন | মোট সঞ্চয়: ৳${totalDep.toStringAsFixed(2)} | মোট বকেয়া: ৳${totalDue.toStringAsFixed(2)}',
        ),
        footer: (ctx) => _buildFooter(font, ctx),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
            columnWidths: {
              0: const pw.FixedColumnWidth(38),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green800),
                repeat: true,
                children: [
                  _cell(font, 'ID', isHeader: true, align: pw.TextAlign.center),
                  _cell(font, 'সদস্যের নাম', isHeader: true),
                  _cell(font, 'মোবাইল', isHeader: true),
                  _cell(font, 'মূল জমা', isHeader: true, align: pw.TextAlign.right),
                  _cell(font, 'অর্জিত লাভ', isHeader: true, align: pw.TextAlign.right),
                  _cell(font, 'মোট ব্যালেন্স', isHeader: true, align: pw.TextAlign.right),
                  _cell(font, 'বকেয়া / অগ্রিম', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              ...members.asMap().entries.map((entry) {
                final idx = entry.key;
                final m = entry.value;
                final String dueAdv = m.dueAmount > 0
                    ? 'বকেয়া: ৳${m.dueAmount.toStringAsFixed(0)} (${m.dueMonthsCount} মা.)'
                    : (m.advanceAmount > 0
                        ? 'অগ্রিম: ৳${m.advanceAmount.toStringAsFixed(0)}'
                        : '৳0.00');

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: idx % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
                  ),
                  children: [
                    _cell(font, m.id, align: pw.TextAlign.center),
                    _cell(font, m.name),
                    _cell(font, m.mobile),
                    _cell(font, '৳${m.deposit.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    _cell(font, '৳${m.profitEarned.toStringAsFixed(2)}',
                        align: pw.TextAlign.right, color: PdfColors.blue800),
                    _cell(font, '৳${m.totalBalance.toStringAsFixed(2)}',
                        align: pw.TextAlign.right, color: PdfColors.green800),
                    _cell(font, dueAdv,
                        align: pw.TextAlign.right,
                        color: m.dueAmount > 0 ? PdfColors.red800 : PdfColors.teal800),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                children: [
                  _cell(font, '', isHeader: true, color: PdfColors.black),
                  _cell(font, 'সর্বমোট হিসাব', isHeader: true, color: PdfColors.black),
                  _cell(font, '', isHeader: true, color: PdfColors.black),
                  _cell(font, '৳${totalDep.toStringAsFixed(2)}',
                      isHeader: true, align: pw.TextAlign.right, color: PdfColors.black),
                  _cell(font, '৳${totalProf.toStringAsFixed(2)}',
                      isHeader: true, align: pw.TextAlign.right, color: PdfColors.blue800),
                  _cell(font, '৳${totalBal.toStringAsFixed(2)}',
                      isHeader: true, align: pw.TextAlign.right, color: PdfColors.green800),
                  _cell(font, '৳${totalDue.toStringAsFixed(2)}',
                      isHeader: true, align: pw.TextAlign.right, color: PdfColors.red800),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await _saveAndOpenPdf(context, pdf, 'All_Members_Report.pdf');
  }

  static Future<void> generateSingleMemberStatement(
    BuildContext context,
    String societyName,
    Member member,
  ) async {
    final font = await _loadNikoshFont();
    final pdf = pw.Document();

    final String statusText = member.dueAmount > 0
        ? 'বকেয়া: ৳${member.dueAmount.toStringAsFixed(2)} (${member.dueMonthsCount} মাস)'
        : (member.advanceAmount > 0
            ? 'অতিরিক্ত জমা: ৳${member.advanceAmount.toStringAsFixed(2)}'
            : 'বকেয়া: ৳0.00 (পরিশোধিত)');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(
          font,
          societyName,
          'সদস্যের ব্যক্তিগত হিসাব বিবরণী',
          'নাম: ${member.name} | আইডি: ${member.id} | মোবাইল: ${member.mobile}',
        ),
        footer: (ctx) => _buildFooter(font, ctx),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• মূল সঞ্চয় (কিস্তি জমা): ৳${member.deposit.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '• অর্জিত মোট লাভ: ৳${member.profitEarned.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.blue800),
                ),
                pw.Text(
                  '• সর্বমোট ব্যালেন্স: ৳${member.totalBalance.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  '• $statusText',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: member.dueAmount > 0 ? PdfColors.red800 : PdfColors.teal800,
                  ),
                ),
              ],
            ),
          ),
          if (member.transactions.isEmpty)
            pw.Text('কোনো লেনদেন রেকর্ড নেই।', style: pw.TextStyle(font: font, fontSize: 11))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(32),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(2.4),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  repeat: true,
                  children: [
                    _cell(font, 'ক্রম', isHeader: true, align: pw.TextAlign.center),
                    _cell(font, 'তারিখ', isHeader: true),
                    _cell(font, 'বিবরণ / মাধ্যম', isHeader: true),
                    _cell(font, 'TrxID / স্ট্যাটাস', isHeader: true),
                    _cell(font, 'টাকার পরিমাণ', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...member.transactions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tx = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      _cell(font, '${idx + 1}', align: pw.TextAlign.center),
                      _cell(font, _formatDate(tx.date)),
                      _cell(font, tx.paymentMethod),
                      _cell(
                        font,
                        tx.trxId.isNotEmpty
                            ? '${tx.trxId} (${tx.status})'
                            : tx.status,
                      ),
                      _cell(
                        font,
                        '৳${tx.amount.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                        color: tx.isProfit ? PdfColors.blue800 : PdfColors.green800,
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    await _saveAndOpenPdf(context, pdf, 'Member_${member.name}_Statement.pdf');
  }

  static Future<void> generateBusinessLedgerReport(
    BuildContext context,
    String societyName,
    List<BusinessRecord> records,
    double currentIncome,
    double currentExpense,
    double currentNetProfit,
  ) async {
    final font = await _loadNikoshFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(
          font,
          societyName,
          'ব্যবসার লাভ-ক্ষতি খতিয়ান ও রিপোর্ট',
          'চলমান মুনাফা: ৳${currentIncome.toStringAsFixed(2)} | চলমান খরচ: ৳${currentExpense.toStringAsFixed(2)} | নিট লাভ: ৳${currentNetProfit.toStringAsFixed(2)}',
        ),
        footer: (ctx) => _buildFooter(font, ctx),
        build: (ctx) => [
          if (records.isEmpty)
            pw.Text('কোনো ব্যবসায়িক পোস্টিং নেই।', style: pw.TextStyle(font: font, fontSize: 11))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(32),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(2.6),
                3: const pw.FlexColumnWidth(1.1),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  repeat: true,
                  children: [
                    _cell(font, 'ক্রম', isHeader: true, align: pw.TextAlign.center),
                    _cell(font, 'তারিখ', isHeader: true),
                    _cell(font, 'বিবরণ', isHeader: true),
                    _cell(font, 'ধরন', isHeader: true),
                    _cell(font, 'অবস্থা', isHeader: true),
                    _cell(font, 'টাকার পরিমাণ', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...records.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      _cell(font, '${idx + 1}', align: pw.TextAlign.center),
                      _cell(font, _formatDate(r.date)),
                      _cell(font, r.title),
                      _cell(
                        font,
                        r.isIncome ? 'লাভ (+)' : 'খরচ (-)',
                        color: r.isIncome ? PdfColors.green800 : PdfColors.red800,
                      ),
                      _cell(font, r.isSettled ? 'বণ্টনকৃত' : 'চলমান'),
                      _cell(
                        font,
                        '${r.isIncome ? '+' : '-'}৳${r.amount.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                        color: r.isIncome ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    await _saveAndOpenPdf(
      context,
      pdf,
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
    final font = await _loadNikoshFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(
          font,
          societyName,
          'মাসিক আয়-ব্যয় ও জমা রিপোর্ট — $monthLabel',
          'কিস্তি জমা: ৳${monthlyDepositTotal.toStringAsFixed(2)} ($monthlyDepositCountটি) | লাভ বণ্টন: ৳${monthlyProfitTotal.toStringAsFixed(2)}',
        ),
        footer: (ctx) => _buildFooter(font, ctx),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              border: pw.Border.all(color: PdfColors.teal300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• মোট কিস্তি জমা: ৳${monthlyDepositTotal.toStringAsFixed(2)} ($monthlyDepositCountটি)',
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.green800)),
                pw.Text('• মোট লাভ বণ্টন: ৳${monthlyProfitTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.blue800)),
                pw.Text('• ব্যবসায়িক আয়: ৳${monthlyBizIncome.toStringAsFixed(2)} | প্রজেক্ট খরচ: ৳${monthlyBizExpense.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font, fontSize: 11)),
              ],
            ),
          ),
          pw.Text(
            '১. সদস্যদের লেনদেনসমূহ:',
            style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (memberMonthEntries.isEmpty)
            pw.Text('এই মাসে কোনো সদস্যের লেনদেন নেই।', style: pw.TextStyle(font: font, fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(32),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  repeat: true,
                  children: [
                    _cell(font, 'ক্রম', isHeader: true, align: pw.TextAlign.center),
                    _cell(font, 'তারিখ', isHeader: true),
                    _cell(font, 'সদস্য (ID)', isHeader: true),
                    _cell(font, 'মাধ্যম / ধরন', isHeader: true),
                    _cell(font, 'টাকার পরিমাণ', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...memberMonthEntries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final Member m = entry.value['member'];
                  final TransactionHistory t = entry.value['tx'];
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      _cell(font, '${idx + 1}', align: pw.TextAlign.center),
                      _cell(font, _formatDate(t.date)),
                      _cell(font, '${m.name} (${m.id})'),
                      _cell(font, t.isProfit ? 'লাভ বণ্টন' : t.paymentMethod),
                      _cell(font, '৳${t.amount.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            '২. ব্যবসার আয়-ব্যয় পোস্টিং:',
            style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (monthBizRecords.isEmpty)
            pw.Text('এই মাসে কোনো ব্যবসায়িক পোস্টিং নেই।', style: pw.TextStyle(font: font, fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FixedColumnWidth(32),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(2.6),
                3: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  repeat: true,
                  children: [
                    _cell(font, 'ক্রম', isHeader: true, align: pw.TextAlign.center),
                    _cell(font, 'তারিখ', isHeader: true),
                    _cell(font, 'বিবরণ', isHeader: true),
                    _cell(font, 'টাকার পরিমাণ', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...monthBizRecords.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      _cell(font, '${idx + 1}', align: pw.TextAlign.center),
                      _cell(font, _formatDate(r.date)),
                      _cell(font, r.title),
                      _cell(
                        font,
                        '${r.isIncome ? '+' : '-'}৳${r.amount.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                        color: r.isIncome ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    await _saveAndOpenPdf(context, pdf, 'Monthly_Report_${selectedMonth}_${selectedYear}.pdf');
  }
}
