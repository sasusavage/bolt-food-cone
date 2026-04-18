import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  Map<String, dynamic>? _stats;
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
      final data = await ApiClient.get('/api/admin/stats');
      if (mounted) setState(() => _stats = data as Map<String, dynamic>);
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading && _stats == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null && _stats == null)
            _ErrorBox(message: _error!, onRetry: _load)
          else if (_stats != null) ...[
            _statsGrid(),
            const SizedBox(height: 16),
            _statusBreakdown(),
            const SizedBox(height: 16),
            _popularSection(),
          ],
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final s = _stats!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.receipt_long,
          color: AppColors.primary,
          label: 'Orders today',
          value: '${s['orders_today'] ?? 0}',
          subtext: '${s['orders_week'] ?? 0} this week',
        ),
        _StatCard(
          icon: Icons.payments,
          color: AppColors.success,
          label: 'Revenue today',
          value: 'GHS ${(s['revenue_today'] ?? 0).toStringAsFixed(2)}',
          subtext: 'GHS ${(s['revenue_week'] ?? 0).toStringAsFixed(2)} / week',
        ),
        _StatCard(
          icon: Icons.pending_actions,
          color: AppColors.warning,
          label: 'Pending orders',
          value: '${s['pending_orders'] ?? 0}',
          subtext: 'needs attention',
        ),
        _StatCard(
          icon: Icons.people_alt,
          color: AppColors.statusConfirmed,
          label: 'Users',
          value: '${s['total_users'] ?? 0}',
          subtext:
              '${s['total_items'] ?? 0} items · ${s['out_of_stock'] ?? 0} out',
        ),
      ],
    );
  }

  Widget _statusBreakdown() {
    final breakdown = (_stats!['status_breakdown'] as Map?) ?? {};
    if (breakdown.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in breakdown.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(status: entry.key as String, small: true),
                    const SizedBox(width: 6),
                    Text('${entry.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 12),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _popularSection() {
    final popular =
        (_stats!['popular_items'] as List?) ?? const <dynamic>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular this week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (popular.isEmpty)
            const Text('No sales data yet',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (var i = 0; i < popular.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      popular[i]['name']?.toString() ?? 'Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('${popular[i]['sold'] ?? 0} sold',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              if (i < popular.length - 1)
                const Divider(height: 20, indent: 38),
            ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtext;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtext,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
