import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/shop_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/gradient_hero.dart';
import '../../widgets/stat_chip.dart';
import 'my_purchases_screen.dart';
import 'shop_category_screen.dart';
import 'shop_item_sheet.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final featured = state.allShopItems.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AAURA Shop'),
        actions: [
          IconButton(
            tooltip: 'My purchases',
            onPressed: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(builder: (_) => const MyPurchasesScreen()),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          GradientHero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spend your points',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${state.points} pts',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${state.ownedShopItemIds.length} owned',
                    ),
                    StatChip(
                      icon: Icons.workspace_premium_outlined,
                      label: '${state.earnedBadgeIds.length} badges',
                    ),
                    StatChip(
                      icon: Icons.access_time,
                      label: '${state.volunteerHours}h service',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.lg),
          Text('Categories',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.22,
            children: [
              for (int i = 0; i < ShopCategory.values.length; i++)
                _CategoryTile(
                  category: ShopCategory.values[i],
                  count: state.allShopItems
                      .where((it) => it.category == ShopCategory.values[i])
                      .length,
                ).animate().fadeIn(delay: (60 * i).ms).scaleXY(
                      begin: 0.92,
                      end: 1,
                      duration: 240.ms,
                      curve: Curves.easeOut,
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Featured',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _FeaturedCard(item: featured[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ShopCategory category;
  final int count;
  const _CategoryTile({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () {
        Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => ShopCategoryScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(category.icon, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(category.blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                  ),
                  Text('$count items',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final ShopItem item;
  const _FeaturedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => showShopItemSheet(context, item),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.92),
              AppColors.accent.withValues(alpha: 0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                if (item.tag != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('${item.cost} pts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
