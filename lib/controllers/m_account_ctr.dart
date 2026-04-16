import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/master_account.dart';

class MaFormController extends GetxController {
  final MasterAccount? ma;

  MaFormController({this.ma});

  late final TextEditingController nameCtrl;
  late final TextEditingController accNumCtrl;
  late final TextEditingController bankCtrl;
  late final RxBool isDefault;

  bool get isEdit => ma != null;

  @override
  void onInit() {
    super.onInit();
    nameCtrl = TextEditingController(text: ma?.name ?? '');
    accNumCtrl = TextEditingController(text: ma?.accountNumber ?? '');
    bankCtrl = TextEditingController(text: ma?.bankName ?? '');
    // isDefault = (ma?.isDefault ?? false).obs;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    accNumCtrl.dispose();
    bankCtrl.dispose();
    super.onClose();
  }
}
