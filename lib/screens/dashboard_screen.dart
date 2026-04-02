// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../controllers/master_account_controller.dart';
import '../utils/constants.dart';
import 'add_voucher_screen.dart';
import 'ledger_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maCtrl = Get.find<MasterAccountController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GetBuilder<AppController>(
        builder: (c) => RefreshIndicator(
          onRefresh: c.loadAll,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Obx(
                                        () => Text(
                                          maCtrl.defaultMA.value?.name ??
                                              'Dashboard',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              fmtAmt(c.totalAssetBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _topStat(
                                  'Expenses',
                                  c.totalExpenses,
                                  Colors.redAccent.shade100,
                                ),
                                const SizedBox(width: 20),
                                _topStat(
                                  'Will Receive',
                                  c.totalOutstandingToReceive,
                                  Colors.greenAccent.shade100,
                                ),
                                const SizedBox(width: 20),
                                _topStat(
                                  'Will Pay',
                                  c.totalOutstandingToPay,
                                  Colors.orangeAccent.shade100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── My Accounts ──────────────────────────────
                    _sectionLabel('My Accounts'),
                    const SizedBox(height: 8),
                    c.assetAccounts.isEmpty
                        ? _emptyBox('No accounts yet')
                        : SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: c.assetAccounts.length,
                              itemBuilder: (_, i) {
                                final acc = c.assetAccounts[i];
                                final bal = c.balances[acc.id] ?? 0;
                                return GestureDetector(
                                  onTap: () =>
                                      Get.to(() => LedgerScreen(account: acc)),
                                  child: Container(
                                    width: 148,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          AppIcons.forAccount(acc.type),
                                          color: AppIcons.colorFor(acc.type),
                                          size: 20,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              acc.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              fmtAmt(bal),
                                              style: TextStyle(
                                                color: bal >= 0
                                                    ? AppColors.credit
                                                    : AppColors.debit,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 20),

                    // ── Outstanding ──────────────────────────────
                    _sectionLabel('Outstanding'),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final persons = c.personAccounts
                            .where((p) => (c.balances[p.id] ?? 0) != 0)
                            .take(5)
                            .toList();

                        if (persons.isEmpty) {
                          return _emptyBox('No outstanding');
                        }

                        return Column(
                          children: List.generate(persons.length, (index) {
                            final p = persons[index];
                            final bal = c.balances[p.id] ?? 0;
                            final isPositive = bal > 0;

                            return GestureDetector(
                              onTap: () =>
                                  Get.to(() => LedgerScreen(account: p)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      child: Text(
                                        p.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          fmtAmt(bal.abs()),
                                          style: TextStyle(
                                            color: isPositive
                                                ? AppColors.credit
                                                : AppColors.debit,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isPositive
                                              ? 'Will give me'
                                              : 'I will give',
                                          style: TextStyle(
                                            color: isPositive
                                                ? AppColors.credit
                                                : AppColors.debit,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Recent Vouchers ──────────────────────────
                    _sectionLabel('Recent Vouchers'),
                    const SizedBox(height: 8),
                    if (c.vouchers.isEmpty)
                      _emptyBox('No vouchers available.')
                    else
                      ...c.vouchers.take(6).map((v) {
                        final entries = c.entriesCache[v.id] ?? [];
                        final drAccs = entries
                            .where((e) => e.isDebit)
                            .map((e) => c.accountById(e.accountId)?.name ?? '?')
                            .join(', ');
                        final crAccs = entries
                            .where((e) => e.isCredit)
                            .map((e) => c.accountById(e.accountId)?.name ?? '?')
                            .join(', ');

                        final tag = v.tagId != null
                            ? c.tagById(v.tagId!)
                            : null;

                        return Dismissible(
                          key: Key('dv_${v.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) => c.deleteVoucher(v.id!),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final es = await c.getVoucherEntries(v.id!);
                              Get.to(
                                () => AddVoucherScreen(
                                  existing: v,
                                  existingEntries: es,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$crAccs  →  $drAccs',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (v.note.isNotEmpty)
                                              Text(
                                                v.note,
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
                                      Text(
                                        DateFormat('dd/MM/yy').format(v.date),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ✅ Single tag chip
                                  if (tag != null) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: _tagChip(tag.name, tag.color),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tag chip ─────────────────────────────────────────
  Widget _tagChip(String name, String colorHex) {
    final tc = hexColor(colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tc.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tc,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: tc,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topStat(String l, double v, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(
        fmtAmt(v),
        style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _emptyBox(String msg) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    ),
  );
}
