import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart';

Future<void> showDebitCreditStatementDialog({
  required BuildContext context,
  required String societyName,
  required List<Member> members,
  required List<BusinessRecord> businessRecords,
}) async {
  DateTime startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime endDate = DateTime.now();

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

        final List> entries = [];

        for (final member in members) {
          for (final tx in member.transactions) {
            if (tx.status != 'approved') continue;
            if (tx.date.isBefore(normalizedStart) || tx.date.isAfter(normalizedEnd)) {
              continue;
            }

            if (tx.isProfit) {
              totalProfitDistributionDebit += tx.amount;
              entries.add({
                'date': tx.date,
                'title': 'সদস্যদের লাভ বণ্টন',
                'sub': tx.paymentMethod.isNotEmpty ? tx.paymentMethod : 'লাভ বণ্টন',
                'amount': tx.amount,
                'isCredit': false,
              });
            } else {
              totalMemberDepositCredit += tx.amount;
              entries.add({
                'date': tx.date,
                'title': 'সদস্য কিস্তি / সঞ্চয় জমা',
                'sub': tx.paymentMethod.isNotEmpty ? tx.paymentMethod : 'কিস্তি জমা',
                'amount': tx.amount,
                'isCredit': true,
              });
            }
          }
        }

        for (final record in businessRecords) {
          if (record.date.isBefore(normalizedStart) || record.date.isAfter(normalizedEnd)) {
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
              'title': record.title.isNotEmpty ? record.title : 'প্রজেক্ট / ব্যবসায়িক খরচ',
              'sub': 'সমিতির খরচ',
              'amount': record.amount,
              'isCredit': false,
            });
          }
        }

        entries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        final double totalCredit = totalMemberDepositCredit + totalBusinessIncomeCredit;
        final double totalDebit = totalBusinessExpenseDebit + totalProfitDistributionDebit;
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
                        child: Text("শুরু: ${fmtDate(startDate)}", style: const TextStyle(fontSize: 12)),
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
                        child: const Text("তারিখ দিন", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text("শেষ: ${fmtDate(endDate)}", style: const TextStyle(fontSize: 12)),
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
                        child: const Text("তারিখ দিন", style: TextStyle(fontSize: 12)),
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
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "• ব্যবসায়িক আয় ক্রেডিট: ৳${totalBusinessIncomeCredit.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "মোট ক্রেডিট (+): ৳${totalCredit.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "• প্রজেক্ট/ব্যবসায়িক খরচ ডেবিট: ৳${totalBusinessExpenseDebit.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "• লাভ বণ্টন ডেবিট: ৳${totalProfitDistributionDebit.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "মোট ডেবিট (-): ৳${totalDebit.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
                            child: Text("নির্বাচিত তারিখের মধ্যে কোনো এন্ট্রি পাওয়া যায়নি।"),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                        color: isCredit ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      isCredit ? "ক্রেডিট" : "ডেবিট",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isCredit ? Colors.green : Colors.red,
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
              onPressed: () async {
                await _generateDebitCreditPdf(
                  societyName: societyName,
                  startDate: startDate,
                  endDate: endDate,
                  totalMemberDepositCredit: totalMemberDepositCredit,
                  totalBusinessIncomeCredit: totalBusinessIncomeCredit,
                  totalBusinessExpenseDebit: totalBusinessExpenseDebit,
                  totalProfitDistributionDebit: totalProfitDistributionDebit,
                  totalCredit: totalCredit,
                  totalDebit: totalDebit,
                  netBalance: netBalance,
                  entries: entries,
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text("PDF ডাউনলোড"),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _generateDebitCreditPdf({
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
  required List> entries,
}) async {
  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  pw.Font? bengaliFont;
  try {
    final fontData = await rootBundle.load('assets/fonts/SolaimanLipi.ttf');
    bengaliFont = pw.Font.ttf(fontData);
  } catch (_) {}

  final pdf = pw.Document();
  final baseStyle = pw.TextStyle(font: bengaliFont, fontSize: 10);
  final boldStyle = pw.TextStyle(font: bengaliFont, fontSize: 10, fontWeight: pw.FontWeight.bold);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context ctx) => [
        pw.Text(
          societyName,
          style: pw.TextStyle(font: bengaliFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'সমিতির সামগ্রিক ডেবিট-ক্রেডিট স্টেটমেন্ট (${fmtDate(startDate)} - ${fmtDate(endDate)})',
          style: boldStyle,
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('কিস্তি/সঞ্চয় ক্রেডিট: ${totalMemberDepositCredit.toStringAsFixed(2)} টাকা', style: baseStyle),
              pw.Text('ব্যবসায়িক আয় ক্রেডিট: ${totalBusinessIncomeCredit.toStringAsFixed(2)} টাকা', style: baseStyle),
              pw.Text('মোট ক্রেডিট (+): ${totalCredit.toStringAsFixed(2)} টাকা', style: boldStyle),
              pw.SizedBox(height: 4),
              pw.Text('প্রজেক্ট/ব্যবসায়িক খরচ ডেবিট: ${totalBusinessExpenseDebit.toStringAsFixed(2)} টাকা', style: baseStyle),
              pw.Text('লাভ বণ্টন ডেবিট: ${totalProfitDistributionDebit.toStringAsFixed(2)} টাকা', style: baseStyle),
              pw.Text('মোট ডেবিট (-): ${totalDebit.toStringAsFixed(2)} টাকা', style: boldStyle),
              pw.SizedBox(height: 4),
              pw.Text('নিট তহবিল ব্যালেন্স: ${netBalance.toStringAsFixed(2)} টাকা', style: boldStyle),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          headerStyle: boldStyle,
          cellStyle: baseStyle,
          headers: ['তারিখ', 'বিবরণ', 'ধরন', 'ক্রেডিট (+)', 'ডেবিট (-)'],
          data: entries.map((e) {
            final DateTime d = e['date'] as DateTime;
            final bool isCredit = e['isCredit'] as bool;
            final double amt = e['amount'] as double;
            return [
              fmtDate(d),
              '${e['title']} (${e['sub']})',
              isCredit ? 'ক্রেডিট' : 'ডেবিট',
              isCredit ? amt.toStringAsFixed(2) : '-',
              !isCredit ? amt.toStringAsFixed(2) : '-',
            ];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
