import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool small;
  const StatusChip({super.key, required this.status, this.small = false});

  static Color colorFor(String status) => switch (status) {
        'pending' => AppColors.statusPending,
        'confirmed' => AppColors.statusConfirmed,
        'preparing' => AppColors.statusPreparing,
        'out_for_delivery' => AppColors.statusOut,
        'delivered' => AppColors.statusDelivered,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.textTertiary,
      };

  static String labelFor(String status) => switch (status) {
        'out_for_delivery' => 'Out for delivery',
        _ => status[0].toUpperCase() + status.substring(1),
      };

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            labelFor(status),
            style: TextStyle(
              color: c,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
