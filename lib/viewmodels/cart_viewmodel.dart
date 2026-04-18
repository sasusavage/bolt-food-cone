import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../core/constants.dart';

class CartViewModel extends ChangeNotifier {
  late Box<CartItem> _cartBox;

  List<CartItem> get items => _cartBox.values.toList();

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> init() async {
    _cartBox = await Hive.openBox<CartItem>(AppConstants.cartBoxName);
    notifyListeners();
  }

  void addItem(MenuItemModel menuItem) {
    // Find existing entry by menuItemId
    MapEntry<dynamic, CartItem>? existingEntry;
    for (final key in _cartBox.keys) {
      final item = _cartBox.get(key);
      if (item?.menuItemId == menuItem.id) {
        existingEntry = MapEntry(key, item!);
        break;
      }
    }

    if (existingEntry != null) {
      existingEntry.value.quantity += 1;
      existingEntry.value.save();
    } else {
      _cartBox.add(CartItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: 1,
        imageUrl: menuItem.imageUrl,
      ));
    }
    notifyListeners();
  }

  /// Increments quantity of an existing cart entry by menuItemId.
  /// Used by the cart screen's + button.
  void incrementItem(int menuItemId) {
    for (final key in _cartBox.keys) {
      final item = _cartBox.get(key);
      if (item?.menuItemId == menuItemId) {
        item!.quantity += 1;
        item.save();
        break;
      }
    }
    notifyListeners();
  }

  void decrementItem(int menuItemId) {
    for (final key in _cartBox.keys) {
      final item = _cartBox.get(key);
      if (item?.menuItemId == menuItemId) {
        if (item!.quantity <= 1) {
          _cartBox.delete(key);
        } else {
          item.quantity -= 1;
          item.save();
        }
        break;
      }
    }
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    for (final key in _cartBox.keys) {
      if (_cartBox.get(key)?.menuItemId == menuItemId) {
        _cartBox.delete(key);
        break;
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cartBox.clear();
    notifyListeners();
  }

  /// Converts cart to the payload format expected by POST /api/orders/place
  List<Map<String, dynamic>> toOrderPayload() {
    return items
        .map((e) => {'menu_item_id': e.menuItemId, 'quantity': e.quantity})
        .toList();
  }
}
