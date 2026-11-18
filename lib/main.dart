import 'transaction_history.dart';

class Member {
  String id;
  String name;
  String mobile;
  String pin;
  String profession;
  String address;
  double deposit;
  double profitEarned;
  DateTime joinDate;
  List<TransactionHistory> transactions;

  Member({
    required this.id,
    required this.name,
    required this.mobile,
    required this.pin,
    this.profession = '',
    this.address = '',
    this.deposit = 0.0,
    this.profitEarned = 0.0,
    required this.joinDate,
    required this.transactions,
  });

  double get totalBalance => deposit + profitEarned;

  double get lastDepositAmount {
    var depositTxs = transactions.where((tx) => !tx.isProfit).toList();
    return depositTxs.isNotEmpty ? depositTxs.last.amount : 0.0;
  }

  double get expectedTotalTarget {
    // লক্ষ্য পূরণের হিসাব
    return 0.0;
  }

  double get netDifference => expectedTotalTarget - deposit;
  double get dueAmount => netDifference > 0 ? netDifference : 0.0;
  double get advanceAmount => netDifference < 0 ? netDifference.abs() : 0.0;

  int get dueMonthsCount {
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'pin': pin,
        'profession': profession,
        'address': address,
        'deposit': deposit,
        'profitEarned': profitEarned,
        'joinDate': joinDate.toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        name: json['name'],
        mobile: json['mobile'],
        pin: json['pin'],
        profession: json['profession'] ?? '',
        address: json['address'] ?? '',
        deposit: (json['deposit'] as num).toDouble(),
        profitEarned: (json['profitEarned'] as num).toDouble(),
        joinDate: DateTime.parse(json['joinDate']),
        transactions: (json['transactions'] as List?)?.map((t) => TransactionHistory.fromJson(t)).toList() ?? [],
      );
}
