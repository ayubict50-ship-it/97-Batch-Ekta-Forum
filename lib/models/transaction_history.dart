class TransactionHistory {
  final DateTime date;
  final double amount;
  final String paymentMethod;
  final String trxId;
  final bool isProfit;
  final String? batchId;
  final String status;

  TransactionHistory({
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.trxId = '',
    this.isProfit = false,
    this.batchId,
    this.status = 'approved',
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
        'paymentMethod': paymentMethod,
        'trxId': trxId,
        'isProfit': isProfit,
        'batchId': batchId,
        'status': status,
      };

  factory TransactionHistory.fromJson(Map<String, dynamic> json) => TransactionHistory(
        date: DateTime.parse(json['date']),
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['paymentMethod'],
        trxId: json['trxId'] ?? '',
        isProfit: json['isProfit'] ?? false,
        batchId: json['batchId'],
        status: json['status'] ?? 'approved',
      );
}
