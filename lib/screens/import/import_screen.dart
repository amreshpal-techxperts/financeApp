// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_field

import 'dart:developer';

import 'package:financeapp/controllers/app_controller.dart';
import 'package:financeapp/database/db_helper.dart';
import 'package:financeapp/models/account.dart';

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

  // ✅ Auto-detected bank info
  String? _detectedAccountNumber;
  String? _detectedAccountName;
  Account? _confirmedBankAccount; // confirmation ke baad set hoga

  int get _activeRows => _rows.where((r) => !r.skip).length;
  int get _dupRows => _rows.where((r) => r.isDuplicate).length;
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
          if (_rows.isEmpty && !_imported && !_loading) _buildSetupCard(),
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
          if (!_loading && _rows.isEmpty && _imported) _buildEmptyState(),
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
      if (_rows.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Clear',
          onPressed: _confirmClear,
        ),
    ],
  );

  // ── Setup Card — simplified, no manual bank selection ──
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
        // ── Header ─────────────────────────────────────
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
                      'Upload CSV — bank will be auto-detected',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── How it works ───────────────────────────────
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHowItWorks(),
              const SizedBox(height: 20),

              // ── Upload Button ──────────────────────────
              GestureDetector(
                onTap: _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Choose CSV File',
                        style: TextStyle(
                          color: Colors.white,
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

  /// How it works — 3 steps
  Widget _buildHowItWorks() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
    ),
    child: Column(
      children: [
        _howStep(
          icon: Icons.upload_file_outlined,
          color: AppColors.primary,
          title: 'Upload CSV',
          subtitle: 'Select your bank statement CSV',
        ),
        const SizedBox(height: 10),
        _howStep(
          icon: Icons.auto_fix_high_outlined,
          color: Colors.orange,
          title: 'Auto-detect',
          subtitle: 'Bank account number will be detected from CSV',
        ),
        const SizedBox(height: 10),
        _howStep(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.credit,
          title: 'Confirm',
          subtitle: 'Verify the bank and import',
        ),
      ],
    ),
  );

  Widget _howStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    ],
  );

  // ── Stats Bar ──────────────────────────────────────────
  Widget _buildStatsBar() => Container(
    color: Colors.white,
    child: Column(
      children: [
        // ✅ Confirmed bank account info strip
        if (_confirmedBankAccount != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _confirmedBankAccount!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_confirmedBankAccount!.maskedAccountNumber != null)
                  Text(
                    _confirmedBankAccount!.maskedAccountNumber!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _changeBankAccount,
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
    final Color accColor = row.accountName == null
        ? Colors.red
        : AppColors.primary;

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
                : 'Upload CSV — bank will be auto-detected.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_imported) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _imported = false;
                _selectedBankAccountId = null;
                _confirmedBankAccount = null;
                _detectedAccountNumber = null;
                _detectedAccountName = null;
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

  // ══════════════════════════════════════════════════════
  // ✅ CSV ACCOUNT NUMBER DETECTION
  // ══════════════════════════════════════════════════════

  /// CSV ke pehle 20 lines mein account number dhundo
  String? _detectAccountNumberFromCsv(String csvContent) {
    final lines = csvContent.split('\n').take(20);

    log("lines $lines");

    // Priority patterns (specific se generic ki taraf)
    final patterns = [
      // "Account No.: 123456789012"
      RegExp(
        r'[Aa]ccount\s*[Nn][ou]\.?\s*[:\-]?\s*(\d[\d\s]{8,17}\d)',
        caseSensitive: false,
      ),
      // "A/C No: 123456789"
      RegExp(
        r'[Aa][/\\][Cc]\.?\s*[Nn][ou]?\.?\s*[:\-]?\s*(\d[\d\s]{8,17}\d)',
        caseSensitive: false,
      ),
      // "Acct: 123456789"
      RegExp(r'[Aa]cct\.?\s*[:\-]?\s*(\d[\d\s]{8,17}\d)', caseSensitive: false),
      // "Account Number 123456789012"
      RegExp(
        r'[Aa]ccount\s+[Nn]umber\s*[:\-]?\s*(\d[\d\s]{8,17}\d)',
        caseSensitive: false,
      ),
      // Fallback: standalone 9-18 digit number
      RegExp(r'\b(\d{9,18})\b'),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final num = match.group(1)!.replaceAll(RegExp(r'\s'), '');
          if (num.length >= 9) return num;
        }
      }
    }
    return null;
  }

  String? _detectBankName(String csv) {
    final lines = csv
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(20)
        .toList();

    // 🔥 1. Structured detection (Bank: ...)
    for (final line in lines) {
      final match = RegExp(
        r'bank\s*[:\-,]\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        final bank = match.group(1)?.trim();
        if (bank != null && bank.isNotEmpty) {
          return _normalizeBankName(bank);
        }
      }
    }

    // 🔥 2. Keyword detection (anywhere in header)
    final headerText = lines.join(' ').toLowerCase();

    final bankMap = {
      'state bank': 'SBI',
      'sbi': 'SBI',
      'hdfc': 'HDFC',
      'icici': 'ICICI',
      'axis': 'Axis Bank',
      'kotak': 'Kotak Bank',
      'yes bank': 'Yes Bank',
      'union bank': 'Union Bank',
      'pnb': 'PNB',
      'bank of baroda': 'BOB',
    };

    for (final key in bankMap.keys) {
      if (headerText.contains(key)) {
        return bankMap[key];
      }
    }

    // 🔥 3. Heuristic: line me "bank" word ho
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('bank')) {
        final cleaned = _cleanBankName(line);
        if (cleaned.length > 3) {
          return _normalizeBankName(cleaned);
        }
      }
    }

    return null;
  }

  String _cleanBankName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeBankName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('state bank')) return 'SBI';
    if (lower.contains('hdfc')) return 'HDFC';
    if (lower.contains('icici')) return 'ICICI';
    if (lower.contains('axis')) return 'Axis Bank';
    if (lower.contains('kotak')) return 'Kotak Bank';
    if (lower.contains('yes bank')) return 'Yes Bank';
    if (lower.contains('union bank')) return 'Union Bank';
    if (lower.contains('pnb')) return 'PNB';
    if (lower.contains('baroda')) return 'BOB';

    return _toTitleCase(name);
  }

  String _toTitleCase(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  // ══════════════════════════════════════════════════════
  // ✅ BANK CONFIRMATION BOTTOM SHEET
  // ══════════════════════════════════════════════════════

  /// CSV pick ke baad call hoga — bank confirm karo, phir parse karo
  Future<bool> _showBankConfirmationSheet({
    required String csvContent,
    required String? detectedAccNo,
    required Account? matchedAccount,
    required String? detectedName,
  }) async {
    final bankAccounts = ctrl.assetAccounts
        .where((a) => a.type == 'bank')
        .toList();

    final result = await showModalBottomSheet<_BankConfirmResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _BankConfirmSheet(
        detectedAccNo: detectedAccNo,
        matchedAccount: matchedAccount,
        detectedName: detectedName,
        bankAccounts: bankAccounts,
        onNewAccount: _createNewBankAccount,
      ),
    );

    if (result == null) return false; // user ne dismiss kiya

    setState(() {
      _confirmedBankAccount = result.account;
      _selectedBankAccountId = result.account.id;
    });
    return true;
  }

  /// Naya bank account create karo
  Future<Account?> _createNewBankAccount({
    required String name,
    required String? accountNumber,
  }) async {
    final newAcc = Account(
      name: name,
      type: 'bank',
      openingBalance: 0,
      accountNumber: accountNumber,
      masterAccountId: ctrl.activeMaId.value > 0 ? ctrl.activeMaId.value : null,
    );
    await ctrl.addAccount(newAcc);
    return newAcc;
  }

  /// User stats bar se bank change karna chahe
  void _changeBankAccount() {
    final bankAccounts = ctrl.assetAccounts
        .where((a) => a.type == 'bank')
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BankSelectorSheet(
        bankAccounts: bankAccounts,
        selectedId: _selectedBankAccountId,
        onSelect: (acc) {
          setState(() {
            _confirmedBankAccount = acc;
            _selectedBankAccountId = acc.id;
          });
          Navigator.pop(context);
        },
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
              _confirmedBankAccount = null;
              _selectedBankAccountId = null;
              _detectedAccountNumber = null;
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

  // ══════════════════════════════════════════════════════
  // ✅ PICK & PARSE CSV — AUTO-DETECT FLOW
  // ══════════════════════════════════════════════════════

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

      print('content ${content.runtimeType} $content');

      // ✅ Step 1: Account number detect karo CSV header se
      setState(() => _loadingMsg = 'Detecting bank account...');

      final detectedAccNo = _detectAccountNumberFromCsv(content);
      final detectedName = _detectBankName(content);

      _detectedAccountNumber = detectedAccNo;
      _detectedAccountName = detectedName;

      // ✅ Step 2: Existing bank accounts mein match dhundo
      Account? matchedAccount;
      if (detectedAccNo != null) {
        final activeMaId = ctrl.activeMaId.value > 0
            ? ctrl.activeMaId.value
            : null;
        matchedAccount = await DBHelper.instance.findBankByAccountNumber(
          detectedAccNo,
          masterAccountId: activeMaId,
        );
      }

      setState(() => _loading = false);

      // ✅ Step 3: User se confirm karo
      final confirmed = await _showBankConfirmationSheet(
        csvContent: content,
        detectedAccNo: detectedAccNo,
        matchedAccount: matchedAccount,
        detectedName: detectedName,
      );

      if (!confirmed) return; // user ne cancel kiya

      // ✅ Step 4: Full parse karo
      setState(() {
        _loading = true;
        _loadingMsg = 'Checking duplicates...';
      });

      final existingKeys = await _buildExistingTxKeys();

      setState(() => _loadingMsg = 'Loading keywords...');

      final keywordsMap = <int, List<String>>{};
      for (final acc in ctrl.accounts) {
        if (acc.id != null && acc.keywords.isNotEmpty) {
          keywordsMap[acc.id!] = List<String>.from(acc.keywords);
        }
      }

      final globalKwMap = await DBHelper.instance.getGlobalKeywordsMap();
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
        [activeMaId],
      );
      return result.map((r) => r['importHash'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Edit Row Account ───────────────────────────────────
  void _editRowAcc(int rowIdx) {
    final row = _rows[rowIdx];
    final sugName =
        row.accountName ??
        row.description.split(RegExp(r'\s+')).take(3).join(' ').trim();
    final sugType = row.accountType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
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

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                                onPressed: () =>
                                    ss(() => showCreate = !showCreate),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    24,
                                  ),
                                  children: grouped.entries.map((g) {
                                    final color = AppIcons.colorFor(g.key);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                backgroundColor: color
                                                    .withOpacity(0.12),
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
                                                fmtAmt(
                                                  ctrl.balances[a.id] ?? 0,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              trailing: isSelected
                                                  ? Icon(
                                                      Icons
                                                          .check_circle_rounded,
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
                                                if (a.id != null) {
                                                  final kw = _keywordsFromRow(
                                                    row,
                                                  );
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
      },
    );
  }

  // ── Do Import ──────────────────────────────────────────
  Future<void> _doImport() async {
    if (_selectedBankAccountId == null) {
      Get.snackbar(
        'Error',
        'Bank account not confirmed. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

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
            '$_unsetRows rows do not have an assigned account. Skip them?',
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
      final valid = _rows.where((r) => !r.skip && r.accountId != null).toList();
      final vList = <TxVoucher>[];
      final eList = <List<Entry>>[];
      final bankId = _selectedBankAccountId!;

      for (final row in valid) {
        DateTime date;
        try {
          date = DateTime.parse(normalizeDate(row.date));
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

      setState(() => _loadingMsg = 'Saving keywords...');
      final kwMap = <int, List<String>>{};
      for (final row in valid) {
        if (row.accountId == null) continue;
        final kw = _keywordsFromRow(row);
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

  List<String> _keywordsFromRow(PRowData row) {
    final keywords = <String>{};
    if (row.cleanedName.isNotEmpty) {
      final name = _normalize(row.cleanedName);
      if (name.length >= 3) keywords.add(name);
    }
    final upiMatch = RegExp(
      r'([a-zA-Z0-9]{3,})@',
    ).firstMatch(row.description.toLowerCase());
    if (upiMatch != null) {
      final handle = upiMatch.group(1)!.toLowerCase();
      if (!_isStopWord(handle)) keywords.add(handle);
    }
    final words = _normalize(
      row.description,
    ).split(' ').where((w) => w.length >= 3 && !_isStopWord(w)).toList();
    if (words.isNotEmpty) keywords.add(words.last);
    if (words.length >= 2) {
      keywords.add('${words[words.length - 2]} ${words.last}');
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

// ══════════════════════════════════════════════════════════════════════
// ✅ BANK CONFIRM RESULT
// ══════════════════════════════════════════════════════════════════════

class _BankConfirmResult {
  final Account account;
  const _BankConfirmResult(this.account);
}

// ══════════════════════════════════════════════════════════════════════
// ✅ BANK CONFIRMATION BOTTOM SHEET WIDGET
// ══════════════════════════════════════════════════════════════════════

class _BankConfirmSheet extends StatefulWidget {
  final String? detectedAccNo;
  final String? detectedName;
  final Account? matchedAccount;
  final List<Account> bankAccounts;
  final Future<Account?> Function({
    required String name,
    required String? accountNumber,
  })
  onNewAccount;

  const _BankConfirmSheet({
    required this.detectedAccNo,
    required this.matchedAccount,
    required this.bankAccounts,
    required this.detectedName,
    required this.onNewAccount,
  });

  @override
  State<_BankConfirmSheet> createState() => _BankConfirmSheetState();
}

class _BankConfirmSheetState extends State<_BankConfirmSheet> {
  // View states: 'confirm' | 'select' | 'create'
  String _view = 'confirm';

  Account? _selectedAccount;
  final _nameCtrl = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    if (widget.detectedName != null) {
      _nameCtrl.text = widget.detectedName!;
    }
    _selectedAccount = widget.matchedAccount;
    // Agar match nahi mila to seedha select view
    if (widget.matchedAccount != null) {
      _view = 'confirm';
    } else if (widget.detectedAccNo != null || widget.detectedName != null) {
      _view = 'create';
    } else if (widget.bankAccounts.isNotEmpty) {
      _view = 'select';
    } else {
      _view = 'create';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedAccount == null) {
      Get.snackbar("Error", "Please select account");
      return;
    }

    Navigator.pop(context, _BankConfirmResult(_selectedAccount!));
  }

  Future<void> _createAndConfirm() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar("Error", "Enter account name");
      return;
    }
    setState(() => _creating = true);
    try {
      final acc = await widget.onNewAccount(
        name: name,
        accountNumber: widget.detectedAccNo,
      );
      if (acc != null && mounted) {
        Navigator.pop(context, _BankConfirmResult(acc));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _view == 'select' ? 0.7 : 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            if (_view == 'confirm') _buildConfirmView(),
            if (_view == 'select') _buildSelectView(sc),
            if (_view == 'create') _buildCreateView(),
          ],
        ),
      ),
    );
  }

  // ── View 1: Confirm matched account ─────────────────────
  Widget _buildConfirmView() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    child: Column(
      children: [
        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_outlined,
            size: 30,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bank Account Detected',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Is this your bank account?',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        // Account card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAccount?.name ??
                          widget.detectedName ??
                          'Unknown',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.detectedAccNo != null)
                      Text(
                        'Account: ••••${widget.detectedAccNo!.length >= 4 ? widget.detectedAccNo!.substring(widget.detectedAccNo!.length - 4) : widget.detectedAccNo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _view = 'select'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'No, change',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Yes, this is it ✓',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── View 2: Select from existing bank accounts ───────────
  Widget _buildSelectView(ScrollController sc) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Select Bank Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _view = 'create'),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('New', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (widget.detectedAccNo != null)
                Text(
                  'Detected: ••••${widget.detectedAccNo!.length >= 4 ? widget.detectedAccNo!.substring(widget.detectedAccNo!.length - 4) : widget.detectedAccNo}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey.shade100),
        Expanded(
          child: widget.bankAccounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No bank account found',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _view = 'create'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create new bank account'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: widget.bankAccounts.length,
                  itemBuilder: (_, i) {
                    final acc = widget.bankAccounts[i];
                    final isSelected = _selectedAccount?.id == acc.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.06)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.shade100,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          acc.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                        subtitle: acc.maskedAccountNumber != null
                            ? Text(
                                acc.maskedAccountNumber!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedAccount = acc);
                          _confirm();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );

  // ── View 3: Create new bank account ─────────────────────
  Widget _buildCreateView() => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 12,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Create New Bank Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (widget.bankAccounts.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _view = 'select'),
                child: const Text(
                  'Select existing',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Detected account number display
        if (widget.detectedAccNo != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Account Number',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.detectedAccNo!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Bank Account Name',
            hintText: 'e.g. SBI , HDFC ',
            prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _creating ? null : _createAndConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 16),
            label: Text(
              _creating ? 'Creating...' : 'Create & Import',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
// ✅ BANK SELECTOR SHEET (stats bar "Change" button ke liye)
// ══════════════════════════════════════════════════════════════════════

class _BankSelectorSheet extends StatelessWidget {
  final List<Account> bankAccounts;
  final int? selectedId;
  final void Function(Account) onSelect;

  const _BankSelectorSheet({
    required this.bankAccounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Bank Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ...bankAccounts.map((acc) {
            final isSelected = acc.id == selectedId;
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.account_balance_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                acc.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
              subtitle: acc.maskedAccountNumber != null
                  ? Text(acc.maskedAccountNumber!)
                  : null,
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () => onSelect(acc),
            );
          }),
        ],
      ),
    );
  }
}
