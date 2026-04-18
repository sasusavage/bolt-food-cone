import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../splash_screen.dart';
import 'admin_categories_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_menu_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_stock_tab.dart';
import 'admin_users_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _tabs = const [
    _Tab('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Tab('Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu),
    _Tab('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
    _Tab('Stock', Icons.inventory_2_outlined, Icons.inventory_2),
    _Tab('Users', Icons.people_alt_outlined, Icons.people_alt),
    _Tab('Categories', Icons.category_outlined, Icons.category),
  ];

  final _pages = const [
    AdminDashboardTab(),
    AdminMenuTab(),
    AdminOrdersTab(),
    AdminStockTab(),
    AdminUsersTab(),
    AdminCategoriesTab(),
  ];

  void _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tabs[_index].label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Admin · ${user?.name ?? ""}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Column(
        children: [
          _TabStrip(
            tabs: _tabs,
            index: _index,
            onTap: (i) => setState(() => _index = i),
          ),
          const Divider(height: 1),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.label, this.icon, this.activeIcon);
}

class _TabStrip extends StatelessWidget {
  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  const _TabStrip({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final selected = i == index;
          final t = tabs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: selected ? AppColors.primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        selected ? t.activeIcon : t.icon,
                        size: 18,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
