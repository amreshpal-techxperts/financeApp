import 'package:financeapp/screens/global_keyword_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/import/import_screen.dart';
import '../screens/vouchers_screen.dart';
import '../screens/tags_screen.dart';
import '../screens/master_accounts_screen.dart';
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
    final screens = const [
      DashboardScreen(),
      AccountsScreen(),
      VouchersScreen(),
      TagsScreen(),
      GlobalKeywordsScreen(),
      MasterAccountsScreen(),
      ImportScreen(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(index: idx.value, children: screens),
        drawer: _buildDrawer(context),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
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
                  NavItem(
                    Icons.label_outlined,
                    Icons.label_rounded,
                    'Tags',
                    3,
                    idx,
                  ),
                    NavItem(
                    Icons.label_outlined,
                    Icons.label_rounded,
                    'Keywords',
                    4,
                    idx,
                  ),

                  
                  NavItem(
                    Icons.account_circle_outlined,
                    Icons.account_circle,
                    'MA',
                    5,
                    idx,
                  ),
                  NavItem(
                    Icons.upload_file_outlined,
                    Icons.upload_file,
                    'Import',
                    6,
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
                      // ignore: deprecated_member_use
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

            // ── Menu Items ───────────────────────────────
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Finance Ledger v1.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
