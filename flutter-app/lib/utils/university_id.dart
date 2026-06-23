/// Validates AAUP numeric student / staff IDs shown in the profile.
class UniversityId {
  UniversityId._();

  static final RegExp _pattern = RegExp(r'^\d{6,}$');

  static bool isValid(String? value) {
    if (value == null) return false;
    return _pattern.hasMatch(value.trim());
  }
}
