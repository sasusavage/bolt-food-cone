import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/price_text.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Delivery location'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search for a location…',
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textTertiary),
              suffixIcon: locationVm.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : null,
            ),
            onChanged: (v) => locationVm.searchAddress(v),
          ),
          if (locationVm.searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < locationVm.searchResults.length; i++)
                    Column(
                      children: [
                        if (i > 0)
                          const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.location_on,
                                color: AppColors.primary, size: 18),
                          ),
                          title: Text(
                            locationVm.searchResults[i].address,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            locationVm
                                .selectLocation(locationVm.searchResults[i]);
                            _searchCtrl.text =
                                locationVm.searchResults[i].address;
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (locationVm.selectedLocation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationVm.selectedLocation!.address,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      locationVm.clearSelection();
                      _searchCtrl.clear();
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Delivery notes'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              hintText: 'Ring the doorbell, leave at the front, etc.',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          _sectionTitle('Order summary'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                for (final i in cartVm.items)
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text('${i.quantity}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        PriceText(amount: i.subtotal, fontSize: 14),
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
                        amount: cartVm.totalAmount,
                        fontSize: 18,
                        weight: FontWeight.w800),
                  ],
                ),
              ],
            ),
          ),
          if (orderVm.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(orderVm.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.soft,
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Place order'),
                      PriceText(
                        amount: cartVm.totalAmount,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary));
}
