// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/app_controller.dart';
// import '../database/db_helper.dart';
// import '../utils/constants.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});
//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   final ctrl = Get.find<AppController>();
//   Map<String, double> _tagWise = {};
//   List<Map<String, dynamic>> _monthly = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     _tagWise = await DBHelper.instance.getTagWiseExpenses();
//     _monthly = await DBHelper.instance.getMonthlyExpenses();
//     setState(() => _loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text(
//           'Reports',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
//         ],
//       ),
//       body: GetBuilder<AppController>(
//         builder: (c) => _loading
//             ? const Center(child: CircularProgressIndicator())
//             : ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   // Summary
//                   _section('Summary'), const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _Card(
//                           'Total Balance',
//                           c.totalAssetBalance,
//                           AppColors.primary,
//                           Icons.account_balance_wallet_outlined,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _Card(
//                           'Total Expenses',
//                           c.totalExpenses,
//                           AppColors.debit,
//                           Icons.trending_down_outlined,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _Card(
//                           'Will Receive',
//                           c.totalOutstandingToReceive,
//                           AppColors.credit,
//                           Icons.arrow_circle_down_outlined,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _Card(
//                           'Will Pay',
//                           c.totalOutstandingToPay,
//                           Colors.orange,
//                           Icons.arrow_circle_up_outlined,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Trial Balance
//                   _section('Trial Balance'), const SizedBox(height: 8),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       children: [
//                         Container(
//                           color: Colors.grey.shade50,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 8,
//                           ),
//                           child: Row(
//                             children: const [
//                               Expanded(
//                                 child: Text(
//                                   'Account',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(
//                                 width: 80,
//                                 child: Text(
//                                   'Debit',
//                                   textAlign: TextAlign.right,
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                     color: AppColors.debit,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(
//                                 width: 80,
//                                 child: Text(
//                                   'Credit',
//                                   textAlign: TextAlign.right,
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                     color: AppColors.credit,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         ...c.accounts.map((acc) {
//                           final bal = c.balances[acc.id] ?? 0;
//                           return Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 14,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               border: Border(
//                                 bottom: BorderSide(color: Colors.grey.shade100),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   AppIcons.forAccount(acc.type),
//                                   size: 14,
//                                   color: AppIcons.colorFor(acc.type),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     acc.name,
//                                     style: const TextStyle(fontSize: 13),
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 80,
//                                   child: Text(
//                                     bal > 0 ? fmtAmt(bal) : '',
//                                     textAlign: TextAlign.right,
//                                     style: const TextStyle(
//                                       color: AppColors.debit,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 80,
//                                   child: Text(
//                                     bal < 0 ? fmtAmt(bal.abs()) : '',
//                                     textAlign: TextAlign.right,
//                                     style: const TextStyle(
//                                       color: AppColors.credit,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }),
//                         Container(
//                           color: Colors.grey.shade50,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 10,
//                           ),
//                           child: Row(
//                             children: [
//                               const Expanded(
//                                 child: Text(
//                                   'TOTAL',
//                                   style: TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               SizedBox(
//                                 width: 80,
//                                 child: Text(
//                                   fmtAmt(
//                                     c.accounts.fold(0.0, (s, a) {
//                                       final b = c.balances[a.id] ?? 0;
//                                       return s + (b > 0 ? b : 0);
//                                     }),
//                                   ),
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     color: AppColors.debit,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(
//                                 width: 80,
//                                 child: Text(
//                                   fmtAmt(
//                                     c.accounts.fold(0.0, (s, a) {
//                                       final b = c.balances[a.id] ?? 0;
//                                       return s + (b < 0 ? b.abs() : 0);
//                                     }),
//                                   ),
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     color: AppColors.credit,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Tag-wise expenses
//                   if (_tagWise.isNotEmpty) ...[
//                     _section('Category-wise Expenses'),
//                     const SizedBox(height: 8),
//                     ...() {
//                       final total = _tagWise.values.fold(0.0, (s, v) => s + v);
//                       return _tagWise.entries.map((e) {
//                         final pct = total == 0 ? 0.0 : e.value / total;
//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       e.key,
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                   Text(
//                                     fmtAmt(e.value),
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     '${(pct * 100).toStringAsFixed(1)}%',
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 6),
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(4),
//                                 child: LinearProgressIndicator(
//                                   value: pct,
//                                   minHeight: 6,
//                                   backgroundColor: Colors.grey.shade100,
//                                   valueColor: const AlwaysStoppedAnimation(
//                                     AppColors.debit,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       });
//                     }().toList(),
//                     const SizedBox(height: 24),
//                   ],

//                   // Monthly
//                   if (_monthly.isNotEmpty) ...[
//                     _section('Monthly Expenses'),
//                     const SizedBox(height: 8),
//                     Container(
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         children: () {
//                           final maxVal = _monthly.fold(
//                             0.0,
//                             (s, r) => (r['total'] as num).toDouble() > s
//                                 ? (r['total'] as num).toDouble()
//                                 : s,
//                           );
//                           const months = [
//                             'Jan',
//                             'Feb',
//                             'Mar',
//                             'Apr',
//                             'May',
//                             'Jun',
//                             'Jul',
//                             'Aug',
//                             'Sep',
//                             'Oct',
//                             'Nov',
//                             'Dec',
//                           ];
//                           return _monthly.map((r) {
//                             final month = r['month'] as String;
//                             final val = (r['total'] as num).toDouble();
//                             final pct = maxVal == 0 ? 0.0 : val / maxVal;
//                             final parts = month.split('-');
//                             final label =
//                                 '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 10),
//                               child: Row(
//                                 children: [
//                                   SizedBox(
//                                     width: 68,
//                                     child: Text(
//                                       label,
//                                       style: const TextStyle(
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                   Expanded(
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(4),
//                                       child: LinearProgressIndicator(
//                                         value: pct,
//                                         minHeight: 10,
//                                         backgroundColor: AppColors.debit
//                                             .withOpacity(0.08),
//                                         valueColor:
//                                             const AlwaysStoppedAnimation(
//                                               AppColors.debit,
//                                             ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     fmtAmt(val),
//                                     style: const TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }).toList();
//                         }(),
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 40),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _section(String t) => Text(
//     t,
//     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//   );
// }

// class _Card extends StatelessWidget {
//   final String title;
//   final double amount;
//   final Color color;
//   final IconData icon;
//   const _Card(this.title, this.amount, this.color, this.icon);
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(7),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 18),
//         ),
//         const SizedBox(height: 8),
//         Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
//         Text(
//           fmtAmt(amount),
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     ),
//   );
// }
