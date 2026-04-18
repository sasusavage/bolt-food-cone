import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../widgets/food_image.dart';
import '../../widgets/price_text.dart';

class FoodDetailSheet extends StatefulWidget {
  final MenuItemModel item;
  const FoodDetailSheet({super.key, required this.item});

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cart = context.read<CartViewModel>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FoodImage(
                  url: item.imageUrl,
                  height: 200,
                  radius: AppRadius.lg,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(item.category,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.inventory_2_outlined,
                            size: 14,
                            color: item.stock > 5
                                ? AppColors.success
                                : AppColors.warning),
                        const SizedBox(width: 4),
                        Text('${item.stock} left',
                            style: TextStyle(
                                color: item.stock > 5
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (item.description != null &&
                        item.description!.trim().isNotEmpty)
                      Text(item.description!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.4)),
                  ],
                ),
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    _QtyStepper(
                      value: _qty,
                      min: 1,
                      max: item.stock,
                      onChanged: (v) => setState(() => _qty = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: ElevatedButton(
                  onPressed: () {
                    for (var i = 0; i < _qty; i++) {
                      cart.addItem(item);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} × $_qty added to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add to cart'),
                      PriceText(
                        amount: item.price * _qty,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () {
            if (value > min) onChanged(value - 1);
          }, enabled: value > min),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          _btn(Icons.add, () {
            if (value < max) onChanged(value + 1);
          }, enabled: value < max),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon,
              size: 18,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textTertiary),
        ),
      ),
    );
  }
}
