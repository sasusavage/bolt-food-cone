class MenuItemModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final int stock;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.stock,
    required this.isAvailable,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        category: json['category'],
        imageUrl: json['image_url'],
        stock: json['stock'],
        isAvailable: json['is_available'],
      );
}
