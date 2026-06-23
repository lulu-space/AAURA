enum ClubRequestStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ClubRequestStatus.pending:
        return 'Pending';
      case ClubRequestStatus.approved:
        return 'Approved';
      case ClubRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static ClubRequestStatus fromName(String? value) {
    return ClubRequestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ClubRequestStatus.pending,
    );
  }
}

/// A student's request to found a club, reviewed by campus staff / affairs.
class ClubRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String proposedName;
  final String description;
  final String category;
  final ClubRequestStatus status;
  final String? reviewNote;
  final String? createdClubId;
  final String submittedWhen;
  final String? advisorEmail;
  final List<String> coFounderNames;

  const ClubRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.proposedName,
    required this.description,
    required this.category,
    required this.status,
    this.reviewNote,
    this.createdClubId,
    this.submittedWhen = '',
    this.advisorEmail,
    this.coFounderNames = const [],
  });
}
