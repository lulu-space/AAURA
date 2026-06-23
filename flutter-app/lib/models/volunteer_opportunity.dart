class VolunteerOpportunity {

  final String id;

  final String title;

  final String description;

  final String department;

  final double estimatedHours;

  final int slots;

  final int enrolledCount;

  final String status;
  final String? createdBy;
  final String? eventId;
  final String? joinToken;

  const VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.estimatedHours,
    required this.slots,
    this.enrolledCount = 0,
    required this.status,
    this.createdBy,
    this.eventId,
    this.joinToken,
  });

  bool get isOpen => status == 'open';

  bool get isFull => enrolledCount >= slots;

  int get seatsRemaining => (slots - enrolledCount).clamp(0, slots);
}
