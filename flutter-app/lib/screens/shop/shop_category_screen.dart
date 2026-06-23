import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/shop_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'shop_item_sheet.dart';

class ShopCategoryScreen extends StatelessWidget {
  final ShopCategory category;
  const ShopCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.allShopItems.where((i) => i.category == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  Icon(category.icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(category.blurb,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Icon(Icons.stars, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text('${state.points} pts',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          )),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _ShopGridCard(item: items[i]).animate().fadeIn(
                        delay: (40 * i).ms,
                        duration: 240.ms,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopGridCard extends StatelessWidget {
  final ShopItem item;
  const _ShopGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final owned = state.isShopItemOwned(item.id);
    final canAfford = state.points >= item.cost;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => showShopItemSheet(context, item),
      child: Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accentLight,
                        AppColors.accent.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Center(
                    child: Icon(item.icon, color: Colors.white, size: 36),
                  ),
                ),
                if (item.tag != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(item.tag!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              )),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.stars, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${item.cost}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        )),
                const Spacer(),
                _buyButton(context, owned: owned, canAfford: canAfford),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buyButton(BuildContext context,
      {required bool owned, required bool canAfford}) {
    if (owned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text('Owned',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    )),
          ],
        ),
      );
    }
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: canAfford ? () => showShopItemSheet(context, item) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: canAfford ? AppColors.primary : AppColors.divider,
          foregroundColor: canAfford ? Colors.white : AppColors.textMuted,
          textStyle: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: const Text('Buy'),
      ),
    );
  }
}
