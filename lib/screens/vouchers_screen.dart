// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../controllers/master_account_controller.dart';
import '../models/tag.dart';
import '../utils/constants.dart';
import 'add_voucher_screen.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});
  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final ctrl = Get.find<AppController>();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter =>
      ctrl.filterMAId.value != -1 || ctrl.filterTagId.value != -1;

  void _openFilterSheet() {
    final maCtrl = Get.find<MasterAccountController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          final mas = maCtrl.masterAccounts;
          final tags = ctrl.tags;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (ctrl.filterMAId.value != -1 ||
                        ctrl.filterTagId.value != -1)
                      TextButton(
                        onPressed: () {
                          ctrl.filterMAId.value = -1;
                          ctrl.filterTagId.value = -1;
                          ctrl.update();
                          ss(() {});
                          setState(() {});
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Master Account ──────────────────────────────
                if (mas.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Master Account',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        color: AppColors.primary,
                        isActive: ctrl.filterMAId.value == -1,
                        onTap: () {
                          ctrl.filterMAId.value = -1;
                          ctrl.update();
                          ss(() {});
                          setState(() {});
                        },
                      ),
                      ...mas.map(
                        (ma) => _FilterChip(
                          label: ma.name,
                          color: AppColors.primary,
                          isActive: ctrl.filterMAId.value == ma.id,
                          avatar: ma.name[0].toUpperCase(),
                          isDefault: ma.isDefault,
                          onTap: () {
                            ctrl.filterMAId.value =
                                ctrl.filterMAId.value == ma.id ? -1 : ma.id!;
                            ctrl.update();
                            ss(() {});
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Tags ────────────────────────────────────────
                if (tags.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TAG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        color: Colors.grey.shade600,
                        isActive: ctrl.filterTagId.value == -1,
                        onTap: () {
                          ctrl.filterTagId.value = -1;
                          ctrl.update();
                          ss(() {});
                          setState(() {});
                        },
                      ),
                      ...tags.map((tag) {
                        final tc = hexColor(tag.color);
                        return _FilterChip(
                          label: tag.name,
                          color: tc,
                          isActive: ctrl.filterTagId.value == tag.id,
                          onTap: () {
                            ctrl.filterTagId.value =
                                ctrl.filterTagId.value == tag.id ? -1 : tag.id!;
                            ctrl.update();
                            ss(() {});
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilterSheet,
                  tooltip: 'Filter',
                ),
                if (_hasActiveFilter)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ctrl.searchQuery.value = v;
                ctrl.update();
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search by note...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white60,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white60,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          ctrl.searchQuery.value = '';
                          ctrl.update();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
            ),
          ),
        ),
      ),
      body: GetBuilder<AppController>(
        builder: (c) {
          if (c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = c.filteredVouchers;
          final maCtrl = Get.find<MasterAccountController>();
          final activeMA = c.filterMAId.value != -1
              ? maCtrl.getById(c.filterMAId.value)
              : null;
          final activeTag = c.filterTagId.value != -1
              ? c.tagById(c.filterTagId.value)
              : null;
          final showStrip = activeMA != null || activeTag != null;

          if (list.isEmpty) {
            return Column(
              children: [
                if (showStrip) _buildActiveStrip(c, activeMA, activeTag),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              if (showStrip) _buildActiveStrip(c, activeMA, activeTag),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final v = list[i];
                    final tag = v.tagId != null ? c.tagById(v.tagId!) : null;

                    // ── Lazy load: cache mein nahi hai toh fetch karo ──────
                    if (!c.entriesCache.containsKey(v.id)) {
                      c.getVoucherEntries(v.id!).then((_) => c.update());
                    }
                    final entries = c.entriesCache[v.id] ?? [];

                    final drAccs = entries
                        .where((e) => e.isDebit)
                        .map((e) => c.accountById(e.accountId)?.name ?? '?')
                        .join(', ');
                    final crAccs = entries
                        .where((e) => e.isCredit)
                        .map((e) => c.accountById(e.accountId)?.name ?? '?')
                        .join(', ');

                    return Dismissible(
                      key: Key('dv_${v.id}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Voucher?'),
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
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                                  // ── Loading skeleton jab entries fetch ho rahi hain ──
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: entries.isEmpty
                                        // Jab tak load ho raha hai — shimmer placeholder
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 12,
                                                width: 140,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Container(
                                                height: 10,
                                                width: 90,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

                              if (tag != null) ...[
                                const SizedBox(height: 7),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: _TagChip(tag: tag),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_vouchers',
        onPressed: () => Get.to(() => const AddVoucherScreen()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveStrip(AppController c, dynamic activeMA, Tag? activeTag) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 13,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          if (activeMA != null)
            _ActivePill(
              label: activeMA.name,
              color: AppColors.primary,
              onRemove: () {
                c.filterMAId.value = -1;
                c.update();
                setState(() {});
              },
            ),
          if (activeMA != null && activeTag != null) const SizedBox(width: 6),
          if (activeTag != null)
            _ActivePill(
              label: activeTag.name,
              color: hexColor(activeTag.color),
              onRemove: () {
                c.filterTagId.value = -1;
                c.update();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

// ── Reusable tag chip ──────────────────────────────────
class _TagChip extends StatelessWidget {
  final Tag tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final tc = hexColor(tag.color);
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
            tag.name,
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
}

// ── Active filter pill with X ──────────────────────────
class _ActivePill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;
  const _ActivePill({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip for bottom sheet ──────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool isDefault;
  final String? avatar;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.isDefault = false,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.25),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatar!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star_rounded,
                size: 12,
                color: isActive ? Colors.white : Colors.amber,
              ),
            ],
            if (isActive) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
