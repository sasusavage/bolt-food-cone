import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/menu_viewmodel.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/api/admin/categories');
      final list = data is List ? data : <dynamic>[];
      if (mounted) {
        setState(() {
          _categories = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rename(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isNotEmpty) Navigator.pop(context, v);
              },
              child: const Text('Rename')),
        ],
      ),
    );
    if (result == null || result == oldName || !mounted) return;
    try {
      await ApiClient.post('/api/admin/categories/rename', {
        'old': oldName,
        'new': result,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed "$oldName" → "$result"')));
      await _load();
      if (mounted) await context.read<MenuViewModel>().loadMenu();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading && _categories.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && _categories.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                const Icon(Icons.wifi_off,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_categories.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
              child: Text('No categories yet',
                  style: TextStyle(color: AppColors.textSecondary))),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = _categories[i];
        return _CategoryRow(
          name: c['name'] as String,
          count: c['item_count'] as int? ?? 0,
          onRename: () => _rename(c['name'] as String),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onRename;

  const _CategoryRow({
    required this.name,
    required this.count,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.category,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text('$count item${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRename,
            icon: const Icon(Icons.edit, color: AppColors.primary),
            tooltip: 'Rename',
          ),
        ],
      ),
    );
  }
}
