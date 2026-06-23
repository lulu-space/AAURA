import 'package:flutter/material.dart';

class AppBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool locked;

  const AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.locked = false,
  });
}
