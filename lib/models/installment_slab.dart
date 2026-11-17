class InstallmentSlab {
  final String id;
  DateTime startDate;
  DateTime endDate;
  double amount;

  InstallmentSlab({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'amount': amount,
      };

  factory InstallmentSlab.fromJson(Map<String, dynamic> json) => InstallmentSlab(
        id: json['id'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        amount: (json['amount'] as num).toDouble(),
      );
}
