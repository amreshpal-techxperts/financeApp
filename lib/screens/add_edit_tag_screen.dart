// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../controllers/tag_form_controller.dart';
import '../models/tag.dart';
import '../utils/constants.dart';

class AddEditTagScreen extends GetView<TagFormController> {
  const AddEditTagScreen({super.key});

  // ── Static helper: open screen ───────────────────────────
  static void open({Tag? tag}) {
    Get.delete<TagFormController>(force: true);
    Get.put(TagFormController(tag: tag));
    Get.to(() => const AddEditTagScreen(), transition: Transition.rightToLeft);
  }

  @override
  Widget build(BuildContext context) {
    final appCtrl = Get.find<AppController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          controller.isEdit ? 'Edit Tag' : 'New Tag',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name field ─────────────────────────────
            _label('Tag Name'),
            const SizedBox(height: 10),
            TextField(
              controller: controller.nameCtrl,
              autofocus: !controller.isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Food, Travel, Bills...',
                prefixIcon: const Icon(Icons.label_outline, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Color picker ───────────────────────────
            _label('Choose Color'),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kTagColors.map((c) {
                  final isSel = controller.selectedColor.value == c;
                  final tc = hexColor(c);
                  return GestureDetector(
                    onTap: () => controller.pickColor(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, // ← fixed size, change nahi hoga
                      height: 36, // ← fixed size
                      decoration: BoxDecoration(
                        color: tc,
                        borderRadius: BorderRadius.circular(10),
                        border: isSel
                            ? Border.all(color: Colors.black87, width: 2.5)
                            : Border.all(color: Colors.transparent, width: 2.5),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: tc.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: isSel
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Live preview ───────────────────────────
            _label('Preview'),
            const SizedBox(height: 10),
            Obx(() {
              final tc = hexColor(controller.selectedColor.value);
              final name = controller.nameObs.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: tc.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tc.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: tc,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name.trim().isEmpty ? 'Preview...' : name.trim(),
                      style: TextStyle(
                        color: tc,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),

            // ── Save button ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _save(appCtrl),
                icon: Icon(
                  controller.isEdit
                      ? Icons.update_rounded
                      : Icons.check_rounded,
                ),
                label: Text(
                  controller.isEdit ? 'Update Tag' : 'Create Tag',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // ── Delete (edit only) ─────────────────────
            if (controller.isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(appCtrl),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Tag',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────
  Future<void> _save(AppController appCtrl) async {
    if (controller.nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Tag name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final t = Tag(
      id: controller.tag?.id,
      name: controller.nameCtrl.text.trim(),
      color: controller.selectedColor.value,
    );
    controller.isEdit ? await appCtrl.updateTag(t) : await appCtrl.addTag(t);

    Get.back();
    Get.snackbar(
      controller.isEdit ? 'Updated ✓' : 'Created ✓',
      '"${t.name}" ${controller.isEdit ? 'updated' : 'created'}!',
      backgroundColor: AppColors.credit,
      colorText: Colors.white,
    );
  }

  // ── Delete confirm ────────────────────────────────────────
  void _confirmDelete(AppController appCtrl) {
    final tag = controller.tag!;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: hexColor(tag.color),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('"${tag.name}" delete karein?')),
          ],
        ),
        content: const Text(
          'Tag entries mein se bhi hatega.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              await appCtrl.deleteTag(tag.id!);
              Get.back();

              Get.back();
              Get.snackbar(
                'Deleted',
                '"${tag.name}" deleted',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );
}
