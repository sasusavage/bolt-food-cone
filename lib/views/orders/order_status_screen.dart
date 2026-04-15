import 'package:flutter/material.dart';
import '../../models/order.dart';

class OrderStatusScreen extends StatelessWidget {
  final OrderModel order;
  const OrderStatusScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _StatusChip(status: order.status)),
            const SizedBox(height: 16),
            if (order.deliveryAddress != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(order.deliveryAddress!,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(item.menuItemName ?? 'Item',
                              style: const TextStyle(fontSize: 13))),
                      Text(
                          'x${item.quantity}  GHS ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('GHS ${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed: ${order.createdAt.toLocal().toString().substring(0, 16)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
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

  String get _label => status.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: _color,
    );
  }
}
