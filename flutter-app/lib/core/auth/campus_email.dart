import '../../models/user_role.dart';

/// AAUP campus email rules — only these patterns may sign up or provision:
///
///   * `@student.aaup.edu` — students (and club leads)
///   * `@staff.aaup.edu`   — Student Affairs
///   * `@aaup.edu`         — Dean of Faculty (any address except admin)
///   * `admin@aaup.edu`    — system admin only
///
/// The **authoritative role** always comes from `GET /users/me` after login.
/// Domain guessing below is only used for offline fallback copy.
class CampusEmail {
  const CampusEmail._();

  static const allowedDomains = [
    'student.aaup.edu',
    'staff.aaup.edu',
    'aaup.edu',
  ];

  static const invalidMessage =
      'Use an AAUP campus email only: @student.aaup.edu (students), '
      '@staff.aaup.edu (Student Affairs), @aaup.edu (Dean of Faculty), '
      'or admin@aaup.edu (admin).';

  static const adminEmail = 'admin@aaup.edu';

  static bool isAdminEmail(String email) =>
      normalize(email) == adminEmail;

  static String normalize(String email) => email.trim().toLowerCase();

  /// Returns the domain part (lowercase) or null if malformed.
  static String? domain(String email) {
    final normalized = normalize(email);
    final at = normalized.lastIndexOf('@');
    if (at <= 0 || at == normalized.length - 1) return null;
    return normalized.substring(at + 1);
  }

  /// True only for the four allowed campus patterns above.
  static bool isValid(String email) {
    return campusRole(email) != null;
  }

  /// Maps a valid campus email to its provision role, or null if rejected.
  static String? campusRole(String email) {
    final normalized = normalize(email);
    final at = normalized.lastIndexOf('@');
    if (at <= 0) return null;
    final d = normalized.substring(at + 1);
    if (!allowedDomains.contains(d)) return null;

    switch (d) {
      case 'student.aaup.edu':
        return 'student';
      case 'staff.aaup.edu':
        return 'student_affairs';
      case 'aaup.edu':
        return normalized == adminEmail ? 'admin' : 'dean_of_faculty';
      default:
        return null;
    }
  }

  /// Offline-only hint before `/users/me` is available.
  static UserRole guessRole(String email) {
    switch (campusRole(email)) {
      case 'dean_of_faculty':
        return UserRole.deanOfFaculty;
      case 'admin':
        return UserRole.admin;
      case 'student_affairs':
        return UserRole.studentAffairs;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  /// Maps backend `app_role` from `/users/me` onto the UI [UserRole].
  static UserRole roleFromBackend(String? role) {
    switch (role) {
      case 'dean_of_faculty':
        return UserRole.deanOfFaculty;
      case 'admin':
        return UserRole.admin;
      case 'student_affairs':
      case 'staff':
      case 'hidaya':
        return UserRole.studentAffairs;
      case 'student':
      case 'club_organizer':
      case 'organizer':
      default:
        return UserRole.student;
    }
  }
}
