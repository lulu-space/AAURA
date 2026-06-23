import 'user_role.dart';

class UserProfile {
  final String name;
  final String studentId;
  final String major;
  final String year;
  final List<String> interests;
  final String? quickTitle;
  final String? email;
  final UserRole role;
  final String? gender;
  final String? dateOfBirth;
  final String? campus;
  final String? expectedGraduation;
  final String? careerGoal;
  final List<String> skills;
  final String? bio;
  final String? avatarUrl;
  final String? assignedFaculty;

  const UserProfile({
    required this.name,
    required this.studentId,
    required this.major,
    required this.year,
    this.interests = const [],
    this.quickTitle,
    this.email,
    this.role = UserRole.student,
    this.gender,
    this.dateOfBirth,
    this.campus,
    this.expectedGraduation,
    this.careerGoal,
    this.skills = const [],
    this.bio,
    this.avatarUrl,
    this.assignedFaculty,
  });

  UserProfile copyWith({
    String? name,
    String? studentId,
    String? major,
    String? year,
    List<String>? interests,
    String? quickTitle,
    String? email,
    UserRole? role,
    String? gender,
    String? dateOfBirth,
    String? campus,
    String? expectedGraduation,
    String? careerGoal,
    List<String>? skills,
    String? bio,
    String? avatarUrl,
    String? assignedFaculty,
  }) {
    return UserProfile(
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      major: major ?? this.major,
      year: year ?? this.year,
      interests: interests ?? this.interests,
      quickTitle: quickTitle ?? this.quickTitle,
      email: email ?? this.email,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      campus: campus ?? this.campus,
      expectedGraduation: expectedGraduation ?? this.expectedGraduation,
      careerGoal: careerGoal ?? this.careerGoal,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedFaculty: assignedFaculty ?? this.assignedFaculty,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'studentId': studentId,
        'major': major,
        'year': year,
        'interests': interests,
        'quickTitle': quickTitle,
        'email': email,
        'role': role.name,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'campus': campus,
        'expectedGraduation': expectedGraduation,
        'careerGoal': careerGoal,
        'skills': skills,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'assignedFaculty': assignedFaculty,
      };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        studentId: json['studentId'] as String? ?? '',
        major: json['major'] as String? ?? '',
        year: json['year'] as String? ?? '',
        interests: (json['interests'] as List?)?.cast<String>() ?? const [],
        quickTitle: json['quickTitle'] as String?,
        email: json['email'] as String?,
        role: UserRole.fromJson(json['role'] as String?),
        gender: json['gender'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        campus: json['campus'] as String?,
        expectedGraduation: json['expectedGraduation'] as String?,
        careerGoal: json['careerGoal'] as String?,
        skills: (json['skills'] as List?)?.cast<String>() ?? const [],
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        assignedFaculty: json['assignedFaculty'] as String?,
      );
}
