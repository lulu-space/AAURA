class CampusPerson {
  final String userId;
  final String name;
  final String major;
  final String year;
  final String? statusLabel;
  final bool isHost;

  const CampusPerson({
    required this.userId,
    required this.name,
    required this.major,
    required this.year,
    this.statusLabel,
    this.isHost = false,
  });

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}
