import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/success_burst.dart';

Future<void> showShopItemSheet(BuildContext context, ShopItem item) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (_) => _ItemSheet(item: item),
  );
}

class _ItemSheet extends StatelessWidget {
  final ShopItem item;
  const _ItemSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final owned = state.isShopItemOwned(item.id);
    final canAfford = state.points >= item.cost;
    final missing = (item.cost - state.points).clamp(0, 999999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Center(
              child: Icon(item.icon, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(item.category.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  )),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.cost} points',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('You have ${state.points} pts',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  )),
                    ],
                  ),
                ),
                if (!canAfford && !owned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text('Need $missing more',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                )),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: owned || !canAfford
                  ? null
                  : () async {
                      final ok =
                          await context.read<AppState>().purchaseShopItem(item);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (ok) {
                        showSuccessBurst(
                          context,
                          label: 'Purchased ${item.title}',
                          icon: Icons.shopping_bag_rounded,
                        );
                      }
                    },
              icon: Icon(owned
                  ? Icons.check_circle
                  : (canAfford
                      ? Icons.shopping_bag_rounded
                      : Icons.lock_outline)),
              label: Text(owned
                  ? 'Already owned'
                  : (canAfford ? 'Buy now' : 'Not enough points')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
