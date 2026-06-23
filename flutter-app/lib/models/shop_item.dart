import 'package:flutter/material.dart';

enum ShopCategory {
  customizables,
  recognition,
  eventsCampus,
  academic;

  String get label {
    switch (this) {
      case ShopCategory.customizables:
        return 'Customizables';
      case ShopCategory.recognition:
        return 'Recognition';
      case ShopCategory.eventsCampus:
        return 'Events & Campus Life';
      case ShopCategory.academic:
        return 'Academic';
    }
  }

  String get blurb {
    switch (this) {
      case ShopCategory.customizables:
        return 'Profile themes, frames and avatar perks';
      case ShopCategory.recognition:
        return 'Stand out with rare badges and titles';
      case ShopCategory.eventsCampus:
        return 'Event passes, swag and campus perks';
      case ShopCategory.academic:
        return 'Books, vouchers, study credits';
    }
  }

  IconData get icon {
    switch (this) {
      case ShopCategory.customizables:
        return Icons.palette_outlined;
      case ShopCategory.recognition:
        return Icons.workspace_premium_outlined;
      case ShopCategory.eventsCampus:
        return Icons.celebration_outlined;
      case ShopCategory.academic:
        return Icons.menu_book_outlined;
    }
  }
}

class ShopItem {
  final String id;
  final String title;
  final String description;
  final int cost;
  final ShopCategory category;
  final IconData icon;
  final String? tag;

  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.category,
    required this.icon,
    this.tag,
  });
}
