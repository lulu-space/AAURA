class ClubRequestEligibility {
  final bool eligible;
  final List<String> reasons;
  final DateTime? cooldownUntil;

  const ClubRequestEligibility({
    required this.eligible,
    this.reasons = const [],
    this.cooldownUntil,
  });

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'You can submit a club request.';
}
