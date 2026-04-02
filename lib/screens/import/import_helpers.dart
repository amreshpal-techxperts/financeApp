import 'package:flutter/material.dart';

const kImportTags = [
  'Food',
  'Travel',
  'Shopping',
  'Bills',
  'Salary',
  'Rent',
  'Medical',
  'Fuel',
  'EMI',
  'Investment',
  'Refund',
  'Transfer',
  'Other',
];

Color tagColor(String? tag) {
  switch (tag) {
    case 'Food':
      return const Color(0xFFFF6B35);
    case 'Travel':
      return const Color(0xFF2196F3);
    case 'Shopping':
      return const Color(0xFF9C27B0);
    case 'Bills':
      return const Color(0xFFF44336);
    case 'Salary':
      return const Color(0xFF4CAF50);
    case 'Rent':
      return const Color(0xFF795548);
    case 'Medical':
      return const Color(0xFFE91E63);
    case 'Fuel':
      return const Color(0xFFFF9800);
    case 'EMI':
      return const Color(0xFF3F51B5);
    case 'Investment':
      return const Color(0xFF009688);
    case 'Refund':
      return const Color(0xFF8BC34A);
    case 'Transfer':
      return const Color(0xFF607D8B);
    default:
      return const Color(0xFF9E9E9E);
  }
}

IconData tagIcon(String? tag) {
  switch (tag) {
    case 'Food':
      return Icons.restaurant_outlined;
    case 'Travel':
      return Icons.flight_outlined;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Bills':
      return Icons.receipt_outlined;
    case 'Salary':
      return Icons.work_outline;
    case 'Rent':
      return Icons.home_outlined;
    case 'Medical':
      return Icons.local_hospital_outlined;
    case 'Fuel':
      return Icons.local_gas_station_outlined;
    case 'EMI':
      return Icons.account_balance_outlined;
    case 'Investment':
      return Icons.trending_up_outlined;
    case 'Refund':
      return Icons.keyboard_return_outlined;
    case 'Transfer':
      return Icons.swap_horiz_outlined;
    default:
      return Icons.label_outline;
  }
}
