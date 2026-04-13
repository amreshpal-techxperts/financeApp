// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_form_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/master_account_controller.dart';
import '../models/account.dart';
import '../utils/constants.dart';
import '../database/db_helper.dart';

// ═══════════════════════════════════════════════════════════════════
// AddEditAccountScreen
// ═══════════════════════════════════════════════════════════════════

class AddEditAccountScreen extends GetView<AccountFormController> {
  const AddEditAccountScreen({super.key});

  /// Open this screen with optional existing [account] and [selectedType].
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
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Account Details'),
            const SizedBox(height: 12),
            _buildTypeDropdown(),
            const SizedBox(height: 14),
            _buildNameField(),
            const SizedBox(height: 14),
            _buildBalanceField(),
            _buildPhoneField(),
            const SizedBox(height: 24),
            _KeywordsSection(controller: controller),
            _buildMasterAccountSection(maCtrl),
            const SizedBox(height: 30),
            _buildSaveButton(appCtrl),
            if (controller.isEdit) ...[
              const SizedBox(height: 12),
              _buildDeleteButton(appCtrl),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  AppBar _buildAppBar() => AppBar(
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
  );

  // ── Form Fields ───────────────────────────────────────────

  Widget _buildTypeDropdown() => Obx(
    () => DropdownButtonFormField<String>(
      value: controller.type.value,
      decoration: _inputDec('Account Type', Icons.category_outlined),
      items: AppLabels.accountType.entries.map((e) {
        return DropdownMenuItem(
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
        );
      }).toList(),
      onChanged: (v) => controller.type.value = v!,
    ),
  );

  Widget _buildNameField() => TextField(
    controller: controller.nameCtrl,
    textCapitalization: TextCapitalization.words,
    decoration: _inputDec('Account Name', Icons.person_outline),
  );

  Widget _buildBalanceField() => TextField(
    controller: controller.balCtrl,
    keyboardType: TextInputType.number,
    decoration: _inputDec('Opening Balance', Icons.account_balance_outlined),
  );

  Widget _buildPhoneField() => Obx(
    () =>
        (controller.type.value == 'person' || controller.type.value == 'vendor')
        ? Column(
            children: [
              const SizedBox(height: 14),
              TextField(
                controller: controller.phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDec('Phone (optional)', Icons.phone_outlined),
              ),
            ],
          )
        : const SizedBox.shrink(),
  );

  // ── Master Account Section ────────────────────────────────

  Widget _buildMasterAccountSection(MasterAccountController maCtrl) => Obx(() {
    final mas = maCtrl.masterAccounts;
    if (mas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionLabel('Master Account'),
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
                        backgroundColor: AppColors.primary.withOpacity(0.1),
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
                      onTap: () => controller.selectedMAId.value = ma.id!,
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
  });

  // ── Buttons ───────────────────────────────────────────────

  Widget _buildSaveButton(AppController appCtrl) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => _save(appCtrl),
      icon: Icon(
        controller.isEdit ? Icons.update_rounded : Icons.check_rounded,
      ),
      label: Text(
        controller.isEdit ? 'Update Account' : 'Add Account',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Widget _buildDeleteButton(AppController appCtrl) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _confirmDelete(appCtrl),
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  // ── Actions ───────────────────────────────────────────────

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

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
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

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// Keywords Section
// ═══════════════════════════════════════════════════════════════════

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
    _keywords = List<String>.from(widget.controller.account?.keywords ?? []);
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  // ── DB Sync ───────────────────────────────────────────────

  Future<void> _persistKeywords() async {
    final id = widget.controller.account?.id;
    if (id == null) return;
    // ✅ Naya method
    await DBHelper.instance.setAccountKeywords(id, _keywords);
    await Get.find<AppController>().loadAll();
  }

  // ── Keyword Actions ───────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        // _buildInfoBanner(),
        const SizedBox(height: 10),
        _buildChipsContainer(),
      ],
    );
  }

  Widget _buildHeader() => Row(
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
  );

  // Widget _buildInfoBanner() => Container(
  //   padding: const EdgeInsets.all(12),
  //   decoration: BoxDecoration(
  //     color: AppColors.primary.withOpacity(0.04),
  //     borderRadius: BorderRadius.circular(10),
  //     border: Border.all(color: AppColors.primary.withOpacity(0.12)),
  //   ),
  //   child: Row(
  //     children: [
  //       Icon(
  //         Icons.auto_awesome_outlined,
  //         size: 14,
  //         color: AppColors.primary.withOpacity(0.7),
  //       ),
  //       const SizedBox(width: 8),
  //       const Expanded(
  //         child: Text(
  //           'Whenever these keywords are found in a transaction description, it will automatically be assigned to this account.',
  //           style: TextStyle(fontSize: 11, color: Colors.black54),
  //         ),
  //       ),
  //     ],
  //   ),
  // );

  Widget _buildChipsContainer() => Container(
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
        if (_keywords.isEmpty && !_showAddField) _buildEmptyHint(),
        if (_keywords.isNotEmpty) _buildChips(),
        if (_showAddField) ...[
          if (_keywords.isNotEmpty) const SizedBox(height: 10),
          _buildAddField(),
        ],
        if (!_showAddField) ...[
          if (_keywords.isNotEmpty) const SizedBox(height: 10),
          _buildAddButton(),
        ],
      ],
    ),
  );

  Widget _buildEmptyHint() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'No keywords yet. It will learn automatically from imports.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
      ],
    ),
  );

  Widget _buildChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _keywords
        .asMap()
        .entries
        .map(
          (e) => _KeywordChip(
            keyword: e.value,
            onDelete: () => _removeKeyword(e.key),
          ),
        )
        .toList(),
  );

  Widget _buildAddField() => Row(
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
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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
      _iconBtn(Icons.check, AppColors.primary, _addKeyword),
      const SizedBox(width: 6),
      _iconBtn(
        Icons.close,
        Colors.grey.shade100,
        () => setState(() {
          _showAddField = false;
          _addCtrl.clear();
        }),
        iconColor: Colors.grey.shade600,
      ),
    ],
  );

  Widget _buildAddButton() => GestureDetector(
    onTap: () => setState(() => _showAddField = true),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14, color: AppColors.primary.withOpacity(0.8)),
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
  );

  Widget _iconBtn(
    IconData icon,
    Color bg,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: iconColor),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// Keyword Chip
// ═══════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════
// Master Account Tile
// ═══════════════════════════════════════════════════════════════════

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
