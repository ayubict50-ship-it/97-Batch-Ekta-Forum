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

Future<void> showDebitCreditStatementDialog({
  required BuildContext context,
  required String societyName,
  required List<Member> members,
  required List<BusinessRecord> businessRecords,
}) async {
  DateTime startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime endDate = DateTime.now();
  bool isExporting = false;

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final DateTime normalizedStart =
            DateTime(startDate.year, startDate.month, startDate.day);
        final DateTime normalizedEnd =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        double totalMemberDepositCredit = 0.0;
        double totalBusinessIncomeCredit = 0.0;
        double totalBusinessExpenseDebit = 0.0;
        double totalProfitDistributionDebit = 0.0;

        final entries = [];

        for (final member in members) {
          for (final tx in member.transactions) {
            if (tx.status != 'approved') continue;
            if (tx.date.isBefore(normalizedStart) ||
                tx.date.isAfter(normalizedEnd)) {
              continue;
            }

            if (tx.isProfit) {
              totalProfitDistributionDebit += tx.amount;
              entries.add({
                'date': tx.date,
                'title': 'সদস্যদের লাভ বণ্টন',
                'sub': tx.paymentMethod.isNotEmpty
                    ? tx.paymentMethod
                    : 'লাভ বণ্টন',
                'amount': tx.amount,
                'isCredit': false,
              });
            } else {
              totalMemberDepositCredit += tx.amount;
              entries.add({
                'date': tx.date,
                'title': 'সদস্য কিস্তি / সঞ্চয় জমা',
                'sub': tx.paymentMethod.isNotEmpty
                    ? tx.paymentMethod
                    : 'কিস্তি জমা',
                'amount': tx.amount,
                'isCredit': true,
              });
            }
          }
        }

        for (final record in businessRecords) {
          if (record.date.isBefore(normalizedStart) ||
              record.date.isAfter(normalizedEnd)) {
            continue;
          }

          if (record.isIncome) {
            totalBusinessIncomeCredit += record.amount;
            entries.add({
              'date': record.date,
              'title': record.title.isNotEmpty ? record.title : 'ব্যবসায়িক আয়',
              'sub': 'সমিতির ব্যবসায়িক আয়',
              'amount': record.amount,
              'isCredit': true,
            });
          } else {
            totalBusinessExpenseDebit += record.amount;
            entries.add({
              'date': record.date,
              'title': record.title.isNotEmpty
                  ? record.title
                  : 'প্রজেক্ট / ব্যবসায়িক খরচ',
              'sub': 'সমিতির খরচ',
              'amount': record.amount,
              'isCredit': false,
            });
          }
        }

        entries.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        final double totalCredit =
            totalMemberDepositCredit + totalBusinessIncomeCredit;
        final double totalDebit =
            totalBusinessExpenseDebit + totalProfitDistributionDebit;
        final double netBalance = totalCredit - totalDebit;

        return AlertDialog(
          title: const Text("⚖️ সমিতির ডেবিট–ক্রেডিট স্টেটমেন্ট"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("শুরু: ${fmtDate(startDate)}",
                            style: const TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: const Text("তারিখ দিন",
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text("শেষ: ${fmtDate(endDate)}",
                            style: const TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: const Text("তারিখ দিন",
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• কিস্তি/সঞ্চয় ক্রেডিট: ৳${totalMemberDepositCredit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "• ব্যবসায়িক আয় ক্রেডিট: ৳${totalBusinessIncomeCredit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "মোট ক্রেডিট (+): ৳${totalCredit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "• প্রজেক্ট/ব্যবসায়িক খরচ ডেবিট: ৳${totalBusinessExpenseDebit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "• লাভ বণ্টন ডেবিট: ৳${totalProfitDistributionDebit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "মোট ডেবিট (-): ৳${totalDebit.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const Divider(height: 10),
                        Text(
                          "নিট তহবিল ব্যালেন্স: ৳${netBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: netBalance >= 0 ? Colors.indigo : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  entries.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                                "নির্বাচিত তারিখের মধ্যে কোনো এন্ট্রি পাওয়া যায়নি।"),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entries.length,
                          itemBuilder: (context, idx) {
                            final item = entries[idx];
                            final DateTime d = item['date'] as DateTime;
                            final bool isCredit = item['isCredit'] as bool;
                            final double amt = item['amount'] as double;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  item['title'].toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                subtitle: Text(
                                  "${fmtDate(d)} | ${item['sub']}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${isCredit ? '+' : '-'}৳${amt.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      isCredit ? "ক্রেডিট" : "ডেবিট",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("বন্ধ করুন"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: isExporting
                  ? null
                  : () async {
                      setDialogState(() => isExporting = true);
                      try {
                        await _generateRepaintedDebitCreditPdf(
                          context: context,
                          societyName: societyName,
                          startDate: startDate,
                          endDate: endDate,
                          totalMemberDepositCredit: totalMemberDepositCredit,
                          totalBusinessIncomeCredit: totalBusinessIncomeCredit,
                          totalBusinessExpenseDebit: totalBusinessExpenseDebit,
                          totalProfitDistributionDebit:
                              totalProfitDistributionDebit,
                          totalCredit: totalCredit,
                          totalDebit: totalDebit,
                          netBalance: netBalance,
                          entries: entries,
                        );
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isExporting = false);
                        }
                      }
                    },
              icon: isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, size: 16),
              label: Text(isExporting ? "তৈরি হচ্ছে..." : "PDF ডাউনলোড"),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _generateRepaintedDebitCreditPdf({
  required BuildContext context,
  required String societyName,
  required DateTime startDate,
  required DateTime endDate,
  required double totalMemberDepositCredit,
  required double totalBusinessIncomeCredit,
  required double totalBusinessExpenseDebit,
  required double totalProfitDistributionDebit,
  required double totalCredit,
  required double totalDebit,
  required double netBalance,
  required List entries,
}) async {
  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  final GlobalKey repaintKey = GlobalKey();
  final overlay = Overlay.of(context);

  final sheetWidget = Material(
    color: Colors.white,
    child: Container(
      width: 794, // A4 অনুপাতে পরিষ্কার রেন্ডারিং প্রস্থ
      padding: const EdgeInsets.all(28),
      color: Colors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'NikoshBAN',
          color: Colors.black87,
          fontSize: 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              societyName,
              style: const TextStyle(
                fontFamily: 'NikoshBAN',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'সমিতির সামগ্রিক ডেবিট-ক্রেডিট স্টেটমেন্ট (${fmtDate(startDate)} - ${fmtDate(endDate)})',
              style: const TextStyle(
                fontFamily: 'NikoshBAN',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• কিস্তি/সঞ্চয় ক্রেডিট: ৳${totalMemberDepositCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '• ব্যবসায়িক আয় ক্রেডিট: ৳${totalBusinessIncomeCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'মোট ক্রেডিট (+): ৳${totalCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• প্রজেক্ট/ব্যবসায়িক খরচ ডেবিট: ৳${totalBusinessExpenseDebit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '• লাভ বণ্টন ডেবিট: ৳${totalProfitDistributionDebit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'মোট ডেবিট (-): ৳${totalDebit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontFamily: 'NikoshBAN',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  const Divider(height: 12),
                  Text(
                    'নিট তহবিল ব্যালেন্স: ৳${netBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'NikoshBAN',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: netBalance >= 0
                          ? const Color(0xFF1A237E)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400, width: 0.8),
              columnWidths: const {
                0: FixedColumnWidth(105),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(105),
                4: FixedColumnWidth(105),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade700),
                  children: const [
                    _PdfHeaderCell('তারিখ'),
                    _PdfHeaderCell('বিবরণ'),
                    _PdfHeaderCell('ধরন'),
                    _PdfHeaderCell('ক্রেডিট (+)'),
                    _PdfHeaderCell('ডেবিট (-)'),
                  ],
                ),
                ...entries.map((e) {
                  final DateTime d = e['date'] as DateTime;
                  final bool isCredit = e['isCredit'] as bool;
                  final double amt = e['amount'] as double;
                  return TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      _PdfBodyCell(fmtDate(d)),
                      _PdfBodyCell('${e['title']} (${e['sub']})'),
                      _PdfBodyCell(isCredit ? 'ক্রেডিট' : 'ডেবিট'),
                      _PdfBodyCell(isCredit ? amt.toStringAsFixed(2) : '-'),
                      _PdfBodyCell(!isCredit ? amt.toStringAsFixed(2) : '-'),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'তৈরির তারিখ: ${fmtDate(DateTime.now())}',
              style: TextStyle(
                fontFamily: 'NikoshBAN',
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -2000,
      top: -2000,
      child: RepaintBoundary(
        key: repaintKey,
        child: sheetWidget,
      ),
    ),
  );

  overlay.insert(entry);

  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 80));

    final boundary = repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final pdfImage = pw.MemoryImage(pngBytes);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(14),
        build: (pw.Context ctx) {
          return pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'Debit_Credit_Statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  } finally {
    entry.remove();
  }
}

class _PdfHeaderCell extends StatelessWidget {
  final String text;
  const _PdfHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NikoshBAN',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PdfBodyCell extends StatelessWidget {
  final String text;
  const _PdfBodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NikoshBAN',
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }
}
