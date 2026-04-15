class OrderModel {
  final int id;
  final int userId;
  final String status;
  final double totalAmount;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        userId: json['user_id'],
        status: json['status'],
        totalAmount: (json['total_amount'] as num).toDouble(),
        deliveryAddress: json['delivery_address'],
        deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
        deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List)
            .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class OrderItemModel {
  final int id;
  final int menuItemId;
  final String? menuItemName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.menuItemId,
    this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'],
        menuItemId: json['menu_item_id'],
        menuItemName: json['menu_item_name'],
        quantity: json['quantity'],
        unitPrice: (json['unit_price'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}
