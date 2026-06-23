import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'shop_item_sheet.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final owned = state.ownedShopItems;
    return Scaffold(
      appBar: AppBar(title: const Text('My purchases')),
      body: owned.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No purchases yet.\nSpend points in the shop to unlock perks.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
              itemCount: owned.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = owned[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  onTap: () => showShopItemSheet(context, item),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: cardDecoration(),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Icon(item.icon, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(item.category.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            color: AppColors.success),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
