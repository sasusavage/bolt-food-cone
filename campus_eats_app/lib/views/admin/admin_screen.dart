import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../models/order.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  List<OrderModel> _orders = [];
  bool _loadingOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuViewModel>().loadMenu();
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final data = await ApiClient.get('/api/admin/orders');
      final list = data is List ? data : (data as Map)['orders'] as List? ?? data as List;
      setState(() {
        _orders = (list as List)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _logout() async {
    final authVm = context.read<AuthViewModel>();
    await authVm.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          onTap: (i) {
            setState(() => _tab = i);
            if (i == 1) _loadOrders();
          },
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItemSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : FloatingActionButton(
              onPressed: _loadOrders,
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh),
            ),
      body: _tab == 0 ? _buildMenuTab() : _buildOrdersTab(),
    );
  }

  Widget _buildMenuTab() {
    final menuVm = context.watch<MenuViewModel>();
    if (menuVm.state == MenuState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (menuVm.items.isEmpty) {
      return const Center(child: Text('No menu items yet. Tap + to add one.'));
    }
    return ListView.builder(
      itemCount: menuVm.items.length,
      itemBuilder: (context, i) {
        final item = menuVm.items[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(item.imageUrl!,
                        width: 52, height: 52, fit: BoxFit.cover),
                  )
                : const Icon(Icons.fastfood, size: 40),
            title: Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'GHS ${item.price.toStringAsFixed(2)} · Stock: ${item.stock} · ${item.category}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _showEditStockDialog(context, item.id, item.stock),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(context, item.id, item.name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No orders yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final order = _orders[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Row(
                children: [
                  Text('Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _StatusChip(status: order.status),
                ],
              ),
              subtitle: Text(
                '${order.items.length} item(s) · GHS ${order.totalAmount.toStringAsFixed(2)}\n'
                '${order.deliveryAddress ?? "No address"}\n'
                '${order.createdAt.toLocal().toString().substring(0, 16)}',
              ),
              children: [
                // Items list
                ...order.items.map((item) => ListTile(
                      dense: true,
                      title: Text(item.menuItemName ?? 'Item'),
                      trailing: Text(
                          'x${item.quantity}  GHS ${item.subtotal.toStringAsFixed(2)}'),
                    )),
                const Divider(),
                // Status update buttons
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Update Status:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'confirmed',
                          'preparing',
                          'out_for_delivery',
                          'delivered',
                          'cancelled',
                        ].map((status) {
                          final isCurrent = order.status == status;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isCurrent ? Colors.grey : _statusColor(status),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            onPressed: isCurrent
                                ? null
                                : () => _updateStatus(order.id, status),
                            child: Text(
                              status.replaceAll('_', ' '),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await ApiClient.patch(
          '/api/admin/orders/$orderId/status', {'status': status});
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Order #$orderId → ${status.replaceAll("_", " ")}')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddMenuItemSheet(),
    ).then((_) => context.read<MenuViewModel>().loadMenu());
  }

  void _showEditStockDialog(BuildContext context, int itemId, int currentStock) {
    final ctrl = TextEditingController(text: '$currentStock');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Stock'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'New stock quantity'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiClient.patch('/api/admin/menu/$itemId',
                    {'stock': int.parse(ctrl.text)});
                if (context.mounted) {
                  context.read<MenuViewModel>().loadMenu();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock updated')));
                }
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(BuildContext context, int itemId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "$name" from menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiClient.patch(
                    '/api/admin/menu/$itemId', {'is_available': false});
                if (context.mounted) {
                  context.read<MenuViewModel>().loadMenu();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item removed')));
                }
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'confirmed' => Colors.blue,
        'preparing' => Colors.purple,
        'out_for_delivery' => Colors.teal,
        'delivered' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.orange,
      };
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'confirmed' => Colors.blue,
        'preparing' => Colors.purple,
        'out_for_delivery' => Colors.teal,
        'delivered' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' '),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: _color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ─── Add Menu Item Bottom Sheet ───────────────────────────────────────────────

class _AddMenuItemSheet extends StatefulWidget {
  const _AddMenuItemSheet();

  @override
  State<_AddMenuItemSheet> createState() => _AddMenuItemSheetState();
}

class _AddMenuItemSheetState extends State<_AddMenuItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');
  final _categoryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.postMultipart(
        '/api/admin/menu',
        {
          'name': _nameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'category': _categoryCtrl.text.trim(),
          'stock': _stockCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
        },
        imageFile: _imageFile,
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Menu Item',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add image',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Price (GHS)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Stock',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category (e.g. Main Dish, Drinks)',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
