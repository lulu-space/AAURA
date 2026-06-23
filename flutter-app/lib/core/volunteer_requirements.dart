import 'join_links.dart';

/// Mandatory campus volunteering requirement for all students.
class VolunteerRequirements {
  VolunteerRequirements._();

  static const int mandatoryHours = 120;

  static String joinLink(String joinToken) =>
      JoinLinks.volunteerJoinLink(joinToken);

  static String? parseJoinToken(String input) =>
      JoinLinks.parseVolunteerToken(input);

  static String? joinTokenFromUri(Uri uri) =>
      JoinLinks.volunteerTokenFromUri(uri);
}
