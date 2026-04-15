import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuViewModel>().loadMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();

    if (vm.state == MenuState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.state == MenuState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorMessage ?? 'Error loading menu'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: vm.loadMenu, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (vm.categories.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: vm.selectedCategory == null,
                  onSelected: (_) => vm.setCategory(null),
                ),
                ...vm.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: vm.selectedCategory == cat,
                        onSelected: (_) => vm.setCategory(cat),
                      ),
                    )),
              ],
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: vm.items.length,
            itemBuilder: (context, index) =>
                _MenuItemCard(item: vm.items[index]),
          ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartVm = context.read<CartViewModel>();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Center(child: Icon(Icons.fastfood, size: 40)),
                  )
                : const Center(child: Icon(Icons.fastfood, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('GHS ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                Text('Stock: ${item.stock}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: item.stock > 0
                        ? () {
                            cartVm.addItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 1)),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4)),
                    child: Text(item.stock > 0 ? 'Add' : 'Out of stock',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
