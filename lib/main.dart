import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SamobayApp());
}

// গ্লোবাল ভ্যারিয়েবল (সমিতির স্থায়ী নাম এবং অ্যাডমিন আইডি/পাসওয়ার্ড)
String globalSocietyName = '৯৭ ব্যাচ একতা ফোরাম';
String globalAdminId = 'admin';
String globalAdminPassword = '1234';

// কিস্তির মেয়াদের স্লাব মডেল
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
}

// ডাইনামিক স্লাব তালিকা
List<InstallmentSlab> globalInstallmentSlabs = [
  InstallmentSlab(
    id: '1',
    startDate: DateTime(2019, 1, 1),
    endDate: DateTime(2023, 12, 31),
    amount: 1000.0,
  ),
  InstallmentSlab(
    id: '2',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2035, 12, 31),
    amount: 2000.0,
  ),
];

class SamobayApp extends StatelessWidget {
  const SamobayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: globalSocietyName,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ব্যবসায়িক বিনিয়োগ/আয়ের মডেল
class BusinessRecord {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  BusinessRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

// লেনদেনের হিস্ট্রি মডেল
class TransactionHistory {
  final DateTime date;
  final double amount;
  final String paymentMethod;
  final String trxId;
  final bool isProfit;

  TransactionHistory({
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.trxId = '',
    this.isProfit = false,
  });
}

// সদস্য মডেল ক্লাস
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

  double get previousDepositAmount {
    return deposit - lastDepositAmount;
  }

