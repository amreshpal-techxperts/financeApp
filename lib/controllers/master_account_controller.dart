import 'package:financeapp/controllers/app_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/master_account.dart';
import '../models/import_setting.dart';

class MasterAccountController extends GetxController {
  final RxList<MasterAccount> masterAccounts = <MasterAccount>[].obs;
  // final Rx<MasterAccount?> defaultMA = Rx<MasterAccount?>(null);

  /// ✅ Currently active/selected business (Khata Book style)
  final Rx<MasterAccount?> activeMA = Rx<MasterAccount?>(null);

  final appCtrl = Get.find<AppController>();

  static const _prefKey = 'last_active_ma_id';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final list = await DBHelper.instance.getMasterAccounts();
    masterAccounts.assignAll(list);
    // defaultMA.value = list.firstWhereOrNull((m) => m.isDefault);

    // Restore last active MA from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_prefKey);

    MasterAccount? restored;
    if (lastId != null) {
      restored = list.firstWhereOrNull((m) => m.id == lastId);
    }
    // Fallback: default MA, then first in list
    restored ?? list.firstOrNull;

    if (restored != null) {
      activeMA.value = restored;
    }
    update();
  }

  /// ✅ Khata Book style: Switch active business + reload all data
  Future<void> switchBusiness(MasterAccount ma) async {
    if (activeMA.value?.id == ma.id) return; // already active
    activeMA.value = ma;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, ma.id!);
    await appCtrl.loadAll(maId: ma.id);
    update();
  }

  /// Called after creating/logging in — set active MA and load data
  Future<void> initActiveMA() async {
    await load();
    if (activeMA.value != null) {
      await appCtrl.loadAll(maId: activeMA.value!.id);
    }
  }

  Future<MasterAccount> addMasterAccount(MasterAccount ma) async {
    ma.id = await DBHelper.instance.insertMasterAccount(ma);
    // if (ma.isDefault) {
    //   for (var m in masterAccounts) {
    //     if (m.id != ma.id) m.isDefault = false;
    //   }
    //   defaultMA.value = ma;
    // }
    masterAccounts.add(ma);
    masterAccounts.sort((a, b) => a.name.compareTo(b.name));
    await createDefaultAccounts(ma.id!);

    // ✅ Auto-switch to the newly created business
    activeMA.value = ma;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, ma.id!);
    await appCtrl.loadAll(maId: ma.id);

    update();
    return ma;
  }

  Future<void> createDefaultAccounts(int masterId) async {
    final db = await DBHelper.instance.database;

    final now = DateTime.now().toIso8601String();

    final defaultAccounts = [
      {
        'name': 'Cash',
        'type': 'cash',
        'openingBalance': 0.0,
        'masterAccountId': masterId,
        'createdAt': now,
      },
      {
        'name': 'Bank', // 🔥 fixed name
        'type': 'bank',
        'openingBalance': 0.0,
        'masterAccountId': masterId,
        'createdAt': now,
      },
    ];

    for (final acc in defaultAccounts) {
      await db.insert('accounts', acc);
    }
  }

  Future<void> updateMasterAccount(MasterAccount ma) async {
    await DBHelper.instance.updateMasterAccount(ma);
    final i = masterAccounts.indexWhere((m) => m.id == ma.id);
    if (i != -1) masterAccounts[i] = ma;
    update();
  }

  // Future<void> setDefault(int id) async {
  //   await DBHelper.instance.setDefaultMA(id);
  //   for (var m in masterAccounts) {
  //     m.isDefault = m.id == id;
  //   }
  //   defaultMA.value = masterAccounts.firstWhereOrNull((m) => m.id == id);
  //   update();
  // }

  Future<void> deleteMasterAccount(int id) async {
    await DBHelper.instance.deleteMasterAccount(id);
    masterAccounts.removeWhere((m) => m.id == id);
    // ✅ agar active delete hua to pehle wala select karo
    if (activeMA.value?.id == id) {
      activeMA.value = masterAccounts.firstOrNull;
      if (activeMA.value != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKey, activeMA.value!.id!);
        await appCtrl.loadAll(maId: activeMA.value!.id);
      }
    }
    update();
  }

  MasterAccount? getById(int id) =>
      masterAccounts.firstWhereOrNull((m) => m.id == id);

  Future<ImportSetting?> getImportSetting(String accNo) =>
      DBHelper.instance.getImportSetting(accNo);
  Future<void> saveImportSetting(ImportSetting s) =>
      DBHelper.instance.upsertImportSetting(s);
}
