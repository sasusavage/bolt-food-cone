import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../models/menu_item.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../widgets/food_image.dart';

class AdminStockTab extends StatefulWidget {
  const AdminStockTab({super.key});

  @override
  State<AdminStockTab> createState() => _AdminStockTabState();
}

class _AdminStockTabState extends State<AdminStockTab> {
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuViewModel>().loadMenu();
    });
  }

  Future<void> _set(MenuItemModel item, int stock) async {
    if (stock < 0) return;
    setState(() => _saving.add(item.id));
    try {
      await ApiClient.patch(
          '/api/admin/menu/${item.id}', {'stock': stock});
      if (!mounted) return;
      await context.read<MenuViewModel>().loadMenu();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving.remove(item.id));
    }
  }

  Future<void> _promptExact(MenuItemModel item) async {
    final ctrl = TextEditingController(text: '${item.stock}');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Set stock · ${item.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New quantity'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final v = int.tryParse(ctrl.text.trim());
                if (v != null && v >= 0) Navigator.pop(context, v);
              },
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) _set(item, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => vm.loadMenu(),
        child: vm.state == MenuState.loading && vm.items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vm.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = vm.items[i];
                  final saving = _saving.contains(item.id);
                  return _StockRow(
                    item: item,
                    saving: saving,
                    onDecrement: () => _set(item, item.stock - 1),
                    onIncrement: () => _set(item, item.stock + 1),
                    onTapNumber: () => _promptExact(item),
                  );
                },
              ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final MenuItemModel item;
  final bool saving;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapNumber;

  const _StockRow({
    required this.item,
    required this.saving,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
    final low = item.stock <= 3;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          FoodImage(
              url: item.imageUrl, width: 52, height: 52, radius: AppRadius.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(item.category,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: saving || item.stock <= 0 ? null : onDecrement,
                  icon: const Icon(Icons.remove, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                InkWell(
                  onTap: saving ? null : onTapNumber,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : Text('${item.stock}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: low
                                    ? AppColors.danger
                                    : AppColors.textPrimary)),
                  ),
                ),
                IconButton(
                  onPressed: saving ? null : onIncrement,
                  icon: const Icon(Icons.add,
                      size: 18, color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
