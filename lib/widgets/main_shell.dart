// ignore_for_file: deprecated_member_use

import 'package:financeapp/controllers/master_account_controller.dart';
import 'package:financeapp/screens/global_keyword_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/import/import_screen.dart';
import '../screens/vouchers_screen.dart';

import '../screens/master_accounts_screen.dart';
import '../models/master_account.dart';
import 'nav_item.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final idx = 0.obs;

  @override
  Widget build(BuildContext context) {
    final maCtrl = Get.find<MasterAccountController>();

    final screens = const [
      DashboardScreen(),
      AccountsScreen(),
      VouchersScreen(),
      //  TagsScreen(),
      GlobalKeywordsScreen(),
      ImportScreen(),
    ];

    return Obx(
      () => Scaffold(
        appBar: _buildBusinessAppBar(maCtrl),
        body: IndexedStack(index: idx.value, children: screens),
        drawer: _buildDrawer(context),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavItem(
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    'Home',
                    0,
                    idx,
                  ),
                  NavItem(
                    Icons.account_tree_outlined,
                    Icons.account_tree,
                    'Accounts',
                    1,
                    idx,
                  ),
                  NavItem(
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'Transactions',
                    2,
                    idx,
                  ),
                  // NavItem(
                  //   Icons.label_outlined,
                  //   Icons.label_rounded,
                  //   'Tags',
                  //   3,
                  //   idx,
                  // ),
                  NavItem(
                    Icons.key_outlined,
                    Icons.key_rounded,
                    'Keywords',
                    3,
                    idx,
                  ),
                  NavItem(
                    Icons.upload_file_outlined,
                    Icons.upload_file,
                    'Import',
                    4,
                    idx,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Khata Book style AppBar with active business name + tap to switch
  PreferredSizeWidget _buildBusinessAppBar(MasterAccountController maCtrl) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Obx(() {
        final ma = maCtrl.activeMA.value;
        return GestureDetector(
          onTap: () => _showBusinessSwitcher(maCtrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ma?.name ?? 'Select Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, color: Colors.white70, size: 20),
            ],
          ),
        );
      }),
      actions: [
        // Obx(() {
        //   final appCtrl = Get.find<AppController>();
        //   if (appCtrl.isLoading.value) {
        //     return const Padding(
        //       padding: EdgeInsets.only(right: 14),
        //       child: Center(
        //         child: SizedBox(
        //           width: 18,
        //           height: 18,
        //           child: CircularProgressIndicator(
        //             color: Colors.white,
        //             strokeWidth: 2,
        //           ),
        //         ),
        //       ),
        //     );
        //   }
        //   return const SizedBox.shrink();
        // }),
      ],
    );
  }

  /// ✅ Khata Book style business switcher bottom sheet
  void _showBusinessSwitcher(MasterAccountController maCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title + New button
            Row(
              children: [
                const Text(
                  'Switch Account',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const MasterAccountsScreen());
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Business list
            Obx(() {
              final businesses = maCtrl.masterAccounts;
              final activeMa = maCtrl.activeMA.value;

              if (businesses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No businesses yet. Create one!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: businesses.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final ma = businesses[i];
                  final isActive = ma.id == activeMa?.id;
                  return _BusinessTile(
                    ma: ma,
                    isActive: isActive,
                    onTap: () async {
                      Get.back();
                      if (!isActive) {
                        await maCtrl.switchBusiness(ma);
                      }
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Finance Ledger',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Double Entry App',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Master Accounts',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const MasterAccountsScreen());
              },
            ),

            const Divider(),
          ],
        ),
      ),
    );
  }
}

/// Individual business tile in the switcher bottom sheet
class _BusinessTile extends StatelessWidget {
  final MasterAccount ma;
  final bool isActive;
  final VoidCallback onTap;

  const _BusinessTile({
    required this.ma,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Avatar circle with first letter
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  ma.name[0].toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ma.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                      color: isActive ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (ma.bankName != null || ma.accountNumber != null)
                    Text(
                      [
                        ma.bankName,
                        ma.accountNumber,
                      ].where((s) => s != null).join(' • '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),

            // Active checkmark
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