  double get expectedTotalTarget {
    DateTime now = DateTime.now();
    double totalExpected = 0.0;

    for (var slab in globalInstallmentSlabs) {
      DateTime effectiveStart = joinDate.isAfter(slab.startDate) ? joinDate : slab.startDate;
      DateTime effectiveEnd = now.isBefore(slab.endDate) ? now : slab.endDate;

      if (effectiveStart.isBefore(effectiveEnd) || effectiveStart.isAtSameMomentAs(effectiveEnd)) {
        int months = (effectiveEnd.year - effectiveStart.year) * 12 + (effectiveEnd.month - effectiveStart.month);
        if (months < 0) months = 0;
        else months += 1;

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
}

List<Member> globalMembers = [];
List<BusinessRecord> globalBusinessRecords = [];

class SamobayFinance {
  static double get totalBusinessIncome {
    return globalBusinessRecords.where((r) => r.isIncome).fold(0.0, (sum, item) => sum + item.amount);
  }

  static double get totalBusinessExpense {
    return globalBusinessRecords.where((r) => !r.isIncome).fold(0.0, (sum, item) => sum + item.amount);
  }

  static double get totalProfitDistributed {
    return globalMembers.fold(0.0, (sum, item) => sum + item.profitEarned);
  }

  static double get netProfit {
    double profit = (totalBusinessIncome - totalBusinessExpense) - totalProfitDistributed;
    return profit > 0 ? profit : 0.0;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isAdmin = true;

  void _handleLogin() {
    String inputId = _idController.text.trim();
    String inputPin = _pinController.text.trim();

    if (_isAdmin) {
      if (inputId == globalAdminId && inputPin == globalAdminPassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManagerDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ভুল ম্যানেজার আইডি বা পাসওয়ার্ড!")),
        );
      }
    } else {
      try {
        Member matchedMember = globalMembers.firstWhere(
          (m) => (m.mobile == inputId || m.id == inputId) && m.pin == inputPin,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemberDashboard(member: matchedMember),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("সঠিক সদস্য আইডি/মোবাইল এবং পিন দিন!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globalSocietyName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, size: 80, color: Colors.green),
                const SizedBox(height: 10),
                Text(
                  globalSocietyName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ToggleButtons(
                  isSelected: [_isAdmin, !_isAdmin],
                  onPressed: (index) {
                    setState(() {
                      _isAdmin = index == 0;
                    });
                  },
                  color: Colors.black,
                  selectedColor: Colors.white,
                  fillColor: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("ম্যানেজার (অ্যাডমিন)", style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("সাধারণ সদস্য", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: _isAdmin ? "ম্যানেজার আইডি" : "সদস্যের মোবাইল বা আইডি",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "পাসওয়ার্ড / পিন",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleLogin,
                    child: const Text("লগইন করুন", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _initialDepositController = TextEditingController();
  DateTime _selectedDate = DateTime(2019, 1, 1);

  double get totalCollection =>
      globalMembers.fold(0.0, (sum, item) => sum + item.deposit);

  double get totalDue =>
      globalMembers.fold(0.0, (sum, item) => sum + item.dueAmount);

  void _showChangeAdminCredentialsDialog() {
    final adminIdController = TextEditingController(text: globalAdminId);
    final adminPassController = TextEditingController(text: globalAdminPassword);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ম্যানেজার আইডি ও পাসওয়ার্ড পরিবর্তন"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adminIdController,
                decoration: const InputDecoration(
                  labelText: "নতুন ম্যানেজার ইউজার আইডি",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPassController,
                decoration: const InputDecoration(
                  labelText: "নতুন পাসওয়ার্ড / পিন",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              if (adminIdController.text.trim().isNotEmpty && adminPassController.text.trim().isNotEmpty) {
                setState(() {
                  globalAdminId = adminIdController.text.trim();
                  globalAdminPassword = adminPassController.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ম্যানেজার আইডি ও পাসওয়ার্ড সফলভাবে আপডেট করা হয়েছে!")),
                );
              }
            },
            child: const Text("আপডেট করুন"),
          ),
        ],
      ),
    );
  }

  void _showSocietySettingsDialog() {
    final societyNameController = TextEditingController(text: globalSocietyName);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("সমিতির সেটিংস ও কিস্তির স্লাবসমূহ"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: societyNameController,
                      decoration: const InputDecoration(
                        labelText: "সমিতির নাম",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade800),
                      ),
                      onPressed: () {
                        _showChangeAdminCredentialsDialog();
                      },
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text("ম্যানেজার আইডি ও পাসওয়ার্ড পরিবর্তন করুন"),
                    ),
                    const SizedBox(height: 15),
                    const Text("🗓 নির্ধারণকৃত কিস্তির মেয়াদের তালিকা:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    globalInstallmentSlabs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("কোনো কিস্তির স্লাব সেট করা নেই। নিচে চাপ দিয়ে যুক্ত করুন।", style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: globalInstallmentSlabs.length,
                            itemBuilder: (context, index) {
                              final slab = globalInstallmentSlabs[index];
                              return Card(
                                color: Colors.green.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    "মেয়াদ: ${slab.startDate.day}/${slab.startDate.month}/${slab.startDate.year} হতে ${slab.endDate.day}/${slab.endDate.month}/${slab.endDate.year}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("মাসিক কিস্তি: ৳${slab.amount.toStringAsFixed(0)}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                                        onPressed: () {
                                          _showEditSlabDialog(context, slab, () {
                                            setDialogState(() {});
                                            setState(() {});
                                          });
                                        },
                                        tooltip: "এই স্লাবটি সংশোধন করুন",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setDialogState(() {
                                            globalInstallmentSlabs.removeWhere((s) => s.id == slab.id);
                                          });
                                          setState(() {});
                                        },
                                        tooltip: "মুছে ফেলুন",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        _showAddNewSlabDialog(context, () {
                          setDialogState(() {});
                          setState(() {});
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("নতুন মেয়াদের কিস্তি যোগ করুন"),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  if (societyNameController.text.trim().isNotEmpty) {
                    setState(() {
                      globalSocietyName = societyNameController.text.trim();
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("সেটিংস সফলভাবে আপডেট হয়েছে!")),
                    );
                  }
                },
                child: const Text("সংরক্ষণ করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSlabDialog(BuildContext context, InstallmentSlab slab, VoidCallback onUpdated) {
    final amountController = TextEditingController(text: slab.amount.toStringAsFixed(0));
    DateTime startDate = slab.startDate;
    DateTime endDate = slab.endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("কিস্তির মেয়াদ ও রেট সংশোধন"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "মাসিক কিস্তির পরিমাণ (BDT)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text("শুরু: ${startDate.day}/${startDate.month}/${startDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2040));
                          if (picked != null) setDialogState(() => startDate = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text("শেষ: ${endDate.day}/${endDate.month}/${endDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2040));
                          if (picked != null) setDialogState(() => endDate = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                onPressed: () {
                  double? amt = double.tryParse(amountController.text.trim());
                  if (amt != null && amt > 0) {
                    slab.startDate = startDate;
                    slab.endDate = endDate;
                    slab.amount = amt;
                    onUpdated();
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("আপডেট করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddNewSlabDialog(BuildContext context, VoidCallback onAdded) {
    final amountController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime(2035, 12, 31);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("নতুন কিস্তির মেয়াদ যোগ"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "মাসিক কিস্তির পরিমাণ (BDT)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text("শুরু: ${startDate.day}/${startDate.month}/${startDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2040));
                          if (picked != null) setDialogState(() => startDate = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text("শেষ: ${endDate.day}/${endDate.month}/${endDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2040));
                          if (picked != null) setDialogState(() => endDate = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                onPressed: () {
                  double? amt = double.tryParse(amountController.text.trim());
                  if (amt != null && amt > 0) {
                    globalInstallmentSlabs.add(
                      InstallmentSlab(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        startDate: startDate,
                        endDate: endDate,
                        amount: amt,
                      ),
                    );
                    onAdded();
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("যোগ করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBusinessPostingDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isIncome = true;
    DateTime postingDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("ব্যবসার লাভ/খরচ পোস্টিং"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isIncome,
                        onChanged: (val) => setDialogState(() => isIncome = val!),
                      ),
                      const Text("ব্যবসার লাভ (+)"),
                      Radio<bool>(
                        value: false,
                        groupValue: isIncome,
                        onChanged: (val) => setDialogState(() => isIncome = val!),
                      ),
                      const Text("প্রজেক্ট খরচ (-)"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "বিবরণ (যেমন: ৭০ লক্ষ টাকার প্রজেক্ট লাভ)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "টাকার পরিমাণ (BDT)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("পোস্টিং তারিখ: ${postingDate.day}/${postingDate.month}/${postingDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: postingDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setDialogState(() => postingDate = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIncome ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  double? amt = double.tryParse(amountController.text.trim());
                  if (titleController.text.isNotEmpty && amt != null && amt > 0) {
                    setState(() {
                      globalBusinessRecords.add(
                        BusinessRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          amount: amt,
                          isIncome: isIncome,
                          date: postingDate,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${titleController.text} এর পোস্টিং সফল হয়েছে!")),
                    );
                  }
                },
                child: const Text("পোস্টিং দিন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManageBusinessRecordsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("📊 ব্যবসার লাভ-ক্ষতি খতিয়ান ও রিপোর্ট"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.green.shade50,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("মোট ব্যবসায়িক মুনাফা: ৳${SamobayFinance.totalBusinessIncome.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text("মোট প্রজেক্ট খরচ: ৳${SamobayFinance.totalBusinessExpense.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          Text("অবশিষ্ট নিট লাভ: ৳${SamobayFinance.netProfit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("🗓 তারিখভিত্তিক পোস্টিং এর বিস্তারিত তালিকা:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    globalBusinessRecords.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("এখনো কোনো লাভ বা খরচের পোস্টিং দেওয়া হয়নি।", textAlign: TextAlign.center),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: globalBusinessRecords.length,
                            itemBuilder: (context, index) {
                              final record = globalBusinessRecords[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: record.isIncome ? Colors.green.shade100 : Colors.red.shade100,
                                    child: Icon(
                                      record.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: record.isIncome ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text("তারিখ: ${record.date.day}/${record.date.month}/${record.date.year} | ধরন: ${record.isIncome ? 'লাভ (+)' : 'প্রজেক্ট খরচ (-)'}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${record.isIncome ? '+' : '-'}৳${record.amount.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: record.isIncome ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            globalBusinessRecords.removeWhere((r) => r.id == record.id);
                                          });
                                          setDialogState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("${record.title} মুছে ফেলা হয়েছে!")),
                                          );
                                        },
                                        tooltip: "এন্ট্রি ডিলিট করুন",
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ব্যবসার সম্পূর্ণ লাভ-ক্ষতির খতিয়ান PDF ডাউনলোড হয়েছে!")),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text("PDF ডাউনলোড/প্রিন্ট"),
              ),
            ],
          );
        },
      ),
    );
  }

  // বর্তমান সঞ্চয়/মূলধনের অনুপাতে ন্যায়সংগত লাভ বন্টন
  void _distributeNetProfit() {
    double netP = SamobayFinance.netProfit;
    double totalDepositCapital = totalCollection;

    if (totalDepositCapital == 0 || netP <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("বণ্টন করার মতো পর্যাপ্ত নিট লাভ নেই!")),
      );
      return;
    }

    setState(() {
      for (var member in globalMembers) {
        // বর্তমান সঞ্চয়/মূলধনের অনুপাতে লাভ বণ্টন
        double shareRatio = member.deposit / totalDepositCapital;
        double memberProfit = netP * shareRatio;

        member.profitEarned += memberProfit;
        member.transactions.add(
          TransactionHistory(
            date: DateTime.now(),
            amount: memberProfit,
            paymentMethod: 'প্রজেক্ট নিট লাভ বণ্টন (মূলধনের অনুপাতে)',
            isProfit: true,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("নতুন প্রজেক্টের ৳${netP.toStringAsFixed(2)} লাভ বর্তমান মূলধনের অনুপাতে ন্যায়সংগতভাবে বণ্টন সম্পন্ন!")),
    );
  }

  void _showAddInstallmentDialog(Member member) {
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: 'মাসিক কিস্তি জমা');
    DateTime depositDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("${member.name}-এর নতুন কিস্তি জমা"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "নতুন জমার পরিমাণ (BDT)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "জমার বিবরণ / মাধ্যম",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("জমার তারিখ: ${depositDate.day}/${depositDate.month}/${depositDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: depositDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              depositDate = picked;
                            });
                          }
                        },
                        child: const Text("তারিখ বদলান"),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  double? amt = double.tryParse(amountController.text.trim());
                  if (amt != null && amt > 0) {
                    setState(() {
                      member.deposit += amt;
                      member.transactions.add(
                        TransactionHistory(
                          date: depositDate,
                          amount: amt,
                          paymentMethod: noteController.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${member.name}-এর ৳$amt কিস্তি জমা সফলভাবে রেকর্ড হয়েছে!")),
                    );
                  }
                },
                child: const Text("জমা কনফার্ম করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditMemberDialog(Member member) {
    final editNameController = TextEditingController(text: member.name);
    final editMobileController = TextEditingController(text: member.mobile);
    final editDepositController = TextEditingController(text: member.deposit.toString());
    DateTime tempJoinDate = member.joinDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("${member.name}-এর তথ্য সংশোধন"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editNameController,
                    decoration: const InputDecoration(labelText: "সদস্যের নাম", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editMobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "মোবাইল নম্বর", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editDepositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "মোট জমা সংশোধন (BDT)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("যোগদান: ${tempJoinDate.day}/${tempJoinDate.month}/${tempJoinDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: tempJoinDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              tempJoinDate = picked;
                            });
                          }
                        },
                        child: const Text("তারিখ বদলান"),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                onPressed: () {
                  if (editNameController.text.trim().isNotEmpty && editMobileController.text.trim().isNotEmpty) {
                    setState(() {
                      member.name = editNameController.text.trim();
                      member.mobile = editMobileController.text.trim();
                      member.deposit = double.tryParse(editDepositController.text) ?? member.deposit;
                      member.joinDate = tempJoinDate;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("সদস্যের তথ্য সফলভাবে আপডেট করা হয়েছে!")),
                    );
                  }
                },
                child: const Text("আপডেট করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resetMemberPinDialog(Member member) {
    final newPinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${member.name}-এর পিন রিসেট"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("বর্তমান পিন: ${member.pin}"),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "নতুন পিন লিখুন",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              if (newPinController.text.trim().isNotEmpty) {
                setState(() {
                  member.pin = newPinController.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${member.name}-এর পিন সফলভাবে আপডেট করা হয়েছে!")),
                );
              }
            },
            child: const Text("আপডেট করুন"),
          ),
        ],
      ),
    );
  }

 void _sendSmsDialog(Member member) {
  double todayDeposit = member.lastDepositAmount;
  double previousDeposit = member.previousDepositAmount;
  double totalDeposit = member.deposit;
  double due = member.dueAmount;

  String smsMessage =
      "প্রিয় ${member.name}, আজকে আপনি ${todayDeposit.toStringAsFixed(0)} টাকা জমা দিলেন। আগের জমা ছিল ${previousDeposit.toStringAsFixed(0)} টাকা। মোট হলো ${totalDeposit.toStringAsFixed(0)} টাকা। বকেয়া ${due.toStringAsFixed(0)} টাকা। ধন্যবাদ, $globalSocietyName";

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("${member.name}-কে SMS পাঠান"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("প্রাপক নম্বর: ${member.mobile}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SelectableText(
              smsMessage,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("বাতিল"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final Uri smsUri = Uri(
              scheme: 'sms',
              path: member.mobile,
              queryParameters: <String, String>{
                'body': smsMessage,
              },
            );
            if (await canLaunchUrl(smsUri)) {
              await launchUrl(smsUri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("SMS অ্যাপ ওপেন করা যায়নি")),
              );
            }
          },
          icon: const Icon(Icons.send, size: 16),
          label: const Text("SMS পাঠাতেন"),
        ),
      ],
    ),
  );
}

  void _showMemberStatementDialog(Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${member.name}-এর বিস্তারিত হিসাব"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("আইডি: ${member.id} | মোবাইল: ${member.mobile}"),
              Text("• মূল সঞ্চয় (কিস্তি): ৳${member.deposit}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("• অর্জিত লাভ: ৳${member.profitEarned.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text("• সর্বমোট ব্যালেন্স: ৳${member.totalBalance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              if (member.dueAmount > 0)
                Text("• বকেয়া (${member.dueMonthsCount} মাসের হিসাবে): ৳${member.dueAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
              else if (member.advanceAmount > 0)
                Text("• অতিরিক্ত জমা (Advance): ৳${member.advanceAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))
              else
                const Text("• বকেয়া: ৳০ (সম্পূর্ণ পরিশোধিত)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(),
              const Text("🗓 জমার ইতিহাস (কিস্তি ও লাভ):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: member.transactions.isEmpty
                    ? const Center(child: Text("কোনো লেনদেন রেকর্ড নেই।"))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: member.transactions.length,
                        itemBuilder: (context, idx) {
                          final tx = member.transactions[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              tx.isProfit ? Icons.trending_up : Icons.check_circle,
                              color: tx.isProfit ? Colors.blue : Colors.green,
                              size: 18,
                            ),
                            title: Text("${tx.date.day}/${tx.date.month}/${tx.date.year} - ৳${tx.amount.toStringAsFixed(2)}"),
                            subtitle: Text("${tx.paymentMethod} ${tx.trxId.isNotEmpty ? '(TrxID: ${tx.trxId})' : ''}"),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বন্ধ করুন"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${member.name}-এর বিস্তারিত স্টেটমেন্ট PDF ডাউনলোড হয়েছে!")),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text("PDF ডাউনলোড"),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    _nameController.clear();
    _mobileController.clear();
    _initialDepositController.clear();
    _pinController.text = '1234';
    _selectedDate = DateTime(2019, 1, 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("সদস্য যুক্ত করুন"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "সদস্যের নাম")),
                  TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "মোবাইল নম্বর")),
                  TextField(controller: _initialDepositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মোট জমাকৃত সঞ্চয় (BDT)")),
                  TextField(controller: _pinController, decoration: const InputDecoration(labelText: "পিন/পাসওয়ার্ড (প্রাথমিক)")),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("যোগদান: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        child: const Text("তারিখ পরিবর্তন"),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty && _mobileController.text.trim().isNotEmpty) {
                    double initDeposit = double.tryParse(_initialDepositController.text.trim()) ?? 0.0;
                    List<TransactionHistory> initTx = [];
                    if (initDeposit > 0) {
                      initTx.add(TransactionHistory(
                        date: _selectedDate,
                        amount: initDeposit,
                        paymentMethod: 'প্রাথমিক সঞ্চয় জমা',
                      ));
                    }

                    setState(() {
                      globalMembers.add(
                        Member(
                          id: (100 + globalMembers.length + 1).toString(),
                          name: _nameController.text.trim(),
                          mobile: _mobileController.text.trim(),
                          pin: _pinController.text.trim(),
                          deposit: initDeposit,
                          joinDate: _selectedDate,
                          transactions: initTx,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("দয়া করে নাম ও মোবাইল নম্বর ঘর পূরণ করুন!")),
                    );
                  }
                },
                child: const Text("সংরক্ষণ"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globalSocietyName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "সমিতির সেটিংস (কিস্তির স্লাব ও অ্যাডমিন তথ্য)",
            onPressed: _showSocietySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: "ব্যবসার লাভ/খরচ পোস্টিং দিন",
            onPressed: _showAddBusinessPostingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "📊 $globalSocietyName - সার্বিক হিসাব",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: _showAddBusinessPostingDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("লাভ পোস্টিং", style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                  const Divider(),
                  Text("• বর্তমান কিস্তি: ৳${globalInstallmentSlabs.isNotEmpty ? globalInstallmentSlabs.last.amount.toStringAsFixed(0) : '0'}/মাস", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Text("• মোট সঞ্চয় (মূলধন): $totalCollection টাকা", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("• মোট ব্যবসায়িক মুনাফা: ${SamobayFinance.totalBusinessIncome} টাকা", style: const TextStyle(fontSize: 14, color: Colors.green)),
                  Text("• মোট প্রজেক্ট খরচ: ${SamobayFinance.totalBusinessExpense} টাকা", style: const TextStyle(fontSize: 14, color: Colors.red)),
                  Text("• মোট বণ্টনকৃত লাভ: ${SamobayFinance.totalProfitDistributed.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.bold)),
                  Text("• নিট বণ্টনযোগ্য মুনাফা (অবশিষ্ট): ${SamobayFinance.netProfit.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
                  Text("• মোট বকেয়া (ডিউ): $totalDue টাকা", style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                          onPressed: _showManageBusinessRecordsDialog,
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text("লাভ/ক্ষতি খতিয়ান ও রিপোর্ট", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4)),
                          onPressed: _distributeNetProfit,
                          icon: const Icon(Icons.calculate, size: 16),
                          label: const Text("অটো লাভ বণ্টন", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("সকল সদস্যের তালিকা:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            globalMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text(
                        "এখনো কোনো সদস্য যোগ করা হয়নি।\nনিচের 'সদস্য যুক্ত করুন' বোতামে চাপ দিন।",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
               ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: globalMembers.length,
        itemBuilder: (context, index) {
          final member = globalMembers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  // ১. আইডি ও নাম
                  Expanded(
                    flex: 3,
                    child: Text(
                      "${member.id}. ${member.name}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ২. জমা
                  Expanded(
                    flex: 2,
                    child: Text(
                      "জমা: ${member.deposit}৳",
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ৩. বকেয়া/ডিউ
                  Expanded(
                    flex: 3,
                    child: Text(
                      member.dueAmount > 0 
                          ? "বকেয়া: ${member.dueAmount.toStringAsFixed(0)}৳" 
                          : "বকেয়া: ০৳ (পরিশোধিত)",
                      style: TextStyle(
                        fontSize: 11, 
                        color: member.dueAmount > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () => _showAddInstallmentDialog(member),
                                tooltip: "নতুন কিস্তি জমা দিন",
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showEditMemberDialog(member),
                                tooltip: "সদস্যের তথ্য সংশোধন করুন",
                              ),
                              IconButton(
                                icon: const Icon(Icons.key, color: Colors.orange),
                                onPressed: () => _resetMemberPinDialog(member),
                                tooltip: "পিন রিসেট করুন",
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.blue),
                                onPressed: () => _sendSmsDialog(member),
                                tooltip: "SMS পাঠান",
                              ),
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.green),
                                onPressed: () => _showMemberStatementDialog(member),
                                tooltip: "বিস্তারিত হিসাব ও ডাউনলোড",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("সদস্য যুক্ত করুন", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class MemberDashboard extends StatefulWidget {
  final Member member;
  const MemberDashboard({super.key, required this.member});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _trxController = TextEditingController();
  String _selectedMethod = 'bKash';

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("আপনার পিন পরিবর্তন করুন"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "বর্তমান পিন", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "নতুন পিন", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              if (oldPinController.text == widget.member.pin) {
                if (newPinController.text.trim().isNotEmpty) {
                  setState(() {
                    widget.member.pin = newPinController.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("আপনার পিন সফলভাবে পরিবর্তন করা হয়েছে!")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("বর্তমান পিন সঠিক নয়!")),
                );
              }
            },
            child: const Text("পরিবর্তন করুন"),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    _amountController.clear();
    _trxController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("অনলাইন জমার মাধ্যম বিবরণ"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("পেমেন্ট মাধ্যম বেছে নিন:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'bKash',
                        groupValue: _selectedMethod,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedMethod = val;
                            });
                          }
                        },
                      ),
                      const Text("bKash"),
                      const SizedBox(width: 15),
                      Radio<String>(
                        value: 'Bank',
                        groupValue: _selectedMethod,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedMethod = val;
                            });
                          }
                        },
                      ),
                      const Text("সোনালী ব্যাংক"),
                    ],
                  ),
                  const Divider(),
                  if (_selectedMethod == 'bKash') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.pink.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("বিকাশ পার্সোনাল (Send Money):", style: TextStyle(fontSize: 12, color: Colors.pink, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const SelectableText("01728021804", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.pink),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: "01728021804"));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("বিকাশ নম্বর কপি করা হয়েছে!")),
                                  );
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("সোনালী ব্যাংক পিএলসি:", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          const Text("অ্যাকাউন্ট নম্বর:", style: TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              const SelectableText("0204801010355", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: "0204801010355"));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ব্যাংক অ্যাকাউন্ট নম্বর কপি করা হয়েছে!")),
                                  );
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "টাকার পরিমাণ (BDT)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _trxController,
                    decoration: InputDecoration(
                      labelText: _selectedMethod == 'bKash' ? "bKash TrxID (ট্রানজেকশন আইডি)" : "ডিপোজিট স্লিপ / ট্রানজেকশন নম্বর",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod == 'bKash' ? Colors.pink : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  double? amount = double.tryParse(_amountController.text.trim());
                  if (amount != null && amount > 0 && _trxController.text.isNotEmpty) {
                    setState(() {
                      widget.member.deposit += amount;
                      widget.member.transactions.add(
                        TransactionHistory(
                          date: DateTime.now(),
                          amount: amount,
                          paymentMethod: _selectedMethod == 'bKash' ? 'bKash Send Money' : 'সোনালী ব্যাংক',
                          trxId: _trxController.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("৳$amount টাকা সঞ্চয় জমা হিসেবে রেকর্ড করা হয়েছে!")),
                    );
                  }
                },
                child: const Text("জমা কনফার্ম করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globalSocietyName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: "পিন পরিবর্তন করুন",
            onPressed: _showChangePinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("👤 ${widget.member.name}-এর খতিয়ান", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green)),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: _showChangePinDialog,
                        icon: const Icon(Icons.lock_reset, size: 16),
                        label: const Text("পিন বদলান", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text("• সদস্য আইডি: ${widget.member.id}", style: const TextStyle(fontSize: 15)),
                  Text("• মূল সঞ্চয় (কিস্তি জমা): ৳${widget.member.deposit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("• অর্জিত মোট লাভ: ৳${widget.member.profitEarned.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text("• সর্বমোট ব্যালেন্স: ৳${widget.member.totalBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  if (widget.member.dueAmount > 0)
                    Text("• বকেয়া কিস্তি (${widget.member.dueMonthsCount} মাসের হিসাবে): ৳${widget.member.dueAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold))
                  else if (widget.member.advanceAmount > 0)
                    Text("• অতিরিক্ত জমা (Advance): ৳${widget.member.advanceAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.teal, fontWeight: FontWeight.bold))
                  else
                    const Text("• বকেয়া: ৳০ (পরিশোধিত)", style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                onPressed: _showDepositDialog,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text("অনলাইনে কিস্তি জমা দিন (bKash / Bank)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("🗓 আপনার জমা ও লাভের ইতিহাস:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.member.transactions.isEmpty
                  ? const Center(child: Text("এখনো কোনো জমা এন্ট্রি হয়নি।"))
                  : ListView.builder(
                      itemCount: widget.member.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = widget.member.transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.isProfit ? Colors.blue : (tx.paymentMethod.contains('bKash') ? Colors.pink : Colors.green),
                              child: Icon(tx.isProfit ? Icons.trending_up : Icons.attach_money, color: Colors.white),
                            ),
                            title: Text("${tx.isProfit ? 'লাভ যোগ:' : 'জমা:'} ৳${tx.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("তারিখ: ${tx.date.day}/${tx.date.month}/${tx.date.year} | মাধ্যম: ${tx.paymentMethod}"),
                            trailing: tx.trxId.isNotEmpty ? Text("ID: ${tx.trxId}", style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${widget.member.name}-এর বিস্তারিত স্টেটমেন্ট ডাউনলোড করা হয়েছে!")),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text(
                  "বিস্তারিত স্টেটমেন্ট ডাউনলোড করুন",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
