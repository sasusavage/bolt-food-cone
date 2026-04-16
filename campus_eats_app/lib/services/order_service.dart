import '../core/api_client.dart';
import '../models/order.dart';

class OrderService {
  Future<OrderModel> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
  }) async {
    final data = await ApiClient.post('/api/orders/place', {
      'items': items,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      if (notes != null) 'notes': notes,
    });
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final data = await ApiClient.get('/api/orders/my-orders');
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['orders'] != null) {
      list = data['orders'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final data =
        await ApiClient.get('/api/orders/$orderId') as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}
