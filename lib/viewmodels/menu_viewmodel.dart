import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import '../core/api_client.dart';

enum MenuState { idle, loading, loaded, error }

class MenuViewModel extends ChangeNotifier {
  final _service = MenuService();

  MenuState state = MenuState.idle;
  List<MenuItemModel> _allItems = [];
  List<String> categories = [];
  String? selectedCategory;
  String? errorMessage;

  List<MenuItemModel> get items => selectedCategory == null
      ? _allItems
      : _allItems.where((i) => i.category == selectedCategory).toList();

  Future<void> loadMenu() async {
    state = MenuState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getMenu(),
        _service.getCategories(),
      ]);
      _allItems = results[0] as List<MenuItemModel>;
      categories = results[1] as List<String>;
      state = MenuState.loaded;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = MenuState.error;
    } catch (e) {
      errorMessage = e.toString();
      state = MenuState.error;
    } finally {
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }
}
