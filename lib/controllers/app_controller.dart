import 'package:get/get.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/tx_voucher.dart';
import '../models/entry.dart';
import '../database/db_helper.dart';

class AppController extends GetxController {
  final RxList<Account> accounts = <Account>[].obs;
  final RxList<Tag> tags = <Tag>[].obs;
  final RxList<TxVoucher> vouchers = <TxVoucher>[].obs;
  final RxMap<int, double> balances = <int, double>{}.obs;
  final RxMap<int, List<Entry>> entriesCache = <int, List<Entry>>{}.obs;
  final RxBool isLoading = false.obs;

  final RxString searchQuery = ''.obs;
  final RxInt filterTagId = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      accounts.assignAll(await DBHelper.instance.getAllAccounts());

      print("accounts = $accounts");

      final kwMap = await DBHelper.instance.getAllAccountKeywordsMap();
      final accountsWithKw = accounts.map((a) {
        return a.copyWith(keywords: kwMap[a.id] ?? []);
      }).toList();

      this.accounts.assignAll(accountsWithKw);

      print("accountsWithKw = $accountsWithKw");

      print("accountsWithKw = ${accountsWithKw.first.keywords}  ");

      tags.assignAll(await DBHelper.instance.getAllTags());
      final v = await DBHelper.instance.getVouchers();
      vouchers.assignAll(v);
      balances.assignAll(await DBHelper.instance.getAllBalances());
      for (var voucher in v.take(50)) {
        entriesCache[voucher.id!] = await DBHelper.instance
            .getEntriesForVoucher(voucher.id!);
      }
    } finally {
      isLoading.value = false;
    }
    update();
  }

  Future<void> refreshBalances() async {
    balances.assignAll(await DBHelper.instance.getAllBalances());
    update();
  }

  // Accounts
  Future<void> addAccount(Account a) async {
    a.id = await DBHelper.instance.insertAccount(a);

    if (a.keywords.isNotEmpty) {
      await DBHelper.instance.setAccountKeywords(a.id!, a.keywords);
    }
    accounts.add(a);
    balances[a.id!] = a.openingBalance;
    accounts.sort((x, y) => x.name.compareTo(y.name));
    update();
  }

  Future<void> updateAccount(Account a) async {
    await DBHelper.instance.updateAccount(a);
    final i = accounts.indexWhere((x) => x.id == a.id);
    if (i != -1) accounts[i] = a;
    await refreshBalances();
  }

  Future<void> deleteAccount(int id) async {
    await DBHelper.instance.deleteAccount(id);
    accounts.removeWhere((a) => a.id == id);
    balances.remove(id);
    update();
  }

  Account? accountById(int id) => accounts.firstWhereOrNull((a) => a.id == id);

  List<Account> get assetAccounts => accounts.where((a) => a.isAsset).toList();
  List<Account> get personAccounts =>
      accounts.where((a) => a.isPerson).toList();
  List<Account> get expenseAccounts =>
      accounts.where((a) => a.isExpense).toList();
  List<Account> get incomeAccounts =>
      accounts.where((a) => a.isIncome).toList();

  double get totalAssetBalance =>
      assetAccounts.fold(0.0, (s, a) => s + (balances[a.id] ?? 0));
  double get totalExpenses =>
      expenseAccounts.fold(0.0, (s, a) => s + ((balances[a.id] ?? 0).abs()));
  double get totalOutstandingToReceive => personAccounts.fold(0.0, (s, a) {
    final b = balances[a.id] ?? 0;
    return s + (b > 0 ? b : 0);
  });
  double get totalOutstandingToPay => personAccounts.fold(0.0, (s, a) {
    final b = balances[a.id] ?? 0;
    return s + (b < 0 ? b.abs() : 0);
  });

  // Tags
  Future<void> addTag(Tag t) async {
    t.id = await DBHelper.instance.insertTag(t);
    tags.add(t);
    update();
  }

  Future<void> updateTag(Tag t) async {
    await DBHelper.instance.updateTag(t);
    final i = tags.indexWhere((x) => x.id == t.id);
    if (i != -1) tags[i] = t;
    update();
  }

  Future<void> deleteTag(int id) async {
    await DBHelper.instance.deleteTag(id);
    tags.removeWhere((t) => t.id == id);
    update();
  }

  Tag? tagById(int id) => tags.firstWhereOrNull((t) => t.id == id);

  // Vouchers
  Future<void> addVoucher(TxVoucher v, List<Entry> entries) async {
    final id = await DBHelper.instance.insertVoucher(v, entries);
    v.id = id;
    for (var e in entries) {
      e.transactionId = id;
    }
    entriesCache[id] = entries;
    vouchers.insert(0, v);
    await refreshBalances();
  }

  Future<void> updateVoucher(TxVoucher v, List<Entry> entries) async {
    await DBHelper.instance.updateVoucher(v, entries);
    entriesCache[v.id!] = entries;
    final i = vouchers.indexWhere((x) => x.id == v.id);
    if (i != -1) vouchers[i] = v;
    vouchers.sort((a, b) => b.date.compareTo(a.date));
    await refreshBalances();
  }

  Future<void> deleteVoucher(int id) async {
    await DBHelper.instance.deleteVoucher(id);
    vouchers.removeWhere((v) => v.id == id);
    entriesCache.remove(id);
    await refreshBalances();
  }

  Future<List<Entry>> getVoucherEntries(int vId) async {
    if (entriesCache.containsKey(vId)) return entriesCache[vId]!;
    final entries = await DBHelper.instance.getEntriesForVoucher(vId);
    entriesCache[vId] = entries;
    return entries;
  }

  final RxInt filterMAId = (-1).obs;

  List<TxVoucher> get filteredVouchers => vouchers.where((v) {
    if (searchQuery.value.isNotEmpty &&
        !v.note.toLowerCase().contains(searchQuery.value.toLowerCase())) {
      return false;
    }
    if (filterTagId.value > 0 && v.tagId != filterTagId.value) {
      // ← simple!
      return false;
    }
    if (filterMAId.value > 0 && v.masterAccountId != filterMAId.value) {
      return false;
    }
    return true;
  }).toList();

  void clearFilters() {
    searchQuery.value = '';
    filterTagId.value = -1;
    filterMAId.value = -1;
    update();
  }
}
