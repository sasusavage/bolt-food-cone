import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../widgets/food_image.dart';
import '../../widgets/price_text.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
      ),
      body: vm.items.isEmpty ? _empty() : _list(vm),
      bottomNavigationBar: vm.items.isEmpty ? null : _checkoutBar(context, vm),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Your cart is empty',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Tap any dish on the home screen to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(CartViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in vm.items) _CartItemRow(item: item),
        const SizedBox(height: 24),
        _Summary(
            subtotal: vm.totalAmount,
            delivery: 0,
            total: vm.totalAmount),
      ],
    );
  }

  Widget _checkoutBar(BuildContext context, CartViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.soft,
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Proceed to checkout'),
              PriceText(
                  amount: vm.totalAmount,
                  color: Colors.white,
                  fontSize: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CartViewModel>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          FoodImage(url: item.imageUrl, width: 64, height: 64, radius: AppRadius.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                PriceText(amount: item.price, fontSize: 14),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => vm.decrementItem(item.menuItemId),
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                Text('${item.quantity}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => vm.incrementItem(item.menuItemId),
                  icon: const Icon(Icons.add,
                      size: 16, color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double subtotal;
  final double delivery;
  final double total;

  const _Summary({
    required this.subtotal,
    required this.delivery,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal),
          const SizedBox(height: 8),
          _row('Delivery',
              delivery == 0 ? null : delivery, fallback: 'Free'),
          const Divider(height: 24),
          _row('Total', total, bold: true, big: true),
        ],
      ),
    );
  }

  Widget _row(String label, double? amount,
      {bool bold = false, bool big = false, String? fallback}) {
    final style = TextStyle(
      fontSize: big ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        amount == null
            ? Text(fallback ?? '-',
                style: style.copyWith(color: AppColors.accent))
            : Text(
                'GHS ${amount.toStringAsFixed(2)}',
                style: style.copyWith(
                  color: bold ? AppColors.textPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ],
    );
  }
}
