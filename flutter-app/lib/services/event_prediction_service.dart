import '../core/network/api_client.dart';
import '../data/repositories/predictions_repository.dart';
import '../models/event.dart';
import '../models/event_prediction.dart';

class EventPredictionService {
  const EventPredictionService();

  /// Calls POST /events/:id/predict-success on the Express backend.
  Future<EventPrediction?> predictFromBackend(
    String eventId, {
    ApiClient? api,
  }) async {
    final client = api ?? ApiClient();
    try {
      return await PredictionsRepository(client).predictEventSuccess(eventId);
    } catch (_) {
      return null;
    }
  }

  /// Maps a backend predict-success response already fetched elsewhere.
  EventPrediction? fromBackendPayload(Map<String, dynamic> payload) =>
      EventPredictionMapper.fromBackend(payload);

  /// POST /events/predict-draft — live XGBoost using majors, interests, skills.
  Future<EventPrediction?> predictDraft({
    required Event event,
    List<String> targetSkills = const [],
    ApiClient? api,
  }) async {
    final client = api ?? ApiClient();
    try {
      return await PredictionsRepository(client).predictEventDraft({
        'title': event.title,
        'description': event.about,
        'category': event.category.name,
        'format': event.format,
        'capacity': event.capacity,
        'promotion_level': event.promotionLevel,
        'target_majors': event.targetMajors,
        'target_interests': event.targetInterests,
        'target_skills': targetSkills,
        'tags': event.tags,
        if (event.clubId != null) 'club_id': event.clubId,
      });
    } catch (_) {
      return null;
    }
  }

  /// Offline estimate from the organizer's draft inputs only (no fake students).
  EventPrediction predict(Event event) {
    final audienceSignals = event.targetMajors.length +
        event.targetInterests.length +
        event.tags.length +
        event.targetYears.length;
    final titleBoost = event.title.trim().length >= 8 ? 0.08 : 0.0;
    final aboutBoost = event.about.trim().length >= 40 ? 0.06 : 0.0;
    final signalBoost = (audienceSignals / 10).clamp(0.0, 1.0);
    final promotionBoost = event.promotionLevel.clamp(1, 5) / 5.0;
    final pointsBoost = event.points.clamp(0, 30) / 30.0;

    final attendanceRate = _clamp(
      0.18 +
          signalBoost * 0.38 +
          promotionBoost * 0.18 +
          pointsBoost * 0.12 +
          titleBoost +
          aboutBoost,
    );
    final predictedAttendance =
        (event.capacity * attendanceRate).round().clamp(0, event.capacity);
    final successScore = _clamp(
      attendanceRate * 0.72 + promotionBoost * 0.18 + pointsBoost * 0.1,
    );

    return EventPrediction(
      predictedAttendance: predictedAttendance,
      attendanceRate: attendanceRate,
      successScore: successScore,
      confidence: audienceSignals >= 5 ? 'Medium' : 'Early signal',
      reasons: _reasonsFromInputs(event, audienceSignals),
      recommendations: _recommendations(event, attendanceRate, successScore),
      matchedStudentSegments: _segmentsFromTargets(event),
      inputSummary: _inputSummary(event, audienceSignals),
    );
  }

  List<String> _inputSummary(Event event, int audienceSignals) {
    return [
      'Title: ${event.title.trim().isEmpty ? '(empty)' : event.title.trim()}',
      'Capacity: ${event.capacity} · Promotion: ${event.promotionLevel}/5',
      'Targets: $audienceSignals majors/interests/years/tags selected',
    ];
  }

  List<String> _reasonsFromInputs(Event event, int audienceSignals) {
    final reasons = <String>[];
    if (audienceSignals >= 4) {
      reasons.add('Targeting is specific enough to estimate likely reach.');
    }
    if (event.promotionLevel >= 4) {
      reasons.add('Higher promotion level improves projected visibility.');
    }
    if (event.points >= 10) {
      reasons.add('Points reward should help drive sign-ups.');
    }
    if (event.targetMajors.isNotEmpty) {
      reasons.add('Major filters focus the audience.');
    }
    if (event.targetInterests.isNotEmpty || event.tags.isNotEmpty) {
      reasons.add('Interests and tags strengthen match signals.');
    }
    if (reasons.isEmpty) {
      reasons.add('Add targets and details to sharpen this estimate.');
    }
    return reasons.take(4).toList();
  }

  List<String> _recommendations(
    Event event,
    double attendanceRate,
    double successScore,
  ) {
    final recommendations = <String>[];
    if (attendanceRate < 0.45) {
      recommendations.add('Broaden interests or raise promotion to lift reach.');
    }
    if (event.targetInterests.length < 2) {
      recommendations.add('Select at least two target interests.');
    }
    if (event.promotionLevel < 4) {
      recommendations.add('Increase promotion through clubs and homepage placement.');
    }
    if (event.points < 10) {
      recommendations.add('Consider stronger points or badge incentives.');
    }
    if (successScore >= 0.65) {
      recommendations.add('Strong draft — publish when schedule is confirmed.');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Adjust targets and re-check the preview after edits.');
    }
    return recommendations.take(4).toList();
  }

  List<String> _segmentsFromTargets(Event event) {
    final segments = <String>[];
    for (final major in event.targetMajors.take(3)) {
      segments.add('$major students');
    }
    segments.addAll(event.targetInterests.take(3));
    if (segments.isEmpty) {
      segments.add('Open to all students');
    }
    return segments;
  }

  double _clamp(double value, {double min = 0, double max = 1}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
