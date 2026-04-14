// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:financeapp/database/db_helper.dart';
import 'package:financeapp/models/account.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../controllers/master_account_controller.dart';
import '../models/entry.dart';
import '../models/tx_voucher.dart';
import '../utils/constants.dart';

class AddVoucherScreen extends StatefulWidget {
  final TxVoucher? existing;
  final List<Entry>? existingEntries;
  const AddVoucherScreen({super.key, this.existing, this.existingEntries});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final ctrl = Get.find<AppController>();
  final maCtrl = Get.find<MasterAccountController>();
  final _noteCtrl = TextEditingController();
  final _addKwCtrl = TextEditingController(); // ✅ for add keyword dialog
  DateTime _date = DateTime.now();
  final List<Map<String, dynamic>> _rows = [];
  int? _selectedMAId;
  int? _selectedTagId;

  Set<String> _liveKeywords = {}; // ✅ live keywords state

  Set<String> _removedKeywords = {};

  bool get _isEdit => widget.existing != null;
  Timer? _kwTimer;

  @override
  void initState() {
    super.initState();

    // ✅ Real-time keyword extraction from note
    _noteCtrl.addListener(() {
      _kwTimer?.cancel(); // pehla timer cancel karo
      _kwTimer = Timer(const Duration(milliseconds: 700), () {
        // 600ms baad extract karo jab user ruk jaye
        final extracted = _extractKeywords(
          _noteCtrl.text,
        ).toSet().difference(_removedKeywords);
        setState(() {
          _liveKeywords = {..._liveKeywords, ...extracted};
        });
      });
    });
    if (_isEdit) {
      _date = widget.existing!.date;
      _noteCtrl.text = widget.existing!.note;
      _selectedMAId = widget.existing!.masterAccountId;
      _selectedTagId = widget.existing!.tagId;
      for (var e in widget.existingEntries ?? []) {
        _rows.add({
          'accountId': e.accountId,
          'type': e.type,
          'amountCtrl': TextEditingController(
            text: e.amount.toStringAsFixed(2),
          ),
        });
      }
    } else {
      // ✅ Auto-set from active business (Khata Book style)
      _selectedMAId = maCtrl.activeMA.value?.id;
      _addRow('debit');
      _addRow('credit');
    }
  }

  void _addRow(String type) => _rows.add({
    'accountId': null,
    'type': type,
    'amountCtrl': TextEditingController(),
  });

  void _clearAll() {
    setState(() {
      for (var r in _rows) {
        (r['amountCtrl'] as TextEditingController).dispose();
      }
      _rows.clear();
      _addRow('debit');
      _addRow('credit');
      _noteCtrl.clear();
      _date = DateTime.now();
      _selectedTagId = null;
      _liveKeywords = {};
      _removedKeywords = {};
    });
  }

