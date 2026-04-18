import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriceText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final Color? color;
  final FontWeight weight;

  const PriceText({
    super.key,
    required this.amount,
    this.fontSize = 15,
    this.color,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'GHS ${amount.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
