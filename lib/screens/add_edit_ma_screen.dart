// ignore_for_file: deprecated_member_use

import 'package:financeapp/controllers/m_account_ctr.dart';
import 'package:financeapp/widgets/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/master_account_controller.dart';
import '../models/master_account.dart';
import '../utils/constants.dart';

class AddEditMaScreen extends GetView<MaFormController> {
  const AddEditMaScreen({super.key});

  // ── Static helper: open screen ───────────────────────────
  static void open({MasterAccount? ma}) {
    Get.to(
      () => const AddEditMaScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MaFormController(ma: ma));
      }),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maCtrl = Get.find<MasterAccountController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          controller.isEdit ? 'Edit Master Account' : 'New Master Account',
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
            // ── Name ──────────────────────────────────
            _label('Account / Person Name *'),
            const SizedBox(height: 8),
            _field(controller.nameCtrl, 'Full name', Icons.person_outline),
            const SizedBox(height: 16),

            // ── Account number ─────────────────────────
            _label('Account Number (optional)'),
            const SizedBox(height: 8),
            _field(
              controller.accNumCtrl,
              'e.g. 123456789',
              Icons.credit_card_outlined,
              kb: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // ── Bank name ─────────────────────────────
            _label('Bank Name (optional)'),
            const SizedBox(height: 8),
            _field(
              controller.bankCtrl,
              'e.g. SBI, HDFC',
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 24),

            // ── Default toggle ─────────────────────────
            Obx(
              () => GestureDetector(
                onTap: () => controller.isDefault.toggle(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: controller.isDefault.value
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: controller.isDefault.value
                          ? AppColors.primary.withOpacity(0.5)
                          : Colors.grey.shade200,
                      width: controller.isDefault.value ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isDefault.value
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: controller.isDefault.value
                            ? Colors.amber
                            : Colors.grey,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set as Default',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Active context for new vouchers',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: controller.isDefault.value,
                          onChanged: (v) => controller.isDefault.value = v,
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ── Save button ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _save(maCtrl),
                icon: Icon(
                  controller.isEdit
                      ? Icons.update_rounded
                      : Icons.check_rounded,
                ),
                label: Text(
                  controller.isEdit
                      ? 'Update Master Account'
                      : 'Create Master Account',
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
                  onPressed: () => _confirmDelete(maCtrl),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Master Account',
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
  Future<void> _save(MasterAccountController maCtrl) async {
    if (controller.nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final m = MasterAccount(
      id: controller.ma?.id,
      name: controller.nameCtrl.text.trim(),
      accountNumber: controller.accNumCtrl.text.trim().isEmpty
          ? null
          : controller.accNumCtrl.text.trim(),
      bankName: controller.bankCtrl.text.trim().isEmpty
          ? null
          : controller.bankCtrl.text.trim(),
      isDefault: controller.isDefault.value,
    );
    controller.isEdit
        ? await maCtrl.updateMasterAccount(m)
        : await maCtrl.addMasterAccount(m);

    final masters = maCtrl.masterAccounts;

    if (masters.length == 1) {
      // only one → auto main screen
      Get.offAll(() => const MainShell());
    } else {
      // more than one → just go back
      Get.back();
    }
    Get.snackbar(
      controller.isEdit ? 'Updated ✓' : 'Created ✓',
      '${m.name} ${controller.isEdit ? 'updated' : 'created'} successfully!',
      backgroundColor: AppColors.credit,
      colorText: Colors.white,
    );
  }

  // ── Delete confirm ────────────────────────────────────────
  void _confirmDelete(MasterAccountController maCtrl) {
    final ma = controller.ma!;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${ma.name}"?'),
        content: const Text(
          'Linked import settings will also be removed.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              await maCtrl.deleteMasterAccount(ma.id!);
              Get.back();

              Get.back();
              Get.snackbar(
                'Deleted',
                '"${ma.name}" has been deleted',
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

  // ── Helpers ───────────────────────────────────────────────
  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? kb,
  }) => TextField(
    controller: c,
    keyboardType: kb,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );
}
