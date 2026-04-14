// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:financeapp/controllers/app_controller.dart';
import 'package:financeapp/database/db_helper.dart';
import 'package:financeapp/models/account.dart';
import 'package:financeapp/screens/import/import_helpers.dart';
import 'package:financeapp/screens/import/import_models.dart';
import 'package:financeapp/screens/import/import_parser.dart';
import 'package:financeapp/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../models/entry.dart';
import '../../models/tx_voucher.dart';
import 'import_widgets.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<AppController>();

  List<PRowData> _rows = [];
  bool _loading = false;
  bool _imported = false;
  String _loadingMsg = 'Parsing CSV...';
  int? _selectedBankAccountId;

  int get _activeRows => _rows.where((r) => !r.skip).length;
  int get _dupRows => _rows.where((r) => r.isDuplicate).length;

  // Unassigned = keyword match nahi hua, user manually select karega
  int get _unsetRows =>
      _rows.where((r) => !r.skip && r.accountName == null).length;

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_rows.isEmpty && !_imported) _buildSetupCard(),
          if (_loading) _buildLoadingState(),
          if (!_loading && _rows.isNotEmpty) ...[
            _buildStatsBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: _rows.length,
                itemBuilder: (_, i) => _buildRowCard(i),
              ),
            ),
          ],
          if (!_loading && _rows.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Statement',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        if (_rows.isNotEmpty)
          Text(
            '$_activeRows of ${_rows.length} transactions',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
      ],
    ),
    actions: [
      // "Review New Accounts" button removed — no auto-creation in new system
      if (_rows.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Clear',
          onPressed: _confirmClear,
        ),
    ],
  );

  // ── Setup Card ─────────────────────────────────────────
  Widget _buildSetupCard() => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Statement Import',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Date, Description, Debit, Credit format',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              StepLabel(step: '1', label: 'Select Bank Account'),
              const SizedBox(height: 10),
              GetBuilder<AppController>(
                builder: (c) {
                  // if (_selectedBankAccountId != null &&
                  //     !c.assetAccounts.any(
                  //       (a) => a.id == _selectedBankAccountId,
                  //     )) {
                  //   WidgetsBinding.instance.addPostFrameCallback((_) {
                  //     if (mounted) {
                  //       setState(() => _selectedBankAccountId = null);
                  //     }

                  //     final validAccounts = c.assetAccounts
                  //         .where((a) => a.type == 'bank')
                  //         .toList();

                  //     final selectedId =
                  //         validAccounts.any(
                  //           (a) => a.id == _selectedBankAccountId,
                  //         )
                  //         ? _selectedBankAccountId
                  //         : null;
                  //   });
                  // }

                  final bankAccounts = c.assetAccounts
                      .where((a) => a.type == 'bank')
                      .toList();

                  // ✅ validate selected value
                  final selectedId =
                      bankAccounts.any((a) => a.id == _selectedBankAccountId)
                      ? _selectedBankAccountId
                      : null;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedBankAccountId != null
                            ? AppColors.primary.withOpacity(0.4)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedId,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        hint: Row(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Select bank account',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        items: c.assetAccounts
                            .where((a) => a.type == 'bank')
                            .toSet()
                            .map(
                              (a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppIcons.colorFor(
                                          a.type,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        AppIcons.forAccount(a.type),
                                        size: 14,
                                        color: AppIcons.colorFor(a.type),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        a.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedBankAccountId = v),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              StepLabel(step: '2', label: 'Upload CSV File'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _selectedBankAccountId == null ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _selectedBankAccountId != null
                        ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade200,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _selectedBankAccountId != null
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: _selectedBankAccountId != null
                            ? Colors.white
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Choose CSV File',
                        style: TextStyle(
                          color: _selectedBankAccountId != null
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Stats Bar ──────────────────────────────────────────
  Widget _buildStatsBar() => Container(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatPill(
                        value: '$_activeRows',
                        label: 'Active',
                        color: AppColors.credit,
                        icon: Icons.check_circle_outline,
                      ),
                      if (_dupRows > 0) ...[
                        const SizedBox(width: 8),
                        StatPill(
                          value: '$_dupRows',
                          label: 'Dup',
                          color: Colors.orange,
                          icon: Icons.copy_outlined,
                          onTap: _toggleAllDuplicates,
                        ),
                      ],
                      // "New Acc" pill removed — no auto-creation
                      if (_unsetRows > 0) ...[
                        const SizedBox(width: 8),
                        StatPill(
                          value: '$_unsetRows',
                          label: 'Unset',
                          color: Colors.red,
                          icon: Icons.warning_amber_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!_imported)
                ImportBtn(enabled: _activeRows > 0, onTap: _doImport),
            ],
          ),
        ),
        if (_dupRows > 0)
          InkWell(
            onTap: _toggleAllDuplicates,
            child: Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _rows.where((r) => r.isDuplicate).every((r) => r.skip)
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Skip $_dupRows duplicate transactions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    ),
  );

  void _toggleAllDuplicates() {
    final allSkipped = _rows.where((r) => r.isDuplicate).every((r) => r.skip);
    setState(() {
      for (final r in _rows) {
        if (r.isDuplicate) r.skip = !allSkipped;
      }
    });
  }

  // ── Row Card ───────────────────────────────────────────
  Widget _buildRowCard(int i) {
    final row = _rows[i];
    final Color cardBg = row.skip
        ? Colors.grey.shade50
        : row.isDuplicate
        ? Colors.orange.shade50
        : Colors.white;

    // accColor: red = unset, primary = assigned
    final Color accColor = row.accountName == null
        ? Colors.red
        : AppColors.primary;
    final tc = tagColor(row.tag);

    return Opacity(
      opacity: row.skip ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: row.isDuplicate && !row.skip
                ? Colors.orange.shade200
                : Colors.grey.shade100,
          ),
          boxShadow: row.skip
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skip toggle checkbox
                GestureDetector(
                  onTap: () => setState(() => row.skip = !row.skip),
                  child: Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: row.skip
                          ? Colors.grey.shade100
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: row.skip
                            ? Colors.grey.shade300
                            : AppColors.primary,
                      ),
                    ),
                    child: row.skip
                        ? null
                        : const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (row.isDuplicate)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy_outlined,
                                          size: 9,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Duplicate',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Title: matched account name OR raw description
                                Text(
                                  row.accountName ?? row.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: row.skip
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Show raw description as subtitle when account matched
                                if (row.accountName != null)
                                  Text(
                                    row.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  row.date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (row.debit > 0)
                                AmountBadge(amount: row.debit, isDebit: true),
                              if (row.credit > 0)
                                AmountBadge(amount: row.credit, isDebit: false),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Account selector
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editRowAcc(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: accColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      row.accountName == null
                                          ? Icons.warning_amber_outlined
                                          : Icons.account_circle_outlined,
                                      size: 13,
                                      color: accColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        row.accountName ?? 'Set account...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: accColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 14,
                                      color: accColor.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tag selector
                          // GestureDetector(
                          //   onTap: () => _pickTag(i),
                          //   child: Container(
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 10,
                          //       vertical: 6,
                          //     ),
                          //     decoration: BoxDecoration(
                          //       color: row.tag != null
                          //           ? tc.withOpacity(0.1)
                          //           : Colors.grey.shade50,
                          //       borderRadius: BorderRadius.circular(8),
                          //       border: Border.all(
                          //         color: row.tag != null
                          //             ? tc.withOpacity(0.3)
                          //             : Colors.grey.shade200,
                          //       ),
                          //     ),
                          //     child: Row(
                          //       mainAxisSize: MainAxisSize.min,
                          //       children: [
                          //         Icon(
                          //           row.tag != null
                          //               ? tagIcon(row.tag)
                          //               : Icons.label_outline,
                          //           size: 12,
                          //           color: row.tag != null ? tc : Colors.grey,
                          //         ),
                          //         const SizedBox(width: 4),
                          //         Text(
                          //           row.tag ?? 'Tag',
                          //           style: TextStyle(
                          //             fontSize: 11,
                          //             color: row.tag != null ? tc : Colors.grey,
                          //             fontWeight: FontWeight.w600,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────
  Widget _buildLoadingState() => Expanded(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingMsg,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please wait...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  // ── Empty State ────────────────────────────────────────
  Widget _buildEmptyState() => Expanded(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _imported
                  ? AppColors.credit.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _imported
                  ? Icons.check_circle_outline_rounded
                  : Icons.upload_file_outlined,
              size: 40,
              color: _imported ? AppColors.credit : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _imported ? 'Import Complete!' : 'Ready to Import',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _imported ? AppColors.credit : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _imported
                ? 'Transactions have been saved.'
                : 'Select a bank account and upload your CSV.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_imported) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _imported = false;
                _selectedBankAccountId = null;
              }),
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Import Another File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // ── Tag Picker ─────────────────────────────────────────
  void _pickTag(int rowIdx) {
    final row = _rows[rowIdx];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Select Tag',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const Spacer(),
                if (row.tag != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => row.tag = null);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 13),
                    label: const Text('Remove', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ctrl.tags.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.label_off_outlined,
                          size: 36,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No tag found',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ctrl.tags.map((tag) {
                      final selected = row.tag == tag.name;
                      final color = tagColor(tag.name);
                      return GestureDetector(
                        onTap: () {
                          setState(() => row.tag = tag.name);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? color : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected ? color : color.withOpacity(0.2),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tagIcon(tag.name),
                                size: 14,
                                color: selected ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tag.name,
                                style: TextStyle(
                                  color: selected ? Colors.white : color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Clear Confirm ──────────────────────────────────────
  void _confirmClear() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Clear All?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'All rows will be removed. No import will be performed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            setState(() {
              _rows = [];
              _imported = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Clear'),
        ),
      ],
    ),
  );

  // ── Pick & Parse CSV ───────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _loading = true;
      _loadingMsg = 'Reading file...';
    });

    try {
      final content = await File(result.files.first.path!).readAsString();

      setState(() => _loadingMsg = 'Checking duplicates...');
      final existingKeys = await _buildExistingTxKeys();

      setState(() => _loadingMsg = 'Loading keywords...');

      // accountId → keywords (from accounts.keywords column)
      final keywordsMap = <int, List<String>>{};
      for (final acc in ctrl.accounts) {
        if (acc.id != null && acc.keywords.isNotEmpty) {
          keywordsMap[acc.id!] = List<String>.from(acc.keywords);
        }
      }

      // global_keywords table se: tagId → keywords
      final globalKwMap = await DBHelper.instance.getGlobalKeywordsMap();

      print("global keyword $globalKwMap");

      // tagId → tagName
      final tagIdToName = <int, String>{
        for (final t in ctrl.tags)
          if (t.id != null) t.id!: t.name,
      };

      setState(() => _loadingMsg = 'Matching accounts...');

      final accMaps = ctrl.accounts
          .map((a) => {'id': a.id, 'name': a.name, 'type': a.type})
          .toList();

      final parsed = await compute(
        doParse,
        ParseParams(
          csvContent: content,
          accounts: accMaps,
          existingTxKeys: existingKeys,
          vendorMap: kAutoVendorMap,
          tagMap: kAutoTagMap,
          tags: ctrl.tags.map((t) => t.name).toList(),
          keywordsMap: keywordsMap,
          globalKeywordsMap: globalKwMap,
          tagIdToName: tagIdToName,
        ),
      );

      setState(() {
        _rows = parsed.rows;
        for (final r in _rows) {
          if (r.isDuplicate) r.skip = true;
        }
        _imported = false;
      });

      for (final w in parsed.warnings) {
        Get.snackbar(
          'Notice',
          w,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      _showParseSummary(parsed);
    } catch (e) {
      Get.snackbar(
        'Error',
        'CSV parse error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showParseSummary(ParseResult r) {
    final parts = ['${r.rows.length} rows'];
    if (r.dupCount > 0) parts.add('${r.dupCount} dup');
    if (r.invalidCount > 0) parts.add('${r.invalidCount} invalid');
    final unset = r.rows.where((row) => row.accountName == null).length;
    if (unset > 0) parts.add('$unset unset');
    Get.snackbar(
      'CSV Loaded ✓',
      parts.join('  •  '),
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<Set<String>> _buildExistingTxKeys() async {
    try {
      final db = await DBHelper.instance.database;
      final activeMaId = ctrl.activeMaId.value > 0
          ? ctrl.activeMaId.value
          : null;

      final result = await db.rawQuery(
        'SELECT importHash FROM transactions WHERE importHash IS NOT NULL AND masterAccountId = ?',
        [activeMaId], // ✅ sirf is MA ki duplicates check karo
      );
      return result.map((r) => r['importHash'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Edit Row Account ───────────────────────────────────
  // User manually select karta hai — keyword bhi save hoga
  void _editRowAcc(int rowIdx) {
    final row = _rows[rowIdx];

    // Suggested name: matched account ya raw description se pehle 3 words
    final sugName =
        row.accountName ??
        row.description.split(RegExp(r'\s+')).take(3).join(' ').trim();
    final sugType = row.accountType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String search = '';
        bool showCreate = false;
        String newName = sugName, newType = sugType;
        final nameCtrl = TextEditingController(text: sugName);
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx, ss) {
            final filtered = search.isEmpty
                ? ctrl.accounts
                : ctrl.accounts
                      .where(
                        (a) =>
                            a.name.toLowerCase().contains(search.toLowerCase()),
                      )
                      .toList();
            final grouped = <String, List<Account>>{};
            for (final a in filtered) {
              grouped.putIfAbsent(a.type, () => []).add(a);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  row.description,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => ss(() => showCreate = !showCreate),
                            icon: Icon(
                              showCreate ? Icons.close : Icons.add,
                              size: 16,
                            ),
                            label: Text(
                              showCreate ? 'Cancel' : 'New',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar (when not creating)
                    if (!showCreate)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => ss(() => search = v),
                          decoration: InputDecoration(
                            hintText: 'Search accounts...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),

                    // Create new account panel
                    if (showCreate) ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: newType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Account Type',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              items: AppLabels.accountType.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Row(
                                        children: [
                                          Icon(
                                            AppIcons.forAccount(e.key),
                                            size: 15,
                                            color: AppIcons.colorFor(e.key),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              e.value,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => ss(() => newType = v!),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (v) => ss(() => newName = v),
                              decoration: InputDecoration(
                                labelText: 'Account Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: newName.trim().isEmpty
                                    ? null
                                    : () async {
                                        final newAcc = Account(
                                          name: nameCtrl.text.trim(),
                                          type: newType,
                                          openingBalance: 0,
                                          masterAccountId:
                                              ctrl.activeMaId.value > 0
                                              ? ctrl.activeMaId.value
                                              : null,
                                        );
                                        await ctrl.addAccount(newAcc);

                                        if (newAcc.id != null) {
                                          final kw = _keywordsFromRow(row);
                                          if (kw.isNotEmpty) {
                                            await DBHelper.instance
                                                .updateAccountKeywords(
                                                  newAcc.id!,
                                                  kw,
                                                );
                                          }
                                        }

                                        setState(() {
                                          _rows[rowIdx]
                                            ..accountId = newAcc.id
                                            ..accountName = newAcc.name
                                            ..accountType = newAcc.type
                                            ..isNewAccount = false;
                                        });
                                        Navigator.pop(context);
                                        Get.snackbar(
                                          'Created',
                                          '"${newAcc.name}" selected.',
                                          backgroundColor: AppColors.credit,
                                          colorText: Colors.white,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(
                                  newName.trim().isEmpty
                                      ? 'Enter name...'
                                      : 'Create "${nameCtrl.text.trim()}"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Text(
                          'Or select existing:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],

                    Divider(height: 1, color: Colors.grey.shade100),

                    // Accounts list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$search" not found',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => ss(() {
                                      showCreate = true;
                                      nameCtrl.text = search;
                                      newName = search;
                                    }),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text('Create "$search"'),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              children: grouped.entries.map((g) {
                                final color = AppIcons.colorFor(g.key);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        top: 8,
                                        bottom: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            AppIcons.forAccount(g.key),
                                            size: 12,
                                            color: color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            AppLabels.accountType[g.key] ??
                                                g.key,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...g.value.map((a) {
                                      final isSelected =
                                          _rows[rowIdx].accountId == a.id;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withOpacity(0.07)
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? color.withOpacity(0.3)
                                                : Colors.grey.shade100,
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 2,
                                              ),
                                          leading: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: color.withOpacity(
                                              0.12,
                                            ),
                                            child: Icon(
                                              AppIcons.forAccount(a.type),
                                              size: 14,
                                              color: color,
                                            ),
                                          ),
                                          title: Text(
                                            a.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isSelected
                                                  ? color
                                                  : Colors.black87,
                                            ),
                                          ),
                                          subtitle: Text(
                                            fmtAmt(ctrl.balances[a.id] ?? 0),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check_circle_rounded,
                                                  color: color,
                                                  size: 20,
                                                )
                                              : null,
                                          onTap: () async {
                                            setState(() {
                                              _rows[rowIdx]
                                                ..accountId = a.id
                                                ..accountName = a.name
                                                ..accountType = a.type
                                                ..isNewAccount = false;
                                            });
                                            Navigator.pop(context);

                                            // Manual assign → keywords save karo
                                            if (a.id != null) {
                                              final kw = _keywordsFromRow(row);
                                              if (kw.isNotEmpty) {
                                                await DBHelper.instance
                                                    .updateAccountKeywords(
                                                      a.id!,
                                                      kw,
                                                    );
                                                await ctrl.loadAll();
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Do Import ──────────────────────────────────────────
  Future<void> _doImport() async {
    // Unset rows hain toh confirm karo
    if (_unsetRows > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Unset Accounts',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            '$_unsetRows rows do not have an assigned account. Do you want to skip them?',
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Skip & Import'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _loading = true;
      _loadingMsg = 'Saving transactions...';
    });

    try {
      // Sirf assigned + not skipped rows import honge
      final valid = _rows.where((r) => !r.skip && r.accountId != null).toList();

      final vList = <TxVoucher>[];
      final eList = <List<Entry>>[];
      final bankId = _selectedBankAccountId!;

      for (final row in valid) {
        DateTime date;
        try {
          date = DateTime.parse(row.date);
        } catch (_) {
          date = DateTime.now();
        }

        final matchedTag = row.tag != null
            ? ctrl.tags.firstWhereOrNull((t) => t.name == row.tag)
            : null;
        final activeMaId = ctrl.activeMaId.value > 0
            ? ctrl.activeMaId.value
            : null;

        vList.add(
          TxVoucher(
            date: date,
            note: row.description,
            source: 'import',
            tagId: matchedTag?.id,
            importHash: row.txHash,
            masterAccountId: activeMaId,
          ),
        );

        eList.add(
          row.debit > 0
              ? [
                  Entry(
                    transactionId: 0,
                    accountId: row.accountId!,
                    type: 'debit',
                    amount: row.debit,
                  ),
                  Entry(
                    transactionId: 0,
                    accountId: bankId,
                    type: 'credit',
                    amount: row.debit,
                  ),
                ]
              : [
                  Entry(
                    transactionId: 0,
                    accountId: bankId,
                    type: 'debit',
                    amount: row.credit,
                  ),
                  Entry(
                    transactionId: 0,
                    accountId: row.accountId!,
                    type: 'credit',
                    amount: row.credit,
                  ),
                ],
        );
      }

      final insertedCount = await DBHelper.instance.bulkInsertVouchers(
        vList,
        eList,
      );

      // Keywords save karo (manual assign ke liye bhi)
      setState(() => _loadingMsg = 'Saving keywords...');
      final kwMap = <int, List<String>>{};
      print("valid rows: $valid");
      for (final row in valid) {
        if (row.accountId == null) continue;
        final kw = _keywordsFromRow(row);

        print('keywords: $kw');
        if (kw.isNotEmpty) {
          kwMap.putIfAbsent(row.accountId!, () => []).addAll(kw);
        }
      }
      await DBHelper.instance.bulkUpdateKeywords(kwMap);

      await ctrl.loadAll();

      setState(() {
        _imported = true;
        _rows = [];
      });

      Get.snackbar(
        'Done! ✓',
        '$insertedCount vouchers imported.'
            '${valid.length - insertedCount > 0 ? " (${valid.length - insertedCount} already existed)" : ""}',
        backgroundColor: AppColors.credit,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Import failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ── Keyword Helpers ────────────────────────────────────
  // Description se keywords extract karo — next import mein auto-match ke liye
  List<String> _keywordsFromRow(PRowData row) {
    final keywords = <String>{};

    // 🔥 1. Cleaned Name (highest priority)
    if (row.cleanedName.isNotEmpty) {
      final name = _normalize(row.cleanedName);
      if (name.length >= 3) {
        keywords.add(name); // full phrase
      }
    }

    // 🔥 2. UPI handle
    final upiMatch = RegExp(
      r'([a-zA-Z0-9]{3,})@',
    ).firstMatch(row.description.toLowerCase());

    if (upiMatch != null) {
      final handle = upiMatch.group(1)!.toLowerCase();
      if (!_isStopWord(handle)) {
        keywords.add(handle);
      }
    }

    // 🔥 3. Smart words extraction
    final words = _normalize(
      row.description,
    ).split(' ').where((w) => w.length >= 3 && !_isStopWord(w)).toList();

    // 👉 Add best single word (main identity)
    if (words.isNotEmpty) {
      keywords.add(words.last); // usually name comes last (suraj)
    }

    // 👉 Add 2-word phrase (better accuracy)
    if (words.length >= 2) {
      keywords.add("${words[words.length - 2]} ${words.last}");
    }

    return keywords.toList();
  }

  static const _stopWords = {
    'upi',
    'neft',
    'imps',
    'rtgs',
    'ref',
    'txn',
    'trf',
    'the',
    'and',
    'for',
    'via',
    'from',
    'bank',
    'pay',
    'ltd',
    'pvt',
    'co',
    'corp',
    'payment',
    'transfer',
    'debit',
    'credit',
    'purchase',
    'order',
    'to',
    'by',
    'dr',
    'cr',
  };

  bool _isStopWord(String w) => _stopWords.contains(w.toLowerCase());
}
