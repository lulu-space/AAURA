class EventPrediction {
  final int predictedAttendance;
  final double attendanceRate;
  final double successScore;
  final String confidence;
  final List<String> reasons;
  final List<String> recommendations;
  final List<String> matchedStudentSegments;
  final bool isLiveMl;
  final List<String> inputSummary;

  const EventPrediction({
    required this.predictedAttendance,
    required this.attendanceRate,
    required this.successScore,
    required this.confidence,
    required this.reasons,
    required this.recommendations,
    required this.matchedStudentSegments,
    this.isLiveMl = false,
    this.inputSummary = const [],
  });

  int get attendancePercent => (attendanceRate * 100).round();
  int get successPercent => (successScore * 100).round();
}
