import '../models/installment_slab.dart';
import '../models/member.dart';
import '../models/business_record.dart';

String globalSocietyName = '৯৭ ব্যাচ একতা ফোরাম';
String globalAdminId = 'admin';
String globalAdminPassword = '1234';

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

List<Member> globalMembers = [];
List<BusinessRecord> globalBusinessRecords = [];
String? lastDistributionBatchId;
