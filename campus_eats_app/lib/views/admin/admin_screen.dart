import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/menu_viewmodel.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuViewModel>().loadMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuVm = context.watch<MenuViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: menuVm.state == MenuState.loading
          ? const Center(child: CircularProgressIndicator())
          : menuVm.items.isEmpty
              ? const Center(child: Text('No menu items yet. Tap + to add one.'))
              : ListView.builder(
                  itemCount: menuVm.items.length,
                  itemBuilder: (context, i) {
                    final item = menuVm.items[i];
                    return ListTile(
                      leading: item.imageUrl != null
                          ? Image.network(item.imageUrl!,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.fastfood, size: 40),
                      title: Text(item.name),
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
                            onPressed: () =>
                                _deleteItem(context, item.id, item.name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
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
          decoration: const InputDecoration(labelText: 'New stock quantity'),
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
        title: const Text('Delete Item'),
        content: Text('Delete "$name"?'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

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
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          labelText: 'Stock', border: OutlineInputBorder()),
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