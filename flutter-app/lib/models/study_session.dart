enum StudySessionType {
  publicTogether,
  tutorLed,
  groupProject;

  String get label {
    switch (this) {
      case StudySessionType.publicTogether:
        return 'Public Study Together Session';
      case StudySessionType.tutorLed:
        return 'Tutor-led Session';
      case StudySessionType.groupProject:
        return 'Group Project Session';
    }
  }
}

class StudySession {
  final String id;
  final String course;
  final StudySessionType type;
  final String details;
  final String when;
  final int seatsLeft;
  final String host;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? hostId;

  const StudySession({
    required this.id,
    required this.course,
    required this.type,
    required this.details,
    required this.when,
    required this.seatsLeft,
    required this.host,
    this.startsAt,
    this.endsAt,
    this.hostId,
  });

  StudySession copyWith({
    String? course,
    StudySessionType? type,
    String? details,
    String? when,
    int? seatsLeft,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return StudySession(
      id: id,
      course: course ?? this.course,
      type: type ?? this.type,
      details: details ?? this.details,
      when: when ?? this.when,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      host: host,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      hostId: hostId,
    );
  }
}
