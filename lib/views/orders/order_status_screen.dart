import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/price_text.dart';
import '../../widgets/status_chip.dart';

class OrderStatusScreen extends StatefulWidget {
  final OrderModel order;
  const OrderStatusScreen({super.key, required this.order});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _refresh() async {
    final vm = context.read<OrderViewModel>();
    await vm.loadMyOrders();
    final updated = vm.myOrders.firstWhere(
      (o) => o.id == _order.id,
      orElse: () => _order,
    );
    if (mounted) setState(() => _order = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order.id}'),
        actions: [
          IconButton(
              onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            _timeline(_order.status),
            const SizedBox(height: 16),
            if (_order.deliveryAddress != null) _addressCard(),
            const SizedBox(height: 16),
            _itemsCard(),
            const SizedBox(height: 16),
            if ((_order.notes ?? '').isNotEmpty) _notesCard(),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final color = StatusChip.colorFor(_order.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(_iconFor(_order.status), color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headlineFor(_order.status),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(_subheadFor(_order.status),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _steps = [
    ('confirmed', 'Confirmed', Icons.receipt_long),
    ('preparing', 'Preparing', Icons.restaurant),
    ('out_for_delivery', 'Out for delivery', Icons.delivery_dining),
    ('delivered', 'Delivered', Icons.check_circle),
  ];

  Widget _timeline(String status) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.danger),
            SizedBox(width: 12),
            Text('This order was cancelled',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    int currentIdx = _steps.indexWhere((s) => s.$1 == status);
    if (status == 'pending') currentIdx = -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _TimelineStep(
              icon: _steps[i].$3,
              label: _steps[i].$2,
              isDone: i <= currentIdx,
              isCurrent: i == currentIdx + 1,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.location_on,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery address',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(_order.deliveryAddress!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final item in _order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.menuItemName ?? 'Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  PriceText(amount: item.subtotal, fontSize: 14),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              PriceText(
                  amount: _order.totalAmount,
                  fontSize: 18,
                  weight: FontWeight.w800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Note to rider',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_order.notes!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  IconData _iconFor(String s) => switch (s) {
        'pending' => Icons.schedule,
        'confirmed' => Icons.receipt_long,
        'preparing' => Icons.restaurant,
        'out_for_delivery' => Icons.delivery_dining,
        'delivered' => Icons.check_circle,
        'cancelled' => Icons.cancel,
        _ => Icons.info,
      };

  String _headlineFor(String s) => switch (s) {
        'pending' => 'We received your order',
        'confirmed' => 'Your order was confirmed',
        'preparing' => "We're preparing your food",
        'out_for_delivery' => 'On the way to you',
        'delivered' => 'Delivered — enjoy!',
        'cancelled' => 'Order cancelled',
        _ => 'Order update',
      };

  String _subheadFor(String s) => switch (s) {
        'pending' => 'Hang tight while the kitchen confirms.',
        'confirmed' => 'The kitchen is getting ready to cook.',
        'preparing' => 'Your food is being prepared with care.',
        'out_for_delivery' => 'A rider is on the way with your order.',
        'delivered' => 'We hope you enjoyed it. Bon appétit!',
        'cancelled' => 'If you were charged, it will be refunded shortly.',
        _ => '',
      };
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final active = isDone || isCurrent;
    final dotColor = isDone
        ? AppColors.success
        : (isCurrent ? AppColors.primary : AppColors.divider);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: active
                      ? dotColor.withValues(alpha: 0.15)
                      : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDone ? Icons.check : icon,
                  size: 16,
                  color: active ? dotColor : AppColors.textTertiary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.success : AppColors.divider,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
