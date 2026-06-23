class Connection {
  final String id;
  final String name;
  final String major;
  final String year;
  final List<String> interests;
  final String? quickTitle;
  final bool suggested;

  const Connection({
    required this.id,
    required this.name,
    required this.major,
    required this.year,
    this.interests = const [],
    this.quickTitle,
    this.suggested = true,
  });

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}
