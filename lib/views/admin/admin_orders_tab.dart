import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/price_text.dart';
import '../../widgets/status_chip.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  List<OrderModel> _orders = [];
  bool _loading = false;
  String? _error;
  String _filter = 'active'; // active | all | delivered | cancelled

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/api/admin/orders');
      final list = data is List ? data : <dynamic>[];
      if (mounted) {
        setState(() {
          _orders = list
              .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(OrderModel order, String status) async {
    try {
      final data = await ApiClient.patch(
          '/api/admin/orders/${order.id}/status', {'status': status});
      if (!mounted) return;
      final updated = OrderModel.fromJson(data);
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Order #${order.id} → ${StatusChip.labelFor(status)}'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<OrderModel> get _filtered {
    switch (_filter) {
      case 'all':
        return _orders;
      case 'delivered':
        return _orders.where((o) => o.status == 'delivered').toList();
      case 'cancelled':
        return _orders.where((o) => o.status == 'cancelled').toList();
      case 'active':
      default:
        return _orders
            .where((o) =>
                o.status != 'delivered' && o.status != 'cancelled')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _filterBar(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    const options = {
      'active': 'Active',
      'all': 'All',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _filter == entry.key,
                onSelected: (_) => setState(() => _filter = entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _orders.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && _orders.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                const Icon(Icons.wifi_off,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
              child: Text('No orders here',
                  style: TextStyle(color: AppColors.textSecondary))),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final order = items[i];
        return _OrderCard(
          order: order,
          onUpdate: (s) => _update(order, s),
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(String status) onUpdate;

  const _OrderCard({required this.order, required this.onUpdate});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${order.id}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        StatusChip(status: order.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.userName ?? 'Unknown user',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PriceText(
                  amount: order.totalAmount,
                  fontSize: 16,
                  weight: FontWeight.w800),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                _fmt(order.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shopping_bag_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${order.items.length} item(s)',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(_expanded ? 'Hide details' : 'View details',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.primary),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            if (order.deliveryAddress != null)
              _detailRow(Icons.location_on, order.deliveryAddress!),
            if (order.userPhone != null && order.userPhone!.isNotEmpty)
              _detailRow(Icons.phone, order.userPhone!),
            if ((order.notes ?? '').isNotEmpty)
              _detailRow(Icons.sticky_note_2_outlined, order.notes!),
            const SizedBox(height: 8),
            const Text('Items',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${it.quantity}× ',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(it.menuItemName ?? 'Item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    PriceText(amount: it.subtotal, fontSize: 13),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in const [
                'confirmed',
                'preparing',
                'out_for_delivery',
                'delivered',
                'cancelled',
              ])
                _StatusButton(
                  status: s,
                  current: order.status == s,
                  onTap: () => widget.onUpdate(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusButton extends StatelessWidget {
  final String status;
  final bool current;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusChip.colorFor(status);
    return Material(
      color: current ? color : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: current ? null : onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            StatusChip.labelFor(status),
            style: TextStyle(
              color: current ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
