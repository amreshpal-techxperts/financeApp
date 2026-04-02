import 'package:get/get.dart';
import '../database/db_helper.dart';
import '../models/master_account.dart';
import '../models/import_setting.dart';

class MasterAccountController extends GetxController {
  final RxList<MasterAccount> masterAccounts = <MasterAccount>[].obs;
  final Rx<MasterAccount?> defaultMA = Rx<MasterAccount?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final list = await DBHelper.instance.getMasterAccounts();
    masterAccounts.assignAll(list);
    defaultMA.value = list.firstWhereOrNull((m) => m.isDefault);
    update();
  }

  Future<MasterAccount> addMasterAccount(MasterAccount ma) async {
    ma.id = await DBHelper.instance.insertMasterAccount(ma);
    if (ma.isDefault) {
      for (var m in masterAccounts) {
        if (m.id != ma.id) m.isDefault = false;
      }
      defaultMA.value = ma;
    }
    masterAccounts.add(ma);
    masterAccounts.sort((a, b) {
      if (a.isDefault) return -1;
      if (b.isDefault) return 1;
      return a.name.compareTo(b.name);
    });
    update();
    return ma;
  }

  Future<void> updateMasterAccount(MasterAccount ma) async {
    await DBHelper.instance.updateMasterAccount(ma);
    final i = masterAccounts.indexWhere((m) => m.id == ma.id);
    if (i != -1) masterAccounts[i] = ma;
    if (ma.isDefault) {
      for (var m in masterAccounts) {
        if (m.id != ma.id) m.isDefault = false;
      }
      defaultMA.value = ma;
    }
    update();
  }

  Future<void> setDefault(int id) async {
    await DBHelper.instance.setDefaultMA(id);
    for (var m in masterAccounts) {
      m.isDefault = m.id == id;
    }
    defaultMA.value = masterAccounts.firstWhereOrNull((m) => m.id == id);
    update();
  }

  Future<void> deleteMasterAccount(int id) async {
    await DBHelper.instance.deleteMasterAccount(id);
    masterAccounts.removeWhere((m) => m.id == id);
    if (defaultMA.value?.id == id) defaultMA.value = null;
    update();
  }

  MasterAccount? getById(int id) =>
      masterAccounts.firstWhereOrNull((m) => m.id == id);

  Future<ImportSetting?> getImportSetting(String accNo) =>
      DBHelper.instance.getImportSetting(accNo);
  Future<void> saveImportSetting(ImportSetting s) =>
      DBHelper.instance.upsertImportSetting(s);
}
