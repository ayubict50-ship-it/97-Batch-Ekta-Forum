import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/member.dart';
import '../models/business_record.dart';
import '../models/installment_slab.dart';

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

  static Future<void> loadDataFromCloud() async {
    try {
      var membersDoc = await _db.collection('society_data').doc('members').get();
      if (membersDoc.exists && membersDoc.data()?['list'] != null) {
        List l = membersDoc.data()!['list'];
        globalMembers = l.map((m) => Member.fromJson(m)).toList();
      }

      var bizDoc = await _db.collection('society_data').doc('business').get();
      if (bizDoc.exists && bizDoc.data()?['list'] != null) {
        List l = bizDoc.data()!['list'];
        globalBusinessRecords = l.map((b) => BusinessRecord.fromJson(b)).toList();
      }

      var slabDoc = await _db.collection('society_data').doc('slabs').get();
      if (slabDoc.exists && slabDoc.data()?['list'] != null) {
        List l = slabDoc.data()!['list'];
        globalInstallmentSlabs = l.map((s) => InstallmentSlab.fromJson(s)).toList();
      }

      var settingsDoc = await _db.collection('society_data').doc('settings').get();
      if (settingsDoc.exists) {
        globalSocietyName = settingsDoc.data()?['societyName'] ?? globalSocietyName;
        globalAdminId = settingsDoc.data()?['adminId'] ?? globalAdminId;
        globalAdminPassword = settingsDoc.data()?['adminPassword'] ?? globalAdminPassword;
        lastDistributionBatchId = settingsDoc.data()?['lastDistributionBatchId'];
      }
    } catch (e) {
      debugPrint("Cloud Load Error: $e");
    }
  }
}
