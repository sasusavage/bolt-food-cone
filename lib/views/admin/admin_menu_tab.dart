import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../models/menu_item.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../widgets/food_image.dart';
import '../../widgets/price_text.dart';

class AdminMenuTab extends StatefulWidget {
  const AdminMenuTab({super.key});

  @override
  State<AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends State<AdminMenuTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuViewModel>().loadMenu();
    });
  }

  Future<void> _showItemSheet(
      BuildContext context, {MenuItemModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemEditSheet(existing: existing),
    );
    if (context.mounted) context.read<MenuViewModel>().loadMenu();
  }

  Future<void> _delete(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiClient.delete('/api/admin/menu/${item.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')));
      context.read<MenuViewModel>().loadMenu();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleAvailable(MenuItemModel item) async {
    try {
      await ApiClient.patch('/api/admin/menu/${item.id}',
          {'is_available': !item.isAvailable});
      if (!mounted) return;
      context.read<MenuViewModel>().loadMenu();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => vm.loadMenu(),
        child: _buildBody(vm),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    );
  }

  Widget _buildBody(MenuViewModel vm) {
    if (vm.state == MenuState.loading && vm.items.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (vm.items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Icons.restaurant_outlined,
                      size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('No menu items yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Tap "Add item" to create your first dish.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: vm.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = vm.items[i];
        return _MenuRow(
          item: item,
          onEdit: () => _showItemSheet(context, existing: item),
          onDelete: () => _delete(item),
          onToggleAvailable: () => _toggleAvailable(item),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailable;

  const _MenuRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final available = item.isAvailable && item.stock > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodImage(
              url: item.imageUrl, width: 72, height: 72, radius: AppRadius.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    _availabilityDot(available),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.category,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PriceText(amount: item.price, fontSize: 14),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.stock > 0
                            ? AppColors.surfaceAlt
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.stock > 0
                            ? 'Stock ${item.stock}'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.stock > 0
                              ? AppColors.textSecondary
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: onToggleAvailable,
                      icon: Icon(
                          item.isAvailable
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16),
                      label: Text(item.isAvailable ? 'Hide' : 'Show'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityDot(bool available) {
    final color = available ? AppColors.success : AppColors.danger;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MenuItemEditSheet extends StatefulWidget {
  final MenuItemModel? existing;
  const _MenuItemEditSheet({this.existing});

  @override
  State<_MenuItemEditSheet> createState() => _MenuItemEditSheetState();
}

class _MenuItemEditSheetState extends State<_MenuItemEditSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');
  final _categoryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _priceCtrl.text = e.price.toStringAsFixed(2);
      _descCtrl.text = e.description ?? '';
      _stockCtrl.text = '${e.stock}';
      _categoryCtrl.text = e.category;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1400);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        final id = widget.existing!.id;
        await ApiClient.patch('/api/admin/menu/$id', {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': double.parse(_priceCtrl.text.trim()),
          'category': _categoryCtrl.text.trim(),
          'stock': int.parse(_stockCtrl.text.trim()),
        });
        if (_imageFile != null) {
          await ApiClient.postMultipart(
            '/api/admin/menu/$id/image',
            const {},
            imageFile: _imageFile,
          );
        }
      } else {
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
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(_isEdit ? 'Edit item' : 'New menu item',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  children: [
                    _imagePicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Price (GHS)'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. Main Dish, Drinks',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description (optional)'),
                      maxLines: 3,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Save changes' : 'Create item'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final existingUrl = widget.existing?.imageUrl;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_imageFile!, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _editBadge(),
                  ),
                ],
              )
            : (existingUrl != null && existingUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      FoodImage(
                          url: existingUrl,
                          height: 180,
                          radius: AppRadius.md),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _editBadge(),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 44, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text('Add a photo',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  )),
      ),
    );
  }

  Widget _editBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('Change',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