  @override
  void dispose() {
    _kwTimer?.cancel();
    _noteCtrl.dispose();
    _addKwCtrl.dispose(); // ✅ dispose
    for (var r in _rows) {
      (r['amountCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  double get _totalDr => _rows
      .where((r) => r['type'] == 'debit')
      .fold(
        0.0,
        (s, r) =>
            s +
            (double.tryParse((r['amountCtrl'] as TextEditingController).text) ??
                0),
      );

  double get _totalCr => _rows
      .where((r) => r['type'] == 'credit')
      .fold(
        0.0,
        (s, r) =>
            s +
            (double.tryParse((r['amountCtrl'] as TextEditingController).text) ??
                0),
      );

  bool get _isBalanced => _totalDr > 0 && (_totalDr - _totalCr).abs() < 0.01;

  bool _shouldLearn(Account acc) {
    return acc.type != 'cash' && acc.type != 'bank';
  }

  List<String> _extractKeywords(String note) {
    final words = note
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((w) => w.length > 3)
        .toList();
    return words;
  }

  // ✅ Add keyword dialog
  void _showAddKeywordDialog() {
    _addKwCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Keyword', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: _addKwCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'e.g. petrol',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final val = _addKwCtrl.text.trim().toLowerCase();
              if (val.isNotEmpty) {
                setState(() => _liveKeywords.add(val));
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Transaction' : 'New Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clear button ─────────────────────────
            if (!_isEdit)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _clearAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_all_rounded,
                          size: 14,
                          color: Colors.red,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Date ─────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(_date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── DR/CR Table ───────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            'Dr/Cr',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        SizedBox(
                          width: 88,
                          child: Text(
                            'Amount',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 28),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...List.generate(_rows.length, (i) => _buildRow(i)),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        _addBtn('+ DR', 'debit', AppColors.debit),
                        const SizedBox(width: 8),
                        _addBtn('+ CR', 'credit', AppColors.credit),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Balance Bar ───────────────────────────
            _buildBalanceBar(),
            const SizedBox(height: 12),

            // ── Note ─────────────────────────────────
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Narration / Note...',
                prefixIcon: const Icon(Icons.notes_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ✅ Live Keywords Section
            if (!_isEdit &&
                (_liveKeywords.isNotEmpty || _noteCtrl.text.isNotEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keywords',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // ✅ Keyword chips
                        ..._liveKeywords.map(
                          (k) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _liveKeywords.remove(k);
                                    _removedKeywords.add(k); // ✅ blacklist
                                  }),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ✅ + Add button
                        GestureDetector(
                          onTap: _showAddKeywordDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 13, color: Colors.grey),
                                SizedBox(width: 3),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_voucher',
        onPressed: _isBalanced ? _save : null,
        backgroundColor: _isBalanced ? AppColors.credit : Colors.grey,
        icon: const Icon(Icons.save_outlined, color: Colors.white),
        label: Text(
          _isBalanced ? 'Save  (DR=CR ✓)' : 'DR ≠ CR',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int i) {
    final row = _rows[i];
    final isDr = row['type'] == 'debit';
    final color = isDr ? AppColors.debit : AppColors.credit;
    final amtCtrl = row['amountCtrl'] as TextEditingController;
    final selAcc = row['accountId'] != null
        ? ctrl.accountById(row['accountId'] as int)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        color: isDr
            ? AppColors.debit.withOpacity(0.02)
            : AppColors.credit.withOpacity(0.02),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              row['type'] = isDr ? 'credit' : 'debit';
            }),
            child: Container(
              width: 36,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  isDr ? 'Dr' : 'Cr',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickAccount(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selAcc == null
                    ? const Text(
                        'Account...',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : Row(
                        children: [
                          Icon(
                            AppIcons.forAccount(selAcc.type),
                            size: 13,
                            color: AppIcons.colorFor(selAcc.type),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              selAcc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 88,
            child: TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                hintText: '0.00',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: _rows.length > 2
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => setState(() {
                      (row['amountCtrl'] as TextEditingController).dispose();
                      _rows.removeAt(i);
                    }),
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBar() {
    final balanced = _isBalanced;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: balanced
            ? AppColors.credit.withOpacity(0.08)
            : AppColors.debit.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: balanced ? AppColors.credit : AppColors.debit,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            balanced
                ? Icons.check_circle_outline
                : Icons.warning_amber_outlined,
            color: balanced ? AppColors.credit : AppColors.debit,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'DR: ${fmtAmt(_totalDr)}',
            style: const TextStyle(
              color: AppColors.debit,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CR: ${fmtAmt(_totalCr)}',
            style: const TextStyle(
              color: AppColors.credit,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            balanced
                ? 'Balanced ✓'
                : 'Diff: ${fmtAmt((_totalDr - _totalCr).abs())}',
            style: TextStyle(
              color: balanced ? AppColors.credit : AppColors.debit,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addBtn(String label, String type, Color color) => GestureDetector(
    onTap: () => setState(() => _addRow(type)),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  void _pickAccount(int idx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, ss) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? ctrl.accounts
                : ctrl.accounts
                      .where((a) => a.name.toLowerCase().contains(query))
                      .toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        const Text(
                          'Select Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: searchCtrl,
                          onChanged: (_) => ss(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final a = filtered[i];
                        final color = AppIcons.colorFor(a.type);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(
                              AppIcons.forAccount(a.type),
                              size: 16,
                              color: color,
                            ),
                          ),
                          title: Text(
                            a.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Balance: ${fmtAmt(ctrl.balances[a.id] ?? 0)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            setState(() => _rows[idx]['accountId'] = a.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_isBalanced) return;

    // ── Validation ─────────────────────────────
    final drIds = _rows
        .where((r) => r['type'] == 'debit' && r['accountId'] != null)
        .map((r) => r['accountId'] as int)
        .toSet();
    final crIds = _rows
        .where((r) => r['type'] == 'credit' && r['accountId'] != null)
        .map((r) => r['accountId'] as int)
        .toSet();
    final conflict = drIds.intersection(crIds);
    if (conflict.isNotEmpty) {
      final name = ctrl.accountById(conflict.first)?.name ?? 'Account';
      Get.snackbar(
        'Invalid Entry',
        '"$name" cannot be both Dr and Cr in the same voucher',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    for (var row in _rows) {
      if (row['accountId'] == null) {
        Get.snackbar(
          'Error',
          'Please select an account for all rows',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // ── Build voucher & entries ─────────────────
    final voucher = TxVoucher(
      id: widget.existing?.id,
      date: _date,
      note: _noteCtrl.text.trim(),
      masterAccountId: _selectedMAId,
      // tagId: _selectedTagId,
    );

    final entries = _rows.map((row) {
      final amt =
          double.tryParse((row['amountCtrl'] as TextEditingController).text) ??
          0;
      return Entry(
        transactionId: 0,
        accountId: row['accountId'] as int,
        type: row['type'] as String,
        amount: amt,
      );
    }).toList();

    // ✅ Directly save _liveKeywords — no bottom sheet!
    if (_liveKeywords.isNotEmpty) {
      for (var e in entries) {
        final acc = ctrl.accountById(e.accountId);
        if (acc == null) continue;

        if (_shouldLearn(acc)) {
          await DBHelper.instance.updateAccountKeywords(
            acc.id!,
            _liveKeywords.toList(),
          );

          final updatedKeywords = await DBHelper.instance.getKeywordsForAccount(
            acc.id!,
          );

          final index = ctrl.accounts.indexWhere((a) => a.id == acc.id);
          if (index != -1) {
            ctrl.accounts[index] = ctrl.accounts[index].copyWith(
              keywords: updatedKeywords,
            );
            ctrl.accounts.refresh();
          }
        }
      }
    }

    // ── Save voucher ────────────────────────────
    if (_isEdit) {
      await ctrl.updateVoucher(voucher, entries);
      Get.back();
      Get.snackbar(
        'Updated',
        'Voucher updated!',
        backgroundColor: AppColors.credit,
        colorText: Colors.white,
      );
    } else {
      await ctrl.addVoucher(voucher, entries);
      Get.back();
      Get.snackbar(
        'Saved',
        'DR = CR ✓',
        backgroundColor: AppColors.credit,
        colorText: Colors.white,
      );
    }
  }
}
