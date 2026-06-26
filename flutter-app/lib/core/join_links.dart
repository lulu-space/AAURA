import 'package:aaura/core/config/app_config.dart';

/// Shareable join links for volunteer opportunities and campus events.
class JoinLinks {
  JoinLinks._();

  static String get _base =>
      AppConfig.appJoinBaseUrl.replaceAll(RegExp(r'/$'), '');

  static String volunteerJoinLink(String joinToken) =>
      '$_base/volunteer/join/$joinToken';

  static String eventJoinLink(String joinToken) =>
      '$_base/event/join/$joinToken';

  /// Extracts a join token from a shared link or QR payload (not bare UUIDs).
  static String? parseVolunteerToken(String input) =>
      _parseToken(input, segment: 'volunteer');

  static String? parseEventToken(String input) =>
      _parseToken(input, segment: 'event');

  static String? volunteerTokenFromUri(Uri uri) =>
      _tokenFromUri(uri, segment: 'volunteer') ??
      parseVolunteerToken(uri.toString());

  static String? eventTokenFromUri(Uri uri) =>
      _tokenFromUri(uri, segment: 'event') ?? parseEventToken(uri.toString());

  static String? _tokenFromUri(Uri uri, {required String segment}) {
    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments[segments.length - 3] == segment &&
        segments[segments.length - 2] == 'join') {
      return segments.last;
    }
    final fragment = uri.fragment;
    if (fragment.contains('/$segment/join/')) {
      return _parseToken(fragment, segment: segment);
    }
    return null;
  }

  static String? _parseToken(String input, {required String segment}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final fromUri = _tokenFromUri(uri, segment: segment);
      if (fromUri != null) return fromUri;
    }

    final match = RegExp(
      '/$segment/join/([0-9a-fA-F-]{36})',
    ).firstMatch(trimmed);
    return match?.group(1);
  }

  static final RegExp _uuid =
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// Personal event check-in token (reservation QR), not a join link.
  static String? parseCheckInQrToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (_uuid.hasMatch(trimmed)) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      for (final key in const ['qr_token', 'token', 'check_in']) {
        final value = uri.queryParameters[key]?.trim();
        if (value != null && _uuid.hasMatch(value)) return value;
      }
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (_uuid.hasMatch(last)) return last;
    }
    return null;
  }
}
