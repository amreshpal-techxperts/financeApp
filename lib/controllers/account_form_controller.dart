import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/account.dart';

class AccountFormController extends GetxController {
  final Account? account;
  final String defaultType;

  AccountFormController({this.account, this.defaultType = 'cash'});

  late final TextEditingController nameCtrl;
  late final TextEditingController balCtrl;
  late final TextEditingController phoneCtrl;
  late final RxString type;
  late final RxInt selectedMAId; // -1 = none selected

  bool get isEdit => account != null;

  @override
  void onInit() {
    super.onInit();
    nameCtrl = TextEditingController(text: account?.name ?? '');
    balCtrl = TextEditingController(
      text: account?.openingBalance.toStringAsFixed(2) ?? '0',
    );
    phoneCtrl = TextEditingController(text: account?.phone ?? '');
    type = (account?.type ?? defaultType).obs;
    selectedMAId = (account?.masterAccountId ?? -1).obs;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    balCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}