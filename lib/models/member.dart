import '../constants/app_constants.dart';

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

class Member {
  String id;
  String name;
  String mobile;
  String pin;
  double deposit;
  double profitEarned;
  DateTime joinDate;
  List<TransactionHistory> transactions;

  Member({
    required this.id,
    required this.name,
    required this.mobile,
    required this.pin,
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
    DateTime now = DateTime.now();
    double totalExpected = 0.0;

    for (var slab in globalInstallmentSlabs) {
      DateTime effectiveStart = joinDate.isAfter(slab.startDate) ? joinDate : slab.startDate;
      DateTime effectiveEnd = now.isBefore(slab.endDate) ? now : slab.endDate;

      if (effectiveStart.isBefore(effectiveEnd) || effectiveStart.isAtSameMomentAs(effectiveEnd)) {
        int months = (effectiveEnd.year - effectiveStart.year) * 12 + (effectiveEnd.month - effectiveStart.month);
        if (months < 0) {
          months = 0;
        } else {
          months += 1;
        }
        totalExpected += (months * slab.amount);
      }
    }
    return totalExpected;
  }

  double get netDifference => expectedTotalTarget - deposit;
  double get dueAmount => netDifference > 0 ? netDifference : 0.0;
  double get advanceAmount => netDifference < 0 ? netDifference.abs() : 0.0;

  int get dueMonthsCount {
    if (dueAmount <= 0 || globalInstallmentSlabs.isEmpty) return 0;
    double currentRate = globalInstallmentSlabs.last.amount;
    return (dueAmount / currentRate).ceil();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'pin': pin,
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
        deposit: (json['deposit'] as num).toDouble(),
        profitEarned: (json['profitEarned'] as num).toDouble(),
        joinDate: DateTime.parse(json['joinDate']),
        transactions: (json['transactions'] as List).map((t) => TransactionHistory.fromJson(t)).toList(),
      );
}

class SamobayFinance {
  static double get currentBusinessIncome {
    return globalBusinessRecords.where((r) => r.isIncome && !r.isSettled).fold(0.0, (sum, item) => sum + item.amount);
  }

  static double get currentBusinessExpense {
 return globalBusinessRecords.where((r) => !r.isIncome && !r.isSettled).fold(0.0, (sum, item) => sum + item.amount);
  }

  static double get totalProfitDistributed {
    return globalMembers.fold(0.0, (sum, item) => sum + item.profitEarned);
  }

  static double get currentNetProfit {
    double profit = currentBusinessIncome - currentBusinessExpense;
    return profit > 0 ? profit : 0.0;
  }
}
