// ignore_for_file: deprecated_member_use

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
import 'tags_screen.dart';

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
  DateTime _date = DateTime.now();
  final List<Map<String, dynamic>> _rows = [];
  int? _selectedMAId;
  int? _selectedTagId; // ✅ Voucher-level tag

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _date = widget.existing!.date;
      _noteCtrl.text = widget.existing!.note;
      _selectedMAId = widget.existing!.masterAccountId;
      _selectedTagId = widget.existing!.tagId; // ✅ Load existing tag
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
      _selectedMAId = maCtrl.defaultMA.value?.id;
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
      _selectedTagId = null; // ✅ Reset tag
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
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
        .where((w) => w.length >= 3)
        .toList();

    return words.where((w) => w.length > 3).toList(); // simple start
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
            // ── Master Account Selector ──────────────
            _buildMASelector(),
            const SizedBox(height: 12),

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
            const SizedBox(height: 12),

            // ✅ Voucher-level Tag Picker
            //  _buildTagPicker(),
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

  // // ✅ Voucher-level tag picker widget
  // Widget _buildTagPicker() {
  //   final selTag = _selectedTagId != null
  //       ? ctrl.tagById(_selectedTagId!)
  //       : null;
  //   return GestureDetector(
  //     onTap: _pickTag,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  //       decoration: BoxDecoration(
  //         color: selTag != null
  //             ? hexColor(selTag.color).withOpacity(0.06)
  //             : Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border.all(
  //           color: selTag != null
  //               ? hexColor(selTag.color).withOpacity(0.4)
  //               : Colors.grey.shade200,
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(
  //             Icons.label_outline,
  //             size: 18,
  //             color: selTag != null ? hexColor(selTag.color) : Colors.grey,
  //           ),
  //           const SizedBox(width: 10),
  //           Expanded(
  //             child: selTag == null
  //                 ? const Text(
  //                     'Add tag...',
  //                     style: TextStyle(color: Colors.grey, fontSize: 13),
  //                   )
  //                 : Row(
  //                     children: [
  //                       Container(
  //                         width: 8,
  //                         height: 8,
  //                         decoration: BoxDecoration(
  //                           color: hexColor(selTag.color),
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Text(
  //                         selTag.name,
  //                         style: TextStyle(
  //                           color: hexColor(selTag.color),
  //                           fontWeight: FontWeight.w600,
  //                           fontSize: 13,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //           ),
  //           if (selTag != null)
  //             GestureDetector(
  //               onTap: () => setState(() => _selectedTagId = null),
  //               child: Icon(
  //                 Icons.close,
  //                 size: 16,
  //                 color: hexColor(selTag.color),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
          // Dr/Cr toggle
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

          // Account picker
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

          // Amount
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

          // Remove row button
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

  // ✅ Voucher-level tag picker — no idx parameter
  void _pickTag() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, ss) {
            final tags = ctrl.tags;
            return SizedBox(
              height: 380,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Select Tag',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedTagId = null);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.label_off_outlined, size: 15),
                          label: const Text(
                            'No Tag',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await Get.to(() => const TagsScreen());
                            ss(() {});
                          },
                          icon: const Icon(Icons.settings_outlined, size: 15),
                          label: const Text(
                            'Manage',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  tags.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text(
                              'No tags — create from Manage',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 2.4,
                                ),
                            itemCount: tags.length,
                            itemBuilder: (_, i) {
                              final tag = tags[i];
                              final tc = hexColor(tag.color);
                              final isSel = _selectedTagId == tag.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedTagId = tag.id);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: tc.withOpacity(isSel ? 0.18 : 0.07),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? tc : tc.withOpacity(0.3),
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: tc,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          tag.name,
                                          style: TextStyle(
                                            color: tc,
                                            fontSize: 11,
                                            fontWeight: isSel
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSel) ...[
                                        const SizedBox(width: 3),
                                        Icon(Icons.check, size: 11, color: tc),
                                      ],
                                    ],
                                  ),
                                ),
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

  Widget _buildMASelector() {
    final mas = maCtrl.masterAccounts;
    final selectedMA = _selectedMAId != null
        ? maCtrl.getById(_selectedMAId!)
        : null;

    if (mas.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_circle_outlined, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No Master Account',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickMA,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selectedMA != null
              ? AppColors.primary.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selectedMA != null
                ? AppColors.primary.withOpacity(0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: selectedMA != null ? AppColors.primary : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedMA != null
                        ? selectedMA.name
                        : 'Select Master Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selectedMA != null
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                  ),
                  if (selectedMA?.accountNumber != null)
                    Text(
                      'A/C: ${selectedMA!.accountNumber}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (selectedMA != null && selectedMA.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              color: selectedMA != null ? AppColors.primary : Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _pickMA() {
    final mas = maCtrl.masterAccounts;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Select Master Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedMAId = null);
                    Get.back();
                  },
                  child: const Text(
                    'None',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...mas.map(
              (ma) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    ma.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  ma.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: ma.accountNumber != null
                    ? Text(
                        'A/C: ${ma.accountNumber}',
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ma.isDefault)
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                    if (_selectedMAId == ma.id)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                onTap: () {
                  setState(() => _selectedMAId = ma.id);
                  Get.back();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

    final voucher = TxVoucher(
      id: widget.existing?.id,
      date: _date,
      note: _noteCtrl.text.trim(),
      masterAccountId: _selectedMAId,
      tagId: _selectedTagId,
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
        // tagId gone ✅
      );
    }).toList();

    final note = _noteCtrl.text.trim().toLowerCase();

    if (note.isNotEmpty) {
      final extracted = _extractKeywords(note);

      final selectedKeywords = await Get.bottomSheet<List<String>>(
        KeywordApprovalSheet(keywords: extracted),
        isScrollControlled: true,
        backgroundColor: Colors.white,
      );
      print("selected keyword = $selectedKeywords");
      if (selectedKeywords == null || selectedKeywords.isEmpty) {
        return; // user cancelled
      }

      for (var e in entries) {
        final acc = ctrl.accountById(e.accountId);
        if (acc == null) continue;

        if (_shouldLearn(acc)) {
          print("account id = ${acc.id}");
          await DBHelper.instance.updateAccountKeywords(
            acc.id!,
            selectedKeywords,
          );

          final updatedKeywords = await DBHelper.instance.getKeywordsForAccount(
            acc.id!,
          );

          final index = ctrl.accounts.indexWhere((a) => a.id == acc.id);

          if (index != -1) {
            ctrl.accounts[index] = ctrl.accounts[index].copyWith(
              keywords: updatedKeywords,
            );

            ctrl.accounts.refresh(); // 🔥 VERY IMPORTANT
          }
        }
      }
    }

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

class KeywordApprovalSheet extends StatefulWidget {
  final List<String> keywords;

  const KeywordApprovalSheet({super.key, required this.keywords});

  @override
  State<KeywordApprovalSheet> createState() => _KeywordApprovalSheetState();
}

class _KeywordApprovalSheetState extends State<KeywordApprovalSheet> {
  late Set<String> selected;

  final TextEditingController addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selected = widget.keywords.toSet(); // initial keywords
  }

  @override
  void dispose() {
    addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Keywords",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // ✅ KEYWORD LIST (UPDATED)
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selected.map((k) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(k, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),

                          // ❌ REMOVE BUTTON
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selected.remove(k);
                              });
                            },
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ➕ ADD NEW KEYWORD
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addCtrl,
                    decoration: InputDecoration(
                      hintText: "Add keyword...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final val = addCtrl.text.trim().toLowerCase();

                    if (val.isNotEmpty) {
                      setState(() {
                        selected.add(val); // ✅ ADD
                      });
                      addCtrl.clear();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ✅ CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selected.toList());
                },
                child: const Text("Confirm"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
