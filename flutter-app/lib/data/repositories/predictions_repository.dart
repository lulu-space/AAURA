import '../../core/network/api_client.dart';

import '../../models/event_prediction.dart';



/// Maps backend AI prediction payloads to UI [EventPrediction] models.

class PredictionsRepository {

  PredictionsRepository(this._api);



  final ApiClient _api;



  /// POST /events/:id/predict-success — runs AI and persists scores on the event.

  Future<EventPrediction?> predictEventSuccess(String eventId) async {

    final result = await _api.post('/events/$eventId/predict-success', body: {});

    if (result is! Map<String, dynamic>) return null;

    return EventPredictionMapper.fromBackend(result);

  }



  /// POST /events/predict-draft — XGBoost preview before publish.

  Future<EventPrediction?> predictEventDraft(Map<String, dynamic> body) async {

    final result = await _api.post('/events/predict-draft', body: body);

    if (result is! Map<String, dynamic>) return null;

    return EventPredictionMapper.fromDraftBackend(result);

  }

}



class EventPredictionMapper {

  const EventPredictionMapper._();



  static EventPrediction fromBackend(Map<String, dynamic> payload) {

    final data = payload['data'] as Map<String, dynamic>? ?? payload;

    final prediction =

        data['prediction'] as Map<String, dynamic>? ?? const {};

    final eventRow = data['event'] as Map<String, dynamic>? ?? const {};

    final features = data['features'] as Map<String, dynamic>? ?? const {};

    final enrolleeCount = (data['enrollee_count'] as num?)?.toInt() ?? 0;



    final successProb =

        _asDouble(prediction['success_probability'], fallback: 0.5);

    final engagement =

        _asDouble(prediction['engagement_score'], fallback: 0.5);

    final aiScore = _asDouble(eventRow['ai_success_score'],

        fallback: successProb * 100);

    final capacity =

        (eventRow['capacity'] as num?)?.toInt().clamp(1, 9999) ?? 60;

    final predictedAttendance =

        (capacity * successProb).round().clamp(0, capacity);



    final successRate = aiScore / 100;

    final interestMatch =

        _asDouble(features['interest_match_score'], fallback: 0);

    final skillMatch = _asDouble(features['skill_match_score'], fallback: 0);

    final expectedAttendance =

        (features['expected_attendance'] as num?)?.toInt() ?? enrolleeCount;

    final modelAcc = _asDouble(prediction['model_cv_accuracy'], fallback: 0);



    return EventPrediction(

      predictedAttendance: predictedAttendance,

      attendanceRate: successProb,

      successScore: successRate,

      confidence: aiScore >= 75

          ? 'High'

          : aiScore >= 50

              ? 'Medium'

              : 'Early signal',

      reasons: [

        'Live XGBoost model — success probability ${(successProb * 100).round()}%',

        '$enrolleeCount enrolled student${enrolleeCount == 1 ? '' : 's'} in model',

        'Interest match: ${(interestMatch * 100).round()}% · Skills match: ${(skillMatch * 100).round()}%',

        'Expected attendance signal: $expectedAttendance',

        if (modelAcc > 0) 'Model CV accuracy: ${(modelAcc * 100).round()}%',

        if (aiScore > 0) 'Saved on event: ${aiScore.round()}%',

      ],

      recommendations: _recommendations(successProb, engagement, aiScore, enrolleeCount),

      matchedStudentSegments: const [],

      isLiveMl: true,

    );

  }



  static EventPrediction fromDraftBackend(Map<String, dynamic> payload) {

    final data = payload['data'] as Map<String, dynamic>? ?? payload;

    final prediction =

        data['prediction'] as Map<String, dynamic>? ?? const {};

    final features = data['features'] as Map<String, dynamic>? ?? const {};

    final summary = data['input_summary'] as Map<String, dynamic>? ?? const {};



    final successProb =

        _asDouble(prediction['success_probability'], fallback: 0.5);

    final engagement =

        _asDouble(prediction['engagement_score'], fallback: 0.5);

    final capacity = (summary['capacity'] as num?)?.toInt().clamp(1, 9999) ?? 60;

    final predictedAttendance =

        (capacity * successProb).round().clamp(0, capacity);

    final interestMatch =

        _asDouble(features['interest_match_score'], fallback: 0);

    final skillMatch = _asDouble(features['skill_match_score'], fallback: 0);

    final modelAcc = _asDouble(prediction['model_cv_accuracy'], fallback: 0);

    final organizerType = features['organizer_type'] as String? ?? 'student_affairs';

    final majors = (summary['majors'] as List?)?.cast<String>() ?? const [];

    final interests =

        (summary['interests'] as List?)?.cast<String>() ?? const [];

    final skills = (summary['skills'] as List?)?.cast<String>() ?? const [];



    return EventPrediction(

      predictedAttendance: predictedAttendance,

      attendanceRate: successProb,

      successScore: successProb,

      confidence: successProb >= 0.75

          ? 'High'

          : successProb >= 0.5

              ? 'Medium'

              : 'Early signal',

      reasons: [

        'Pre-publish XGBoost report from your draft inputs',

        'Organizer channel: ${_labelOrganizer(organizerType)}',

        'Major fit: ${features['student_major'] ?? 'Open'} · Event type: ${features['event_type']}',

        'Interest match: ${(interestMatch * 100).round()}% · Skill match: ${(skillMatch * 100).round()}%',

        if (modelAcc > 0) 'Model CV accuracy: ${(modelAcc * 100).round()}%',

      ],

      recommendations: _recommendations(successProb, engagement, successProb * 100, 0),

      matchedStudentSegments: _segmentsFromInputs(majors, interests, skills),

      isLiveMl: true,

      inputSummary: [

        if (majors.isNotEmpty) 'Majors: ${majors.join(', ')}',

        if (interests.isNotEmpty) 'Interests: ${interests.join(', ')}',

        if (skills.isNotEmpty) 'Skills: ${skills.join(', ')}',

        'Capacity: $capacity · Expected signal: ${features['expected_attendance']}',

      ],

    );

  }



  static String _labelOrganizer(String value) {

    switch (value) {

      case 'club_student':

        return 'Club student leader';

      case 'club_event':

        return 'Club event';

      case 'dean_of_faculty':

        return 'Dean of faculty';

      default:

        return 'Student affairs';

    }

  }



  static List<String> _segmentsFromInputs(

    List<String> majors,

    List<String> interests,

    List<String> skills,

  ) {

    final segments = <String>[];

    for (final major in majors.take(2)) {

      segments.add('$major students');

    }

    for (final interest in interests.take(2)) {

      segments.add('$interest interest');

    }

    for (final skill in skills.take(1)) {

      segments.add('$skill skill');

    }

    return segments;

  }



  static List<String> _recommendations(

    double successProb,

    double engagement,

    double aiScore,

    int enrolleeCount,

  ) {

    final tips = <String>[];

    if (enrolleeCount == 0) {

      tips.add('Add at least two target interests and one skill tag to sharpen the signal.');

    }

    if (successProb < 0.55) {

      tips.add('Narrow the audience or boost promotion before publishing.');

    }

    if (engagement < 0.5) {

      tips.add('Align event title/tags with the skills and interests you selected.');

    }

    if (aiScore >= 75) {

      tips.add('Strong signal — open registration early.');

    }

    if (tips.isEmpty) {

      tips.add('Monitor signups in the first 24 hours and adjust promotion.');

    }

    return tips.take(4).toList();

  }



  static double _asDouble(Object? value, {double fallback = 0}) {

    if (value is num) return value.toDouble();

    if (value is String) return double.tryParse(value) ?? fallback;

    return fallback;

  }

}

