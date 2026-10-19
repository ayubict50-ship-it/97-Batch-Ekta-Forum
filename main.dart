import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SamobayApp());
}

// গ্লোবাল ভ্যারিয়েবল (আপনার সমিতির স্থায়ী নাম এবং অ্যাডমিন আইডি/পাসওয়ার্ড)
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
        useMaterial3: true,
        primaryColor: const Color(0xFF0F5132),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132),
          primary: const Color(0xFF0F5132),
          secondary: const Color(0xFF20C997),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F5132), Color(0xFF0B3C25)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F5132).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, size: 60, color: Color(0xFF0F5132)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      globalSocietyName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F5132)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text("সমবায় সমিতি সার্ভিস পোর্টাল", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    ToggleButtons(
                      isSelected: [_isAdmin, !_isAdmin],
                      onPressed: (index) {
                        setState(() {
                          _isAdmin = index == 0;
                        });
                      },
                      color: Colors.black54,
                      selectedColor: Colors.white,
                      fillColor: const Color(0xFF0F5132),
                      borderRadius: BorderRadius.circular(12),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text("অ্যাডমিন", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text("সদস্য", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: _isAdmin ? "ম্যানেজার আইডি" : "সদস্য আইডি / মোবাইল",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF0F5132)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "পাসওয়ার্ড / পিন",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF0F5132)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: _handleLogin,
                        child: const Text("লগইন করুন", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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

  double get totalCollection => globalMembers.fold(0.0, (sum, item) => sum + item.deposit);
  double get totalDue => globalMembers.fold(0.0, (sum, item) => sum + item.dueAmount);

  void _showChangeAdminCredentialsDialog() {
    final adminIdController = TextEditingController(text: globalAdminId);
    final adminPassController = TextEditingController(text: globalAdminPassword);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("অ্যাডমিন সিকিউরিটি সেটিংস"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adminIdController,
              decoration: const InputDecoration(labelText: "নতুন ইউজার আইডি", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminPassController,
              decoration: const InputDecoration(labelText: "নতুন পাসওয়ার্ড", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5132), foregroundColor: Colors.white),
            onPressed: () {
              if (adminIdController.text.trim().isNotEmpty && adminPassController.text.trim().isNotEmpty) {
                setState(() {
                  globalAdminId = adminIdController.text.trim();
                  globalAdminPassword = adminPassController.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("অ্যাডমিন তথ্য আপডেট হয়েছে!")),
                );
              }
            },
            child: const Text("আপডেট"),
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
            title: const Text("ফোরাম সেটিংস ও কিস্তির স্লাব"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: societyNameController,
                      decoration: const InputDecoration(labelText: "ফোরামের নাম", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showChangeAdminCredentialsDialog,
                      icon: const Icon(Icons.security),
                      label: const Text("অ্যাডমিন ইউজার ও পাসওয়ার্ড বদলান"),
                    ),
                    const Divider(height: 25),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("🗓 কিস্তির মেয়াদের স্লাব তালিকা:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: globalInstallmentSlabs.length,
                      itemBuilder: (context, index) {
                        final slab = globalInstallmentSlabs[index];
                        return Card(
                          color: const Color(0xFFE8F5E9),
                          child: ListTile(
                            dense: true,
                            title: Text("${slab.startDate.day}/${slab.startDate.month}/${slab.startDate.year} হতে ${slab.endDate.day}/${slab.endDate.month}/${slab.endDate.year}"),
                            subtitle: Text("মাসিক কিস্তি: ৳${slab.amount.toStringAsFixed(0)}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.teal, size: 18),
                                  onPressed: () {
                                    _showEditSlabDialog(context, slab, () {
                                      setDialogState(() {});
                                      setState(() {});
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      globalInstallmentSlabs.removeWhere((s) => s.id == slab.id);
                                    });
                                    setState(() {});
                                  },
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5132), foregroundColor: Colors.white),
                onPressed: () {
                  if (societyNameController.text.trim().isNotEmpty) {
                    setState(() {
                      globalSocietyName = societyNameController.text.trim();
                    });
                    Navigator.pop(ctx);
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

  void _showEditSlabDialog(BuildContext context, InstallmentSlab slab, VoidCallback onUpdated) {
    final amountController = TextEditingController(text: slab.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("স্লাব এডিট করুন"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "কিস্তির টাকা", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              double? amt = double.tryParse(amountController.text.trim());
              if (amt != null && amt > 0) {
                slab.amount = amt;
                onUpdated();
                Navigator.pop(ctx);
              }
            },
            child: const Text("আপডেট"),
          )
        ],
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
            title: const Text("নতুন ব্যবসার প্রজেক্ট পোস্টিং"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Radio<bool>(value: true, groupValue: isIncome, onChanged: (val) => setDialogState(() => isIncome = val!)),
                    const Text("লাভ (+)"),
                    Radio<bool>(value: false, groupValue: isIncome, onChanged: (val) => setDialogState(() => isIncome = val!)),
                    const Text("খরচ (-)"),
                  ],
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "বিবরণ (যেমন: জমি বিক্রি)", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "টাকার পরিমাণ", border: OutlineInputBorder())),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isIncome ? Colors.green : Colors.red, foregroundColor: Colors.white),
                onPressed: () {
                  double? amt = double.tryParse(amountController.text.trim());
                  if (titleController.text.isNotEmpty && amt != null && amt > 0) {
                    setState(() {
                      globalBusinessRecords.add(BusinessRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        amount: amt,
                        isIncome: isIncome,
                        date: postingDate,
                      ));
                    });
                    Navigator.pop(ctx);
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
      builder: (ctx) => AlertDialog(
        title: const Text("📊 লাভ-ক্ষতি খতিয়ান ও রিপোর্ট"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: globalBusinessRecords.length,
            itemBuilder: (context, index) {
              final record = globalBusinessRecords[index];
              return ListTile(
                title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${record.date.day}/${record.date.month}/${record.date.year}"),
                trailing: Text("${record.isIncome ? '+' : '-'}৳${record.amount}", style: TextStyle(color: record.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বন্ধ করুন")),
        ],
      ),
    );
  }

  void _distributeNetProfit() {
    double netP = SamobayFinance.netProfit;
    double totalDepositCapital = totalCollection;

    if (totalDepositCapital == 0 || netP <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("বণ্টন করার মতো পর্যাপ্ত নিট লাভ নেই!")));
      return;
    }

    setState(() {
      for (var member in globalMembers) {
        double shareRatio = member.deposit / totalDepositCapital;
        double memberProfit = netP * shareRatio;
        member.profitEarned += memberProfit;
        member.transactions.add(TransactionHistory(
          date: DateTime.now(),
          amount: memberProfit,
          paymentMethod: 'প্রজেক্ট নিট লাভ বণ্টন',
          isProfit: true,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("৳${netP.toStringAsFixed(2)} লাভ সদস্য মূলধনের অনুপাতে বণ্টন সম্পন্ন!")),
    );
  }

  void _showAddMemberDialog() {
    _nameController.clear();
    _mobileController.clear();
    _initialDepositController.clear();
    _pinController.text = '1234';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("নতুন সদস্য যোগ করুন"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "সদস্যের নাম")),
            TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "মোবাইল নম্বর")),
            TextField(controller: _initialDepositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মোট জমা সঞ্চয়")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                double initDeposit = double.tryParse(_initialDepositController.text.trim()) ?? 0.0;
                setState(() {
                  globalMembers.add(Member(
                    id: (100 + globalMembers.length + 1).toString(),
                    name: _nameController.text.trim(),
                    mobile: _mobileController.text.trim(),
                    pin: _pinController.text.trim(),
                    deposit: initDeposit,
                    joinDate: DateTime.now(),
                    transactions: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("সংরক্ষণ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          globalSocietyName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F5132),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSocietySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5132), Color(0xFF198754)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "📊 $globalSocietyName - সার্বিক খতিয়ান",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black),
                        onPressed: _showAddBusinessPostingDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("লাভ পোস্টিং", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white30),
                  Text("• বর্তমান কিস্তি হার: ৳${globalInstallmentSlabs.isNotEmpty ? globalInstallmentSlabs.last.amount.toStringAsFixed(0) : '0'}/মাস", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text("• মোট সঞ্চয় (মূলধন): ৳$totalCollection", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  Text("• মোট ব্যবসায়িক মুনাফা: ৳${SamobayFinance.totalBusinessIncome}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  Text("• নিট বণ্টনযোগ্য লাভ: ৳${SamobayFinance.netProfit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("• মোট বকেয়া (ডিউ): ৳$totalDue", style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                          onPressed: _showManageBusinessRecordsDialog,
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text("লাভ-ক্ষতি রিপোর্ট", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFD7E14), foregroundColor: Colors.white),
                          onPressed: _distributeNetProfit,
                          icon: const Icon(Icons.calculate, size: 16),
                          label: const Text("অটো লাভ বণ্টন", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("👥 সকল সদস্যের তালিকা:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F5132))),
              ),
            ),
            globalMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("এখনো কোনো সদস্য যুক্ত করা হয়নি।", style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalMembers.length,
                    itemBuilder: (context, index) {
                      final member = globalMembers[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0F5132),
                            child: Text(member.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("জমা: ৳${member.deposit} | ব্যালেন্স: ৳${member.totalBalance.toStringAsFixed(1)}"),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        backgroundColor: const Color(0xFF0F5132),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("সদস্য যুক্ত করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showDepositDialog() {
    _amountController.clear();
    _trxController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("অনলাইন সঞ্চয় জমা"),
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
                          if (val != null) setDialogState(() => _selectedMethod = val);
                        },
                      ),
                      const Text("bKash"),
                      const SizedBox(width: 15),
                      Radio<String>(
                        value: 'Bank',
                        groupValue: _selectedMethod,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _selectedMethod = val);
                        },
                      ),
                      const Text("ডাচ-বাংলা ব্যাংক"),
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
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("বিকাশ নম্বর কপি করা হয়েছে!")));
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
                          const Text("ডাচ-বাংলা ব্যাংক পিএলসি (কালীগঞ্জ শাখা):", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          const Text("অ্যাকাউন্ট নাম: MD. AYUB HOSSAIN BHUIYAN", style: TextStyle(fontSize: 11)),
                          Row(
                            children: [
                              const SelectableText("2391570011548", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: "2391570011548"));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ব্যাংক অ্যাকাউন্ট নম্বর কপি করা হয়েছে!")));
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
                      labelText: _selectedMethod == 'bKash' ? "bKash TrxID" : "ডিপোজিট স্লিপ / ট্রানজেকশন নম্বর",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5132), foregroundColor: Colors.white),
                onPressed: () {
                  double? amount = double.tryParse(_amountController.text.trim());
                  if (amount != null && amount > 0 && _trxController.text.isNotEmpty) {
                    setState(() {
                      widget.member.deposit += amount;
                      widget.member.transactions.add(TransactionHistory(
                        date: DateTime.now(),
                        amount: amount,
                        paymentMethod: _selectedMethod == 'bKash' ? 'bKash Send Money' : 'ডাচ-বাংলা ব্যাংক (কালীগঞ্জ শাখা)',
                        trxId: _trxController.text.trim(),
                      ));
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("৳$amount সঞ্চয় রেকর্ড করা হয়েছে!")));
                  }
                },
                child: const Text("কনফার্ম করুন"),
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
        title: Text(globalSocietyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F5132),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 সদস্য: ${widget.member.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5132))),
                  const Divider(),
                  Text("• মোট জমা সঞ্চয়: ৳${widget.member.deposit}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("• মোট অর্জিত লাভ: ৳${widget.member.profitEarned.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.blue)),
                  Text("• সর্বমোট ব্যালেন্স: ৳${widget.member.totalBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5132), foregroundColor: Colors.white),
                onPressed: _showDepositDialog,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text("অনলাইনে কিস্তি জমা দিন (bKash / Bank)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
