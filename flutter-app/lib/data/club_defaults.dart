import 'package:flutter/material.dart';

import '../models/club_server.dart';

/// Standard club chat channels (structure only — no seeded messages).
const List<ClubChannel> kDefaultClubChannels = [
  ClubChannel(id: 'general', name: 'general', icon: Icons.tag_rounded),
  ClubChannel(
    id: 'announcements',
    name: 'announcements',
    icon: Icons.campaign_outlined,
  ),
  ClubChannel(id: 'events', name: 'events', icon: Icons.event_outlined),
  ClubChannel(
    id: 'resources',
    name: 'resources',
    icon: Icons.folder_outlined,
  ),
];
