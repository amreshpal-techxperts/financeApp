// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_form_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/master_account_controller.dart';
import '../models/account.dart';
import '../utils/constants.dart';
import '../database/db_helper.dart';

class AddEditAccountScreen extends GetView<AccountFormController> {
  const AddEditAccountScreen({super.key});

  // ── Static helper: open screen ───────────────────────────
  static void open({Account? account, String selectedType = 'all'}) {
    Get.delete<AccountFormController>(force: true);
    Get.put(
      AccountFormController(
        account: account,
        defaultType: selectedType == 'all' ? 'cash' : selectedType,
      ),
    );
    Get.to(
      () => const AddEditAccountScreen(),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCtrl = Get.find<AppController>();
    final maCtrl = Get.find<MasterAccountController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          controller.isEdit ? 'Edit Account' : 'New Account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Account Details'),
            const SizedBox(height: 12),

            // ── Type dropdown ──────────────────────────
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.type.value,
                decoration: _dec('Account Type', Icons.category_outlined),
                items: AppLabels.accountType.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.forAccount(e.key),
                              size: 16,
                              color: AppIcons.colorFor(e.key),
                            ),
                            const SizedBox(width: 10),
                            Text(e.value),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.type.value = v!,
              ),
            ),
            const SizedBox(height: 14),

            // ── Name ──────────────────────────────────
            TextField(
              controller: controller.nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Account Name', Icons.person_outline),
            ),
            const SizedBox(height: 14),

            // ── Opening Balance ────────────────────────
            TextField(
              controller: controller.balCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(
                'Opening Balance',
                Icons.account_balance_outlined,
              ),
            ),

            // ── Phone (person / vendor only) ──────────
            Obx(
              () =>
                  (controller.type.value == 'person' ||
                      controller.type.value == 'vendor')
                  ? Column(
                      children: [
                        const SizedBox(height: 14),
                        TextField(
                          controller: controller.phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _dec(
                            'Phone (optional)',
                            Icons.phone_outlined,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Keywords Section (edit + new both) ────
            const SizedBox(height: 24),
            _KeywordsSection(controller: controller),

            // ── Master Account selector ────────────────
            Obx(() {
              final mas = maCtrl.masterAccounts;
              if (mas.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _label('Master Account'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _MATile(
                          label: 'None',
                          subtitle: 'No master account',
                          isSelected: controller.selectedMAId.value == -1,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.block_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () => controller.selectedMAId.value = -1,
                        ),
                        Divider(height: 1, color: Colors.grey.shade100),
                        ...mas.map((ma) {
                          final isSel = controller.selectedMAId.value == ma.id;
                          return Column(
                            children: [
                              _MATile(
                                label: ma.name,
                                subtitle: ma.accountNumber != null
                                    ? 'A/C: ${ma.accountNumber}'
                                    : ma.bankName ?? '',
                                isSelected: isSel,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    ma.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                trailing: ma.isDefault
                                    ? const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      )
                                    : null,
                                onTap: () =>
                                    controller.selectedMAId.value = ma.id!,
                              ),
                              if (ma != mas.last)
                                Divider(height: 1, color: Colors.grey.shade100),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
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
                  controller.isEdit ? 'Update Account' : 'Add Account',
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

            // ── Delete button (edit only) ──────────────
            if (controller.isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(appCtrl),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Account',
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
        'Account name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final a = Account(
      id: controller.account?.id,
      name: controller.nameCtrl.text.trim(),
      type: controller.type.value,
      openingBalance: double.tryParse(controller.balCtrl.text) ?? 0,
      phone: controller.phoneCtrl.text.trim().isEmpty
          ? null
          : controller.phoneCtrl.text.trim(),
      masterAccountId: controller.selectedMAId.value == -1
          ? null
          : controller.selectedMAId.value,
      // keywords are saved separately via _KeywordsSection, not here
      keywords: controller.account?.keywords ?? [],
    );
    controller.isEdit
        ? await appCtrl.updateAccount(a)
        : await appCtrl.addAccount(a);

    Get.back();
    Get.snackbar(
      controller.isEdit ? 'Updated ✓' : 'Added ✓',
      '"${a.name}" ${controller.isEdit ? 'updated' : 'added'} successfully',
      backgroundColor: AppColors.credit,
      colorText: Colors.white,
    );
  }

  // ── Delete confirm ────────────────────────────────────────
  void _confirmDelete(AppController appCtrl) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${controller.account!.name}"?'),
        content: const Text(
          'This will remove the account permanently.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              await appCtrl.deleteAccount(controller.account!.id!);
              Get.back();
              Get.back();
              Get.snackbar(
                'Deleted',
                'Account removed',
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
  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
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

// ══════════════════════════════════════════════════════════════
// Keywords Section Widget
// ══════════════════════════════════════════════════════════════
class _KeywordsSection extends StatefulWidget {
  final AccountFormController controller;
  const _KeywordsSection({required this.controller});

  @override
  State<_KeywordsSection> createState() => _KeywordsSectionState();
}

class _KeywordsSectionState extends State<_KeywordsSection> {
  late List<String> _keywords;
  final _addCtrl = TextEditingController();
  bool _showAddField = false;

  @override
  void initState() {
    super.initState();
    // Load existing keywords from account (if editing)
    _keywords = List<String>.from(widget.controller.account?.keywords ?? []);
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  // Save to DB immediately (only if editing existing account)
  Future<void> _persistKeywords() async {
    final id = widget.controller.account?.id;
    if (id == null)
      return; // new account — keywords save honge account create hone ke baad
    await DBHelper.instance.updateAccountKeywords(id, _keywords);
    // Update in-memory account keywords too
    await Get.find<AppController>().loadAll();
  }

  void _addKeyword() {
    final kw = _addCtrl.text.trim().toLowerCase();
    if (kw.length < 2) return;
    if (_keywords.any((k) => k.toLowerCase() == kw)) {
      Get.snackbar(
        'Already exists',
        '"$kw" is already in keywords',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() {
      _keywords.add(kw);
      _addCtrl.clear();
      _showAddField = false;
    });
    _persistKeywords();
  }

  void _removeKeyword(int index) {
    setState(() => _keywords.removeAt(index));
    _persistKeywords();
  }

  void _clearAll() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Clear all keywords?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        content: const Text(
          'Auto-matching for this account will stop until new keywords are learned.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() => _keywords.clear());
              _persistKeywords();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.label_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            const Text(
              'Keywords',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            // count badge
            if (_keywords.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_keywords.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Spacer(),
            if (_keywords.isNotEmpty)
              GestureDetector(
                onTap: _clearAll,
                child: const Text(
                  'Clear all',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Info text ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 14,
                color: AppColors.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Whenever these keywords are found in a transaction description, it will automatically be assigned to this account.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Keywords chips ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_keywords.isEmpty && !_showAddField)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'No keywords yet. It will learn automatically from imports.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

              // Chips
              if (_keywords.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _keywords.asMap().entries.map((e) {
                    return _KeywordChip(
                      keyword: e.value,
                      onDelete: () => _removeKeyword(e.key),
                    );
                  }).toList(),
                ),

              // ── Add field ──────────────────────────────────
              if (_showAddField) ...[
                if (_keywords.isNotEmpty) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.none,
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _addKeyword(),
                        decoration: InputDecoration(
                          hintText: 'e.g. zomato, rahul sharma, hdfc...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addKeyword,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showAddField = false;
                        _addCtrl.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Add button ─────────────────────────────────
              if (!_showAddField) ...[
                if (_keywords.isNotEmpty) const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _showAddField = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Add keyword',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Keyword Chip ─────────────────────────────────────────────
class _KeywordChip extends StatelessWidget {
  final String keyword;
  final VoidCallback onDelete;

  const _KeywordChip({required this.keyword, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyword,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 10,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MA Tile widget ─────────────────────────────────────────
class _MATile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MATile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.leading,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? AppColors.primary.withOpacity(0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
