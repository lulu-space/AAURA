import 'package:flutter/material.dart';

enum ClubActivityLevel {
  veryActive,
  active,
  quiet,
  inactive;

  String get label {
    switch (this) {
      case ClubActivityLevel.veryActive:
        return 'Very Active';
      case ClubActivityLevel.active:
        return 'Active';
      case ClubActivityLevel.quiet:
        return 'Quiet';
      case ClubActivityLevel.inactive:
        return 'Inactive';
    }
  }
}

enum ClubCategory {
  academic,
  cultural,
  wellness,
  arts,
  tech;

  String get label {
    switch (this) {
      case ClubCategory.academic:
        return 'Academic';
      case ClubCategory.cultural:
        return 'Cultural';
      case ClubCategory.wellness:
        return 'Wellness';
      case ClubCategory.arts:
        return 'Arts';
      case ClubCategory.tech:
        return 'Tech';
    }
  }

  IconData get icon {
    switch (this) {
      case ClubCategory.academic:
        return Icons.school_outlined;
      case ClubCategory.cultural:
        return Icons.public_outlined;
      case ClubCategory.wellness:
        return Icons.spa_outlined;
      case ClubCategory.arts:
        return Icons.palette_outlined;
      case ClubCategory.tech:
        return Icons.memory_outlined;
    }
  }
}

class Club {
  final String id;
  final String name;
  final String description;
  final String focus;
  final int members;
  final int eventsHeld;
  final ClubActivityLevel activityLevel;
  final ClubCategory category;
  final String? nextEvent;
  final List<String> roles;
  final String? organizerId;
  final bool isActive;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.focus,
    required this.members,
    required this.eventsHeld,
    required this.activityLevel,
    required this.category,
    this.nextEvent,
    this.roles = const [],
    this.organizerId,
    this.isActive = true,
  });

  Club copyWith({
    String? name,
    String? description,
    String? focus,
    int? members,
    ClubActivityLevel? activityLevel,
    ClubCategory? category,
    List<String>? roles,
    bool? isActive,
  }) =>
      Club(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        focus: focus ?? this.focus,
        members: members ?? this.members,
        eventsHeld: eventsHeld,
        activityLevel: activityLevel ?? this.activityLevel,
        category: category ?? this.category,
        nextEvent: nextEvent,
        roles: roles ?? this.roles,
        organizerId: organizerId,
        isActive: isActive ?? this.isActive,
      );
}
