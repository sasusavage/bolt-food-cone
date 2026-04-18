import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/price_text.dart';
import '../../widgets/status_chip.dart';
import 'order_status_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => vm.loadMyOrders(),
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(OrderViewModel vm) {
    if (vm.state == OrderState.loading && vm.myOrders.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (vm.myOrders.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('No orders yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Orders you place will appear here.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.myOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _OrderCard(order: vm.myOrders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderStatusScreen(order: order)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  Text('Order #${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.items.map((i) => '${i.quantity}× ${i.menuItemName ?? "Item"}').join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(order.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                  const Spacer(),
                  PriceText(
                      amount: order.totalAmount,
                      fontSize: 15,
                      weight: FontWeight.w800),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
