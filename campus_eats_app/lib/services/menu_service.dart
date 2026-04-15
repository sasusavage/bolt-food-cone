import '../core/api_client.dart';
import '../models/menu_item.dart';

class MenuService {
  Future<List<MenuItemModel>> getMenu({String? category}) async {
    final path =
        category != null ? '/api/menu/?category=$category' : '/api/menu/';
    final data = await ApiClient.get(path);
    final list = data is List ? data : (data as Map)['items'] as List? ?? [];
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getCategories() async {
    final data = await ApiClient.get('/api/menu/categories');
    if (data is List) return List<String>.from(data);
    return List<String>.from((data as Map)['categories'] ?? []);
  }
}
