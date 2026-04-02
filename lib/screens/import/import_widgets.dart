// ignore_for_file: deprecated_member_use
import 'package:financeapp/utils/constants.dart';
import 'package:flutter/material.dart';


class StepLabel extends StatelessWidget {
  final String step, label;
  const StepLabel({super.key, required this.step, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

class StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class ImportBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const ImportBtn({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [AppColors.credit, AppColors.credit.withOpacity(0.8)],
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade300],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.credit.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 16,
            color: enabled ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            'Import',
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class AmountBadge extends StatelessWidget {
  final double amount;
  final bool isDebit;
  const AmountBadge({super.key, required this.amount, required this.isDebit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (isDebit ? AppColors.debit : AppColors.credit).withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '${isDebit ? '−' : '+'}${fmtAmt(amount)}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDebit ? AppColors.debit : AppColors.credit,
      ),
    ),
  );
}

class AppBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const AppBarBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 15, color: Colors.white),
    label: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ),
  );
}
