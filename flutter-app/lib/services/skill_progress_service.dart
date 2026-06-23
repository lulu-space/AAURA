/// Activity-driven skill progress boosts (0..1 scale shown in UI rings).
class SkillProgressService {
  SkillProgressService._();

  static const double eventJoin = 0.04;
  static const double eventCheckIn = 0.06;
  static const double studySession = 0.05;
  static const double goalComplete = 0.03;

  /// Skills never display as fully "complete" — campus growth is ongoing.
  static const double maxProgress = 0.90;

  static double clampProgress(double value) =>
      value.clamp(0.0, maxProgress);

  static List<Map<String, dynamic>> boost(
    List<Map<String, dynamic>> skills,
    double delta,
    String changeLabel,
  ) {
    if (skills.isEmpty || delta <= 0) return skills;
    return skills
        .map((skill) {
          final current = (skill['progress'] as num?)?.toDouble() ?? 0;
          return {
            ...skill,
            'progress': clampProgress(current + delta),
            'change': changeLabel,
          };
        })
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> toStrengthsPayload(
    List<Map<String, dynamic>> skills,
  ) =>
      skills
          .map((skill) => <String, dynamic>{
                'name': skill['name'],
                'progress': skill['progress'],
                'note': skill['note'] ?? '',
                'change': skill['change'] ?? '',
              })
          .toList(growable: false);
}

enum SkillActivityKind {
  eventJoin(SkillProgressService.eventJoin, 'Joined a campus event'),
  eventCheckIn(SkillProgressService.eventCheckIn, 'Checked in at an event'),
  studySession(SkillProgressService.studySession, 'Joined a study session'),
  goalComplete(SkillProgressService.goalComplete, 'Completed a semester goal');

  const SkillActivityKind(this.delta, this.changeLabel);
  final double delta;
  final String changeLabel;
}
