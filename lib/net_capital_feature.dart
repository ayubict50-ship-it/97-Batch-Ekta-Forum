import 'package:flutter/material.dart';
import 'main.dart';

class NetCapitalSummaryCard extends StatelessWidget {
  final double totalMembersSavings;

  const NetCapitalSummaryCard({
    super.key,
    required this.totalMembersSavings,
  });

  String _fmt(double amount) => amount.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final double businessProfit = SamobayFinance.currentBusinessIncome;
    final double expense = SamobayFinance.currentBusinessExpense;
    final double netCapital = totalMembersSavings + businessProfit - expense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💼 নীট মূলধন হিসাব",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(height: 10),
          _line("১. সদস্যদের মোট সঞ্চয়", "৳${_fmt(totalMembersSavings)}", Colors.black87),
          const SizedBox(height: 4),
          _line("২. ব্যবসায়িক মুনাফা", "+৳${_fmt(businessProfit)}", Colors.green.shade700),
          const SizedBox(height: 4),
          _line("৩. খরচ", "-৳${_fmt(expense)}", Colors.red.shade700),
          const Divider(height: 12, thickness: 1.2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "নীট মূলধন",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Text(
                "৳${_fmt(netCapital)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
