/// Shared helpers for repositories.

List<Map<String, dynamic>> asRows(dynamic data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

Map<String, dynamic>? asRow(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  return null;
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isBackendId(String id) => _uuidPattern.hasMatch(id);
