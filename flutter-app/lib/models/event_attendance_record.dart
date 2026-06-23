class EventAttendanceRecord {
  final String eventId;
  final String studentId;
  final bool registered;
  final bool attended;
  final bool favorited;
  final double rating;
  final double feedbackScore;

  const EventAttendanceRecord({
    required this.eventId,
    required this.studentId,
    required this.registered,
    required this.attended,
    this.favorited = false,
    this.rating = 0,
    this.feedbackScore = 0,
  });
}
