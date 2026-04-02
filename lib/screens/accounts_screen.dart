// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../models/account.dart';
import '../utils/constants.dart';
import 'add_edit_account_screen.dart';
import 'ledger_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const _typeOrder = [
    'cash',
    'bank',
    'wallet',
    'person',
    'vendor',
    'expense',
  ];

  String _selectedType = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AppController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Accounts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GetBuilder<AppController>(
        builder: (c) {
          if (c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = c.accounts.where((a) {
            final typeMatch = _selectedType == 'all' || a.type == _selectedType;
            final searchMatch =
                _searchQuery.isEmpty ||
                a.name.toLowerCase().contains(_searchQuery.toLowerCase());
            return typeMatch && searchMatch;
          }).toList();

          return Column(
            children: [
              // ── Search bar ──────────────────────────────
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search accounts...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white60),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white60,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                ),
              ),

              // ── Type filter chips ───────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        color: AppColors.primary,
                        isActive: _selectedType == 'all',
                        onTap: () => setState(() => _selectedType = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ..._typeOrder.map((type) {
                        final exists = c.accounts.any((a) => a.type == type);
                        if (!exists) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: _shortLabel(type),
                            color: AppIcons.colorFor(type),
                            icon: AppIcons.forAccount(type),
                            isActive: _selectedType == type,
                            onTap: () => setState(
                              () => _selectedType = _selectedType == type
                                  ? 'all'
                                  : type,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Accounts list ───────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 56,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No accounts found',
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (_selectedType != 'all' ||
                                _searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedType = 'all';
                                  _searchQuery = '';
                                  _searchCtrl.clear();
                                }),
                                child: const Text('Clear filter'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final acc = filtered[index];
                          final bal = c.balances[acc.id] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
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
                            child: ListTile(
                              onTap: () =>
                                  Get.to(() => LedgerScreen(account: acc)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppIcons.colorFor(
                                    acc.type,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  AppIcons.forAccount(acc.type),
                                  color: AppIcons.colorFor(acc.type),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                acc.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                AppLabels.accountType[acc.type] ?? acc.type,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        fmtAmt(bal.abs()),
                                        style: TextStyle(
                                          color: bal >= 0
                                              ? AppColors.debit
                                              : AppColors.credit,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        bal > 0
                                            ? 'Dr'
                                            : bal < 0
                                            ? 'Cr'
                                            : '—',
                                        style: TextStyle(
                                          color: bal >= 0
                                              ? AppColors.debit
                                              : AppColors.credit,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        // ── Navigate to edit screen ──
                                        AddEditAccountScreen.open(
                                          account: acc,
                                          selectedType: _selectedType,
                                        );
                                      }
                                      if (v == 'delete') {
                                        _confirmDelete(ctrl, acc);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Edit'),
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          title: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          dense: true,
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        onPressed: () => AddEditAccountScreen.open(selectedType: _selectedType),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _shortLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Bank';
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      case 'person':
        return 'Person';
      case 'vendor':
        return 'Vendor';
      case 'expense':
        return 'Expense';
      case 'income':
        return 'Income';
      default:
        return type;
    }
  }

  void _confirmDelete(AppController ctrl, Account acc) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete "${acc.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ctrl.deleteAccount(acc.id!);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip Widget ─────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: isActive ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isActive ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
