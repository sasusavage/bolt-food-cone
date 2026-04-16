import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../auth/login_screen.dart';
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

  void _logout(BuildContext context) async {
    final authVm = context.read<AuthViewModel>();
    final cartVm = context.read<CartViewModel>();
    await authVm.logout();
    cartVm.clearCart();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Eats'),
        actions: [
          if (authVm.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text('Hi, ${authVm.currentUser!.name}',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
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
              icon: Icon(Icons.receipt_long), label: 'My Orders'),
        ],
      ),
    );
  }
}
