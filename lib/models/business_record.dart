class BusinessRecord {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  bool isSettled;
  String? batchId;

  BusinessRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.isSettled = false,
    this.batchId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'isSettled': isSettled,
        'batchId': batchId,
      };

  factory BusinessRecord.fromJson(Map<String, dynamic> json) => BusinessRecord(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'],
        date: DateTime.parse(json['date']),
        isSettled: json['isSettled'] ?? false,
        batchId: json['batchId'],
      );
}
