import 'package:flutter/material.dart';

/// A text channel inside a club "server" (Discord-style).
class ClubChannel {
  final String id;
  final String name;
  final IconData icon;

  const ClubChannel({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// A single chat message in a club channel.
class ClubMessage {
  final String id;
  final String author;
  final String role;
  final String text;
  final String time;
  final bool isMe;

  const ClubMessage({
    required this.id,
    required this.author,
    required this.role,
    required this.text,
    required this.time,
    this.isMe = false,
  });

  bool get isLeader => role.toLowerCase() == 'leader';
}

/// A member of a club, used for the members panel.
class ClubMember {
  final String name;
  final String role; // 'Leader' or 'Member'
  final bool online;

  const ClubMember({
    required this.name,
    required this.role,
    this.online = false,
  });

  bool get isLeader => role.toLowerCase() == 'leader';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}
