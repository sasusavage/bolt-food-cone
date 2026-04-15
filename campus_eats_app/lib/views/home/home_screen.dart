import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../menu/menu_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/my_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [MenuScreen(), CartScreen(), MyOrdersScreen()];

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Eats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${cartVm.itemCount}'),
              isLabelVisible: cartVm.itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}
