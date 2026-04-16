// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/master_account_controller.dart';

import '../utils/constants.dart';
import 'add_edit_ma_screen.dart';

class MasterAccountsScreen extends StatelessWidget {
  const MasterAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MasterAccountController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Master Accounts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GetBuilder<MasterAccountController>(
        builder: (c) {
          if (c.masterAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Master Account found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create one via import or tap +',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...c.masterAccounts.map(
                (ma) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    // ── Tap → edit screen ──────────────────
                    onTap: () => AddEditMaScreen.open(ma: ma),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 24,
                      child: Text(
                        ma.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      ma.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // subtitle: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     if (ma.accountNumber != null)
                    //       Text(
                    //         'A/C: ${ma.accountNumber}',
                    //         style: const TextStyle(fontSize: 12),
                    //       ),
                    //     if (ma.bankName != null)
                    //       Text(
                    //         ma.bankName!,
                    //         style: const TextStyle(
                    //           color: Colors.grey,
                    //           fontSize: 11,
                    //         ),
                    //       ),
                    //   ],
                    // ),
                    // trailing: IconButton(
                    //   icon: const Icon(
                    //     Icons.edit_outlined,
                    //     size: 20,
                    //     color: Colors.grey,
                    //   ),
                    //   onPressed: () => AddEditMaScreen.open(ma: ma),
                    // ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_ma',
        onPressed: () => AddEditMaScreen.open(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Master Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
