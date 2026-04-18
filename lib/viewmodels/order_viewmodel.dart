import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../core/api_client.dart';

enum OrderState { idle, loading, success, error }

class OrderViewModel extends ChangeNotifier {
  final _service = OrderService();

  OrderState state = OrderState.idle;
  List<OrderModel> myOrders = [];
  OrderModel? activeOrder;
  String? errorMessage;
  Timer? _pollingTimer;

  /// Place an order. Returns true on success, false on failure.
  Future<bool> placeOrder({
    required List<Map<String, dynamic>> cartPayload,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
  }) async {
    state = OrderState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final order = await _service.placeOrder(
        items: cartPayload,
        deliveryAddress: deliveryAddress,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        notes: notes,
      );
      activeOrder = order;
      myOrders.insert(0, order);
      state = OrderState.success;
      notifyListeners();
      startPolling(order.id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = OrderState.error;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      state = OrderState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyOrders() async {
    state = OrderState.loading;
    notifyListeners();
    try {
      myOrders = await _service.getMyOrders();
      state = OrderState.idle;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = OrderState.error;
    } catch (e) {
      errorMessage = e.toString();
      state = OrderState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Poll order status every 30 seconds until delivered/cancelled
  void startPolling(int orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final updated = await _service.getOrderById(orderId);
        activeOrder = updated;
        final idx = myOrders.indexWhere((o) => o.id == orderId);
        if (idx != -1) myOrders[idx] = updated;
        notifyListeners();
        if (updated.status == 'delivered' || updated.status == 'cancelled') {
          stopPolling();
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
