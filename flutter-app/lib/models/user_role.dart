import '../core/auth/campus_email.dart';

enum UserRole {
  student,
  studentAffairs,
  deanOfFaculty,
  admin,
  staff;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.studentAffairs:
        return 'Student Affairs';
      case UserRole.deanOfFaculty:
        return 'Dean of Faculty';
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
    }
  }

  static UserRole fromJson(String? value) {
    if (value == 'deanOfFaculty' || value == 'dean_of_faculty') {
      return UserRole.deanOfFaculty;
    }
    if (value == 'admin') return UserRole.admin;
    if (value == 'clubLeader' ||
        value == 'clubOrganizer' ||
        value == 'professor') {
      return UserRole.student;
    }
    if (value == 'staff' || value == 'hidaya') {
      return UserRole.studentAffairs;
    }
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }

  static UserRole? fromEmailDomain(String email) {
    if (!CampusEmail.isValid(email)) return null;
    return CampusEmail.guessRole(email);
  }

  bool get needsOnboardingOnSignUp => this == UserRole.student;
}
