import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/tag.dart';

class TagFormController extends GetxController {
  final Tag? tag;

  TagFormController({this.tag});

  late final TextEditingController nameCtrl;
  late final RxString selectedColor;
  late final RxString nameObs; // mirrors nameCtrl for reactive preview

  bool get isEdit => tag != null;

  @override
  void onInit() {
    super.onInit();
    nameCtrl = TextEditingController(text: tag?.name ?? '');
    selectedColor = (tag?.color ?? kTagDefaultColor).obs;
    nameObs = (tag?.name ?? '').obs;
    nameCtrl.addListener(() => nameObs.value = nameCtrl.text);
  }

  void pickColor(String color) => selectedColor.value = color;

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }
}

// Keep this here or in constants — adjust import if needed
const kTagDefaultColor = 'F44336';