import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'due_reminder_feature.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  runApp(const SamobayApp());
}

String globalSocietyName = '৯৭ ব্যাচ একতা ফোরাম';
String globalAdminId = 'admin';
String globalAdminPassword = '1234';
const String globalAdminRecoveryCode = '97EKTA';

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
        id: json['id']?.toString() ?? '',
        startDate: DateTime.parse(json['startDate'].toString()),
        endDate: DateTime.parse(json['endDate'].toString()),
        amount: ((json['amount'] ?? 0) as num).toDouble(),
      );
}

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
      home: const SplashScreen(),
    );
  }
}

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
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        amount: ((json['amount'] ?? 0) as num).toDouble(),
        isIncome: json['isIncome'] == true,
        date: DateTime.parse(json['date'].toString()),
        isSettled: json['isSettled'] ?? false,
        batchId: json['batchId']?.toString(),
      );
}

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
        date: DateTime.parse(json['date'].toString()),
        amount: ((json['amount'] ?? 0) as num).toDouble(),
        paymentMethod: json['paymentMethod']?.toString() ?? '',
        trxId: json['trxId']?.toString() ?? '',
        isProfit: json['isProfit'] ?? false,
        batchId: json['batchId']?.toString(),
        status: json['status']?.toString() ?? 'approved',
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

  factory Member.fromJson(Map<String, dynamic> json) {
    List<TransactionHistory> parsedTx = [];
    if (json['transactions'] is List) {
      for (var t in (json['transactions'] as List)) {
        try {
          if (t is Map<String, dynamic>) {
            parsedTx.add(TransactionHistory.fromJson(t));
          } else if (t is Map) {
            parsedTx.add(TransactionHistory.fromJson(Map<String, dynamic>.from(t)));
          }
        } catch (e) {
          debugPrint("Transaction parse error: $e");
        }
      }
    }

    return Member(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      deposit: ((json['deposit'] ?? 0) as num).toDouble(),
      profitEarned: ((json['profitEarned'] ?? 0) as num).toDouble(),
      joinDate: json['joinDate'] != null ? DateTime.parse(json['joinDate'].toString()) : DateTime(2019, 1, 1),
      transactions: parsedTx,
    );
  }
}

List<Member> globalMembers = [];
List<BusinessRecord> globalBusinessRecords = [];
String? lastDistributionBatchId;

