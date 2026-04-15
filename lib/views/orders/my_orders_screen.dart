import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
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

    if (vm.state == OrderState.loading && vm.myOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.myOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No orders yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: vm.myOrders.length,
      itemBuilder: (context, i) {
        final order = vm.myOrders[i];
        return ListTile(
          title: Text('Order #${order.id}'),
          subtitle: Text(
              '${order.items.length} item(s) · GHS ${order.totalAmount.toStringAsFixed(2)}'),
          trailing: _StatusChip(status: order.status),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderStatusScreen(order: order)),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'confirmed' => Colors.blue,
        'preparing' => Colors.purple,
        'out_for_delivery' => Colors.teal,
        'delivered' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' '),
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: _color,
      padding: EdgeInsets.zero,
    );
  }
}
