import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../orders/order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartViewModel>();
    final orderVm = context.watch<OrderViewModel>();
    final locationVm = context.watch<LocationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Delivery Location',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search for delivery location...',
                border: const OutlineInputBorder(),
                suffixIcon: locationVm.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
              onChanged: (v) => locationVm.searchAddress(v),
            ),
            if (locationVm.searchResults.isNotEmpty)
              Material(
                elevation: 4,
                child: Column(
                  children: locationVm.searchResults
                      .map((r) => ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(r.address,
                                style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              locationVm.selectLocation(r);
                              _searchCtrl.text = r.address;
                            },
                          ))
                      .toList(),
                ),
              ),
            if (locationVm.selectedLocation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(locationVm.selectedLocation!.address,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  TextButton(
                      onPressed: () {
                        locationVm.clearSelection();
                        _searchCtrl.clear();
                      },
                      child: const Text('Change')),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const Spacer(),
            Text(
              'Total: GHS ${cartVm.totalAmount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (orderVm.errorMessage != null) ...[
              Text(orderVm.errorMessage!,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: (orderVm.state == OrderState.loading ||
                      locationVm.selectedLocation == null)
                  ? null
                  : () async {
                      final loc = locationVm.selectedLocation!;
                      final success = await orderVm.placeOrder(
                        cartPayload: cartVm.toOrderPayload(),
                        deliveryAddress: loc.address,
                        deliveryLat: loc.lat,
                        deliveryLng: loc.lng,
                        notes: _notesCtrl.text.isEmpty
                            ? null
                            : _notesCtrl.text,
                      );
                      if (success && mounted) {
                        cartVm.clearCart();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderStatusScreen(
                                order: orderVm.activeOrder!),
                          ),
                        );
                      }
                    },
              child: orderVm.state == OrderState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