class CloudDatabaseService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> syncAllDataToCloud() async {
    try {
      List membersList = globalMembers.map((m) => m.toJson()).toList();
      await _db.collection('society_data').doc('members').set({'list': membersList});

      List businessList = globalBusinessRecords.map((b) => b.toJson()).toList();
      await _db.collection('society_data').doc('business').set({'list': businessList});

      List slabsList = globalInstallmentSlabs.map((s) => s.toJson()).toList();
      await _db.collection('society_data').doc('slabs').set({'list': slabsList});

      await _db.collection('society_data').doc('settings').set({
        'societyName': globalSocietyName,
        'adminId': globalAdminId,
        'adminPassword': globalAdminPassword,
        'lastDistributionBatchId': lastDistributionBatchId,
      });
    } catch (e) {
      debugPrint("Cloud Sync Error: $e");
    }
  }

  static Future<bool> loadDataFromCloud() async {
    bool anyLoaded = false;

    try {
      var membersDoc = await _db.collection('society_data').doc('members').get();
      if (membersDoc.exists && membersDoc.data()?['list'] != null) {
        List l = membersDoc.data()!['list'];
        List<Member> parsedMembers = [];
        for (var item in l) {
          try {
            if (item is Map<String, dynamic>) {
              parsedMembers.add(Member.fromJson(item));
            } else if (item is Map) {
              parsedMembers.add(Member.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (e) {
            debugPrint("Member parse error: $e");
          }
        }
        if (parsedMembers.isNotEmpty || l.isEmpty) {
          globalMembers = parsedMembers;
          anyLoaded = true;
        }
      }
    } catch (e) {
      debugPrint("Members Cloud Load Error: $e");
    }

    try {
      var bizDoc = await _db.collection('society_data').doc('business').get();
      if (bizDoc.exists && bizDoc.data()?['list'] != null) {
        List l = bizDoc.data()!['list'];
        List<BusinessRecord> parsedBiz = [];
        for (var item in l) {
          try {
            if (item is Map<String, dynamic>) {
              parsedBiz.add(BusinessRecord.fromJson(item));
            } else if (item is Map) {
              parsedBiz.add(BusinessRecord.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (e) {
            debugPrint("Business parse error: $e");
          }
        }
        if (parsedBiz.isNotEmpty || l.isEmpty) {
          globalBusinessRecords = parsedBiz;
          anyLoaded = true;
        }
      }
    } catch (e) {
      debugPrint("Business Cloud Load Error: $e");
    }

    try {
      var slabDoc = await _db.collection('society_data').doc('slabs').get();
      if (slabDoc.exists && slabDoc.data()?['list'] != null) {
        List l = slabDoc.data()!['list'];
        List<InstallmentSlab> parsedSlabs = [];
        for (var item in l) {
          try {
            if (item is Map<String, dynamic>) {
              parsedSlabs.add(InstallmentSlab.fromJson(item));
            } else if (item is Map) {
              parsedSlabs.add(InstallmentSlab.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (e) {
            debugPrint("Slab parse error: $e");
          }
        }
        if (parsedSlabs.isNotEmpty) {
          globalInstallmentSlabs = parsedSlabs;
          anyLoaded = true;
        }
      }
    } catch (e) {
      debugPrint("Slabs Cloud Load Error: $e");
    }

    try {
      var settingsDoc = await _db.collection('society_data').doc('settings').get();
      if (settingsDoc.exists && settingsDoc.data() != null) {
        final data = settingsDoc.data()!;
        globalSocietyName = data['societyName'] ?? globalSocietyName;
        globalAdminId = data['adminId'] ?? globalAdminId;
        globalAdminPassword = data['adminPassword'] ?? globalAdminPassword;
        lastDistributionBatchId = data['lastDistributionBatchId'];
        anyLoaded = true;
      }
    } catch (e) {
      debugPrint("Settings Cloud Load Error: $e");
    }

    return anyLoaded;
  }
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

/// RepaintBoundary দিয়ে রিপোর্ট অংশকে PNG ইমেজে রূপান্তর করে PDF ফাইলে সেভ ও ওপেন করার ফাংশন
Future<void> exportBoundaryToPdf(
  BuildContext context,
  GlobalKey boundaryKey,
  String fileName,
) async {
  try {
    final RenderRepaintBoundary? boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিপোর্ট কন্টেন্ট লোড হয়নি, অনুগ্রহ করে আবার চেষ্টা করুন।')),
        );
      }
      return;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("PNG byte conversion failed");
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final pw.Document pdf = pw.Document();
    final pw.MemoryImage pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context pdfContext) {
          return pw.Center(
            child: pw.Image(
              pdfImage,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final String actualFileName = fileName.endsWith('.pdf')
        ? fileName
        : '${fileName.replaceAll(RegExp(r'\.+$'), '')}.pdf';
    final File file = File('${directory!.path}/$actualFileName');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF ফাইল সেভ হয়েছে:\n${file.path}')),
      );
    }

    await OpenFile.open(file.path);
  } catch (e) {
    debugPrint("PDF Save Error: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF সেভ করতে সমস্যা হয়েছে: $e')),
      );
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await CloudDatabaseService.loadDataFromCloud().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Startup Load Error: $e");
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 15),
            Text("ক্লাউড ব্যাকআপ থেকে লোড হচ্ছে...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
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
  bool _obscureLoginPin = true;

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

  void _showForgotPasswordOrPinDialog() {
    if (_isAdmin) {
      final adminIdVerifyController = TextEditingController(text: _idController.text.trim());
      final recoveryCodeController = TextEditingController();
      final newPassController = TextEditingController();
      final confirmPassController = TextEditingController();
      bool obscureNewPass = true;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("🔐 ম্যানেজার পাসওয়ার্ড রিসেট"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "বর্তমান ম্যানেজার আইডি অথবা রিকভারি কোড (97EKTA) দিয়ে নতুন পাসওয়ার্ড সেট করুন।",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adminIdVerifyController,
                      decoration: const InputDecoration(
                        labelText: "বর্তমান ম্যানেজার আইডি",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: recoveryCodeController,
                      decoration: const InputDecoration(
                        labelText: "রিকভারি কোড (ঐচ্ছিক, যদি আইডি না জানেন)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified_user),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNewPass,
                      decoration: InputDecoration(
                        labelText: "নতুন পাসওয়ার্ড / পিন",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNewPass ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => obscureNewPass = !obscureNewPass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPassController,
                      obscureText: obscureNewPass,
                      decoration: const InputDecoration(
                        labelText: "নতুন পাসওয়ার্ড নিশ্চিত করুন",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    String enteredId = adminIdVerifyController.text.trim();
                    String enteredCode = recoveryCodeController.text.trim();
                    String newPass = newPassController.text.trim();
                    String confirmPass = confirmPassController.text.trim();

                    bool isAuthorized = (enteredId.isNotEmpty && enteredId == globalAdminId) ||
                        (enteredCode.isNotEmpty && enteredCode == globalAdminRecoveryCode);

                    if (!isAuthorized) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("সঠিক ম্যানেজার আইডি বা রিকভারি কোড দিন!")),
                      );
                      return;
                    }

                    if (newPass.isEmpty || newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("নতুন পাসওয়ার্ড দিন এবং উভয় ঘরে একই পাসওয়ার্ড লিখুন!")),
                      );
                      return;
                    }

                    setState(() {
                      globalAdminPassword = newPass;
                      _idController.text = globalAdminId;
                      _pinController.text = newPass;
                    });
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ম্যানেজার পাসওয়ার্ড সফলভাবে রিসেট ও ক্লাউডে সেভ হয়েছে!")),
                      );
                    }
                  },
                  child: const Text("পাসওয়ার্ড রিসেট করুন"),
                ),
              ],
            );
          },
        ),
      );
    } else {
      final memberLookupController = TextEditingController(text: _idController.text.trim());
      final memberMobileVerifyController = TextEditingController();
      final newPinController = TextEditingController();
      final confirmPinController = TextEditingController();
      bool obscureNewPin = true;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("🔑 সদস্য পিন রিসেট"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "আপনার সদস্য আইডি/মোবাইল নম্বর এবং রেজিস্টার্ড মোবাইল নম্বর মিলিয়ে নতুন পিন সেট করুন।",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: memberLookupController,
                      decoration: const InputDecoration(
                        labelText: "সদস্য আইডি বা মোবাইল নম্বর",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: memberMobileVerifyController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "রেজিস্টার্ড মোবাইল নম্বর যাচাই",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPinController,
                      obscureText: obscureNewPin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "নতুন পিন দিন",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNewPin ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => obscureNewPin = !obscureNewPin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPinController,
                      obscureText: obscureNewPin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "নতুন পিন নিশ্চিত করুন",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    String lookup = memberLookupController.text.trim();
                    String verifyMobile = memberMobileVerifyController.text.trim();
                    String newPin = newPinController.text.trim();
                    String confirmPin = confirmPinController.text.trim();

                    if (lookup.isEmpty || verifyMobile.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("সদস্য আইডি/মোবাইল এবং রেজিস্টার্ড মোবাইল নম্বর দিন!")),
                      );
                      return;
                    }

                    Member? matchedMember;
                    for (var m in globalMembers) {
                      if ((m.id == lookup || m.mobile == lookup) && m.mobile == verifyMobile) {
                        matchedMember = m;
                        break;
                      }
                    }

                    if (matchedMember == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("সদস্যের তথ্য বা রেজিস্টার্ড মোবাইল নম্বর মেলেনি!")),
                      );
                      return;
                    }

                    if (newPin.isEmpty || newPin != confirmPin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("নতুন পিন দিন এবং উভয় ঘরে একই পিন লিখুন!")),
                      );
                      return;
                    }

                    setState(() {
                      matchedMember!.pin = newPin;
                      _idController.text = matchedMember.mobile;
                      _pinController.text = newPin;
                    });
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${matchedMember.name}-এর নতুন পিন সেট ও ক্লাউডে সেভ হয়েছে!")),
                      );
                    }
                  },
                  child: const Text("পিন রিসেট করুন"),
                ),
              ],
            );
          },
        ),
      );
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
                  obscureText: _obscureLoginPin,
                  decoration: InputDecoration(
                    labelText: "পাসওয়ার্ড / পিন",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureLoginPin ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureLoginPin = !_obscureLoginPin;
                        });
                      },
                    ),
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
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _showForgotPasswordOrPinDialog,
                  icon: const Icon(Icons.help_outline, size: 18, color: Colors.teal),
                  label: Text(
                    _isAdmin ? "ম্যানেজার পাসওয়ার্ড ভুলে গেছেন? রিসেট করুন" : "সদস্য পিন ভুলে গেছেন? রিসেট করুন",
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
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

  double get totalCollection => globalMembers.fold(0.0, (sum, item) => sum + item.deposit);

  double get totalDue => globalMembers.fold(0.0, (sum, item) => sum + item.dueAmount);

  String _getBengaliMonthName(int month) {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  void _showMonthlyReportDialog() {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    final GlobalKey monthlyBoundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double monthlyDepositTotal = 0.0;
          int monthlyDepositCount = 0;
          double monthlyProfitTotal = 0.0;
          var memberMonthEntries = [];

          for (var member in globalMembers) {
            for (var tx in member.transactions) {
              if (tx.status == 'approved' &&
                  tx.date.year == selectedYear &&
                  tx.date.month == selectedMonth) {
                if (tx.isProfit) {
                  monthlyProfitTotal += tx.amount;
                } else {
                  monthlyDepositTotal += tx.amount;
                  monthlyDepositCount += 1;
                }
                memberMonthEntries.add({
                  'member': member,
                  'tx': tx,
                });
              }
            }
          }

          var monthBizRecords = globalBusinessRecords
              .where((r) => r.date.year == selectedYear && r.date.month == selectedMonth)
              .toList();

          double monthlyBizIncome = monthBizRecords.where((r) => r.isIncome).fold(0.0, (sum, r) => sum + r.amount);
          double monthlyBizExpense = monthBizRecords.where((r) => !r.isIncome).fold(0.0, (sum, r) => sum + r.amount);

          String monthLabel = "${_getBengaliMonthName(selectedMonth)} $selectedYear";

          return AlertDialog(
            title: const Text("🗓 মাস ভিত্তিক রিপোর্ট"),
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
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: "মাস নির্বাচন",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(12, (idx) {
                              int mNum = idx + 1;
                              return DropdownMenuItem<int>(
                                value: mNum,
                                child: Text(_getBengaliMonthName(mNum)),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedMonth = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: selectedYear,
                            decoration: const InputDecoration(
                              labelText: "বছর নির্বাচন",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(16, (idx) {
                              int yr = 2019 + idx;
                              return DropdownMenuItem<int>(
                                value: yr,
                                child: Text("$yr"),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedYear = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RepaintBoundary(
                      key: monthlyBoundaryKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              globalSocietyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("সারসংক্ষেপ — $monthLabel", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                                  const Divider(),
                                  Text("• মোট কিস্তি জমা: ৳${monthlyDepositTotal.toStringAsFixed(2)} ($monthlyDepositCountটি)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text("• মোট লাভ বণ্টন: ৳${monthlyProfitTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  Text("• ব্যবসায়িক আয়: ৳${monthlyBizIncome.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                                  Text("• প্রজেক্ট খরচ: ৳${monthlyBizExpense.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text("সদস্যদের লেনদেনসমূহ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            memberMonthEntries.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text("এই মাসে কোনো সদস্যের লেনদেন নেই।", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: memberMonthEntries.length,
                                    itemBuilder: (context, idx) {
                                      Member m = memberMonthEntries[idx]['member'];
                                      TransactionHistory t = memberMonthEntries[idx]['tx'];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 3),
                                        child: ListTile(
                                          dense: true,
                                          title: Text("${m.name} (ID: ${m.id}) — ৳${t.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year} | ${t.isProfit ? 'লাভ বণ্টন' : t.paymentMethod}"),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 10),
                            const Text("ব্যবসার আয়-ব্যয় পোস্টিং:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            monthBizRecords.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text("এই মাসে কোনো ব্যবসায়িক পোস্টিং নেই।", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: monthBizRecords.length,
                                    itemBuilder: (context, idx) {
                                      final r = monthBizRecords[idx];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 3),
                                        child: ListTile(
                                          dense: true,
                                          title: Text("${r.title} (${r.isIncome ? '+' : '-'}৳${r.amount.toStringAsFixed(2)})", style: TextStyle(fontWeight: FontWeight.bold, color: r.isIncome ? Colors.green : Colors.red)),
                                          subtitle: Text("তারিখ: ${r.date.day}/${r.date.month}/${r.date.year}"),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বন্ধ করুন")),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  await exportBoundaryToPdf(
                    context,
                    monthlyBoundaryKey,
                    "Monthly_Report_${selectedMonth}_${selectedYear}.pdf",
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

  void _showPendingApprovalsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          var pendingList = [];
          for (var member in globalMembers) {
            for (var tx in member.transactions) {
              if (tx.status == 'pending') {
                pendingList.add({
                  'member': member,
                  'tx': tx,
                });
              }
            }
          }

          return AlertDialog(
            title: const Text("⏳ অনুমোদনের অপেক্ষায় থাকা জমা"),
            content: SizedBox(
              width: double.maxFinite,
              child: pendingList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("বর্তমানে কোনো পেন্ডিং জমা নেই।", textAlign: TextAlign.center),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        var item = pendingList[index];
                        Member member = item['member'];
                        TransactionHistory tx = item['tx'];

                        return Card(
                          color: Colors.orange.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("সদস্য: ${member.name} (ID: ${member.id})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("জমার পরিমাণ: ৳${tx.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text("মাধ্যম: ${tx.paymentMethod} | TrxID: ${tx.trxId}"),
                                Text("তারিখ: ${tx.date.day}/${tx.date.month}/${tx.date.year}"),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () async {
                                        setState(() {
                                          member.transactions.remove(tx);
                                        });
                                        await CloudDatabaseService.syncAllDataToCloud();
                                        setDialogState(() {});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("পেমেন্টটি বাতিল করা হয়েছে!")),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text("বাতিল"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      onPressed: () async {
                                        setState(() {
                                          member.deposit += tx.amount;
                                          var targetTx = member.transactions.firstWhere((t) => t == tx);
                                          int txIndex = member.transactions.indexOf(targetTx);
                                          member.transactions[txIndex] = TransactionHistory(
                                            date: tx.date,
                                            amount: tx.amount,
                                            paymentMethod: tx.paymentMethod,
                                            trxId: tx.trxId,
                                            isProfit: tx.isProfit,
                                            batchId: tx.batchId,
                                            status: 'approved',
                                          );
                                        });
                                        await CloudDatabaseService.syncAllDataToCloud();
                                        setDialogState(() {});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("${member.name}-এর ৳${tx.amount.toStringAsFixed(2)} জমা সফলভাবে অনুমোদিত হয়েছে!")),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text("অনুমোদন দিন"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বন্ধ করুন")),
            ],
          );
        },
      ),
    );
  }

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
            onPressed: () async {
              if (adminIdController.text.trim().isNotEmpty && adminPassController.text.trim().isNotEmpty) {
                setState(() {
                  globalAdminId = adminIdController.text.trim();
                  globalAdminPassword = adminPassController.text.trim();
                });
                await CloudDatabaseService.syncAllDataToCloud();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ম্যানেজার আইডি ও পাসওয়ার্ড সফলভাবে আপডেট ও ক্লাউডে সেভ হয়েছে!")),
                  );
                }
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
                                  subtitle: Text("মাসিক কিস্তি: ৳${slab.amount.toStringAsFixed(2)}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                                        onPressed: () {
                                          _showEditSlabDialog(context, slab, () async {
                                            setDialogState(() {});
                                            setState(() {});
                                            await CloudDatabaseService.syncAllDataToCloud();
                                          });
                                        },
                                        tooltip: "এই স্লাবটি সংশোধন করুন",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          setDialogState(() {
                                            globalInstallmentSlabs.removeWhere((s) => s.id == slab.id);
                                          });
                                          setState(() {});
                                          await CloudDatabaseService.syncAllDataToCloud();
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
                        _showAddNewSlabDialog(context, () async {
                          setDialogState(() {});
                          setState(() {});
                          await CloudDatabaseService.syncAllDataToCloud();
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
                onPressed: () async {
                  if (societyNameController.text.trim().isNotEmpty) {
                    setState(() {
                      globalSocietyName = societyNameController.text.trim();
                    });
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("সেটিংস সফলভাবে আপডেট ও ক্লাউডে সেভ হয়েছে!")),
                      );
                    }
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
    final amountController = TextEditingController(text: slab.amount.toStringAsFixed(2));
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
                      labelText: "বিবরণ (যেমন: চলতি বছরের প্রজেক্ট লাভ)",
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
                onPressed: () async {
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
                          isSettled: false,
                        ),
                      );
                    });
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${titleController.text} এর পোস্টিং সফল হয়েছে এবং ক্লাউডে সেভ হয়েছে!")),
                      );
                    }
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
    final GlobalKey bizBoundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("📊 ব্যবসার লাভ-ক্ষতি খতিয়ান ও রিপোর্ট"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: bizBoundaryKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          globalSocietyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.green.shade50,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("চলমান মুনাফা: ৳${SamobayFinance.currentBusinessIncome.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  Text("চলমান খরচ: ৳${SamobayFinance.currentBusinessExpense.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              Text("অবশিষ্ট বণ্টনযোগ্য নিট লাভ: ৳${SamobayFinance.currentNetProfit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
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
                                    color: record.isSettled ? Colors.grey.shade100 : Colors.white,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        record.title,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                    ),
                                                    if (record.isSettled)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                                        child: const Text("বণ্টনকৃত", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "তারিখ: ${record.date.day}/${record.date.month}/${record.date.year} | ধরন: ${record.isIncome ? 'লাভ (+)' : 'খরচ (-)'}",
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "${record.isIncome ? '+' : '-'}৳${record.amount.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: record.isIncome ? Colors.green : Colors.red,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () async {
                                                  setState(() {
                                                    globalBusinessRecords.removeWhere((r) => r.id == record.id);
                                                  });
                                                  await CloudDatabaseService.syncAllDataToCloud();
                                                  setDialogState(() {});
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("${record.title} মুছে ফেলা হয়েছে!")),
                                                    );
                                                  }
                                                },
                                                tooltip: "এন্ট্রি ডিলিট করুন",
                                              ),
                                            ],
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("বন্ধ করুন"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  await exportBoundaryToPdf(
                    context,
                    bizBoundaryKey,
                    "Business_Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf",
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text("ডাউনলোড/সেভ (PDF)"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProfitDistributionDialog() {
    double netP = SamobayFinance.currentNetProfit;

    if (netP <= 0 || globalMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("বণ্টন করার মতো পর্যাপ্ত চলমান নিট লাভ বা সদস্য নেই!")),
      );
      return;
    }

    DateTime periodStart = DateTime(DateTime.now().year, 1, 1);
    DateTime periodEnd = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("📅 তারিখ ও মূলধন অনুযায়ী লাভ বণ্টন"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("বণ্টনযোগ্য নিট লাভ: ৳${netP.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text("সদস্যদের কিস্তি জমার তারিখ অনুযায়ী (টাকা × দিন) অনুপাতে পুরো ১০০% লাভ ভাগ হবে।", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Divider(),
                  Row(
                    children: [
                      Text("হিসাব শুরু: ${periodStart.day}/${periodStart.month}/${periodStart.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodStart,
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setDialogState(() => periodStart = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("হিসাব শেষ: ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodEnd,
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setDialogState(() => periodEnd = picked);
                        },
                        child: const Text("তারিখ দিন"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _executeTimeWeightedProfitDistribution(periodStart, periodEnd, netP);
                },
                child: const Text("নিশ্চিত বণ্টন করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _executeTimeWeightedProfitDistribution(DateTime periodStart, DateTime periodEnd, double netP) async {
    if (periodEnd.isBefore(periodStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("শেষের তারিখ শুরুর তারিখের আগে হতে পারবে না!")),
      );
      return;
    }

    int totalPeriodDays = periodEnd.difference(periodStart).inDays + 1;
    if (totalPeriodDays <= 0) totalPeriodDays = 1;

    Map<String, double> memberCapitalDays = {};
    double totalSocietyCapitalDays = 0.0;

    for (var member in globalMembers) {
      double mCapDays = 0.0;
      double accountedDeposit = 0.0;

      var depositTxs = member.transactions
          .where((t) => !t.isProfit && t.status == 'approved')
          .toList();

      for (var tx in depositTxs) {
        accountedDeposit += tx.amount;

        DateTime effectiveDate = tx.date.isBefore(periodStart) ? periodStart : tx.date;
        int activeDays = periodEnd.difference(effectiveDate).inDays + 1;
        if (activeDays <= 0) activeDays = 1;

        mCapDays += (tx.amount * activeDays);
      }

      if (member.deposit > accountedDeposit) {
        double diff = member.deposit - accountedDeposit;
        DateTime effectiveJoin = member.joinDate.isBefore(periodStart) ? periodStart : member.joinDate;
        int activeDays = periodEnd.difference(effectiveJoin).inDays + 1;
        if (activeDays <= 0) activeDays = 1;

        mCapDays += (diff * activeDays);
      }

      memberCapitalDays[member.id] = mCapDays;
      totalSocietyCapitalDays += mCapDays;
    }

    if (totalSocietyCapitalDays <= 0) {
      double totalDep = totalCollection;
      if (totalDep <= 0) return;
      for (var member in globalMembers) {
        memberCapitalDays[member.id] = member.deposit;
        totalSocietyCapitalDays += member.deposit;
      }
    }

    if (totalSocietyCapitalDays <= 0) return;

    Map<String, double> calculatedProfits = {};
    double totalAllocated = 0.0;
    Member? topMember;
    double maxCapDays = -1.0;

    for (var member in globalMembers) {
      double capDays = memberCapitalDays[member.id] ?? 0.0;
      if (capDays > maxCapDays) {
        maxCapDays = capDays;
        topMember = member;
      }

      double weight = capDays / totalSocietyCapitalDays;
      double rawProfit = netP * weight;
      double roundedProfit = double.parse(rawProfit.toStringAsFixed(2));

      calculatedProfits[member.id] = roundedProfit;
      totalAllocated += roundedProfit;
    }

    double remainder = double.parse((netP - totalAllocated).toStringAsFixed(2));
    if (remainder != 0.0 && topMember != null) {
      calculatedProfits[topMember.id] = double.parse(
        ((calculatedProfits[topMember.id] ?? 0.0) + remainder).toStringAsFixed(2),
      );
    }

    String newBatchId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      for (var member in globalMembers) {
        double memberProfit = calculatedProfits[member.id] ?? 0.0;

        if (memberProfit > 0) {
          member.profitEarned = double.parse((member.profitEarned + memberProfit).toStringAsFixed(2));
          member.transactions.add(
            TransactionHistory(
              date: DateTime.now(),
              amount: memberProfit,
              paymentMethod: 'লাভ বণ্টন (${periodStart.day}/${periodStart.month}/${periodStart.year}-${periodEnd.day}/${periodEnd.month}/${periodEnd.year})',
              isProfit: true,
              batchId: newBatchId,
            ),
          );
        }
      }

      for (var record in globalBusinessRecords) {
        if (!record.isSettled) {
          record.isSettled = true;
          record.batchId = newBatchId;
        }
      }

      lastDistributionBatchId = newBatchId;
    });

    await CloudDatabaseService.syncAllDataToCloud();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("৳${netP.toStringAsFixed(2)} লাভের পুরো ১০০% টাকা জমাকৃত টাকার মেয়াদ অনুযায়ী বণ্টন সম্পন্ন এবং চলমান হিসাব ০.০০ করা হয়েছে!")),
      );
    }
  }

  void _showReverseProfitDialog() {
    if (lastDistributionBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("রিভার্স করার মতো কোনো সাম্প্রতিক লাভ বণ্টন পাওয়া যায়নি!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ সর্বশেষ লাভ বণ্টন রিভার্স (Undo)"),
        content: const Text("আপনি কি নিশ্চিত যে সর্বশেষ বণ্টনকৃত লাভটি বাতিল করতে চান? এতে সদস্যদের অ্যাকাউন্ট থেকে ওই লাভ মাইনাস হয়ে যাবে এবং চলমান ব্যবসায়িক মুনাফা আগের অবস্থায় ফিরে আসবে।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("না, থাক")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeReverseProfit();
            },
            child: const Text("হ্যাঁ, রিভার্স করুন"),
          ),
        ],
      ),
    );
  }

  Future<void> _executeReverseProfit() async {
    if (lastDistributionBatchId == null) return;
    String targetBatch = lastDistributionBatchId!;

    setState(() {
      for (var member in globalMembers) {
        double deductedAmount = 0.0;
        member.transactions.removeWhere((tx) {
          if (tx.isProfit && tx.batchId == targetBatch) {
            deductedAmount += tx.amount;
            return true;
          }
          return false;
        });
        member.profitEarned = double.parse((member.profitEarned - deductedAmount).toStringAsFixed(2));
        if (member.profitEarned < 0) member.profitEarned = 0.0;
      }

      for (var record in globalBusinessRecords) {
        if (record.batchId == targetBatch) {
          record.isSettled = false;
          record.batchId = null;
        }
      }

      // আগের ব্যাচগুলো লক থাকবে; সর্বশেষ ব্যাচ রিভার্স হওয়ার পর আর কোনো রিভার্স নয়
      lastDistributionBatchId = null;
    });

    await CloudDatabaseService.syncAllDataToCloud();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("সর্বশেষ লাভ বণ্টন সফলভাবে রিভার্স করা হয়েছে!")),
      );
    }
  }

  void _confirmDeleteMember(Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ সদস্য ডিলিট নিশ্চিতকরণ"),
        content: Text("আপনি কি নিশ্চিত যে '${member.name}' (ID: ${member.id})-কে সমিতির তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান? সমস্ত জমা ও লেনদেনের হিসাব মুছে যাবে।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() {
                globalMembers.removeWhere((m) => m.id == member.id);
              });
              await CloudDatabaseService.syncAllDataToCloud();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${member.name}-কে তালিকা থেকে মুছে ফেলা হয়েছে!")),
                );
              }
            },
            child: const Text("হ্যাঁ, মুছে ফেলুন"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSmsApp(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("SMS অ্যাপ ওপেন হয়নি। মেসেজটি ক্লিপবোর্ডে কপি করা হয়েছে।")),
          );
        }
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("মেসেজটি ক্লিপবোর্ডে কপি করা হয়েছে।")),
        );
      }
    }
  }

  void _sendSmsDialog(Member member) {
    double todayDeposit = member.lastDepositAmount;
    double totalDeposit = member.deposit;
    double balance = member.totalBalance;
    double due = member.dueAmount;
    double advance = member.advanceAmount;
    double profit = member.profitEarned;

    String dueAdvanceStr = due > 0
        ? "বকেয়া: ${due.toStringAsFixed(2)}৳ (${member.dueMonthsCount} মাস)"
        : (advance > 0 ? "অগ্রিম জমা: ${advance.toStringAsFixed(2)}৳" : "বকেয়া: ৳0.00");

    String smsMessage =
        "[$globalSocietyName]\nপ্রিয় ${member.name},\nআজকে জমা: ${todayDeposit.toStringAsFixed(2)}৳\nমোট মূল জমা: ${totalDeposit.toStringAsFixed(2)}৳\nসর্বমোট ব্যালেন্স: ${balance.toStringAsFixed(2)}৳\n$dueAdvanceStr\nঅর্জিত লাভ: ${profit.toStringAsFixed(2)}৳\nধন্যবাদ!";

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: smsMessage));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("মেসেজটি কপি করা হয়েছে!")),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("কপি করুন"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _launchSmsApp(member.mobile, smsMessage);
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text("সরাসরি SMS"),
          ),
        ],
      ),
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
                      Text("তারিখ: ${depositDate.day}/${depositDate.month}/${depositDate.year}"),
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
                onPressed: () async {
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
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      _sendSmsDialog(member);
                    }
                  }
                },
                child: const Text("জমা দিন ও SMS পাঠান"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditMemberDialog(Member member) {
    final nameController = TextEditingController(text: member.name);
    final mobileController = TextEditingController(text: member.mobile);
    final depositController = TextEditingController(text: member.deposit.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${member.name}-এর তথ্য সংশোধন"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "নাম")),
            const SizedBox(height: 10),
            TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "মোবাইল নম্বর")),
            const SizedBox(height: 10),
            TextField(controller: depositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মোট জমা সংশোধন")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                member.name = nameController.text.trim();
                member.mobile = mobileController.text.trim();
                member.deposit = double.tryParse(depositController.text) ?? member.deposit;
              });
              await CloudDatabaseService.syncAllDataToCloud();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("সদস্যের তথ্য আপডেট ও ক্লাউডে সেভ হয়েছে!")),
                );
              }
            },
            child: const Text("আপডেট করুন"),
          ),
        ],
      ),
    );
  }

  void _resetPinDialog(Member member) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${member.name}-এর পিন রিসেট"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "নতুন পিন দিন", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim().isNotEmpty) {
                setState(() {
                  member.pin = pinController.text.trim();
                });
                await CloudDatabaseService.syncAllDataToCloud();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("পিন সফলভাবে আপডেট ও ক্লাউডে সেভ হয়েছে!")),
                  );
                }
              }
            },
            child: const Text("সেভ করুন"),
          ),
        ],
      ),
    );
  }

  void _showMemberStatementDialog(Member member) {
    final GlobalKey memberStatementKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${member.name}-এর পূর্ণাঙ্গ হিসাব ও ইতিহাস"),
        content: SizedBox(
          width: double.maxFinite,
          child: RepaintBoundary(
            key: memberStatementKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    globalSocietyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                  Text("সদস্য: ${member.name} | আইডি: ${member.id} | মোবাইল: ${member.mobile}"),
                  const Divider(),
                  Text("• মূল জমা: ৳${member.deposit.toStringAsFixed(2)}"),
                  Text("• অর্জিত লাভ: ৳${member.profitEarned.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blue)),
                  Text("• সর্বমোট ব্যালেন্স: ৳${member.totalBalance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  if (member.dueAmount > 0)
                    Text("• বকেয়া: ৳${member.dueAmount.toStringAsFixed(2)} (${member.dueMonthsCount} মাস)", style: const TextStyle(color: Colors.red))
                  else if (member.advanceAmount > 0)
                    Text("• অতিরিক্ত জমা: ৳${member.advanceAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.teal))
                  else
                    const Text("• বকেয়া: ৳0.00"),
                  const Divider(),
                  const Text("🗓 এ পর্যন্ত যতবার ও যত তারিখে কিস্তি/লেনদেন হয়েছে:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 180,
                    child: member.transactions.isEmpty
                        ? const Center(child: Text("কোনো লেনদেন রেকর্ড নেই।"))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: member.transactions.length,
                            itemBuilder: (context, idx) {
                              final tx = member.transactions[idx];
                              return Card(
                                color: Colors.grey.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  dense: true,
                                  title: Text("${tx.date.day}/${tx.date.month}/${tx.date.year} — ৳${tx.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${tx.paymentMethod} ${tx.trxId.isNotEmpty ? '(Trx: ${tx.trxId})' : ''}"),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বন্ধ করুন")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await exportBoundaryToPdf(
                context,
                memberStatementKey,
                "Member_${member.name}_Statement.pdf",
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text("ফাইল ডাউনলোড (PDF)"),
          ),
        ],
      ),
    );
  }

  void _showMemberActionMenu(Member member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${member.name} (ID: ${member.id})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const Text("কার্যক্রম নির্বাচন করুন", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text("নতুন কিস্তি জমা দিন (+)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddInstallmentDialog(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.teal),
                title: const Text("সদস্যের তথ্য এডিট করুন"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditMemberDialog(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.orange),
                title: const Text("পিন রিসেট করুন"),
                onTap: () {
                  Navigator.pop(ctx);
                  _resetPinDialog(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: const Text("সরাসরি SMS পাঠান"),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendSmsDialog(member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                title: const Text("হিসাব ও স্টেটমেন্ট দেখুন/ডাউনলোড"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMemberStatementDialog(member);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("সদস্য মুছে ফেলুন (Delete)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMember(member);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllMembersReportDialog() {
    final GlobalKey allMembersBoundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("📋 সকল সদস্যের সার্বিক স্টেটমেন্ট (ব্যালেন্স, লাভ ও ডিউ)"),
        content: SizedBox(
          width: double.maxFinite,
          child: RepaintBoundary(
            key: allMembersBoundaryKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$globalSocietyName — সকল সদস্যের স্টেটমেন্ট",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  globalMembers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("কোনো সদস্যের তথ্য নেই।", textAlign: TextAlign.center),
                        )
                      : Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: globalMembers.length,
                            itemBuilder: (context, index) {
                              final m = globalMembers[index];
                              String dueAdvStr = m.dueAmount > 0
                                  ? "Due: ${m.dueAmount.toStringAsFixed(2)}৳ (${m.dueMonthsCount} মাস)"
                                  : (m.advanceAmount > 0 ? "Adv: ${m.advanceAmount.toStringAsFixed(2)}৳" : "Due: ৳0.00");

                              return Card(
                                color: Colors.grey.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("ID: ${m.id} | নাম: ${m.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text("মোবাইল: ${m.mobile}"),
                                      const Divider(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("ব্যালেন্স: ৳${m.totalBalance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          Text("লাভ: ৳${m.profitEarned.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(dueAdvStr, style: TextStyle(fontWeight: FontWeight.bold, color: m.dueAmount > 0 ? Colors.red : Colors.teal)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বন্ধ করুন")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await exportBoundaryToPdf(
                context,
                allMembersBoundaryKey,
                "All_Members_Report.pdf",
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text("সকলের স্টেটমেন্ট ডাউনলোড (PDF)"),
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
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                onPressed: () async {
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
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) Navigator.pop(ctx);
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
            icon: const Icon(Icons.pending_actions),
            tooltip: "পেন্ডিং জমা অনুমোদন",
            onPressed: _showPendingApprovalsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "সমিতির সেটিংস",
            onPressed: _showSocietySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: "ব্যবসার লাভ/খরচ পোস্টিং",
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
                  Text("• বর্তমান কিস্তি: ৳${globalInstallmentSlabs.isNotEmpty ? globalInstallmentSlabs.last.amount.toStringAsFixed(2) : '0.00'}/মাস", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Text("• মোট সঞ্চয় (মূলধন): ${totalCollection.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("• চলমান ব্যবসায়িক মুনাফা: ${SamobayFinance.currentBusinessIncome.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.green)),
                  Text("• চলমান প্রজেক্ট খরচ: ${SamobayFinance.currentBusinessExpense.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.red)),
                  Text("• সর্বমোট বণ্টনকৃত লাভ: ${SamobayFinance.totalProfitDistributed.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.bold)),
                  Text("• নিট বণ্টনযোগ্য মুনাফা (চলমান): ${SamobayFinance.currentNetProfit.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
                  Text("• মোট বকেয়া (ডিউ): ${totalDue.toStringAsFixed(2)} টাকা", style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 4)),
                          onPressed: _showManageBusinessRecordsDialog,
                          icon: const Icon(Icons.receipt_long, size: 15),
                          label: const Text("খতিয়ান", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 4)),
                          onPressed: _showAllMembersReportDialog,
                          icon: const Icon(Icons.people, size: 15),
                          label: const Text("স্টেটমেন্ট", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4)),
                          onPressed: _showProfitDistributionDialog,
                          icon: const Icon(Icons.calculate, size: 14),
                          label: const Text("অটো লাভ", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      if (lastDistributionBatchId != null) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4)),
                            onPressed: _showReverseProfitDialog,
                            icon: const Icon(Icons.undo, size: 14),
                            label: const Text("রিভার্স", style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: _showMonthlyReportDialog,
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text("মাসিক রিপোর্ট (যেকোনো মাস ও PDF)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => DueReminderDialog(
                            societyName: globalSocietyName,
                            members: globalMembers,
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text(
                        "বকেয়া রিমাইন্ডার ও নোটিশ",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("সকল সদস্যের তালিকা (অপশন পেতে ক্লিক করুন):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            globalMembers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text("এখনো কোনো সদস্য যোগ করা হয়নি।", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalMembers.length,
                    itemBuilder: (context, index) {
                      final member = globalMembers[index];
                      String dueAdvText = member.dueAmount > 0
                          ? "Due: ${member.dueAmount.toStringAsFixed(2)}৳"
                          : (member.advanceAmount > 0 ? "Adv: ${member.advanceAmount.toStringAsFixed(2)}৳" : "Due: ৳0.00");

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: InkWell(
                          onTap: () => _showMemberActionMenu(member),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green,
                                      radius: 14,
                                      child: Text(member.id, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        member.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.touch_app, size: 18, color: Colors.grey),
                                  ],
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ব্যালেন্স: ${member.totalBalance.toStringAsFixed(2)}৳",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    Text(
                                      dueAdvText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: member.dueAmount > 0 ? Colors.red : Colors.teal,
                                      ),
                                    ),
                                    Text(
                                      "লাভ: ${member.profitEarned.toStringAsFixed(2)}৳",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
  final GlobalKey _memberDashBoundaryKey = GlobalKey();
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
            onPressed: () async {
              if (oldPinController.text == widget.member.pin) {
                if (newPinController.text.trim().isNotEmpty) {
                  setState(() {
                    widget.member.pin = newPinController.text.trim();
                  });
                  await CloudDatabaseService.syncAllDataToCloud();
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("আপনার পিন সফলভাবে পরিবর্তন ও ক্লাউডে সেভ হয়েছে!")),
                    );
                  }
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
                          const Text("Bank: Sonali Bank PLC", style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Account Name: 97 Batch Akata Foram", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text("Account Number:", style: TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              const SelectableText("0204801011895", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: "0204801011895"));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ব্যাংক অ্যাকাউন্ট নম্বর কপি করা হয়েছে!")),
                                  );
                                },
                              )
                            ],
                          ),
                          const Text("Branch: Bhawal Jamalpur Branch", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                onPressed: () async {
                  double? amount = double.tryParse(_amountController.text.trim());
                  if (amount != null && amount > 0 && _trxController.text.isNotEmpty) {
                    setState(() {
                      widget.member.transactions.add(
                        TransactionHistory(
                          date: DateTime.now(),
                          amount: amount,
                          paymentMethod: _selectedMethod == 'bKash' ? 'bKash Send Money' : 'সোনালী ব্যাংক',
                          trxId: _trxController.text.trim(),
                          status: 'pending',
                        ),
                      );
                    });
                    await CloudDatabaseService.syncAllDataToCloud();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("আপনার পেমেন্টটি সফলভাবে সাবমিট হয়েছে। এডমিন অনুমোদন করার পর এটি আপনার অ্যাকাউন্টে যোগ হবে!")),
                      );
                    }
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
            tooltip: "পিন পরিবর্তন",
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
            Expanded(
              child: RepaintBoundary(
                key: _memberDashBoundaryKey,
                child: Container(
                  color: Colors.white,
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
                              const Text("• বকেয়া: ৳0.00 (পরিশোধিত)", style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("🗓 আপনার জমা ও লাভের হিসাবের ইতিহাস:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await exportBoundaryToPdf(
                    context,
                    _memberDashBoundaryKey,
                    "${widget.member.name}_Statement.pdf",
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text(
                  "বিস্তারিত স্টেটমেন্ট ডাউনলোড করুন (PDF)",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
