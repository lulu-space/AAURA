import 'package:flutter/material.dart';

enum EventCategory {
  learn,
  serve,
  connect,
  explore;

  String get label {
    switch (this) {
      case EventCategory.learn:
        return 'Learn';
      case EventCategory.serve:
        return 'Serve';
      case EventCategory.connect:
        return 'Connect';
      case EventCategory.explore:
        return 'Explore';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.learn:
        return Icons.school_outlined;
      case EventCategory.serve:
        return Icons.volunteer_activism_outlined;
      case EventCategory.connect:
        return Icons.groups_2_outlined;
      case EventCategory.explore:
        return Icons.explore_outlined;
    }
  }
}

class EventReward {
  final String label;
  final String detail;
  final IconData icon;

  const EventReward({
    required this.label,
    required this.detail,
    required this.icon,
  });
}

class Event {
  final String id;
  final String title;
  final String organizer;
  final String organizerRole;
  final String about;
  final String location;
  final String date;
  final String duration;
  final String participants;
  final String format;
  final EventCategory category;
  final int points;
  final List<EventReward> rewards;
  final List<String> tags;
  final int capacity;
  final List<String> targetMajors;
  final List<String> targetYears;
  final List<String> targetInterests;
  final String? clubId;
  final int promotionLevel;
  final String? organizerId;
  final double? aiSuccessScore;
  final double? aiEngagementScore;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isApproved;
  final String? approvalNote;
  final String status;
  final bool possibleDuplicate;
  final int duplicateMatchCount;
  final String whatToExpect;
  final double volunteerHours;
  final String? joinToken;

  const Event({
    required this.id,
    required this.title,
    required this.organizer,
    required this.organizerRole,
    required this.about,
    required this.location,
    required this.date,
    required this.duration,
    required this.participants,
    required this.format,
    required this.category,
    required this.points,
    required this.rewards,
    this.tags = const [],
    this.capacity = 60,
    this.targetMajors = const [],
    this.targetYears = const [],
    this.targetInterests = const [],
    this.clubId,
    this.promotionLevel = 2,
    this.organizerId,
    this.aiSuccessScore,
    this.aiEngagementScore,
    this.startsAt,
    this.endsAt,
    this.isApproved = true,
    this.approvalNote,
    this.status = 'published',
    this.possibleDuplicate = false,
    this.duplicateMatchCount = 0,
    this.whatToExpect = '',
    this.volunteerHours = 0,
    this.joinToken,
  });
}
