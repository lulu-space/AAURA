import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../models/campus_person.dart';
import '../../models/peer_conversation.dart';
import '../../models/club_server.dart';
import '../../models/connection.dart';
import '../../models/event.dart';
import '../../models/leaderboard.dart';
import '../../models/app_notification.dart';
import '../../models/study_session.dart';
import '../../models/volunteer_opportunity.dart';
import '../../models/volunteer_request.dart';
import '../../models/shop_item.dart';
import '../../models/badge.dart';
import '../../utils/university_id.dart';
import '../../models/club_request.dart';

/// Maps backend (Supabase, snake_case) JSON rows onto UI models.
class ApiMappers {
  const ApiMappers._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _formatDateTime(Object? value, {String fallback = 'TBA'}) {
    final dt = _parseDate(value);
    if (dt == null) return fallback;
    final weekday = _weekdays[(dt.weekday - 1) % 7];
    final month = _months[(dt.month - 1) % 12];
    return '$weekday, $month ${dt.day} - ${_formatTime(dt)}';
  }

  static String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  static String _formatDuration(Object? start, Object? end) {
    final s = _parseDate(start);
    final e = _parseDate(end);
    if (s == null || e == null) return '';
    final minutes = e.difference(s).inMinutes;
    if (minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static EventCategory _eventCategory(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    switch (raw) {
      case 'serve':
        return EventCategory.serve;
      case 'connect':
        return EventCategory.connect;
      case 'explore':
        return EventCategory.explore;
      case 'learn':
        return EventCategory.learn;
      default:
        return EventCategory.learn;
    }
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Event event(Map<String, dynamic> row) {
    final aiScore = _asDouble(row['ai_success_score']);
    final engagement = _asDouble(row['ai_engagement_score']);
    // Prefer the real stored reward, fall back to an AI-derived estimate.
    final storedPoints = _asInt(row['reward_points'], fallback: 0);
    final points = storedPoints > 0
        ? storedPoints
        : (aiScore > 0 ? (aiScore / 10).round().clamp(1, 30) : 10);
    final category = _eventCategory(row['category']);
    final targetMajors = _stringList(row['target_majors']);
    final tags = _stringList(row['tags']);
    final startsAt = _parseDate(row['starts_at']);
    final endsAt = _parseDate(row['ends_at']);
    return Event(
      id: row['id']?.toString() ?? '',
      title: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Campus Event',
      organizer: (row['organizer_name'] as String?)?.trim().isNotEmpty == true
          ? row['organizer_name'] as String
          : 'Campus',
      organizerRole: 'Organizer',
      organizerId: row['organizer_id']?.toString(),
      about: (row['description'] as String?) ?? '',
      whatToExpect: (row['what_to_expect'] as String?)?.trim() ?? '',
      location: (row['location'] as String?)?.trim().isNotEmpty == true
          ? row['location'] as String
          : 'On campus',
      date: _formatDateTime(row['starts_at']),
      duration: _formatDuration(row['starts_at'], row['ends_at']),
      startsAt: startsAt,
      endsAt: endsAt,
      participants:
          targetMajors.isEmpty ? 'Open to all students' : targetMajors.join(', '),
      format: (row['format'] as String?)?.trim().isNotEmpty == true
          ? row['format'] as String
          : 'On-campus',
      category: category,
      points: points,
      aiSuccessScore: aiScore > 0 ? aiScore : null,
      aiEngagementScore: engagement > 0 ? engagement : null,
      rewards: [
        EventReward(
          label: '+$points Points',
          detail: 'Displayed on Profile',
          icon: Icons.stars_outlined,
        ),
      ],
      tags: [
        ...tags,
        if (aiScore > 0) '${aiScore.round()}% AI success',
      ],
      capacity: _asInt(row['capacity'], fallback: 60),
      targetMajors: targetMajors,
      targetYears: _stringList(row['target_years']),
      targetInterests: _stringList(row['target_interests']),
      clubId: row['club_id']?.toString(),
      promotionLevel: _asInt(row['promotion_level'],
          fallback: aiScore >= 75 ? 5 : (aiScore >= 50 ? 3 : 2)),
      isApproved: row['is_approved'] as bool? ?? false,
      approvalNote: (row['approval_note'] as String?)?.trim(),
      status: (row['status'] as String?) ?? 'published',
      possibleDuplicate: row['possible_duplicate'] as bool? ?? false,
      duplicateMatchCount:
          _asInt(row['duplicate_match_count'], fallback: 0),
      volunteerHours: _asDouble(row['volunteer_hours']),
      joinToken: row['join_token']?.toString(),
    );
  }

  static Map<String, dynamic> eventToCreateBody(
    Event event, {
    required DateTime startsAt,
    required DateTime endsAt,
    String status = 'published',
  }) =>
      {
        'title': event.title,
        'description': event.about,
        if (event.whatToExpect.trim().isNotEmpty)
          'what_to_expect': event.whatToExpect.trim(),
        'location': event.location,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'capacity': event.capacity,
        'status': status,
        'category': event.category.name,
        'reward_points': event.points,
        'format': event.format,
        'promotion_level': event.promotionLevel,
        'tags': event.tags
            .where((t) => !t.endsWith('% AI success'))
            .toList(),
        'target_majors': event.targetMajors,
        'target_years': event.targetYears,
        'target_interests': event.targetInterests,
        if (event.clubId != null && event.clubId!.isNotEmpty)
          'club_id': event.clubId,
        if (event.category == EventCategory.serve && event.volunteerHours > 0)
          'volunteer_hours': event.volunteerHours,
      };

  static Map<String, dynamic> eventToUpdateBody(
    Event event, {
    required DateTime startsAt,
    required DateTime endsAt,
    String status = 'published',
  }) =>
      eventToCreateBody(event,
          startsAt: startsAt, endsAt: endsAt, status: status);

  static Club club(
    Map<String, dynamic> row, {
    int memberCount = 0,
  }) {
    final name = (row['name'] as String?)?.trim();
    final description = (row['description'] as String?)?.trim() ?? '';
    final isActive = row['is_active'] as bool? ?? true;
    final label = name?.isNotEmpty == true ? name! : 'Campus Club';
    final members =
        memberCount > 0 ? memberCount : _asInt(row['member_count'], fallback: 0);
    return Club(
      id: row['id']?.toString() ?? '',
      name: label,
      description: description.isNotEmpty ? description : 'AAUP campus club',
      focus: _inferClubFocus(label, description),
      members: members,
      eventsHeld: 0,
      activityLevel: !isActive
          ? ClubActivityLevel.inactive
          : (members >= 50
              ? ClubActivityLevel.veryActive
              : (members >= 15
                  ? ClubActivityLevel.active
                  : ClubActivityLevel.quiet)),
      category: _inferClubCategory(label, description),
      organizerId: row['organizer_id']?.toString(),
      isActive: isActive,
    );
  }

  static Map<String, dynamic> clubToCreateBody({
    required String name,
    required String description,
  }) =>
      {
        'name': name,
        'description': description,
        'is_active': true,
      };

  static Map<String, dynamic> clubToUpdateBody({
    String? name,
    String? description,
    bool? isActive,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;
    return body;
  }

  static String _inferClubFocus(String name, String description) {
    final text = '$name $description'.toLowerCase();
    if (text.contains('tech') || text.contains('code')) return 'Technology';
    if (text.contains('art') || text.contains('design')) return 'Creative arts';
    if (text.contains('volunteer') || text.contains('service')) {
      return 'Community service';
    }
    if (text.contains('sport') || text.contains('wellness')) return 'Wellness';
    return 'Campus community';
  }

  static ClubCategory _inferClubCategory(String name, String description) {
    final text = '$name $description'.toLowerCase();
    if (text.contains('tech') ||
        text.contains('code') ||
        text.contains('computer')) {
      return ClubCategory.tech;
    }
    if (text.contains('art') || text.contains('design')) {
      return ClubCategory.arts;
    }
    if (text.contains('culture') || text.contains('heritage')) {
      return ClubCategory.cultural;
    }
    if (text.contains('wellness') ||
        text.contains('sport') ||
        text.contains('health')) {
      return ClubCategory.wellness;
    }
    return ClubCategory.academic;
  }

  static StudySession studySession(
    Map<String, dynamic> row, {
    String hostName = 'Campus host',
  }) {
    final topic = (row['topic'] as String?)?.trim() ?? '';
    final location = (row['location'] as String?)?.trim() ?? '';
    final details = [topic, location].where((s) => s.isNotEmpty).join(' · ');
    final startsAt = _parseDate(row['starts_at']);
    final endsAt = _parseDate(row['ends_at']);
    return StudySession(
      id: row['id']?.toString() ?? '',
      course: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Study Session',
      type: StudySessionType.publicTogether,
      details: details.isNotEmpty ? details : 'Open study session',
      when: _formatDateTime(row['starts_at']),
      seatsLeft: _asInt(row['capacity'], fallback: 4),
      host: hostName,
      startsAt: startsAt,
      endsAt: endsAt,
      hostId: row['host_user_id']?.toString(),
    );
  }

  static Map<String, dynamic> studySessionToCreateBody({
    required String title,
    required String topic,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    String? location,
  }) =>
      {
        'title': title,
        if (topic.isNotEmpty) 'topic': topic,
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
      };

  static VolunteerRequest volunteerRequest(Map<String, dynamic> row) {
    final statusStr = (row['status'] as String?) ?? 'pending';
    final status = VolunteerRequestStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => VolunteerRequestStatus.pending,
    );
    final userId = row['user_id']?.toString() ?? '';
    final nestedStudent = row['student'] ?? row['users'];
    String? universityId;
    if (nestedStudent is Map) {
      final students = nestedStudent['students'];
      if (students is Map) {
        universityId = students['university_id']?.toString();
      } else if (students is List && students.isNotEmpty) {
        final first = students.first;
        if (first is Map) {
          universityId = first['university_id']?.toString();
        }
      }
      universityId ??= nestedStudent['university_id']?.toString();
    }
    return VolunteerRequest(
      id: row['id']?.toString() ?? '',
      studentName: _resolvePersonName(
        row,
        directKey: 'student_name',
        userIdKey: 'user_id',
        nestedKeys: const ['student', 'users'],
      ),
      studentId: universityId ??
          (UniversityId.isValid(row['university_id']?.toString())
              ? row['university_id'].toString()
              : (userId.isNotEmpty ? userId : 'unknown')),
      hours: _asDouble(row['hours']).round(),
      eventTitle: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Volunteer activity',
      submittedAt: _formatDateTime(row['created_at'], fallback: ''),
      status: status,
      approvalNote: (row['approval_note'] as String?)?.trim().isNotEmpty == true
          ? row['approval_note'] as String
          : null,
      opportunityId: row['opportunity_id']?.toString(),
    );
  }

  static String _studentLabel(String userId, {String? email}) {
    final fromEmail = _displayNameFromEmail(email);
    if (fromEmail != null) return fromEmail;
    if (userId.length >= 8) return 'Student ${userId.substring(0, 8)}';
    return 'Student';
  }

  static String? _displayNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return null;
    final displayName = localPart
        .split(RegExp(r'[._-]'))
        .where((part) => part.isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
    return displayName.isEmpty ? null : displayName;
  }

  static String _resolvePersonName(
    Map<String, dynamic> row, {
    required String directKey,
    required String userIdKey,
    List<String> nestedKeys = const [],
    String? email,
  }) {
    final direct = (row[directKey] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    for (final key in nestedKeys) {
      final nested = row[key];
      if (nested is Map) {
        final name = (nested['full_name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }

    final resolvedEmail =
        email ?? (row['requester_email'] as String?) ?? (row['email'] as String?);
    return _studentLabel(row[userIdKey]?.toString() ?? '', email: resolvedEmail);
  }

  static String _relativeWhen(Object? value) {
    final dt = _parseDate(value);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDateTime(value, fallback: '');
  }

  static AppNotification notification(Map<String, dynamic> row) {
    final payload = row['payload'];
    String? peerUserId;
    if (payload is Map) {
      peerUserId = payload['peer_user_id']?.toString();
    }
    return AppNotification(
      id: row['id']?.toString() ?? '',
      title: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Notification',
      body: (row['body'] as String?) ?? '',
      when: _relativeWhen(row['created_at']),
      type: (row['notification_type'] as String?) ?? 'system',
      isRead: row['is_read'] as bool? ?? false,
      peerUserId: peerUserId,
    );
  }

  static PeerConversation peerConversation(
    Map<String, dynamic> row, {
    required String currentUserId,
  }) {
    final yearNum = row['academic_year'];
    final year = yearNum is num ? 'Year ${yearNum.toInt()}' : 'Student';
    final lastSenderId = row['last_sender_user_id']?.toString() ?? '';
    return PeerConversation(
      peerUserId: row['peer_user_id']?.toString() ?? '',
      name: (row['full_name'] as String?)?.trim().isNotEmpty == true
          ? row['full_name'] as String
          : 'Student',
      major: (row['major'] as String?)?.trim().isNotEmpty == true
          ? row['major'] as String
          : 'Undeclared',
      year: year,
      lastMessageBody: (row['last_message_body'] as String?) ?? '',
      lastMessageAt: DateTime.tryParse(
        row['last_message_at']?.toString() ?? '',
      ),
      lastMessageIsMine: lastSenderId == currentUserId,
      unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, String> calendarDeadline(Map<String, dynamic> row) => {
        'id': row['id']?.toString() ?? '',
        'source': 'calendar',
        'title': (row['title'] as String?)?.trim().isNotEmpty == true
            ? row['title'] as String
            : 'Deadline',
        'due': _formatDateTime(row['starts_at']),
        'iso': row['starts_at']?.toString() ?? '',
      };

  static Map<String, String> calendarCourse(Map<String, dynamic> row) {
    final title = (row['title'] as String?)?.trim();
    final type = (row['item_type'] as String?) ?? 'study';
    return {
      'id': row['id']?.toString() ?? '',
      'source': 'calendar',
      'code': type.substring(0, type.length >= 3 ? 3 : type.length).toUpperCase(),
      'title': title?.isNotEmpty == true ? title! : 'Scheduled item',
      'next': _formatDateTime(row['starts_at']),
      'iso': row['starts_at']?.toString() ?? '',
    };
  }

  static List<Map<String, String>> studyPlanCourses(Map<String, dynamic> plan) {
    final out = <Map<String, String>>[];
    final planId = plan['id']?.toString() ?? '';
    final schedule = plan['schedule'];
    if (schedule is List) {
      for (var i = 0; i < schedule.length; i++) {
        final entry = schedule[i];
        if (entry is Map) {
          out.add({
            'source': 'study_plan',
            'planId': planId,
            'entryIndex': '$i',
            'code': entry['code']?.toString() ?? 'CRS',
            'title': entry['title']?.toString() ??
                entry['name']?.toString() ??
                'Course',
            'next': entry['next']?.toString() ??
                entry['when']?.toString() ??
                'TBA',
          });
        }
      }
    }
    if (out.isEmpty) {
      final title = (plan['title'] as String?)?.trim();
      if (title?.isNotEmpty == true) {
        out.add({
          'source': 'study_plan',
          'planId': planId,
          'entryIndex': '0',
          'code': 'PLAN',
          'title': title!,
          'next': 'See schedule',
        });
      }
    }
    return out;
  }

  static LeaderboardEntry leaderboardEntry(Map<String, dynamic> row) {
    final points = _asInt(row['points']);
    final badges = row['badges'];
    final highlights = <String>['$points points'];
    if (badges is List && badges.isNotEmpty) {
      highlights.add('${badges.length} badges earned');
    }
    final level = _asInt(row['level'], fallback: 1);
    if (level > 1) highlights.add('Level $level');
    return LeaderboardEntry(
      name: (row['full_name'] as String?)?.trim().isNotEmpty == true
          ? row['full_name'] as String
          : 'Student',
      highlights: highlights,
      tag: points >= 100 ? 'Top Contributor' : 'Rising Star',
    );
  }

  static VolunteerOpportunity volunteerOpportunity(Map<String, dynamic> row) {
    return VolunteerOpportunity(
      id: row['id']?.toString() ?? '',
      title: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Volunteer opportunity',
      description: (row['description'] as String?)?.trim() ?? '',
      department: (row['department'] as String?)?.trim() ?? 'Campus',
      estimatedHours: _asDouble(row['estimated_hours']),
      slots: _asInt(row['slots'], fallback: 1),
      enrolledCount: _asInt(row['enrolled_count']),
      status: (row['status'] as String?) ?? 'open',
      createdBy: row['created_by']?.toString(),
      eventId: row['event_id']?.toString(),
      joinToken: row['join_token']?.toString(),
    );
  }

  static Map<String, dynamic> volunteerOpportunityToCreateBody({
    required String title,
    required String description,
    required String department,
    required double estimatedHours,
    required int slots,
    String status = 'open',
  }) =>
      {
        'title': title,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        if (department.trim().isNotEmpty) 'department': department.trim(),
        'estimated_hours': estimatedHours,
        'slots': slots,
        'status': status,
      };

  static IconData shopIcon(String? key) {
    switch (key) {
      case 'palette':
        return Icons.palette_outlined;
      case 'water':
        return Icons.water_outlined;
      case 'premium':
        return Icons.workspace_premium_outlined;
      case 'emoji':
        return Icons.emoji_emotions_outlined;
      case 'code':
        return Icons.code;
      case 'volunteer':
        return Icons.volunteer_activism_outlined;
      case 'military_tech':
        return Icons.military_tech_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'event':
        return Icons.event_available_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  static ShopItem shopItem(Map<String, dynamic> row) {
    final categoryName = row['category'] as String? ?? 'customizables';
    final category = ShopCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => ShopCategory.customizables,
    );
    return ShopItem(
      id: row['id']?.toString() ?? '',
      title: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Shop item',
      description: (row['description'] as String?) ?? '',
      cost: _asInt(row['cost'], fallback: 0),
      category: category,
      icon: shopIcon(row['icon_key']?.toString()),
      tag: row['tag'] as String?,
    );
  }

  static Connection connection(Map<String, dynamic> row) {
    final interestsRaw = row['interests'];
    final interests = <String>[];
    if (interestsRaw is List) {
      for (final item in interestsRaw) {
        if (item is String && item.isNotEmpty) interests.add(item);
      }
    }
    final yearNum = row['academic_year'];
    final year = yearNum is num ? 'Year ${yearNum.toInt()}' : 'Student';
    return Connection(
      id: row['user_id']?.toString() ?? '',
      name: (row['full_name'] as String?)?.trim().isNotEmpty == true
          ? row['full_name'] as String
          : 'Student',
      major: (row['major'] as String?)?.trim().isNotEmpty == true
          ? row['major'] as String
          : 'Undeclared',
      year: year,
      interests: interests,
    );
  }

  static ClubMessage clubMessage(
    Map<String, dynamic> row, {
    required String currentUserId,
  }) {
    final users = row['users'] as Map<String, dynamic>?;
    final authorId = row['author_user_id']?.toString() ?? '';
    final authorName = (users?['full_name'] as String?)?.trim().isNotEmpty == true
        ? users!['full_name'] as String
        : 'Member';
    final createdAt = _parseDate(row['created_at']);
    String time = '';
    if (createdAt != null) {
      time = _formatTime(createdAt);
    }
    return ClubMessage(
      id: row['id']?.toString() ?? '',
      author: authorName,
      role: 'Member',
      text: (row['body'] as String?) ?? '',
      time: time,
      isMe: authorId == currentUserId,
    );
  }

  static IconData badgeIcon(String? key) {
    switch (key) {
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'school':
        return Icons.school;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }

  static AppBadge badgeDefinition(Map<String, dynamic> row) {
    return AppBadge(
      id: row['id']?.toString() ?? '',
      name: (row['name'] as String?)?.trim().isNotEmpty == true
          ? row['name'] as String
          : 'Badge',
      description: (row['description'] as String?) ?? '',
      icon: badgeIcon(row['icon_key']?.toString()),
      locked: row['locked_by_default'] as bool? ?? false,
    );
  }

  static ClubMember clubMember(Map<String, dynamic> row) {
    final users = row['users'] as Map<String, dynamic>?;
    final name = (users?['full_name'] as String?)?.trim().isNotEmpty == true
        ? users!['full_name'] as String
        : 'Member';
    final roleRaw = row['role']?.toString() ?? 'member';
    return ClubMember(
      name: name,
      role: roleRaw == 'lead' ? 'Leader' : 'Member',
      online: false,
    );
  }

  static CampusPerson campusPerson(Map<String, dynamic> row) {
    final yearNum = row['academic_year'];
    final year = yearNum is num ? 'Year ${yearNum.toInt()}' : 'Student';
    final status = row['reservation_status']?.toString();
    String? statusLabel;
    if (status == 'checked_in') {
      statusLabel = 'Checked in';
    } else if (status == 'reserved') {
      statusLabel = 'Enrolled';
    } else if (row['is_host'] == true) {
      statusLabel = 'Host';
    }
    return CampusPerson(
      userId: row['user_id']?.toString() ?? '',
      name: (row['full_name'] as String?)?.trim().isNotEmpty == true
          ? row['full_name'] as String
          : 'Student',
      major: (row['major'] as String?)?.trim().isNotEmpty == true
          ? row['major'] as String
          : 'Undeclared',
      year: year,
      statusLabel: statusLabel,
      isHost: row['is_host'] == true,
    );
  }

  static Map<String, String> clubActivityPost(Map<String, dynamic> row) {
    final clubs = row['clubs'] as Map<String, dynamic>?;
    return {
      'club': clubs?['name']?.toString() ?? 'Club',
      'when': _relativeWhen(row['created_at']),
      'title': row['title']?.toString() ?? '',
      'body': row['body']?.toString() ?? '',
      'icon': row['icon_key']?.toString() ?? 'code',
    };
  }

  static ClubRequest clubRequest(Map<String, dynamic> row) {
    final requesterId = row['requester_id']?.toString() ?? '';
    return ClubRequest(
      id: row['id']?.toString() ?? '',
      requesterId: requesterId,
      requesterName: _resolvePersonName(
        row,
        directKey: 'requester_name',
        userIdKey: 'requester_id',
        nestedKeys: const ['requester', 'users'],
        email: row['requester_email'] as String?,
      ),
      proposedName: (row['proposed_name'] as String?)?.trim().isNotEmpty == true
          ? row['proposed_name'] as String
          : 'New club',
      description: (row['description'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'academic',
      status: ClubRequestStatus.fromName(row['status'] as String?),
      reviewNote: (row['review_note'] as String?)?.trim().isNotEmpty == true
          ? row['review_note'] as String
          : null,
      createdClubId: row['created_club_id']?.toString(),
      submittedWhen: _relativeWhen(row['created_at']),
      advisorEmail: (row['advisor_email'] as String?)?.trim(),
      coFounderNames: _stringList(row['co_founder_names']),
    );
  }

  static List<Map<String, dynamic>> skillsFromProfile(
    Map<String, dynamic>? profile,
  ) {
    if (profile == null) return const [];
    // `confidence` is stored as a 0..1 fraction by the AI pipeline, but older
    // rows may store a 0..100 percentage. Normalise both into a 0..1 range.
    var confidence = _asDouble(profile['confidence']);
    if (confidence > 1) confidence = confidence / 100;
    confidence = confidence.clamp(0.0, 1.0);
    final strengths = profile['strengths'];
    if (strengths is! List || strengths.isEmpty) return const [];

    return strengths.map((entry) {
      if (entry is Map) {
        final progress = entry['progress'];
        return {
          'name': entry['name']?.toString() ?? 'Skill',
          'progress': progress is num
              ? _normalizeSkillProgress(progress.toDouble(), confidence)
              : confidence.clamp(0.0, 1.0),
          'note': entry['note']?.toString() ?? '',
          'change': entry['change']?.toString() ?? '',
        };
      }
      return {
        'name': entry.toString(),
        'progress': confidence.clamp(0.0, 1.0),
        'note': 'From your Shams profile',
        'change': '',
      };
    }).toList();
  }

  /// Skill progress is stored as 0..1; legacy rows may use 0..100.
  /// Skill progress is stored as 0..1; legacy rows may use 0..100.
  static const double _maxSkillProgress = 0.9;

  static double _normalizeSkillProgress(double value, double fallback) {
    var progress = value;
    if (progress > 1) progress = progress / 100;
    if (progress <= 0) return fallback.clamp(0.0, _maxSkillProgress);
    return progress.clamp(0.0, _maxSkillProgress);
  }

  static List<String> goalsFromProfileAndPlans(
    Map<String, dynamic>? profile,
    List<Map<String, dynamic>> studyPlans,
  ) {
    final goals = <String>[];
    final profileGoals = profile?['goals'];
    if (profileGoals is List) {
      for (final goal in profileGoals) {
        if (goal is String && goal.isNotEmpty) goals.add(goal);
        if (goal is Map && goal['title'] != null) {
          goals.add(goal['title'].toString());
        }
      }
    }
    for (final plan in studyPlans) {
      final planGoals = plan['goals'];
      if (planGoals is List) {
        for (final goal in planGoals) {
          if (goal is String && goal.isNotEmpty) goals.add(goal);
          if (goal is Map && goal['title'] != null) {
            goals.add(goal['title'].toString());
          }
        }
      }
    }
    return goals.toSet().toList();
  }
}
