import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3949AB);
  static const debit = Color(0xFFE53935);
  static const credit = Color(0xFF43A047);
  static const background = Color(0xFFF0F2F8);
}

class AppIcons {
  static IconData forAccount(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'cash':
        return Icons.money_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'person':
        return Icons.person_outline;
      case 'vendor':
        return Icons.store_outlined;
      case 'expense':
        return Icons.trending_down_outlined;
      case 'income':
        return Icons.trending_up_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  static Color colorFor(String type) {
    switch (type) {
      case 'bank':
        return const Color(0xFF1E88E5);
      case 'cash':
        return const Color(0xFF43A047);
      case 'wallet':
        return const Color(0xFF00ACC1);
      case 'person':
        return const Color(0xFF8E24AA);
      case 'vendor':
        return const Color(0xFFFF7043);
      case 'expense':
        return const Color(0xFFE53935);
      case 'income':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }
}

class AppLabels {
  static const Map<String, String> accountType = {
    'bank': 'Bank Account',
    'cash': 'Cash',
    'wallet': 'Digital Wallet',
    'person': 'Person',
    'vendor': 'Vendor / Store',
    'expense': 'Expense Account',
    'income': 'Income Account',
  };
}

String fmtAmt(double amount) {
  final abs = amount.abs();
  String s;
  if (abs >= 10000000) {
    s = '₹${(abs / 10000000).toStringAsFixed(2)}Cr';
  } else if (abs >= 100000) {
    s = '₹${(abs / 100000).toStringAsFixed(2)}L';
  } else {
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    String res = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) res = ',$res';
      res = intPart[i] + res;
      count++;
    }
    s = '₹$res.${parts[1]}';
  }
  return amount < 0 ? '-$s' : s;
}

Color hexColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return Colors.grey;
  }
}

const Map<String, String> kAutoTagMap = {
  'AMAZON': 'Shopping',
  'FLIPKART': 'Shopping',
  'SWIGGY': 'Food',
  'ZOMATO': 'Food',
  'OLA': 'Travel',
  'UBER': 'Travel',
  'RAPIDO': 'Travel',
  'IRCTC': 'Travel',
  'HOSPITAL': 'Medical',
  'PHARMA': 'Medical',
  'ELECTRIC': 'Bills & Utilities',
  'WATER': 'Bills & Utilities',
  'NETFLIX': 'Entertainment',
  'HOTSTAR': 'Entertainment',
};

const Map<String, String> kAutoVendorMap = {
  'AMAZON': 'Amazon',
  'FLIPKART': 'Flipkart',
  'SWIGGY': 'Swiggy',
  'ZOMATO': 'Zomato',
  'OLA': 'Ola',
  'UBER': 'Uber',
  'IRCTC': 'IRCTC',
  'NETFLIX': 'Netflix',
};

const List<String> kTagColors = [
  '#FF5722',
  '#2196F3',
  '#4CAF50',
  '#F44336',
  '#9C27B0',
  '#FF9800',
  '#607D8B',
  '#795548',
  '#E91E63',
  '#00BCD4',
  '#8BC34A',
  '#FFC107',
  '#3F51B5',
  '#009688',
  '#FF5252',
  '#FF6D00',
  '#AA00FF',
  '#00BFA5',
  '#D50000',
  '#2962FF',
];
