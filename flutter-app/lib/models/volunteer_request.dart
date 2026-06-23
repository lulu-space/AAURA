enum VolunteerRequestStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case VolunteerRequestStatus.pending:
        return 'Pending';
      case VolunteerRequestStatus.approved:
        return 'Approved';
      case VolunteerRequestStatus.rejected:
        return 'Rejected';
    }
  }
}

/// A student's request for volunteer hours to be approved by campus staff.
class VolunteerRequest {
  final String id;
  final String studentName;
  final String studentId;
  final int hours;
  final String eventTitle;
  final String submittedAt;
  final VolunteerRequestStatus status;
  final String? approvalNote;
  final String? opportunityId;

  const VolunteerRequest({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.hours,
    required this.eventTitle,
    required this.submittedAt,
    this.status = VolunteerRequestStatus.pending,
    this.approvalNote,
    this.opportunityId,
  });

  /// Enrollment requests use title prefix and 0 hours until staff approves.
  bool get isEnrollment =>
      eventTitle.startsWith('Enrollment:') ||
      (hours == 0 && eventTitle.toLowerCase().contains('enrollment'));

  VolunteerRequest copyWith({
    VolunteerRequestStatus? status,
    String? approvalNote,
  }) {
    return VolunteerRequest(
      id: id,
      studentName: studentName,
      studentId: studentId,
      hours: hours,
      eventTitle: eventTitle,
      submittedAt: submittedAt,
      status: status ?? this.status,
      approvalNote: approvalNote ?? this.approvalNote,
      opportunityId: opportunityId ?? this.opportunityId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'studentId': studentId,
        'hours': hours,
        'eventTitle': eventTitle,
        'submittedAt': submittedAt,
        'status': status.name,
        if (approvalNote != null) 'approvalNote': approvalNote,
        if (opportunityId != null) 'opportunityId': opportunityId,
      };

  static VolunteerRequest fromJson(Map<String, dynamic> m) => VolunteerRequest(
        id: m['id'] as String,
        studentName: m['studentName'] as String,
        studentId: m['studentId'] as String,
        hours: (m['hours'] as num).toInt(),
        eventTitle: m['eventTitle'] as String,
        submittedAt: m['submittedAt'] as String? ?? '',
        status: VolunteerRequestStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => VolunteerRequestStatus.pending,
        ),
        approvalNote: m['approvalNote'] as String?,
        opportunityId: m['opportunityId'] as String?,
      );
}
