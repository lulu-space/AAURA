import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/campus_email.dart';
import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_client.dart';
import '../data/api_mappers.dart';
import '../data/repositories/_repo_support.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/club_membership_repository.dart';
import '../data/repositories/club_messages_repository.dart';
import '../data/repositories/clubs_repository.dart';
import '../data/repositories/badges_repository.dart';
import '../data/repositories/event_feedback_repository.dart';
import '../data/repositories/connections_repository.dart';
import '../data/repositories/events_repository.dart';
import '../data/repositories/gamification_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/profiling_repository.dart';
import '../data/repositories/recommendations_repository.dart';
import '../data/repositories/student_profiles_repository.dart';
import '../data/repositories/study_plans_repository.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/peer_messages_repository.dart';
import '../data/repositories/predictions_repository.dart';
import '../data/repositories/study_session_membership_repository.dart';
import '../data/repositories/study_sessions_repository.dart';
import '../data/repositories/volunteering_opportunities_repository.dart';
import '../data/repositories/cv_repository.dart';
import '../data/repositories/avatar_repository.dart';
import '../data/repositories/club_requests_repository.dart';
import '../data/repositories/dean_repository.dart';
import '../data/repositories/admin_repository.dart';
import '../core/join_links.dart';
import '../core/volunteer_requirements.dart';
import '../models/club.dart';
import '../models/club_request.dart';
import '../models/club_request_eligibility.dart';
import '../data/repositories/volunteering_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/badge.dart';
import '../models/auth_flow_result.dart' show AuthFormMode, SignUpResult;
import '../models/app_notification.dart';
import '../models/campus_person.dart';
import '../models/peer_message.dart';
import '../models/peer_conversation.dart';
import '../models/club_server.dart';
import '../models/connection.dart';
import '../models/event.dart';
import '../models/event_prediction.dart';
import '../models/leaderboard.dart';
import '../models/shop_item.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/home_personalization_service.dart';
import '../utils/university_id.dart';
import '../services/skill_progress_service.dart';
import '../models/volunteer_request.dart';
import '../models/volunteer_opportunity.dart';

class AppState extends ChangeNotifier {
  static const _kAuthenticated = 'aaura.authenticated';
  static const _kProfile = 'aaura.profile';
  static const _kOnboarded = 'aaura.onboarded';
  static const _kOnboardedUserId = 'aaura.onboardedUserId';
  static const _kJoinedEvents = 'aaura.joinedEvents';
  static const _kJoinedClubs = 'aaura.joinedClubs';
  static const _kJoinedSessions = 'aaura.joinedSessions';
  static const _kPoints = 'aaura.points';
  static const _kEarnedBadges = 'aaura.earnedBadges';
  static const _kVolunteerHours = 'aaura.volunteerHours';
  static const _kCompletedGoals = 'aaura.completedGoals';
  static const _kAttendedAt = 'aaura.attendedAt';
  static const _kOwnedShopItems = 'aaura.ownedShopItems';
  static const _kConnections = 'aaura.connections';
  static const _kFavoriteEvents = 'aaura.favoriteEvents';
  static const _kPublishedSessions = 'aaura.publishedSessions';
  static const _kCvPinnedEvents = 'aaura.cvPinnedEvents';
  static const _kCustomSessions = 'aaura.customSessions';
  static const _kCreatedClubs = 'aaura.createdClubs';
  static const _kLedClubs = 'aaura.ledClubs';
  static const _kPublishedEvents = 'aaura.publishedEvents';
  static const _kVolunteerRequests = 'aaura.volunteerRequests';
  static const _kCvUrl = 'aaura.cvUrl';
  static const _kCvFileName = 'aaura.cvFileName';

  final AuthService _auth = AuthService();
  final ApiClient _api = ApiClient();
  late final EventsRepository _eventsRepo = EventsRepository(_api);
  late final ClubsRepository _clubsRepo = ClubsRepository(_api);
  late final BadgesRepository _badgesRepo = BadgesRepository(_api);
  late final EventFeedbackRepository _eventFeedbackRepo =
      EventFeedbackRepository(_api);
  late final ClubMembershipRepository _clubMembershipRepo =
      ClubMembershipRepository(_api);
  late final GamificationRepository _gamificationRepo =
      GamificationRepository(_api);
  late final ProfilingRepository _profilingRepo = ProfilingRepository(_api);
  late final VolunteeringRepository _volunteeringRepo =
      VolunteeringRepository(_api);
  late final StudySessionsRepository _studySessionsRepo =
      StudySessionsRepository(_api);
  late final StudySessionMembershipRepository _studySessionMembershipRepo =
      StudySessionMembershipRepository(_api);
  late final ShopRepository _shopRepo = ShopRepository(_api);
  late final ConnectionsRepository _connectionsRepo = ConnectionsRepository(_api);
  late final ClubMessagesRepository _clubMessagesRepo =
      ClubMessagesRepository(_api);
  late final StudentProfilesRepository _studentProfilesRepo =
      StudentProfilesRepository(_api);
  late final RecommendationsRepository _recommendationsRepo =
      RecommendationsRepository(_api);
  late final NotificationsRepository _notificationsRepo =
      NotificationsRepository(_api);
  late final CalendarRepository _calendarRepo = CalendarRepository(_api);
  late final StudyPlansRepository _studyPlansRepo = StudyPlansRepository(_api);
  late final VolunteeringOpportunitiesRepository _volunteeringOpportunitiesRepo =
      VolunteeringOpportunitiesRepository(_api);
  final CvRepository _cvRepo = CvRepository();
  final AvatarRepository _avatarRepo = AvatarRepository();
  late final ClubRequestsRepository _clubRequestsRepo =
      ClubRequestsRepository(_api);
  late final PeerMessagesRepository _peerMessagesRepo =
      PeerMessagesRepository(_api);
  late final DeanRepository _deanRepo = DeanRepository(_api);
  late final AdminRepository _adminRepo = AdminRepository(_api);

  String? _userId;
  String? _gamificationRowId;
  String? get userId => _userId;

  bool _useBackendData = false;
  bool get useBackendData => _useBackendData;

  final List<Event> _backendEvents = [];
  final List<Club> _backendClubs = [];
  final List<StudySession> _backendStudySessions = [];
  final List<String> _recommendedEventIds = [];
  final List<AppNotification> _notifications = [];
  final List<Map<String, String>> _backendCourses = [];
  final List<Map<String, String>> _backendDeadlines = [];
  final List<Map<String, dynamic>> _backendStudyPlans = [];
  final List<LeaderboardEntry> _leaderboardEntries = [];
  final List<VolunteerOpportunity> _volunteeringOpportunities = [];
  final List<VolunteerOpportunity> _managedVolunteerOpportunities = [];
  Map<String, dynamic>? _deanDashboard;
  Map<String, dynamic>? _deanInsights;
  List<Event> _deanFacultyEvents = [];
  List<Club> _deanFacultyClubs = [];
  List<Map<String, dynamic>> _deanAnnouncements = [];
  String? _deanLastError;
  Map<String, dynamic>? get deanDashboard => _deanDashboard;
  Map<String, dynamic>? get deanInsights => _deanInsights;
  List<Event> get deanFacultyEvents => List.unmodifiable(_deanFacultyEvents);
  List<Club> get deanFacultyClubs => List.unmodifiable(_deanFacultyClubs);
  List<Map<String, dynamic>> get deanAnnouncements =>
      List.unmodifiable(_deanAnnouncements);
  String? get deanLastError => _deanLastError;
  bool get deanHasFaculty =>
      assignedFaculty != null && assignedFaculty!.trim().isNotEmpty;

  Map<String, dynamic>? _adminDashboard;
  Map<String, dynamic>? _adminContent;
  Map<String, dynamic>? _adminAnalytics;
  Map<String, dynamic>? _adminSettings;
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _adminAuditLogs = [];
  List<Map<String, dynamic>> _adminVolunteeringRecords = [];
  List<Map<String, dynamic>> _adminBadges = [];

  Map<String, dynamic>? get adminDashboard => _adminDashboard;
  Map<String, dynamic>? get adminContent => _adminContent;
  Map<String, dynamic>? get adminAnalytics => _adminAnalytics;
  Map<String, dynamic>? get adminSettings => _adminSettings;
  List<Map<String, dynamic>> get adminUsers => List.unmodifiable(_adminUsers);
  List<Map<String, dynamic>> get adminAuditLogs =>
      List.unmodifiable(_adminAuditLogs);
  List<Map<String, dynamic>> get adminVolunteeringRecords =>
      List.unmodifiable(_adminVolunteeringRecords);
  List<Map<String, dynamic>> get adminBadges => List.unmodifiable(_adminBadges);
  final List<Map<String, String>> _backendStudyPlanCourses = [];
  final List<ShopItem> _backendShopItems = [];
  final List<Connection> _suggestedConnections = [];
  final List<Connection> _myConnections = [];
  final List<AppBadge> _badgeCatalog = [];
  final List<Map<String, String>> _clubActivityFeed = [];
  final Map<String, List<ClubMember>> _clubMembersByClubId = {};
  final Map<String, List<CampusPerson>> _eventAttendeesByEventId = {};
  final Map<String, List<CampusPerson>> _studySessionMembersBySessionId = {};
  final Map<String, List<PeerMessage>> _peerMessagesByUserId = {};
  final List<PeerConversation> _peerConversations = [];
  final Map<String, Map<String, dynamic>> _eventFeedbackByEventId = {};
  List<Map<String, dynamic>> _skillProgress = [];
  List<String> _semesterGoals = [];

  /// event_id -> reservation row (includes qr_token, reservation_status).
  final Map<String, Map<String, dynamic>> _eventReservations = {};

  /// study_session_id -> membership row id.
  final Map<String, String> _studySessionMembershipIds = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  AuthFormMode? _pendingAuthForm;
  AuthFormMode? get pendingAuthForm => _pendingAuthForm;
  String? _authFormInitialEmail;
  String? get authFormInitialEmail => _authFormInitialEmail;

  void showAuthForm(AuthFormMode mode, {String? initialEmail}) {
    _pendingAuthForm = mode;
    final trimmed = initialEmail?.trim();
    _authFormInitialEmail =
        trimmed == null || trimmed.isEmpty ? null : trimmed;
    notifyListeners();
  }

  void clearAuthForm() {
    if (_pendingAuthForm == null && _authFormInitialEmail == null) return;
    _pendingAuthForm = null;
    _authFormInitialEmail = null;
    notifyListeners();
  }

  bool _onboarded = false;
  bool get onboarded => _onboarded;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  String? get assignedFaculty => _profile?.assignedFaculty;

  bool get isStudent => _profile?.role == UserRole.student;
  bool get isDeanOfFaculty => _profile?.role == UserRole.deanOfFaculty;
  bool get isAdmin => _profile?.role == UserRole.admin;
  bool get isStudentAffairs =>
      _profile?.role == UserRole.studentAffairs ||
      _profile?.role == UserRole.staff;
  bool get isStaff => false; // merged into Student Affairs
  /// Campus staff / student affairs (not students or deans).
  bool get isStaffOrAffairs => isStudentAffairs;

  bool get canManageCampusEvents =>
      isStudentAffairs || isDeanOfFaculty || isAdmin;

  /// Student Affairs, staff, deans, and admins can review club requests.
  bool get canReviewClubRequests =>
      isStudentAffairs || isDeanOfFaculty || isAdmin;

  bool get canReviewEvents =>
      isStudentAffairs || isDeanOfFaculty || isAdmin;

  bool get canReviewVolunteerHours => canReviewEvents;

  /// Student Affairs browses clubs only — no join or founding flows.
  bool get canJoinOrCreateClubs => !isStudentAffairs;

  bool get _canReviewClubRequests => canReviewClubRequests;
  bool get needsOnboarding => _authenticated && !_onboarded;

  final Set<String> _joinedEventIds = {};
  Set<String> get joinedEventIds => _joinedEventIds;

  final Set<String> _joinedClubIds = {};
  Set<String> get joinedClubIds => _joinedClubIds;

  int get joinedEventsCount => _joinedEventIds.length;

  int get joinedClubsCount => _joinedClubIds.length;

  // In-memory club chat for the current app session (seeded lazily from mock,
  // not persisted to disk). Keyed by "<clubId>#<channelId>".
  final Map<String, List<ClubMessage>> _clubChat = {};

  final Set<String> _joinedSessionIds = {};
  Set<String> get joinedSessionIds => _joinedSessionIds;

  final Set<String> _earnedBadgeIds = {};
  Set<String> get earnedBadgeIds => _earnedBadgeIds;

  final Set<String> _completedGoals = {};
  Set<String> get completedGoals => _completedGoals;

  int _points = 0;
  int get points => _points;

  int _volunteerHours = 0;
  int get volunteerHours => _volunteerHours;
  static const int mandatoryVolunteerHours =
      VolunteerRequirements.mandatoryHours;
  int get volunteerHoursRemaining =>
      (mandatoryVolunteerHours - _volunteerHours).clamp(0, mandatoryVolunteerHours);
  double get volunteerProgress =>
      (_volunteerHours / mandatoryVolunteerHours).clamp(0.0, 1.0);

  String? _cvUrl;
  String? _cvFileName;
  String? get cvUrl => _cvUrl;
  String? get cvFileName => _cvFileName;
  bool get hasCv => _cvUrl != null && _cvUrl!.isNotEmpty;
  bool _cvUploading = false;
  bool get cvUploading => _cvUploading;
  bool _avatarUploading = false;
  bool get avatarUploading => _avatarUploading;

  /// Uploads a CV (PDF bytes) to Supabase storage and remembers the public URL.
  /// Returns true on success.
  Future<bool> uploadCv(Uint8List bytes, String fileName) async {
    final userId = _userId ?? _auth.currentUser?.id;
    if (userId == null || !_useBackendData) return false;
    _cvUploading = true;
    notifyListeners();
    try {
      final url = await _cvRepo.upload(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
      );
      _cvUrl = url;
      _cvFileName = fileName;
      _cvUploading = false;
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      _cvUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Uploads a profile photo and persists the public URL on `/users/me`.
  Future<bool> uploadAvatar(Uint8List bytes, String contentType) async {
    final userId = _userId ?? _auth.currentUser?.id;
    if (userId == null || !_useBackendData) return false;
    _avatarUploading = true;
    notifyListeners();
    try {
      final url = await _avatarRepo.upload(
        userId: userId,
        bytes: bytes,
        contentType: contentType,
      );
      await _api.patch('/users/me', body: {'avatar_url': url});
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(avatarUrl: url);
      }
      _avatarUploading = false;
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      _avatarUploading = false;
      notifyListeners();
      return false;
    }
  }

  final Map<String, DateTime> _attendedAt = {};
  Map<String, DateTime> get attendedAt => Map.unmodifiable(_attendedAt);

  final Set<String> _ownedShopItemIds = {};
  Set<String> get ownedShopItemIds => _ownedShopItemIds;

  final Set<String> _connectionIds = {};
  Set<String> get connectionIds => _connectionIds;

  final Set<String> _favoriteEventIds = {};
  Set<String> get favoriteEventIds => _favoriteEventIds;

  final Set<String> _publishedSessionIds = {};
  Set<String> get publishedSessionIds => _publishedSessionIds;

  final Set<String> _cvPinnedEventIds = {};
  Set<String> get cvPinnedEventIds => _cvPinnedEventIds;

  final List<StudySession> _customSessions = [];
  List<StudySession> get customSessions => List.unmodifiable(_customSessions);

  // Clubs the current user created/leads, plus runtime-published events and
  // volunteer-hour approval requests. Merged into the mock catalogs at read.
  final List<Club> _createdClubs = [];
  List<Club> get createdClubs => List.unmodifiable(_createdClubs);

  final Set<String> _ledClubIds = {};
  Set<String> get ledClubIds => _ledClubIds;
  final Map<String, String> _clubMemberRoles = {};

  final List<Event> _publishedEvents = [];

  final List<VolunteerRequest> _volunteerRequests = [];
  List<VolunteerRequest> get volunteerRequests =>
      List.unmodifiable(_volunteerRequests);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  int get unreadPeerMessageCount =>
      _peerConversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  List<PeerConversation> get peerConversations =>
      List.unmodifiable(_peerConversations);

  List<Map<String, String>> get courseSchedule {
    if (_useBackendData) {
      return [..._backendStudyPlanCourses, ..._backendCourses];
    }
    return const [];
  }

  List<Map<String, String>> get upcomingDeadlines {
    if (_useBackendData) return List.unmodifiable(_backendDeadlines);
    return const [];
  }

  /// True when calendar / study-plan CRUD should hit the backend.
  bool get canManagePlanner =>
      AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn;

  List<LeaderboardEntry> get leaderboardEntries {
    // Authenticated users always see real standings (even if short); mock data
    // is only used in the offline/demo experience.
    if (_useBackendData) return List.unmodifiable(_leaderboardEntries);
    return const [];
  }

  List<Map<String, String>> get feedItems {
    if (_useBackendData) {
      return _notifications.map((n) => n.toFeedItem()).toList();
    }
    return const [];
  }

  List<VolunteerOpportunity> get volunteeringOpportunities =>
      List.unmodifiable(_volunteeringOpportunities);

  /// Opportunities published by the signed-in Student Affairs user.
  List<VolunteerOpportunity> get managedVolunteerOpportunities {
    if (_userId == null) return const [];
    return _managedVolunteerOpportunities
        .where((o) => o.createdBy == _userId)
        .toList(growable: false);
  }

  int get openManagedVolunteerOpportunityCount =>
      managedVolunteerOpportunities.where((o) => o.isOpen).length;

  List<ShopItem> get allShopItems {
    if (_useBackendData && _backendShopItems.isNotEmpty) {
      return List.unmodifiable(_backendShopItems);
    }
    return const [];
  }

  List<ShopItem> get ownedShopItems =>
      allShopItems.where((item) => _ownedShopItemIds.contains(item.id)).toList();

  List<Connection> get suggestedConnections {
    if (_useBackendData) return List.unmodifiable(_suggestedConnections);
    return const [];
  }

  List<Connection> get myConnections {
    if (_useBackendData) return List.unmodifiable(_myConnections);
    return const [];
  }

  List<Map<String, dynamic>> get skillProgress {
    // Prefer persisted Shams/manual skills whenever we have them, even if a
    // partial refresh left [_useBackendData] false.
    if (_skillProgress.isNotEmpty) {
      return List.unmodifiable(_skillProgress);
    }
    if (_useBackendData) return List.unmodifiable(_skillProgress);
    return const [];
  }

  List<String> get semesterGoals {
    if (_useBackendData) return List.unmodifiable(_semesterGoals);
    return const [];
  }

  /// Badge catalog with earned state from [gamification.badges].
  List<AppBadge> get allBadges {
    final catalog =
        _useBackendData && _badgeCatalog.isNotEmpty ? _badgeCatalog : const <AppBadge>[];
    return catalog
        .map(
          (badge) => AppBadge(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            icon: badge.icon,
            // Authenticated: a badge is unlocked only if the user truly earned
            // it. Offline demo keeps the catalog's default unlock state.
            locked: _useBackendData
                ? !isBadgeEarned(badge.id)
                : (badge.locked && !isBadgeEarned(badge.id)),
          ),
        )
        .toList(growable: false);
  }

  List<Map<String, String>> get clubActivityFeed {
    if (_useBackendData) return List.unmodifiable(_clubActivityFeed);
    return const [];
  }

  Map<String, dynamic>? eventFeedbackFor(String eventId) =>
      _eventFeedbackByEventId[eventId];

  List<ClubMember> clubMembers(Club club) {
    final cached = _clubMembersByClubId[club.id];
    if (_useBackendData && cached != null && cached.isNotEmpty) {
      return List.unmodifiable(cached);
    }
    return const [];
  }

  List<CampusPerson> eventAttendees(String eventId) =>
      List.unmodifiable(_eventAttendeesByEventId[eventId] ?? const []);

  List<CampusPerson> studySessionMembers(String sessionId) =>
      List.unmodifiable(_studySessionMembersBySessionId[sessionId] ?? const []);

  List<PeerMessage> peerMessagesWith(String userId) =>
      List.unmodifiable(_peerMessagesByUserId[userId] ?? const []);

  Connection? connectionForPeer(String userId) {
    for (final connection in myConnections) {
      if (connection.id == userId) return connection;
    }
    for (final conversation in _peerConversations) {
      if (conversation.peerUserId == userId) {
        return Connection(
          id: conversation.peerUserId,
          name: conversation.name,
          major: conversation.major,
          year: conversation.year,
          suggested: false,
        );
      }
    }
    return null;
  }

  /// First reservation QR token that is not yet checked in (for simulate scan).
  String? get nextCheckInQrToken {
    for (final row in _eventReservations.values) {
      final status = row['reservation_status']?.toString();
      if (status == 'checked_in' || status == 'cancelled') continue;
      final token = row['qr_token']?.toString();
      if (token != null && isBackendId(token)) return token;
    }
    return null;
  }

  String? reservationQrTokenForEvent(String eventId) {
    final token = _eventReservations[eventId]?['qr_token']?.toString();
    if (token != null && isBackendId(token)) return token;
    return null;
  }

  bool isEventCheckedIn(String eventId) =>
      _eventReservations[eventId]?['reservation_status']?.toString() ==
      'checked_in';

  String? _pendingVolunteerJoinToken;

  /// Join token from a shared volunteer link, ready for QR scan flow.
  String? get pendingVolunteerJoinToken => _pendingVolunteerJoinToken;

  void setPendingVolunteerJoinToken(String? token) {
    _pendingVolunteerJoinToken = token?.trim();
    notifyListeners();
  }

  String? consumeLaunchVolunteerJoinToken() {
    final token = JoinLinks.volunteerTokenFromUri(Uri.base);
    if (token == null || token.isEmpty) return null;
    _pendingVolunteerJoinToken = token;
    return token;
  }

  String? _pendingEventJoinToken;

  String? get pendingEventJoinToken => _pendingEventJoinToken;

  void setPendingEventJoinToken(String? token) {
    _pendingEventJoinToken = token?.trim();
    notifyListeners();
  }

  String? consumeLaunchEventJoinToken() {
    final token = JoinLinks.eventTokenFromUri(Uri.base);
    if (token == null || token.isEmpty) return null;
    _pendingEventJoinToken = token;
    return token;
  }

  /// club_id -> membership row id (for leave/update via API).
  final Map<String, String> _clubMembershipIds = {};

  List<Club> get allClubs {
    if (_useBackendData) return List.unmodifiable(_backendClubs);
    return List.unmodifiable(_createdClubs);
  }

  Club? clubById(String id) {
    for (final club in allClubs) {
      if (club.id == id) return club;
    }
    return null;
  }

  Event? eventById(String id) {
    for (final event in allEvents) {
      if (event.id == id) return event;
    }
    return null;
  }

  bool isEventOrganizer(String eventId) {
    if (_userId == null) return false;
    final event = eventById(eventId);
    return event?.organizerId == _userId;
  }

  /// Runs POST /events/:id/predict-success and refreshes the cached event row.
  Future<EventPrediction?> refreshEventPrediction(String eventId) async {
    if (!_useBackendData || !isBackendId(eventId)) return null;
    try {
      final result = await _eventsRepo.predictSuccess(eventId);
      if (result == null) return null;
      final eventRow = result['event'];
      if (eventRow is Map<String, dynamic>) {
        _upsertBackendEvent(ApiMappers.event(eventRow));
      }
      notifyListeners();
      await _save();
      return EventPredictionMapper.fromBackend(result);
    } catch (_) {
      return null;
    }
  }

  List<Event> get allEvents {
    if (_useBackendData) return List.unmodifiable(_backendEvents);
    return List.unmodifiable(_publishedEvents);
  }

  final List<ClubRequest> _myClubRequests = [];
  final List<ClubRequest> _clubRequestQueue = [];
  ClubRequestEligibility? _clubRequestEligibility;
  final List<Event> _eventReviewQueue = [];

  /// The current user's own club-founding requests.
  List<ClubRequest> get myClubRequests => List.unmodifiable(_myClubRequests);

  ClubRequestEligibility? get clubRequestEligibility => _clubRequestEligibility;

  bool get canSubmitClubRequest =>
      canJoinOrCreateClubs &&
      (_clubRequestEligibility?.eligible ??
          !myClubRequests.any((r) => r.status == ClubRequestStatus.pending));

  /// Review queue for staff / student affairs (all requests, any status).
  List<ClubRequest> get clubRequestQueue => List.unmodifiable(_clubRequestQueue);

  /// Student-submitted events awaiting or after Student Affairs review.
  List<Event> get eventReviewQueue => List.unmodifiable(_eventReviewQueue);

  int get pendingClubRequestCount =>
      _clubRequestQueue.where((r) => r.status == ClubRequestStatus.pending).length;

  int get pendingEventReviewCount => _eventReviewQueue
      .where((e) => !e.isApproved && e.status != 'cancelled')
      .length;

  /// Student submits a request to found a new club.
  /// Returns `null` on success, or an error message from the backend.
  Future<String?> submitClubRequest({
    required String proposedName,
    required String description,
    required String category,
    required String advisorEmail,
    List<String> coFounderNames = const [],
  }) async {
    if (!_useBackendData) {
      return 'Sign in with your campus account to submit a club request.';
    }
    try {
      final created = await _clubRequestsRepo.submit(
        proposedName: proposedName,
        description: description,
        category: category,
        advisorEmail: advisorEmail,
        coFounderNames: coFounderNames,
      );
      if (created != null) {
        _myClubRequests.insert(0, created);
        await refreshClubRequestEligibility();
        notifyListeners();
        return null;
      }
      return 'Could not submit club request.';
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not submit. Check your connection and try again.';
    }
  }

  Future<void> refreshClubRequestEligibility() async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }
    if (!isStudent) {
      _clubRequestEligibility = null;
      return;
    }
    try {
      _clubRequestEligibility = await _clubRequestsRepo.fetchEligibility();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> approveClubRequest(String id, {String? note}) {
    if (!canReviewClubRequests) {
      return Future.value('Reviewer access required.');
    }
    return _reviewClubRequest(
      () => _clubRequestsRepo.approve(id, note: note),
    );
  }

  Future<String?> rejectClubRequest(String id, {String? note}) {
    if (!canReviewClubRequests) {
      return Future.value('Student Affairs access required.');
    }
    return _reviewClubRequest(
      () => _clubRequestsRepo.reject(id, note: note),
    );
  }

  Future<String?> revokeClubRequest(String id, {String? note}) {
    if (!canReviewClubRequests) {
      return Future.value('Student Affairs access required.');
    }
    return _reviewClubRequest(
      () => _clubRequestsRepo.revoke(id, note: note),
    );
  }

  Future<bool> approveEventReview(String id, {String? note}) async {
    final err = await _reviewEventAction(
      () => _eventsRepo.approveReview(id, note: note),
    );
    return err == null;
  }

  Future<bool> rejectEventReview(String id, {String? note}) async {
    final err = await _reviewEventAction(
      () => _eventsRepo.rejectReview(id, note: note),
    );
    return err == null;
  }

  Future<String?> withdrawEventReview(String id, {String? note}) async {
    return _reviewEventAction(
      () => _eventsRepo.withdrawReview(id, note: note),
    );
  }

  Future<String?> _reviewEventAction(Future<void> Function() action) async {
    if (!canReviewEvents) {
      return 'Student Affairs access required.';
    }
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return 'Sign in with your campus account.';
    }
    if (!_useBackendData) {
      await refreshAll();
    }
    if (!_useBackendData) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    try {
      await action();
      await _loadEventReviews();
      await refreshAll();
      return null;
    } on ApiException catch (e) {
      return e.message.trim().isNotEmpty
          ? e.message.trim()
          : 'Action failed.';
    } catch (_) {
      return 'Action failed. Check your connection and try again.';
    }
  }

  Future<String?> _reviewClubRequest(Future<void> Function() action) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return 'Sign in with your campus account.';
    }
    if (!_useBackendData) {
      await refreshAll();
    }
    if (!_useBackendData) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    try {
      await action();
      await refreshAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Action failed. Check your connection and try again.';
    }
  }

  /// Events that belong to a specific club (organised by the club leader),
  /// soonest first.
  List<Event> eventsForClub(String clubId) {
    final list = allEvents.where((e) => e.clubId == clubId).toList();
    list.sort((a, b) {
      final aDate = a.startsAt;
      final bDate = b.startsAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return list;
  }

  List<StudySession> get studySessions {
    if (_useBackendData) return List.unmodifiable(_backendStudySessions);
    return List.unmodifiable(_customSessions);
  }

  /// Sessions that have not ended yet (hidden from Academics carousel).
  List<StudySession> get activeStudySessions {
    final now = DateTime.now();
    return studySessions
        .where((s) {
          final end = s.endsAt;
          return end == null || end.isAfter(now);
        })
        .toList(growable: false);
  }

  /// Skill names used for home personalization (profile + skill progress).
  List<String> get personalizationSkillNames {
    final names = <String>{};
    for (final skill in _profile?.skills ?? const <String>[]) {
      final trimmed = skill.trim();
      if (trimmed.isNotEmpty) names.add(trimmed);
    }
    for (final row in _skillProgress) {
      final name = row['name']?.toString().trim();
      if (name != null && name.isNotEmpty) names.add(name);
    }
    return names.toList(growable: false);
  }

  bool get _hasHomePersonalizationSignals {
    if (isStaffOrAffairs) return false;
    final interests = _profile?.interests ?? const <String>[];
    final major = _profile?.major.trim() ?? '';
    return interests.isNotEmpty ||
        personalizationSkillNames.isNotEmpty ||
        (major.isNotEmpty && major != 'Undeclared');
  }

  /// Study sessions ranked for the signed-in student; excludes mismatched topics.
  List<StudySession> get suggestedStudySessions {
    if (isStaffOrAffairs) return activeStudySessions;
    final sessions = activeStudySessions;
    if (sessions.isEmpty) return sessions;

    final ranked = HomePersonalizationService.rankStudySessions(
      sessions,
      interests: _profile?.interests ?? const [],
      skills: personalizationSkillNames,
      major: _profile?.major,
      hostSessionIds: sessions
          .where((s) => isSessionHost(s))
          .map((s) => s.id)
          .toSet(),
      joinedSessionIds: _joinedSessionIds,
    );
    if (ranked.isNotEmpty) return ranked;
    return sessions
        .where((s) => isSessionHost(s) || isSessionJoined(s.id))
        .toList(growable: false);
  }

  /// Event recommendations from the backend, falling back to profile-ranked events.
  List<Event> get suggestedEvents {
    if (_hasHomePersonalizationSignals) {
      final ranked = HomePersonalizationService.rankEvents(
        allEvents,
        interests: _profile?.interests ?? const [],
        skills: personalizationSkillNames,
        major: _profile?.major,
        limit: 6,
      );
      return ranked.take(4).toList(growable: false);
    }

    if (_useBackendData && _recommendedEventIds.isNotEmpty) {
      final byId = {for (final event in allEvents) event.id: event};
      final matched = <Event>[];
      for (final id in _recommendedEventIds) {
        final event = byId[id];
        if (event != null) matched.add(event);
      }
      if (matched.isNotEmpty) return matched;
    }
    return allEvents.take(4).toList(growable: false);
  }

  /// Clubs ranked for the signed-in student (interests, skills, major).
  List<Club> get suggestedClubs {
    if (_hasHomePersonalizationSignals) {
      final ranked = HomePersonalizationService.rankClubs(
        allClubs,
        interests: _profile?.interests ?? const [],
        skills: personalizationSkillNames,
        major: _profile?.major,
        limit: 6,
      );
      return ranked.take(4).toList(growable: false);
    }
    return allClubs.take(4).toList(growable: false);
  }

  /// Hero trending strip — top matches when profile signals exist.
  List<Event> get trendingEventsForHome {
    if (_hasHomePersonalizationSignals) {
      return HomePersonalizationService.rankEvents(
        allEvents,
        interests: _profile?.interests ?? const [],
        skills: personalizationSkillNames,
        major: _profile?.major,
        limit: 6,
      );
    }
    return allEvents.take(6).toList(growable: false);
  }

  void _syncProfileSkillsFromProgress() {
    final names = personalizationSkillNames;
    if (_profile == null) return;
    _profile = _profile!.copyWith(skills: names);
  }

  /// Events published by the signed-in organizer (staff / club leader flows).
  List<Event> get publishedEvents {
    if (_useBackendData && _userId != null) {
      return _backendEvents
          .where((event) => event.organizerId == _userId)
          .toList(growable: false);
    }
    return List.unmodifiable(_publishedEvents);
  }

  bool isClubLeader(String id) {
    if (_ledClubIds.contains(id)) return true;
    if (_userId == null) return false;
    return _backendClubs.any((c) => c.id == id && c.organizerId == _userId);
  }

  bool canPostClubAnnouncements(String clubId) {
    if (isClubLeader(clubId)) return true;
    final role = _clubMemberRoles[clubId];
    return role != null && role != 'member';
  }

  bool isSessionHost(StudySession session) {
    if (_userId == null) return false;
    if (session.hostId != null) return session.hostId == _userId;
    return _publishedSessionIds.contains(session.id);
  }

  // The app is light-theme only.
  ThemeMode get themeMode => ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _onboarded = prefs.getBool(_kOnboarded) ?? false;

    final profileRaw = prefs.getString(_kProfile);
    if (profileRaw != null) {
      try {
        final map = jsonDecode(profileRaw) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(map);
      } catch (_) {
        _profile = null;
      }
    }

    _authenticated = prefs.getBool(_kAuthenticated) ?? false;

    _joinedEventIds
      ..clear()
      ..addAll(prefs.getStringList(_kJoinedEvents) ?? const []);
    _joinedClubIds
      ..clear()
      ..addAll(prefs.getStringList(_kJoinedClubs) ?? const []);
    _joinedSessionIds
      ..clear()
      ..addAll(prefs.getStringList(_kJoinedSessions) ?? const []);

    final badges = prefs.getStringList(_kEarnedBadges);
    if (badges != null) {
      _earnedBadgeIds
        ..clear()
        ..addAll(badges);
    }

    final goals = prefs.getStringList(_kCompletedGoals);
    if (goals != null) {
      _completedGoals
        ..clear()
        ..addAll(goals);
    }

    _points = prefs.getInt(_kPoints) ?? _points;
    _volunteerHours = prefs.getInt(_kVolunteerHours) ?? _volunteerHours;
    _cvUrl = prefs.getString(_kCvUrl);
    _cvFileName = prefs.getString(_kCvFileName);

    final attendedRaw = prefs.getString(_kAttendedAt);
    if (attendedRaw != null) {
      try {
        final map = jsonDecode(attendedRaw) as Map<String, dynamic>;
        _attendedAt
          ..clear()
          ..addEntries(map.entries
              .map((e) => MapEntry(e.key, DateTime.parse(e.value as String))));
      } catch (_) {}
    }

    _ownedShopItemIds
      ..clear()
      ..addAll(prefs.getStringList(_kOwnedShopItems) ?? const []);
    _connectionIds
      ..clear()
      ..addAll(prefs.getStringList(_kConnections) ?? const []);
    _favoriteEventIds
      ..clear()
      ..addAll(prefs.getStringList(_kFavoriteEvents) ?? const []);
    _publishedSessionIds
      ..clear()
      ..addAll(prefs.getStringList(_kPublishedSessions) ?? const []);
    _cvPinnedEventIds
      ..clear()
      ..addAll(prefs.getStringList(_kCvPinnedEvents) ?? const []);

    final sessionsRaw = prefs.getString(_kCustomSessions);
    if (sessionsRaw != null) {
      try {
        final list = jsonDecode(sessionsRaw) as List<dynamic>;
        _customSessions
          ..clear()
          ..addAll(list.map((e) => _sessionFromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    final createdClubsRaw = prefs.getString(_kCreatedClubs);
    if (createdClubsRaw != null) {
      try {
        final list = jsonDecode(createdClubsRaw) as List<dynamic>;
        _createdClubs
          ..clear()
          ..addAll(list.map((e) => _clubFromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    _ledClubIds
      ..clear()
      ..addAll(prefs.getStringList(_kLedClubs) ?? const []);

    final publishedRaw = prefs.getString(_kPublishedEvents);
    if (publishedRaw != null) {
      try {
        final list = jsonDecode(publishedRaw) as List<dynamic>;
        _publishedEvents
          ..clear()
          ..addAll(list.map((e) => _eventFromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    final requestsRaw = prefs.getString(_kVolunteerRequests);
    _volunteerRequests.clear();
    if (requestsRaw != null) {
      try {
        final list = jsonDecode(requestsRaw) as List<dynamic>;
        _volunteerRequests.addAll(
            list.map((e) => VolunteerRequest.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }

    await _bootstrapAuthSession();

    consumeLaunchVolunteerJoinToken();
    consumeLaunchEventJoinToken();

    AppColors.applyMode(false);

    _loaded = true;
    notifyListeners();
  }

  Future<void> _bootstrapAuthSession() async {
    if (!AppConfig.backendEnabled || !_auth.isReady) return;

    if (_auth.isSignedIn) {
      _authenticated = true;
      _userId = _auth.currentUser?.id;
      await _syncOnboardedFlagForUser();
      await _hydrateSessionFromBackend(
        emailFallback: _auth.currentUser?.email ?? _profile?.email ?? '',
        isNewSignUp: false,
      );
      await refreshAll();
    } else {
      _authenticated = false;
      _userId = null;
    }
  }

  /// Loads events, reservations, and gamification from the backend.
  Future<void> _syncEarnedBadgesInBackground(
    Map<String, dynamic> gamification,
  ) async {
    try {
      final synced = await _api.post('/gamification/sync-badges');
      if (synced is Map<String, dynamic>) {
        final badges = synced['badges'];
        if (badges is List) {
          _earnedBadgeIds
            ..clear()
            ..addAll(badges.map((b) => b.toString()));
          notifyListeners();
        }
      }
    } catch (_) {
      final badges = gamification['badges'];
      if (badges is List) {
        _earnedBadgeIds
          ..clear()
          ..addAll(badges.map((b) => b.toString()));
      }
    }
  }

  /// Loads events, reservations, and gamification from the backend.
  Future<void> refreshAll() async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      _useBackendData = false;
      return;
    }

    try {
      if (isDeanOfFaculty) {
        await refreshDeanData();
        _backendEvents
          ..clear()
          ..addAll(_deanFacultyEvents);
        _backendClubs
          ..clear()
          ..addAll(_deanFacultyClubs);
      } else {
        if (isAdmin) {
          await refreshAdminData();
        }
        final events = await _eventsRepo.list();
        _backendEvents
          ..clear()
          ..addAll(events);
      }

      final reservations = await _eventsRepo.myReservations();
      _eventReservations.clear();
      _joinedEventIds.clear();
      for (final row in reservations) {
        final eventId = row['event_id']?.toString();
        if (eventId == null) continue;
        _eventReservations[eventId] = row;
        if (row['reservation_status'] != 'cancelled') {
          _joinedEventIds.add(eventId);
        }
        if (row['reservation_status'] == 'checked_in') {
          _attendedAt[eventId] = DateTime.tryParse(
                row['checked_in_at']?.toString() ?? '') ??
              DateTime.now();
        }
      }

      if (_userId != null) {
        final gamification =
            await _gamificationRepo.ensureProfile(_userId!);
        if (gamification != null) {
          _gamificationRowId = gamification['id']?.toString();
          _points = (gamification['points'] as num?)?.toInt() ?? 0;
          final existing = gamification['badges'];
          if (existing is List) {
            _earnedBadgeIds
              ..clear()
              ..addAll(existing.map((b) => b.toString()));
          }
          unawaited(_syncEarnedBadgesInBackground(gamification));
        }
      }

      final parallel = await Future.wait<Object?>([
        _studySessionsRepo.list(),
        _studySessionMembershipRepo.listMine(),
        _shopRepo.listItems(),
        _shopRepo.listPurchasedItems(),
        _recommendationsRepo.listMine(),
        _clubMembershipRepo.listMine(),
        isDeanOfFaculty
            ? Future<List<dynamic>>.value(const [])
            : _clubsRepo.list(),
        _notificationsRepo.listMine(),
        _calendarRepo.listMine(),
        _studyPlansRepo.listMine(),
        _gamificationRepo.leaderboard(limit: 10),
        _badgesRepo.listDefinitions(),
        _clubsRepo.activityFeed(),
        _volunteeringOpportunitiesRepo.listOpen(),
        if (isStudentAffairs)
          _volunteeringOpportunitiesRepo.listAll()
        else
          Future<List<dynamic>>.value(const []),
        if (isStudent)
          _eventFeedbackRepo.listMine()
        else
          Future<List<Map<String, dynamic>>>.value(const []),
        if (isStudent)
          Future.wait([
            _volunteeringRepo.listMine(),
            _connectionsRepo.suggestions(),
            _connectionsRepo.listMine(),
            _studentProfilesRepo.mine(),
          ])
        else
          Future<List<dynamic>>.value(const []),
      ]);

      var i = 0;
      final sessions = parallel[i++] as List<StudySession>;
      _backendStudySessions
        ..clear()
        ..addAll(sessions);

      final sessionMemberships =
          parallel[i++] as List<Map<String, dynamic>>;
      _studySessionMembershipIds.clear();
      _joinedSessionIds.clear();
      for (final row in sessionMemberships) {
        final sessionId = row['study_session_id']?.toString();
        final membershipId = row['id']?.toString();
        if (sessionId == null) continue;
        _joinedSessionIds.add(sessionId);
        if (membershipId != null) {
          _studySessionMembershipIds[sessionId] = membershipId;
        }
      }

      final shopItems = parallel[i++] as List<dynamic>;
      _backendShopItems
        ..clear()
        ..addAll(shopItems.cast());

      final purchased = parallel[i++] as List<dynamic>;
      _ownedShopItemIds
        ..clear()
        ..addAll(purchased.map((item) => item.id));

      final recommendations = parallel[i++] as List<Map<String, dynamic>>;
      _recommendedEventIds
        ..clear()
        ..addAll(
          recommendations
              .where((row) => row['recommendation_type'] == 'event')
              .map((row) => row['target_id']?.toString())
              .whereType<String>(),
        );

      await _refreshStaffVolunteerQueue();
      if (isStudentAffairs || isDeanOfFaculty || isAdmin) {
        await _loadEventReviews();
      }

      final memberships = parallel[i++] as List<Map<String, dynamic>>;
      _clubMembershipIds.clear();
      _clubMemberRoles.clear();
      _joinedClubIds.clear();
      _ledClubIds.clear();
      for (final row in memberships) {
        final clubId = row['club_id']?.toString();
        final membershipId = row['id']?.toString();
        final role = row['role']?.toString() ?? 'member';
        if (clubId == null) continue;
        _joinedClubIds.add(clubId);
        _clubMemberRoles[clubId] = role;
        if (membershipId != null) {
          _clubMembershipIds[clubId] = membershipId;
        }
        if (role == 'lead') {
          _ledClubIds.add(clubId);
        }
      }

      if (isDeanOfFaculty) {
        _backendClubs
          ..clear()
          ..addAll(_deanFacultyClubs);
      } else {
        final clubs = parallel[i++] as List<Club>;
        _backendClubs
          ..clear()
          ..addAll(clubs.map((club) {
            if (_userId != null && club.organizerId == _userId) {
              _ledClubIds.add(club.id);
            }
            return club;
          }));
      }

      final notifications = parallel[i++] as List<AppNotification>;
      _notifications
        ..clear()
        ..addAll(notifications);

      final calendar = parallel[i++] as List<Map<String, dynamic>>;
      _backendCourses
        ..clear()
        ..addAll(
          calendar
              .where((row) => row['item_type'] == 'study')
              .map(ApiMappers.calendarCourse),
        );
      _backendDeadlines
        ..clear()
        ..addAll(
          calendar
              .where((row) =>
                  row['item_type'] == 'reminder' || row['item_type'] == 'event')
              .map(ApiMappers.calendarDeadline),
        );

      final studyPlans = parallel[i++] as List<Map<String, dynamic>>;
      _backendStudyPlans
        ..clear()
        ..addAll(studyPlans);
      _reloadStudyPlanCourses();

      final leaderboard = parallel[i++] as List<Map<String, dynamic>>;
      _leaderboardEntries
        ..clear()
        ..addAll(leaderboard.map(ApiMappers.leaderboardEntry));

      final badgeCatalog = parallel[i++] as List<AppBadge>;
      _badgeCatalog
        ..clear()
        ..addAll(badgeCatalog);

      final activityFeed = parallel[i++] as List<Map<String, String>>;
      _clubActivityFeed
        ..clear()
        ..addAll(activityFeed);

      final opportunities = parallel[i++] as List<dynamic>;
      _volunteeringOpportunities
        ..clear()
        ..addAll(opportunities.cast());

      final managedOpportunities = parallel[i++] as List<dynamic>;
      if (isStudentAffairs) {
        _managedVolunteerOpportunities
          ..clear()
          ..addAll(managedOpportunities.cast());
      }

      final feedbackRows = parallel[i++] as List<Map<String, dynamic>>;
      if (isStudent) {
        _eventFeedbackByEventId.clear();
        for (final row in feedbackRows) {
          final eventId = row['event_id']?.toString();
          if (eventId != null) {
            _eventFeedbackByEventId[eventId] = row;
          }
        }
      }

      final studentBundle = parallel[i++] as List<dynamic>;
      if (isStudent && studentBundle.isNotEmpty) {
        final mine = studentBundle[0] as List<VolunteerRequest>;
        _volunteerRequests
          ..clear()
          ..addAll(mine);
        _recomputeVolunteerHours();

        final suggestions = studentBundle[1] as List<dynamic>;
        _suggestedConnections
          ..clear()
          ..addAll(suggestions.cast());

        final connected = studentBundle[2] as List<dynamic>;
        _myConnections
          ..clear()
          ..addAll(connected.cast());
        _connectionIds
          ..clear()
          ..addAll(_myConnections.map((c) => c.id));

        unawaited(loadPeerInbox());

        final studentProfile =
            studentBundle[3] as Map<String, dynamic>?;
        _skillProgress = ApiMappers.skillsFromProfile(studentProfile);
        _semesterGoals = ApiMappers.goalsFromProfileAndPlans(
          studentProfile,
          studyPlans,
        );
        if (studentProfile != null && _profile != null) {
          final interests = (studentProfile['interests'] as List?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
          final summary =
              (studentProfile['profile_summary'] as String?)?.trim();
          final skillNames = _skillProgress
              .map((s) => s['name']?.toString())
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();
          _profile = _profile!.copyWith(
            interests: interests.isNotEmpty ? interests : null,
            bio: (summary != null && summary.isNotEmpty)
                ? summary
                : _profile!.bio,
            skills: skillNames.isNotEmpty ? skillNames : null,
          );
        }
      }

      // Club-founding requests: students see their own, reviewers see the queue.
      await _loadClubRequests();
      if (isStudent) {
        await refreshClubRequestEligibility();
      }

      _useBackendData = true;
    notifyListeners();
      await _save();
    } catch (_) {
      _useBackendData = false;
    }
  }

  /// Notifies listeners after auth forms finish — lets navigation complete
  /// before [MaterialApp] swaps away from the login stack.
  Future<void> finalizeAuth() async {
    _pendingAuthForm = null;
    _authFormInitialEmail = null;
    notifyListeners();
    unawaited(refreshAll());
  }

  /// Reloads club founding requests for the current role (review queue or mine).
  Future<void> refreshClubRequestQueue() async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }
    if (_profile == null) {
      await _hydrateProfileFromBackend();
    }
    try {
      await _loadClubRequests();
      if (isStudent) {
        await refreshClubRequestEligibility();
      }
      if (isStudentAffairs || isDeanOfFaculty || isAdmin) {
        await _loadEventReviews();
      }
      notifyListeners();
      await _save();
    } catch (_) {}
  }

  Future<void> _loadEventReviews() async {
    try {
      final reviews = await _eventsRepo.listReviewsAll();
      _eventReviewQueue
        ..clear()
        ..addAll(reviews);
    } catch (_) {}
  }

  Future<void> _loadClubRequests() async {
    try {
      final canReview =
          _canReviewClubRequests || await _resolveReviewerRoleFromBackend();
      if (canReview) {
        final queue = await _clubRequestsRepo.listAll();
        _clubRequestQueue
          ..clear()
          ..addAll(queue);
      } else {
        final mine = await _clubRequestsRepo.listMine();
        _myClubRequests
          ..clear()
          ..addAll(mine);
      }
    } catch (_) {
      // Do not fail the whole refresh if club requests are unavailable.
    }
  }

  Future<bool> _resolveReviewerRoleFromBackend() async {
    try {
      final me = await _api.get('/users/me');
      if (me is! Map<String, dynamic>) return false;
      final role = CampusEmail.roleFromBackend(me['role'] as String?);
      if (role != UserRole.studentAffairs &&
          role != UserRole.staff &&
          role != UserRole.deanOfFaculty &&
          role != UserRole.admin) {
        return false;
      }
      final email =
          (me['email'] as String?) ?? _auth.currentUser?.email ?? _profile?.email ?? '';
      _profile = (_profile ?? _profileFromEmail(email, role)).copyWith(
        role: role,
        email: email.isNotEmpty ? email : _profile?.email,
        name: (me['full_name'] as String?)?.trim().isNotEmpty == true
            ? me['full_name'] as String
            : _profile?.name,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void _upsertBackendClub(Club club) {
    final idx = _backendClubs.indexWhere((c) => c.id == club.id);
    if (idx >= 0) {
      _backendClubs[idx] = club;
    } else {
      _backendClubs.insert(0, club);
    }
  }

  void _upsertBackendEvent(Event event) {
    final idx = _backendEvents.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _backendEvents[idx] = event;
    } else {
      _backendEvents.insert(0, event);
    }
  }

  Future<void> _hydrateProfileFromBackend() async {
    await _hydrateSessionFromBackend(
      emailFallback: _auth.currentUser?.email ?? _profile?.email ?? '',
      isNewSignUp: false,
    );
  }

  /// Loads `/users/me` (+ student + Shams profile) and decides onboarding.
  Future<void> _hydrateSessionFromBackend({
    required String emailFallback,
    bool isNewSignUp = false,
  }) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }

    _userId = _auth.currentUser?.id;
    final email = _auth.currentUser?.email ?? emailFallback;

    try {
      await _api.post('/auth/provision', body: const <String, dynamic>{});
    } catch (_) {}

    Map<String, dynamic>? meRow;
    UserProfile? fetched;
    try {
      final result = await _api.get('/users/me');
      if (result is Map<String, dynamic>) {
        meRow = result;
        fetched = _mergeBackendProfile(result, email);
      }
    } catch (_) {}

    final role = fetched?.role ?? CampusEmail.guessRole(email);
    _profile = fetched ?? _profileFromEmail(email, role);

    final profileRow = _relationRow(meRow?['student_profiles']);
    if (profileRow != null) {
      _skillProgress = ApiMappers.skillsFromProfile(profileRow);
    }

    _onboarded = _resolveOnboarded(
      role: _profile!.role,
      isNewSignUp: isNewSignUp,
      meRow: meRow,
    );

    notifyListeners();
    await _save();
    unawaited(_maybePromoteAcademicYear());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAuthenticated, _authenticated);
    await prefs.setBool(_kOnboarded, _onboarded);
    if (_onboarded && _userId != null) {
      await prefs.setString(_kOnboardedUserId, _userId!);
    } else if (!_onboarded) {
      await prefs.remove(_kOnboardedUserId);
    }
    if (_profile != null) {
      await prefs.setString(_kProfile, jsonEncode(_profile!.toJson()));
    } else {
      await prefs.remove(_kProfile);
    }
    await prefs.setStringList(_kJoinedEvents, _joinedEventIds.toList());
    await prefs.setStringList(_kJoinedClubs, _joinedClubIds.toList());
    await prefs.setStringList(_kJoinedSessions, _joinedSessionIds.toList());
    await prefs.setStringList(_kEarnedBadges, _earnedBadgeIds.toList());
    await prefs.setStringList(_kCompletedGoals, _completedGoals.toList());
    await prefs.setInt(_kPoints, _points);
    await prefs.setInt(_kVolunteerHours, _volunteerHours);
    if (_cvUrl != null) {
      await prefs.setString(_kCvUrl, _cvUrl!);
    } else {
      await prefs.remove(_kCvUrl);
    }
    if (_cvFileName != null) {
      await prefs.setString(_kCvFileName, _cvFileName!);
    } else {
      await prefs.remove(_kCvFileName);
    }

    await prefs.setString(
      _kAttendedAt,
      jsonEncode(_attendedAt
          .map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
    await prefs.setStringList(_kOwnedShopItems, _ownedShopItemIds.toList());
    await prefs.setStringList(_kConnections, _connectionIds.toList());
    await prefs.setStringList(_kFavoriteEvents, _favoriteEventIds.toList());
    await prefs.setStringList(
        _kPublishedSessions, _publishedSessionIds.toList());
    await prefs.setStringList(_kCvPinnedEvents, _cvPinnedEventIds.toList());
    await prefs.setString(
      _kCustomSessions,
      jsonEncode(_customSessions.map(_sessionToJson).toList()),
    );
    await prefs.setString(
      _kCreatedClubs,
      jsonEncode(_createdClubs.map(_clubToJson).toList()),
    );
    await prefs.setStringList(_kLedClubs, _ledClubIds.toList());
    await prefs.setString(
      _kPublishedEvents,
      jsonEncode(_publishedEvents.map(_eventToJson).toList()),
    );
    await prefs.setString(
      _kVolunteerRequests,
      jsonEncode(_volunteerRequests.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _authenticated = true;
    _userId = _auth.currentUser?.id ?? _userId;
    _profile = profile.copyWith(role: _profile?.role ?? UserRole.student);
    try {
      await _persistOnboardingToBackend(_profile!);
    } catch (_) {
      // Provision is best-effort when Shams confirm already created profile rows.
    }
    try {
      await _persistStudentProfileFields(_profile!);
    } catch (_) {}
    _onboarded = true;
    notifyListeners();
    await _save();
    unawaited(refreshAll());
  }

  /// Finishes Shams NLP onboarding: confirms draft on backend, then saves locally.
  Future<String?> completeShamsOnboarding(UserProfile profile) async {
    var resolved = profile;
    var confirmedOnBackend = false;
    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final confirmed = await _profilingRepo.confirmDraft();
        final saved = confirmed['profile'];
        if (saved is Map<String, dynamic>) {
          resolved = _profileFromShamsConfirm(resolved, saved);
          _skillProgress = ApiMappers.skillsFromProfile(saved);
          final goals = (saved['goals'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
          if (goals != null && goals.isNotEmpty) {
            _semesterGoals = goals;
          }
          confirmedOnBackend = true;
        }
      } catch (e) {
        return 'Could not save your profile. Try again.';
      }
    }

    resolved = _mergeProfileSkills(resolved, profile.skills);

    _authenticated = true;
    _userId = _auth.currentUser?.id ?? _userId;
    _profile = resolved.copyWith(role: _profile?.role ?? UserRole.student);
    _syncProfileSkillsFromProgress();

    try {
      await _persistOnboardingToBackend(_profile!);
    } catch (_) {}

    try {
      await _persistStudentProfileFields(_profile!);
      _syncProfileSkillsFromProgress();
    } catch (_) {
      if (!confirmedOnBackend) {
        return 'Could not save your profile. Check that the backend is running, then try again.';
      }
    }

    _onboarded = true;
    notifyListeners();
    await _save();
    unawaited(refreshAll());
    return null;
  }

  /// Updates an existing profile via Shams NLP (logged-in students).
  Future<String?> completeShamsProfileUpdate(UserProfile profile) async {
    final current = _profile;
    if (current == null) return 'No profile loaded.';

    var resolved = profile.copyWith(
      email: current.email,
      role: current.role,
    );

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final confirmed = await _profilingRepo.confirmDraft();
        final saved = confirmed['profile'];
        if (saved is Map<String, dynamic>) {
          resolved = _profileFromShamsConfirm(resolved, saved).copyWith(
            email: current.email,
            role: current.role,
          );
          _skillProgress = ApiMappers.skillsFromProfile(saved);
          final goals = (saved['goals'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
          if (goals != null && goals.isNotEmpty) {
            _semesterGoals = goals;
          }
        }
      } catch (e) {
        return 'Could not save your profile. Try again.';
      }
    }

    resolved = _mergeProfileSkills(
      resolved,
      [...current.skills, ...profile.skills],
    );

    _profile = resolved;
    unawaited(_persistOnboardingToBackend(resolved));
    await _persistStudentProfileFields(resolved);
    _syncProfileSkillsFromProgress();
    notifyListeners();
    await _save();
    unawaited(refreshAll());
    return null;
  }

  /// Manual profile form save for logged-in students.
  Future<void> saveManualProfileUpdate(UserProfile profile) async {
    final current = _profile;
    if (current == null) return;

    final resolved = profile.copyWith(
      email: current.email,
      role: current.role,
    );
    _profile = resolved;
    notifyListeners();
    await _save();
    await _persistOnboardingToBackend(resolved);
    await _persistStudentProfileFields(resolved);
    await refreshAll();
  }

  List<Map<String, dynamic>> _strengthEntriesFromSkills(
    List<String> skills, {
    String note = 'From your profile setup',
  }) {
    return skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .map(
          (skill) => {
            'name': skill,
            'progress': 0.5,
            'note': note,
            'change': '',
          },
        )
        .toList();
  }

  static const _kYearRollover = 'aaura.academicYearRollover';

  String _skillKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), ' ');

  UserProfile _mergeProfileSkills(UserProfile profile, List<String> extra) {
    final merged = <String>[
      ...profile.skills,
      for (final skill in extra)
        if (skill.trim().isNotEmpty) skill.trim(),
    ];
    final seen = <String>{};
    final unique = <String>[];
    for (final skill in merged) {
      final key = _skillKey(skill);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(skill.trim());
    }
    if (unique.length == profile.skills.length &&
        unique.every((s) => profile.skills.any((p) => _skillKey(p) == _skillKey(s)))) {
      return profile;
    }
    return profile.copyWith(skills: unique);
  }

  List<Map<String, dynamic>> _mergedStrengthPayload(UserProfile profile) {
    final byName = <String, Map<String, dynamic>>{};
    for (final entry in _skillProgress) {
      final name = entry['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      byName[_skillKey(name)] = Map<String, dynamic>.from(entry);
    }
    for (final entry in _strengthEntriesFromSkills(profile.skills)) {
      final name = entry['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      byName.putIfAbsent(_skillKey(name), () => entry);
    }
    return byName.values.toList();
  }

  Future<void> _maybePromoteAcademicYear() async {
    if (!isStudent || _profile == null) return;
    final now = DateTime.now();
    if (now.month < 9) return;

    final prefs = await SharedPreferences.getInstance();
    final lastRollover = prefs.getInt(_kYearRollover) ?? 0;
    if (lastRollover >= now.year) return;

    final current = _yearToInt(_profile!.year);
    if (current == null || current >= 5) {
      await prefs.setInt(_kYearRollover, now.year);
      return;
    }

    final nextLabel = _yearLabel(current + 1);
    _profile = _profile!.copyWith(year: nextLabel);
    notifyListeners();

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        await _persistOnboardingToBackend(_profile!);
      } catch (_) {}
    }
    await prefs.setInt(_kYearRollover, now.year);
    await _save();
  }

  Future<void> _persistStudentProfileFields(UserProfile profile) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }

    final strengths = _mergedStrengthPayload(profile);
    final saved = await _studentProfilesRepo.upsertFields(
      interests: profile.interests,
      strengths: strengths.isNotEmpty ? strengths : null,
      profileSummary: profile.bio,
      confidence: 50,
    );
    if (saved != null) {
      _skillProgress = ApiMappers.skillsFromProfile(saved);
      final interests = (saved['interests'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];
      final summary = (saved['profile_summary'] as String?)?.trim();
      final savedSkillNames = _skillProgress
          .map((s) => s['name']?.toString())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      _profile = _profile?.copyWith(
        interests: interests.isNotEmpty ? interests : null,
        skills: savedSkillNames.isNotEmpty ? savedSkillNames : profile.skills,
        bio: (summary != null && summary.isNotEmpty) ? summary : _profile?.bio,
      );
      notifyListeners();
    }
  }

  UserProfile _profileFromShamsConfirm(
    UserProfile draft,
    Map<String, dynamic> saved,
  ) {
    final interests =
        (saved['interests'] as List?)?.map((e) => e.toString()).toList() ??
            draft.interests;
    final strengthsRaw = saved['strengths'] as List?;
    final strengths = strengthsRaw == null
        ? draft.skills
        : strengthsRaw
            .map((entry) {
              if (entry is Map && entry['name'] != null) {
                return entry['name'].toString();
              }
              return entry.toString();
            })
            .where((name) => name.isNotEmpty)
            .toList();
    final mergedSkills = _mergeProfileSkills(
      draft.copyWith(skills: strengths),
      draft.skills,
    ).skills;
    final summary = saved['profile_summary'] as String? ?? draft.bio;
    return draft.copyWith(
      interests: interests,
      skills: mergedSkills,
      bio: summary,
      quickTitle: mergedSkills.isNotEmpty ? mergedSkills.first : draft.quickTitle,
    );
  }

  /// Sign up a new user. Success navigates to Shams (students) via [finalizeAuth].
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return const SignUpResult.failed('Please enter your email and password.');
    }
    if (!CampusEmail.isValid(trimmedEmail)) {
      return SignUpResult.failed(CampusEmail.invalidMessage);
    }

    if (!AppConfig.backendEnabled || !_auth.isReady) {
      final err = await _legacySignUp(trimmedEmail, password);
      if (err != null) return SignUpResult.failed(err);
      return const SignUpResult.success();
    }

    final outcome =
        await _auth.signUp(email: trimmedEmail, password: password);
    if (outcome.needsEmailConfirmation) {
      return const SignUpResult.pendingEmail();
    }
    if (!outcome.success) {
      return SignUpResult.failed(
        outcome.error ?? 'Sign up failed. Please try again.',
      );
    }

    await _hydrateAfterAuth(
      emailFallback: trimmedEmail,
      isNewSignUp: true,
    );
    return const SignUpResult.success();
  }

  /// Returns null on success, or an error message.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return 'Please enter your email and password.';
    }
    if (!CampusEmail.isValid(trimmedEmail)) {
      return CampusEmail.invalidMessage;
    }

    if (!AppConfig.backendEnabled || !_auth.isReady) {
      return _legacySignIn(trimmedEmail, password);
    }

    final outcome =
        await _auth.signIn(email: trimmedEmail, password: password);
    if (!outcome.success) {
      return outcome.error ?? 'Sign in failed. Please try again.';
    }

    await _hydrateAfterAuth(
      emailFallback: trimmedEmail,
      isNewSignUp: false,
    );
    return null;
  }

  Future<void> _syncOnboardedFlagForUser() async {
    final prefs = await SharedPreferences.getInstance();
    final forUser = prefs.getString(_kOnboardedUserId);
    if (_userId == null || forUser != _userId) {
      _onboarded = false;
      return;
    }
    _onboarded = prefs.getBool(_kOnboarded) ?? false;
  }

  Future<void> _hydrateAfterAuth({
    required String emailFallback,
    required bool isNewSignUp,
  }) async {
    _clearAccountData();
    _authenticated = true;
    await _syncOnboardedFlagForUser();
    await _hydrateSessionFromBackend(
      emailFallback: emailFallback,
      isNewSignUp: isNewSignUp,
    );
    await refreshAll();
  }

  bool _resolveOnboarded({
    required UserRole role,
    required bool isNewSignUp,
    Map<String, dynamic>? meRow,
  }) {
    if (role != UserRole.student) return true;

    if (meRow != null && _hasCompletedStudentSetup(meRow)) {
      return true;
    }

    if (isNewSignUp) return false;

    return _onboarded;
  }

  bool _hasCompletedStudentSetup(Map<String, dynamic> me) {
    final student = _relationRow(me['students']);
    final major = (student?['major'] as String?)?.trim();
    if (major != null &&
        major.isNotEmpty &&
        major.toLowerCase() != 'undeclared') {
      return true;
    }

    final profile = _relationRow(me['student_profiles']);
    if (profile == null) return false;

    final summary = (profile['profile_summary'] as String?)?.trim();
    if (summary != null && summary.isNotEmpty) return true;

    final interests = profile['interests'];
    if (interests is List && interests.isNotEmpty) return true;

    final strengths = profile['strengths'];
    if (strengths is List && strengths.isNotEmpty) return true;

    return false;
  }

  Map<String, dynamic>? _relationRow(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List) {
      for (final entry in value) {
        if (entry is Map<String, dynamic>) return entry;
      }
    }
    return null;
  }

  Future<String?> _legacySignUp(String trimmedEmail, String password) async {
    final role = UserRole.fromEmailDomain(trimmedEmail);
    if (role == null) return CampusEmail.invalidMessage;
    _authenticated = true;
    _userId = null;
    _onboarded = !role.needsOnboardingOnSignUp;
    _profile = _profileFromEmail(trimmedEmail, role);
    notifyListeners();
    await _save();
    return null;
  }

  Future<String?> _legacySignIn(String trimmedEmail, String password) async {
    final role = UserRole.fromEmailDomain(trimmedEmail);
    if (role == null) return CampusEmail.invalidMessage;
    _authenticated = true;
    _onboarded = true;
    _profile = _profileFromEmail(trimmedEmail, role);
    notifyListeners();
    await _save();
    return null;
  }

  UserProfile _mergeBackendProfile(Map<String, dynamic> me, String email) {
    final role = CampusEmail.roleFromBackend(me['role'] as String?);
    final resolvedEmail = (me['email'] as String?) ?? email;
    final base = _profile ??
        _profileFromEmail(
          resolvedEmail.isEmpty ? 'user@student.aaup.edu' : resolvedEmail,
          role,
        );
    final backendName = (me['full_name'] as String?)?.trim();
    final student = _relationRow(me['students']);
    String? major;
    String? universityId;
    int? academicYear;
    if (student != null) {
      major = student['major'] as String?;
      universityId = student['university_id'] as String?;
      academicYear = student['academic_year'] is num
          ? (student['academic_year'] as num).toInt()
          : null;
    }

    final shamsProfile = _relationRow(me['student_profiles']);
    List<String> interests = base.interests;
    List<String> skills = base.skills;
    String? bio = base.bio;
    String? quickTitle = base.quickTitle;
    if (shamsProfile != null) {
      interests = (shamsProfile['interests'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          interests;
      final strengthsRaw = shamsProfile['strengths'] as List?;
      if (strengthsRaw != null && strengthsRaw.isNotEmpty) {
        skills = strengthsRaw
            .map((entry) {
              if (entry is Map && entry['name'] != null) {
                return entry['name'].toString();
              }
              return entry.toString();
            })
            .where((name) => name.isNotEmpty)
            .toList();
      }
      final summary = (shamsProfile['profile_summary'] as String?)?.trim();
      if (summary != null && summary.isNotEmpty) {
        bio = summary;
      }
      if (skills.isNotEmpty) {
        quickTitle = skills.first;
      }
    }

    return base.copyWith(
      role: role,
      email: resolvedEmail,
      name: (backendName != null && backendName.isNotEmpty)
          ? backendName
          : base.name,
      studentId: universityId ??
          (UniversityId.isValid(base.studentId) ? base.studentId : ''),
      major: major ?? base.major,
      year: academicYear != null ? _yearLabel(academicYear) : base.year,
      interests: interests,
      skills: skills,
      bio: bio,
      quickTitle: quickTitle,
      avatarUrl: (me['avatar_url'] as String?)?.trim().isNotEmpty == true
          ? me['avatar_url'] as String
          : base.avatarUrl,
      assignedFaculty: (me['assigned_faculty'] as String?)?.trim().isNotEmpty == true
          ? me['assigned_faculty'] as String
          : base.assignedFaculty,
    );
  }

  Future<void> _persistOnboardingToBackend(UserProfile profile) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }
    final name = profile.name.trim();
    final universityId = profile.studentId.trim();
    final major = profile.major.trim();
    final academicYear = _yearToInt(profile.year);
    await _api.post('/auth/provision', body: {
      if (name.length >= 3) 'fullName': name,
      if (universityId.length >= 3) 'universityId': universityId,
      if (major.length >= 2) 'major': major,
      'academicYear': ?academicYear,
    });
    if (name.length >= 3) {
      await _api.patch('/users/me', body: {'full_name': name});
    }
  }

  int? _yearToInt(String year) {
    final match = RegExp(r'\d+').firstMatch(year);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  String _yearLabel(int year) {
    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      case 5:
        return '5th Year';
      default:
        return 'Year $year';
    }
  }

  UserProfile _profileFromEmail(String email, UserRole role) {
    final localPart = email.split('@').first;
    final displayName = localPart
        .split(RegExp(r'[._-]'))
        .where((part) => part.isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');

    String majorFor(UserRole r) {
      switch (r) {
        case UserRole.deanOfFaculty:
          return 'Dean of Faculty';
        case UserRole.admin:
          return 'System Admin';
        case UserRole.studentAffairs:
        case UserRole.staff:
          return 'Student Affairs';
        case UserRole.student:
          return 'Undeclared';
      }
    }

    return UserProfile(
      name: displayName.isEmpty ? 'AAURA User' : displayName,
      studentId: '',
      major: majorFor(role),
      year: role == UserRole.student ? 'Year 1' : 'Campus staff',
      interests: const [],
      quickTitle: role.label,
      email: email,
      role: role,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
    _clearAccountData();
    notifyListeners();
    await _save();
  }

  void _clearAccountData() {
    _authenticated = false;
    _userId = null;
    _pendingAuthForm = null;
    _authFormInitialEmail = null;
    _profile = null;
    _onboarded = false;
    _joinedEventIds.clear();
    _joinedClubIds.clear();
    _joinedSessionIds.clear();
    _completedGoals.clear();
    _attendedAt.clear();
    _ownedShopItemIds.clear();
    _connectionIds.clear();
    _favoriteEventIds.clear();
    _publishedSessionIds.clear();
    _cvPinnedEventIds.clear();
    _customSessions.clear();
    _createdClubs.clear();
    _ledClubIds.clear();
    _publishedEvents.clear();
    _volunteerRequests.clear();
    _pendingVolunteerJoinToken = null;
    _pendingEventJoinToken = null;
    _earnedBadgeIds.clear();
    _points = 0;
    _volunteerHours = 0;
    _backendEvents.clear();
    _backendClubs.clear();
    _backendStudySessions.clear();
    _recommendedEventIds.clear();
    _eventReservations.clear();
    _notifications.clear();
    _backendCourses.clear();
    _backendDeadlines.clear();
    _backendStudyPlans.clear();
    _backendStudyPlanCourses.clear();
    _leaderboardEntries.clear();
    _volunteeringOpportunities.clear();
    _managedVolunteerOpportunities.clear();
    _backendShopItems.clear();
    _suggestedConnections.clear();
    _myConnections.clear();
    _peerConversations.clear();
    _peerMessagesByUserId.clear();
    _clubMemberRoles.clear();
    _skillProgress = [];
    _semesterGoals = [];
    _myClubRequests.clear();
    _clubRequestQueue.clear();
    _clubRequestEligibility = null;
    _cvUrl = null;
    _cvFileName = null;
    _studySessionMembershipIds.clear();
    _gamificationRowId = null;
    _clubMembershipIds.clear();
    _deanDashboard = null;
    _deanInsights = null;
    _deanFacultyEvents = [];
    _deanFacultyClubs = [];
    _deanAnnouncements = [];
    _deanLastError = null;
    _useBackendData = false;
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _save();
  }

  /// Persists an interest selection to the backend Shams profile (when
  /// authenticated) and mirrors it on the local profile for instant UI.
  Future<void> updateInterests(List<String> interests) async {
    final seen = <String>{};
    final unique = <String>[];
    for (final interest in interests) {
      final trimmed = interest.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) unique.add(trimmed);
    }
    final current = _profile;
    if (current != null) {
      _profile = current.copyWith(interests: unique);
      notifyListeners();
    }
    if (_useBackendData) {
      try {
        await _studentProfilesRepo.updateInterests(unique);
      } catch (_) {}
    }
    await _save();
  }

  bool isEventJoined(String id) => _joinedEventIds.contains(id);
  bool isClubJoined(String id) => _joinedClubIds.contains(id);
  bool isSessionJoined(String id) => _joinedSessionIds.contains(id);
  bool isGoalDone(String goal) => _completedGoals.contains(goal);
  bool isBadgeEarned(String id) => _earnedBadgeIds.contains(id);
  bool isShopItemOwned(String id) => _ownedShopItemIds.contains(id);
  bool isConnected(String id) => _connectionIds.contains(id);
  bool isEventFavorite(String id) => _favoriteEventIds.contains(id);
  bool isCvPinned(String id) => _cvPinnedEventIds.contains(id);

  Future<void> _refreshLeaderboard() async {
    if (!_useBackendData) return;
    try {
      final leaderboard = await _gamificationRepo.leaderboard(limit: 10);
      _leaderboardEntries
        ..clear()
        ..addAll(leaderboard.map(ApiMappers.leaderboardEntry));
    } catch (_) {}
  }

  Future<void> _boostSkillProgress(SkillActivityKind activity) async {
    if (!_useBackendData || _skillProgress.isEmpty) return;
    final changeLabel =
        '+${(activity.delta * 100).round()}% · ${activity.changeLabel}';
    _skillProgress = SkillProgressService.boost(
      _skillProgress,
      activity.delta,
      changeLabel,
    );
    notifyListeners();
    try {
      await _studentProfilesRepo.updateStrengths(
        SkillProgressService.toStrengthsPayload(_skillProgress),
      );
    } catch (_) {}
  }

  Future<void> _applyPointsDelta(int delta) async {
    if (delta == 0) return;
    if (_useBackendData && _gamificationRowId != null) {
      try {
        final row =
            await _gamificationRepo.addPoints(_gamificationRowId!, delta);
        if (row != null) {
          _points = (row['points'] as num?)?.toInt() ?? _points;
          await _refreshLeaderboard();
          notifyListeners();
          await _save();
          return;
        }
      } catch (_) {
        return;
      }
    }
    _points = (_points + delta).clamp(0, 999999);
    notifyListeners();
    await _save();
  }

  Future<void> toggleEventJoin(String id, {int rewardPoints = 0}) async {
    await toggleEventJoinResult(id, rewardPoints: rewardPoints);
  }

  /// Enrolls or cancels enrollment. Returns `null` on success, or an error message.
  Future<String?> toggleEventJoinResult(String id, {int rewardPoints = 0}) async {
    final joining = !_joinedEventIds.contains(id);

    if (_useBackendData && isBackendId(id)) {
      if (joining) {
        try {
          final row = await _eventsRepo.reserve(id);
          if (row == null) {
            return 'Could not enroll. Try again.';
          }
          _eventReservations[id] = row;
        } on ApiException catch (e) {
          return e.message.trim().isNotEmpty
              ? e.message.trim()
              : 'Could not enroll in this event.';
        } catch (_) {
          return 'Could not enroll. Check your connection and try again.';
        }
      } else {
        final reservation = _eventReservations[id];
        final reservationId = reservation?['id']?.toString();
        if (reservationId != null) {
          try {
            await _eventsRepo.cancelReservation(reservationId);
            _eventReservations.remove(id);
          } on ApiException catch (e) {
            return e.message.trim().isNotEmpty
                ? e.message.trim()
                : 'Could not cancel enrollment.';
          } catch (_) {
            return 'Could not cancel enrollment. Try again.';
          }
        }
      }
    }

    if (joining) {
      _joinedEventIds.add(id);
      if (!_useBackendData) {
        await _applyPointsDelta(rewardPoints);
      _attendedAt[id] = DateTime.now();
      } else {
        final existing = _eventReservations[id];
        if (existing == null) {
          _eventReservations[id] = {
            'event_id': id,
            'reservation_status': 'reserved',
            'reserved_at': DateTime.now().toUtc().toIso8601String(),
          };
        }
      }
      _cvPinnedEventIds.add(id);
      unawaited(_boostSkillProgress(SkillActivityKind.eventJoin));
      unawaited(loadEventAttendees(id));
    } else {
      _joinedEventIds.remove(id);
      _eventAttendeesByEventId.remove(id);
      if (!_useBackendData) {
        if (rewardPoints > 0) await _applyPointsDelta(-rewardPoints);
      _attendedAt.remove(id);
      }
      _cvPinnedEventIds.remove(id);
    }
    notifyListeners();
    await _save();
    return null;
  }

  /// Check in at an event using the reservation QR token (UUID).
  Future<Event?> checkInByQrToken(String qrToken) async {
    final trimmed = qrToken.trim();
    if (trimmed.isEmpty) return null;

    if (_useBackendData && isBackendId(trimmed)) {
      final result = await _eventsRepo.checkIn(trimmed);
      if (result == null) return null;
      final reservation = result['reservation'];
      if (reservation is! Map<String, dynamic>) return null;
      final eventId = reservation['event_id']?.toString();
      if (eventId == null) return null;

      _eventReservations[eventId] = reservation;
      _joinedEventIds.add(eventId);

      Event? event;
      for (final e in allEvents) {
        if (e.id == eventId) {
          event = e;
          break;
        }
      }
      event ??= await _eventsRepo.getById(eventId);
      if (event == null) return null;

      final wasAttended = _attendedAt.containsKey(eventId);
      _attendedAt[eventId] = DateTime.now();
      _cvPinnedEventIds.add(eventId);
      if (!wasAttended) {
        await _applyPointsDelta(event.points);
        unawaited(_boostSkillProgress(SkillActivityKind.eventCheckIn));
      }

      notifyListeners();
      await _save();
      return event;
    }

    return null;
  }

  Future<String?> applyToVolunteerOpportunity(
    VolunteerOpportunity opportunity,
  ) async {
    if (hasAppliedForVolunteerOpportunity(opportunity.id)) {
      return 'You already applied for this opportunity.';
    }

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final created = await _volunteeringRepo.create(
          title: opportunity.title,
          hours: opportunity.estimatedHours,
          occurredAt: DateTime.now(),
          opportunityId: opportunity.id,
        );
        if (created != null) {
          _volunteerRequests.insert(0, created);
          notifyListeners();
          await _save();
          return null;
        }
        return 'Could not submit application. Try again.';
      } on ApiException catch (e) {
        return e.message;
      } catch (_) {
        return 'Could not submit application. Try again.';
      }
    }

    final local = VolunteerRequest(
      id: 'vr-local-${DateTime.now().millisecondsSinceEpoch}',
      studentName: _profile?.name ?? 'You',
      studentId: _userId ?? 'local',
      hours: opportunity.estimatedHours.round(),
      eventTitle: opportunity.title,
      submittedAt: 'Just now',
      opportunityId: opportunity.id,
    );
    _volunteerRequests.insert(0, local);
    notifyListeners();
    await _save();
    return null;
  }

  /// Enrolls in an event using a shared join link / QR code.
  Future<String?> joinEventByToken(String input) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return 'Sign in to enroll in events.';
    }
    final token = JoinLinks.parseEventToken(input);
    if (token == null || token.isEmpty) {
      return 'Invalid event join link.';
    }
    try {
      final row = await _eventsRepo.reserveByJoinToken(token);
      if (row == null) {
        return 'Could not enroll. Try again.';
      }
      final eventId = row['event_id']?.toString();
      if (eventId != null) {
        _eventReservations[eventId] = row;
        _joinedEventIds.add(eventId);
        _cvPinnedEventIds.add(eventId);
        unawaited(_boostSkillProgress(SkillActivityKind.eventJoin));
        unawaited(loadEventAttendees(eventId));
      }
      _pendingEventJoinToken = null;
      notifyListeners();
      await _save();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not open event link.';
    }
  }

  Future<String?> applyToVolunteerOpportunityByToken(String input) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return 'Sign in to apply for volunteer opportunities.';
    }
    final token = JoinLinks.parseVolunteerToken(input);
    if (token == null || token.isEmpty) {
      return 'Invalid volunteer join link.';
    }
    try {
      final created =
          await _volunteeringOpportunitiesRepo.applyByJoinToken(token);
      if (created != null) {
        _volunteerRequests.insert(0, created);
        _pendingVolunteerJoinToken = null;
        notifyListeners();
        await _save();
        return null;
      }
      return 'Could not submit application. Try again.';
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not open volunteer link.';
    }
  }

  VolunteerOpportunity? volunteerOpportunityForEvent(String eventId) {
    for (final opp in _volunteeringOpportunities) {
      if (opp.eventId == eventId && opp.isOpen) return opp;
    }
    for (final opp in _managedVolunteerOpportunities) {
      if (opp.eventId == eventId && opp.isOpen) return opp;
    }
    return null;
  }

  bool hasAppliedForVolunteerOpportunity(String opportunityId) {
    return _volunteerRequests.any(
      (r) =>
          r.opportunityId == opportunityId &&
          r.status != VolunteerRequestStatus.rejected,
    );
  }

  bool isEnrolledInVolunteerOpportunity(String opportunityId) =>
      hasAppliedForVolunteerOpportunity(opportunityId);

  Future<void> refreshAdminData() async {
    if (!isAdmin ||
        !AppConfig.backendEnabled ||
        !_auth.isReady ||
        !_auth.isSignedIn) {
      return;
    }

    Future<void> load<T>(
      Future<T> Function() fetch,
      void Function(T value) store,
    ) async {
      try {
        store(await fetch());
      } catch (_) {
        // Keep other admin panels usable if one endpoint fails.
      }
    }

    await load(_adminRepo.fetchDashboard, (v) => _adminDashboard = v);
    await load(_adminRepo.fetchContent, (v) => _adminContent = v);
    await load(_adminRepo.fetchAnalytics, (v) => _adminAnalytics = v);
    await load(_adminRepo.fetchSettings, (v) => _adminSettings = v);
    await load(_adminRepo.fetchUsers, (v) => _adminUsers = v);
    await load(_adminRepo.fetchAuditLogs, (v) => _adminAuditLogs = v);
    await load(
      _adminRepo.fetchVolunteeringRecords,
      (v) => _adminVolunteeringRecords = v,
    );
    await load(_adminRepo.fetchBadges, (v) => _adminBadges = v);

    notifyListeners();
    await _save();
  }

  Future<String?> adminUpdateUser(
    String userId, {
    String? role,
    bool? isSuspended,
  }) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.updateUser(
        userId,
        role: role,
        isSuspended: isSuspended,
      );
      await refreshAdminData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not update user.';
    }
  }

  Future<String?> adminUpdateSettings(String key, Map<String, dynamic> value) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.updateSettings(key, value);
      await refreshAdminData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not save settings.';
    }
  }

  Future<String?> sendAdminAnnouncement({
    required String title,
    required String body,
  }) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      final sent = await _adminRepo.sendAnnouncement(title: title, body: body);
      if (sent == null || sent == 0) return 'No recipients found.';
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not send announcement.';
    }
  }

  Future<String?> adminModerateEvent(String eventId, String action) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.moderateEvent(eventId, action);
      if (action == 'hide' || action == 'cancel') {
        _backendEvents.removeWhere((e) => e.id == eventId);
      }
      await refreshAdminData();
      await refreshAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not moderate event.';
    }
  }

  Future<String?> adminModerateClub(String clubId, String action) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.moderateClub(clubId, action);
      await refreshAdminData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not moderate club.';
    }
  }

  Future<String?> adminModeratePost(String postId, {required bool hidden}) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.moderatePost(postId, hidden: hidden);
      await refreshAdminData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not moderate post.';
    }
  }

  Future<String?> adminModerateMessage(String messageId, {required bool hidden}) async {
    if (!isAdmin) return 'Admin access required.';
    try {
      await _adminRepo.moderateMessage(messageId, hidden: hidden);
      await refreshAdminData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not moderate message.';
    }
  }

  Future<void> refreshDeanData() async {
    if (!isDeanOfFaculty ||
        !AppConfig.backendEnabled ||
        !_auth.isReady ||
        !_auth.isSignedIn) {
      return;
    }
    _deanLastError = null;
    if (!deanHasFaculty) {
      _deanDashboard = null;
      _deanInsights = null;
      _deanFacultyEvents = [];
      _deanFacultyClubs = [];
      _deanAnnouncements = [];
      notifyListeners();
      return;
    }
    try {
      _deanDashboard = await _deanRepo.fetchDashboard();
      _deanInsights = await _deanRepo.fetchInsights();
      _deanFacultyEvents = await _deanRepo.fetchFacultyEvents();
      for (final event in _deanFacultyEvents) {
        _upsertBackendEvent(event);
      }
      _deanFacultyClubs = await _deanRepo.fetchFacultyClubs();
      _deanAnnouncements = await _deanRepo.fetchAnnouncements();
      _deanLastError = null;
      notifyListeners();
      await _save();
    } on ApiException catch (e) {
      _deanLastError = e.message;
      notifyListeners();
    } catch (_) {
      _deanLastError = 'Could not load faculty data.';
      notifyListeners();
    }
  }

  Future<String?> setAssignedFaculty(String faculty) async {
    if (!isDeanOfFaculty || !AppConfig.backendEnabled || !_auth.isReady) {
      return 'Dean profile required.';
    }
    try {
      await _api.patch('/users/me', body: {'assigned_faculty': faculty});
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(assignedFaculty: faculty);
      }
      notifyListeners();
      await refreshDeanData();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not save faculty.';
    }
  }

  Future<Map<String, dynamic>?> generateDeanReport(String type) async {
    if (!isDeanOfFaculty) return null;
    if (!deanHasFaculty) {
      _deanLastError = 'Select your faculty first.';
      notifyListeners();
      return null;
    }
    try {
      final report = await _deanRepo.fetchReport(type);
      _deanLastError = null;
      notifyListeners();
      return report;
    } on ApiException catch (e) {
      _deanLastError = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _deanLastError = 'Could not generate report.';
      notifyListeners();
      return null;
    }
  }

  Future<String?> sendDeanAnnouncement({
    required String title,
    required String body,
  }) async {
    if (!isDeanOfFaculty) return 'Dean access required.';
    if (!deanHasFaculty) return 'Select your faculty first.';
    try {
      final sent = await _deanRepo.sendAnnouncement(title: title, body: body);
      await refreshDeanData();
      if (sent == null || sent == 0) {
        return 'Announcement saved, but no students were found in your faculty.';
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not send announcement.';
    }
  }


  Future<VolunteerRequest?> submitVolunteerHours({
    required String title,
    required double hours,
    required DateTime occurredAt,
    String? opportunityId,
  }) async {
    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final created = await _volunteeringRepo.create(
          title: title,
          hours: hours,
          occurredAt: occurredAt,
          opportunityId: opportunityId,
        );
        if (created != null) {
          _volunteerRequests.insert(0, created);
          notifyListeners();
          await _save();
          return created;
        }
      } on ApiException catch (_) {
        return null;
      } catch (_) {
        return null;
      }
    }

    final local = VolunteerRequest(
      id: 'vr-local-${DateTime.now().millisecondsSinceEpoch}',
      studentName: _profile?.name ?? 'You',
      studentId: _userId ?? 'local',
      hours: hours.round(),
      eventTitle: title,
      submittedAt: 'Just now',
    );
    _volunteerRequests.insert(0, local);
    notifyListeners();
    await _save();
    return local;
  }

  Future<VolunteerOpportunity?> createVolunteerOpportunity({
    required String title,
    required String description,
    required String department,
    required double estimatedHours,
    required int slots,
  }) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return null;
    }
    if (!isStudentAffairs && !isDeanOfFaculty) return null;
    try {
      final created = await _volunteeringOpportunitiesRepo.create(
        ApiMappers.volunteerOpportunityToCreateBody(
          title: title,
          description: description,
          department: department,
          estimatedHours: estimatedHours,
          slots: slots,
        ),
      );
      if (created != null) {
        _managedVolunteerOpportunities.insert(0, created);
        if (created.isOpen) {
          _volunteeringOpportunities.insert(0, created);
        }
        notifyListeners();
        await _save();
      }
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateVolunteerOpportunity(
    String id, {
    String? title,
    String? description,
    String? department,
    double? estimatedHours,
    int? slots,
    String? status,
  }) async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return false;
    }
    if (!isStudentAffairs) return false;
    try {
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (department != null) 'department': department,
        if (estimatedHours != null) 'estimated_hours': estimatedHours,
        if (slots != null) 'slots': slots,
        if (status != null) 'status': status,
      };
      final updated = await _volunteeringOpportunitiesRepo.update(id, body);
      if (updated == null) return false;
      _upsertVolunteerOpportunity(updated);
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> closeVolunteerOpportunity(String id) =>
      updateVolunteerOpportunity(id, status: 'closed');

  Future<bool> reopenVolunteerOpportunity(String id) =>
      updateVolunteerOpportunity(id, status: 'open');

  Future<void> refreshVolunteerOpportunities() async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }
    try {
      final open = await _volunteeringOpportunitiesRepo.listOpen();
      _volunteeringOpportunities
        ..clear()
        ..addAll(open);
      if (isStudentAffairs) {
        final managed = await _volunteeringOpportunitiesRepo.listAll();
        _managedVolunteerOpportunities
          ..clear()
          ..addAll(managed);
      }
      notifyListeners();
      await _save();
    } catch (_) {}
  }

  void _upsertVolunteerOpportunity(VolunteerOpportunity opportunity) {
    void replaceIn(List<VolunteerOpportunity> list) {
      final idx = list.indexWhere((o) => o.id == opportunity.id);
      if (idx >= 0) {
        list[idx] = opportunity;
      } else {
        list.insert(0, opportunity);
      }
    }

    replaceIn(_managedVolunteerOpportunities);
    _volunteeringOpportunities.removeWhere((o) => o.id == opportunity.id);
    if (opportunity.isOpen) {
      _volunteeringOpportunities.insert(0, opportunity);
    }
  }

  Future<void> toggleCvPin(String id) async {
    if (!_cvPinnedEventIds.add(id)) {
      _cvPinnedEventIds.remove(id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> toggleClubJoin(String id) async {
    final joining = !_joinedClubIds.contains(id);
    if (isStudentAffairs && joining) return;

    if (_useBackendData && isBackendId(id)) {
      try {
        if (joining) {
          final row = await _clubMembershipRepo.join(id);
          if (row != null) {
            final membershipId = row['id']?.toString();
            if (membershipId != null) {
              _clubMembershipIds[id] = membershipId;
            }
          }
        } else {
          final membershipId = _clubMembershipIds[id];
          if (membershipId != null) {
            await _clubMembershipRepo.leave(membershipId);
            _clubMembershipIds.remove(id);
          }
          _ledClubIds.remove(id);
        }
      } catch (_) {
        return;
      }
    }

    if (joining) {
      _joinedClubIds.add(id);
    } else {
      _joinedClubIds.remove(id);
    }
    notifyListeners();
    await _save();
  }

  /// Loads chat history for a club channel from the backend.
  Future<void> loadClubMessages(Club club, String channelId) async {
    if (!_useBackendData || !isBackendId(club.id) || _userId == null) return;
    try {
      final messages = await _clubMessagesRepo.list(
        clubId: club.id,
        channelId: channelId,
        currentUserId: _userId!,
      );
      final key = '${club.id}#$channelId';
      _clubChat[key] = messages;
      notifyListeners();
    } catch (_) {}
  }

  /// Loads member roster for a club from the backend.
  Future<void> loadClubMembers(String clubId) async {
    if (!_useBackendData || !isBackendId(clubId)) return;
    try {
      final members = await _clubsRepo.listMembers(clubId);
      _clubMembersByClubId[clubId] = members;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadEventAttendees(String eventId) async {
    if (!_useBackendData || !isBackendId(eventId)) return;
    try {
      final rows = await _eventsRepo.listAttendees(eventId);
      _eventAttendeesByEventId[eventId] =
          rows.map(ApiMappers.campusPerson).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadStudySessionMembers(String sessionId) async {
    if (!_useBackendData || !isBackendId(sessionId)) return;
    try {
      final rows = await _studySessionMembershipRepo.listMembers(sessionId);
      _studySessionMembersBySessionId[sessionId] =
          rows.map(ApiMappers.campusPerson).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshNotifications() async {
    if (!_useBackendData) return;
    try {
      final notifications = await _notificationsRepo.listMine();
      _notifications
        ..clear()
        ..addAll(notifications);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPeerInbox() async {
    if (!_useBackendData || _userId == null) return;
    try {
      final inbox = await _peerMessagesRepo.listInbox(currentUserId: _userId!);
      _peerConversations
        ..clear()
        ..addAll(inbox);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPeerMessages(String userId, {bool markRead = true}) async {
    if (!_useBackendData || !isBackendId(userId)) return;
    try {
      final messages = await _peerMessagesRepo.listConversation(userId);
      _peerMessagesByUserId[userId] = messages;
      if (markRead) {
        await markPeerConversationRead(userId, refreshInbox: false);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markPeerConversationRead(
    String userId, {
    bool refreshInbox = true,
  }) async {
    if (!_useBackendData || !isBackendId(userId)) return;
    try {
      await _peerMessagesRepo.markConversationRead(userId);
      final idx = _peerConversations.indexWhere((c) => c.peerUserId == userId);
      if (idx >= 0) {
        final current = _peerConversations[idx];
        _peerConversations[idx] = PeerConversation(
          peerUserId: current.peerUserId,
          name: current.name,
          major: current.major,
          year: current.year,
          lastMessageBody: current.lastMessageBody,
          lastMessageAt: current.lastMessageAt,
          lastMessageIsMine: current.lastMessageIsMine,
          unreadCount: 0,
        );
      }
      for (var i = 0; i < _notifications.length; i++) {
        final notification = _notifications[i];
        if (notification.isMessage &&
            notification.peerUserId == userId &&
            !notification.isRead) {
          _notifications[i] = AppNotification(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            when: notification.when,
            type: notification.type,
            isRead: true,
            peerUserId: notification.peerUserId,
          );
        }
      }
      notifyListeners();
      if (refreshInbox) {
        await loadPeerInbox();
      }
    } catch (_) {}
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (!_useBackendData || !isBackendId(notificationId)) return;
    try {
      final updated = await _notificationsRepo.markRead(notificationId);
      if (updated == null) return;
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        _notifications[idx] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> sendPeerMessage(String userId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return false;
    if (_useBackendData && isBackendId(userId)) {
      try {
        final sent = await _peerMessagesRepo.send(
          recipientUserId: userId,
          body: trimmed,
        );
        if (sent != null) {
          final list = _peerMessagesByUserId.putIfAbsent(userId, () => []);
          list.add(sent);
          notifyListeners();
          unawaited(loadPeerInbox());
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void _recomputeVolunteerHours() {
    _volunteerHours = _volunteerRequests
        .where((r) =>
            r.status == VolunteerRequestStatus.approved && !r.isEnrollment)
        .fold<int>(0, (sum, r) => sum + r.hours);
  }

  /// Reloads volunteer submissions from the backend (student or staff view).
  Future<void> refreshVolunteerRecords() async {
    if (!AppConfig.backendEnabled || !_auth.isReady || !_auth.isSignedIn) {
      return;
    }
    try {
      if (canReviewVolunteerHours) {
        await _refreshStaffVolunteerQueue();
      } else if (isStudent) {
        final mine = await _volunteeringRepo.listMine();
        _volunteerRequests
          ..clear()
          ..addAll(mine);
        final opportunities = await _volunteeringOpportunitiesRepo.listOpen();
        _volunteeringOpportunities
          ..clear()
          ..addAll(opportunities);
        _recomputeVolunteerHours();
      } else {
        return;
      }
      notifyListeners();
      await _save();
    } catch (_) {}
  }

  Future<void> _refreshStaffVolunteerQueue() async {
    if (!canReviewVolunteerHours) return;
    try {
      final all = await _volunteeringRepo.listAll();
      _volunteerRequests
        ..clear()
        ..addAll(all);
      _recomputeVolunteerHours();
    } catch (_) {}
  }

  Future<void> _refreshConnections() async {
    if (!_useBackendData) return;
    try {
      final suggestions = await _connectionsRepo.suggestions();
      _suggestedConnections
        ..clear()
        ..addAll(suggestions);
      final connected = await _connectionsRepo.listMine();
      _myConnections
        ..clear()
        ..addAll(connected);
      _connectionIds
        ..clear()
        ..addAll(connected.map((c) => c.id));
      notifyListeners();
    } catch (_) {}
  }

  /// Loads organizer analytics (attendance + feedback) for an event.
  Future<Map<String, dynamic>?> loadEventAnalytics(String eventId) async {
    if (!_useBackendData || !isBackendId(eventId)) return null;
    try {
      return await _eventsRepo.getAnalytics(eventId);
    } catch (_) {
      return null;
    }
  }

  /// Submits star rating + optional comment for a joined event.
  Future<bool> submitEventFeedback({
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    if (!_useBackendData || !isBackendId(eventId)) return false;
    try {
      final row = await _eventFeedbackRepo.submit(
        eventId: eventId,
        rating: rating,
        comment: comment,
      );
      if (row != null) {
        _eventFeedbackByEventId[eventId] = row;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Session chat for a club channel, seeded from mock data on first access.
  List<ClubMessage> clubChat(Club club, String channelId) {
    final key = '${club.id}#$channelId';
    return _clubChat.putIfAbsent(
      key,
      () => <ClubMessage>[],
    );
  }

  Future<void> sendClubMessage(Club club, String channelId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final key = '${club.id}#$channelId';

    if (_useBackendData && isBackendId(club.id) && _userId != null) {
      try {
        final message = await _clubMessagesRepo.send(
          clubId: club.id,
          channelId: channelId,
          body: trimmed,
          currentUserId: _userId!,
        );
        if (message != null) {
          final list = _clubChat.putIfAbsent(key, () => <ClubMessage>[]);
          list.add(message);
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    final list = _clubChat.putIfAbsent(
      key,
      () => <ClubMessage>[],
    );
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    list.add(ClubMessage(
      id: '$key-${list.length}-${DateTime.now().millisecondsSinceEpoch}',
      author: _profile?.name ?? 'You',
      role: 'Member',
      text: trimmed,
      time: '$hh:$mm',
      isMe: true,
    ));
    notifyListeners();
  }

  Future<void> toggleSessionJoin(String id) async {
    final joining = !_joinedSessionIds.contains(id);

    if (_useBackendData && isBackendId(id)) {
      try {
        if (joining) {
          final row = await _studySessionMembershipRepo.join(id);
          if (row != null) {
            final membershipId = row['id']?.toString();
            if (membershipId != null) {
              _studySessionMembershipIds[id] = membershipId;
            }
          }
        } else {
          final membershipId = _studySessionMembershipIds[id];
          if (membershipId != null) {
            await _studySessionMembershipRepo.leave(membershipId);
            _studySessionMembershipIds.remove(id);
          }
        }
      } catch (_) {
        return;
      }
    }

    if (joining) {
      _joinedSessionIds.add(id);
      unawaited(_boostSkillProgress(SkillActivityKind.studySession));
      unawaited(loadStudySessionMembers(id));
    } else {
      _joinedSessionIds.remove(id);
      _studySessionMembersBySessionId.remove(id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> toggleGoal(String goal) async {
    if (_completedGoals.add(goal)) {
      unawaited(_boostSkillProgress(SkillActivityKind.goalComplete));
    } else {
      _completedGoals.remove(goal);
    }
    notifyListeners();
    await _save();
  }

  Future<void> addSemesterGoal(String text) async {
    final trimmed = text.trim();
    if (trimmed.length < 2 || _semesterGoals.contains(trimmed)) return;
    _semesterGoals = [..._semesterGoals, trimmed];
    notifyListeners();
    await _persistSemesterGoals();
  }

  Future<void> updateSemesterGoal(String oldGoal, String newGoal) async {
    final trimmed = newGoal.trim();
    if (trimmed.length < 2) return;
    final idx = _semesterGoals.indexOf(oldGoal);
    if (idx == -1) return;
    _semesterGoals = [..._semesterGoals]..[idx] = trimmed;
    if (_completedGoals.remove(oldGoal)) {
      _completedGoals.add(trimmed);
    }
    notifyListeners();
    await _persistSemesterGoals();
  }

  Future<void> removeSemesterGoal(String goal) async {
    _semesterGoals = _semesterGoals.where((g) => g != goal).toList();
    _completedGoals.remove(goal);
    notifyListeners();
    await _persistSemesterGoals();
  }

  Future<void> _persistSemesterGoals() async {
    if (_useBackendData) {
      try {
        await _studentProfilesRepo.updateGoals(_semesterGoals);
      } catch (_) {}
    }
    await _save();
  }

  Future<bool> updateSkillAt(
    int index, {
    String? name,
  }) async {
    if (index < 0 || index >= _skillProgress.length) return false;
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.length < 2) return false;

    final next = List<Map<String, dynamic>>.from(_skillProgress);
    next[index] = {
      ...next[index],
      'name': trimmed,
    };
    _skillProgress = next;
    _syncProfileSkillsFromProgress();
    notifyListeners();

    if (_useBackendData) {
      try {
        final profile = await _studentProfilesRepo.updateStrengths(
          SkillProgressService.toStrengthsPayload(_skillProgress),
        );
        if (profile != null) {
          _skillProgress = ApiMappers.skillsFromProfile(profile);
          _syncProfileSkillsFromProgress();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    await _save();
    return true;
  }

  Future<bool> deleteSkillAt(int index) async {
    if (index < 0 || index >= _skillProgress.length) return false;
    final next = List<Map<String, dynamic>>.from(_skillProgress)..removeAt(index);
    _skillProgress = next;
    _syncProfileSkillsFromProgress();
    notifyListeners();

    if (_useBackendData) {
      try {
        final profile = await _studentProfilesRepo.updateStrengths(
          SkillProgressService.toStrengthsPayload(_skillProgress),
        );
        if (profile != null) {
          _skillProgress = ApiMappers.skillsFromProfile(profile);
          _syncProfileSkillsFromProgress();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    await _save();
    return true;
  }

  Future<void> toggleConnection(String id) async {
    final connecting = !_connectionIds.contains(id);

    if (_useBackendData && isBackendId(id)) {
      try {
        if (connecting) {
          await _connectionsRepo.connect(id);
        } else {
          await _connectionsRepo.disconnect(id);
          _peerMessagesByUserId.remove(id);
          _peerConversations.removeWhere((c) => c.peerUserId == id);
        }
        await _refreshConnections();
        await _save();
        return;
      } catch (_) {
        return;
      }
    }

    if (connecting) {
      _connectionIds.add(id);
    } else {
      _connectionIds.remove(id);
      _peerMessagesByUserId.remove(id);
      _peerConversations.removeWhere((c) => c.peerUserId == id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> toggleFavoriteEvent(String id) async {
    if (!_favoriteEventIds.add(id)) {
      _favoriteEventIds.remove(id);
    }
    notifyListeners();
    await _save();
  }

  /// Returns true on success; false if not enough points or already owned.
  Future<bool> purchaseShopItem(ShopItem item) async {
    if (_ownedShopItemIds.contains(item.id)) return false;
    if (_points < item.cost) return false;

    if (_useBackendData) {
      try {
        final nextPoints = await _shopRepo.purchase(item.id);
        if (nextPoints != null) {
          _points = nextPoints;
          _ownedShopItemIds.add(item.id);
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
    }

    await _applyPointsDelta(-item.cost);
    _ownedShopItemIds.add(item.id);
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> publishStudySession(StudySession session) async {
    final startsAt =
        session.startsAt ?? DateTime.now().add(const Duration(days: 1));
    final endsAt = session.endsAt ?? startsAt.add(const Duration(hours: 2));

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final created = await _studySessionsRepo.create(
          title: session.course,
          topic: session.details,
          startsAt: startsAt,
          endsAt: endsAt,
          capacity: session.seatsLeft,
          location: 'Campus library',
        );
        if (created != null) {
          _backendStudySessions.insert(0, created);
          _publishedSessionIds.add(created.id);
          _joinedSessionIds.add(created.id);
          _useBackendData = true;
    notifyListeners();
    await _save();
          return;
        }
      } catch (_) {}
    }

    final local = session.copyWith(
      startsAt: startsAt,
      endsAt: endsAt,
      when: _formatSessionWhen(startsAt),
    );
    _customSessions.insert(0, local);
    _publishedSessionIds.add(local.id);
    _joinedSessionIds.add(local.id);
    notifyListeners();
    await _save();
  }

  Future<bool> updateStudySession(
    StudySession session, {
    required DateTime startsAt,
    required DateTime endsAt,
    String? title,
    String? details,
    int? capacity,
    bool applyCapacity = false,
  }) async {
    if (_useBackendData && isBackendId(session.id)) {
      try {
        final updated = await _studySessionsRepo.update(
          id: session.id,
          title: title ?? session.course,
          topic: details ?? session.details,
          startsAt: startsAt,
          endsAt: endsAt,
          capacity: capacity,
          applyCapacity: applyCapacity,
        );
        if (updated != null) {
          final idx =
              _backendStudySessions.indexWhere((s) => s.id == session.id);
          if (idx >= 0) {
            _backendStudySessions[idx] = updated;
          }
          await _studySessionsRepo.notifyMembers(
            id: session.id,
            title: 'Study session updated',
            body:
                '${updated.course} is now scheduled for ${updated.when}. Open Academics to review.',
          );
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
    }

    final idx = _customSessions.indexWhere((s) => s.id == session.id);
    if (idx == -1) return false;
    _customSessions[idx] = session.copyWith(
      course: title ?? session.course,
      details: details ?? session.details,
      seatsLeft: applyCapacity ? capacity : session.seatsLeft,
      startsAt: startsAt,
      endsAt: endsAt,
      when: _formatSessionWhen(startsAt),
    );
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> deleteStudySession(StudySession session) async {
    if (_useBackendData && isBackendId(session.id)) {
      try {
        await _studySessionsRepo.notifyMembers(
          id: session.id,
          title: 'Study session cancelled',
          body: '${session.course} on ${session.when} was cancelled by the host.',
          kind: 'cancelled',
        );
        await _studySessionsRepo.delete(session.id);
        _backendStudySessions.removeWhere((s) => s.id == session.id);
        _joinedSessionIds.remove(session.id);
        _publishedSessionIds.remove(session.id);
        notifyListeners();
        await _save();
        return true;
      } catch (_) {
        return false;
      }
    }

    _customSessions.removeWhere((s) => s.id == session.id);
    _joinedSessionIds.remove(session.id);
    _publishedSessionIds.remove(session.id);
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> addCalendarDeadline({
    required String title,
    required DateTime dueAt,
  }) async {
    if (canManagePlanner) {
      try {
        final row = await _calendarRepo.create(
          title: title,
          itemType: 'reminder',
          startsAt: dueAt,
        );
        if (row != null) {
          _backendDeadlines.insert(0, ApiMappers.calendarDeadline(row));
          _useBackendData = true;
          notifyListeners();
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> addCalendarCourse({
    required String title,
    required DateTime startsAt,
  }) async {
    if (canManagePlanner) {
      try {
        final row = await _calendarRepo.create(
          title: title,
          itemType: 'study',
          startsAt: startsAt,
        );
        if (row != null) {
          _backendCourses.insert(0, ApiMappers.calendarCourse(row));
          _useBackendData = true;
          notifyListeners();
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> generateStudyPlan({required String focusCourse}) async {
    if (!_useBackendData || !_auth.isReady || !_auth.isSignedIn) return false;
    final trimmed = focusCourse.trim();
    if (trimmed.length < 2) return false;

    final goals = _semesterGoals.isNotEmpty
        ? _semesterGoals
        : ['Stay on top of $trimmed', 'Join one study session each week'];

    final schedule = <Map<String, String>>[
      {
        'code': trimmed.length >= 6 ? trimmed.substring(0, 6).toUpperCase() : 'CRS',
        'title': trimmed,
        'next': 'Mon 4:00 PM',
      },
      {
        'code': 'REV',
        'title': '$trimmed review block',
        'next': 'Wed 6:00 PM',
      },
    ];

    try {
      final plan = await _studyPlansRepo.create(
        title: '$trimmed study plan',
        goals: goals,
        schedule: schedule,
        source: 'ai',
      );
      if (plan == null) return false;
      _backendStudyPlans.insert(0, plan);
      _reloadStudyPlanCourses();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _reloadStudyPlanCourses() {
    _backendStudyPlanCourses
      ..clear()
      ..addAll(_backendStudyPlans.expand(ApiMappers.studyPlanCourses));
  }

  Future<bool> updateCalendarDeadline({
    required String id,
    required String title,
    required DateTime dueAt,
  }) async {
    if (!canManagePlanner) return false;
    try {
      final row = await _calendarRepo.update(id, title: title, startsAt: dueAt);
      if (row == null) return false;
      final mapped = ApiMappers.calendarDeadline(row);
      final idx = _backendDeadlines.indexWhere((d) => d['id'] == id);
      if (idx >= 0) {
        _backendDeadlines[idx] = mapped;
      } else {
        _backendDeadlines.insert(0, mapped);
      }
      _useBackendData = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCalendarCourse({
    required String id,
    required String title,
    required DateTime startsAt,
  }) async {
    if (!canManagePlanner) return false;
    try {
      final row =
          await _calendarRepo.update(id, title: title, startsAt: startsAt);
      if (row == null) return false;
      final mapped = ApiMappers.calendarCourse(row);
      final idx = _backendCourses.indexWhere((c) => c['id'] == id);
      if (idx >= 0) {
        _backendCourses[idx] = mapped;
      } else {
        _backendCourses.insert(0, mapped);
      }
      _useBackendData = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCalendarDeadline(String id) async {
    if (!canManagePlanner) return false;
    try {
      await _calendarRepo.delete(id);
      _backendDeadlines.removeWhere((d) => d['id'] == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCalendarCourse(String id) async {
    if (!canManagePlanner) return false;
    try {
      await _calendarRepo.delete(id);
      _backendCourses.removeWhere((c) => c['id'] == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStudyPlanCourse({
    required String planId,
    required int entryIndex,
    required String title,
    required String next,
  }) async {
    if (!canManagePlanner) return false;
    final planIdx =
        _backendStudyPlans.indexWhere((p) => p['id']?.toString() == planId);
    if (planIdx < 0) return false;
    final plan = Map<String, dynamic>.from(_backendStudyPlans[planIdx]);
    final scheduleRaw = plan['schedule'];
    if (scheduleRaw is! List ||
        entryIndex < 0 ||
        entryIndex >= scheduleRaw.length) {
      return false;
    }
    final schedule = scheduleRaw.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'title': e.toString()};
    }).toList();
    final entry = Map<String, dynamic>.from(schedule[entryIndex]);
    entry['title'] = title;
    entry['next'] = next;
    if (entry['code'] == null || entry['code'].toString().isEmpty) {
      entry['code'] =
          title.length >= 6 ? title.substring(0, 6).toUpperCase() : 'CRS';
    }
    schedule[entryIndex] = entry;
    try {
      final updated =
          await _studyPlansRepo.update(planId, schedule: schedule);
      if (updated == null) return false;
      _backendStudyPlans[planIdx] = updated;
      _reloadStudyPlanCourses();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStudyPlanCourse({
    required String planId,
    required int entryIndex,
  }) async {
    if (!canManagePlanner) return false;
    final planIdx =
        _backendStudyPlans.indexWhere((p) => p['id']?.toString() == planId);
    if (planIdx < 0) return false;
    final plan = Map<String, dynamic>.from(_backendStudyPlans[planIdx]);
    final scheduleRaw = plan['schedule'];
    if (scheduleRaw is! List ||
        entryIndex < 0 ||
        entryIndex >= scheduleRaw.length) {
      return false;
    }
    final schedule = scheduleRaw.toList()..removeAt(entryIndex);
    try {
      final updated =
          await _studyPlansRepo.update(planId, schedule: schedule);
      if (updated == null) return false;
      _backendStudyPlans[planIdx] = updated;
      _reloadStudyPlanCourses();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addManualSkill(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 2) return false;

    if (_skillProgress.any(
      (skill) => _skillKey(skill['name']?.toString() ?? '') == _skillKey(trimmed),
    )) {
      return false;
    }

    final next = {
      'name': trimmed,
      'progress': 0.15,
      'note': 'Added from your profile',
      'change': '+ new',
    };

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final existing = List<Map<String, dynamic>>.from(_skillProgress);
        existing.add(next);
        final strengths = existing
            .map((skill) => {
                  'name': skill['name'],
                  'progress': skill['progress'],
                  'note': skill['note'],
                  'change': skill['change'],
                })
            .toList();
        final profile = await _studentProfilesRepo.updateStrengths(strengths);
        if (profile != null) {
          _skillProgress = ApiMappers.skillsFromProfile(profile);
          _syncProfileSkillsFromProgress();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
    }

    _skillProgress = [..._skillProgress, next];
    _syncProfileSkillsFromProgress();
    notifyListeners();
    await _save();
    return true;
  }

  String _formatSessionWhen(DateTime dt) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final day = weekdays[dt.weekday - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $hour:$minute $suffix';
  }

  /// Creates a club. Returns the new id, or null if the backend rejected it.
  Future<String?> createClub({
    required String name,
    required String description,
    required String focus,
    required ClubCategory category,
    List<String> roles = const [],
  }) async {
    if (isStudentAffairs) {
      return null;
    }
    final bodyDescription = focus.trim().isEmpty
        ? description
        : '$description\n\nFocus: $focus';

    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final created = await _clubsRepo.create(
          name: name.trim(),
          description: bodyDescription.trim(),
        );
        if (created != null) {
          try {
            final membership =
                await _clubMembershipRepo.join(created.id, role: 'lead');
            final membershipId = membership?['id']?.toString();
            if (membershipId != null) {
              _clubMembershipIds[created.id] = membershipId;
            }
          } catch (_) {}
          final enriched = created.copyWith(
            focus: focus,
            category: category,
            roles: roles,
            members: 1,
          );
          _upsertBackendClub(enriched);
          _joinedClubIds.add(created.id);
          _ledClubIds.add(created.id);
          _useBackendData = true;
          notifyListeners();
          await _save();
          return created.id;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 403) return null;
      } catch (_) {}
    }

    final id = 'club-user-${DateTime.now().millisecondsSinceEpoch}';
    final club = Club(
      id: id,
      name: name,
      description: description,
      focus: focus,
      members: 1,
      eventsHeld: 0,
      activityLevel: ClubActivityLevel.active,
      category: category,
      roles: roles,
    );
    _createdClubs.insert(0, club);
    _ledClubIds.add(id);
    _joinedClubIds.add(id);
    notifyListeners();
    await _save();
    return id;
  }

  /// Updates a backend club (organizer / admin). Returns false on failure.
  Future<bool> updateClub(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    if (!_useBackendData || !isBackendId(id) || !isClubLeader(id)) {
      return false;
    }
    try {
      final updated = await _clubsRepo.update(
        id,
        name: name,
        description: description,
        isActive: isActive,
      );
      if (updated == null) return false;
      final existing = clubById(id);
      _upsertBackendClub(updated.copyWith(
        focus: existing?.focus ?? updated.focus,
        category: existing?.category ?? updated.category,
        roles: existing?.roles ?? updated.roles,
      ));
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deactivates a backend club (soft delete via is_active=false).
  Future<bool> deactivateClub(String id) => updateClub(id, isActive: false);

  Future<Event?> publishEvent(Event event) async {
    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn) {
      try {
        final (startsAt, endsAt) = _eventScheduleFrom(event);
        final created = await _eventsRepo.create(
          ApiMappers.eventToCreateBody(
            event,
            startsAt: startsAt,
            endsAt: endsAt,
          ),
        );
        if (created != null) {
          Event saved = created;
          try {
            final prediction =
                await _eventsRepo.predictSuccess(created.id);
            final eventRow = prediction?['event'];
            if (eventRow is Map<String, dynamic>) {
              saved = ApiMappers.event(eventRow);
            }
          } catch (_) {}
          _upsertBackendEvent(saved);
          _useBackendData = true;
          if (isDeanOfFaculty) {
            unawaited(refreshDeanData());
          }
          notifyListeners();
          await _save();
          return saved;
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        return null;
      }
      return null;
    }

    _publishedEvents.insert(0, event);
    notifyListeners();
    await _save();
    return event;
  }

  (DateTime, DateTime) _eventScheduleFrom(Event event) {
    // Prefer the real schedule chosen in the create/edit form.
    if (event.startsAt != null) {
      final start = event.startsAt!;
      final end = event.endsAt ?? start.add(const Duration(hours: 2));
      return (start, end.isAfter(start) ? end : start.add(const Duration(hours: 2)));
    }
    final startsAt = DateTime.now().add(const Duration(days: 7));
    final durationHours =
        int.tryParse(RegExp(r'\d+').firstMatch(event.duration)?.group(0) ?? '') ??
            2;
    final endsAt = startsAt.add(Duration(hours: durationHours));
    return (startsAt, endsAt);
  }

  Future<Event?> updateEvent(Event event) async {
    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn &&
        isBackendId(event.id)) {
      try {
        final (startsAt, endsAt) = _eventScheduleFrom(event);
        final updated = await _eventsRepo.update(
          event.id,
          ApiMappers.eventToUpdateBody(
            event,
            startsAt: startsAt,
            endsAt: endsAt,
          ),
        );
        if (updated != null) {
          _upsertBackendEvent(updated);
          _useBackendData = true;
          if (isDeanOfFaculty) {
            unawaited(refreshDeanData());
          }
          notifyListeners();
          await _save();
          return updated;
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        return null;
      }
      return null;
    }

    final idx = _publishedEvents.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _publishedEvents[idx] = event;
    } else {
      _publishedEvents.insert(0, event);
    }
    notifyListeners();
    await _save();
    return event;
  }

  Future<bool> deleteEvent(String id) async {
    if (AppConfig.backendEnabled && _auth.isReady && _auth.isSignedIn &&
        isBackendId(id)) {
      try {
        await _eventsRepo.delete(id);
        _backendEvents.removeWhere((event) => event.id == id);
        _joinedEventIds.remove(id);
        _attendedAt.remove(id);
        _favoriteEventIds.remove(id);
        _cvPinnedEventIds.remove(id);
        _eventReservations.remove(id);
        notifyListeners();
        await _save();
        return true;
      } catch (_) {
        return false;
      }
    }

    _publishedEvents.removeWhere((event) => event.id == id);
    _joinedEventIds.remove(id);
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> approveVolunteerRequest(String id, {String? note}) async {
    final idx = _volunteerRequests.indexWhere((r) => r.id == id);
    if (idx == -1) return false;
    final req = _volunteerRequests[idx];

    if (AppConfig.backendEnabled &&
        _auth.isReady &&
        _auth.isSignedIn &&
        isBackendId(id)) {
      try {
        final updated =
            await _volunteeringRepo.approve(id, approvalNote: note);
        if (updated != null) {
          _volunteerRequests[idx] = updated;
          _recomputeVolunteerHours();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
      return false;
    }

    if (req.status != VolunteerRequestStatus.approved && !req.isEnrollment) {
      _volunteerHours += req.hours;
    }
    _volunteerRequests[idx] = req.copyWith(
      status: VolunteerRequestStatus.approved,
      approvalNote: note,
    );
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> rejectVolunteerRequest(String id, {String? note}) async {
    final idx = _volunteerRequests.indexWhere((r) => r.id == id);
    if (idx == -1) return false;
    final req = _volunteerRequests[idx];

    if (AppConfig.backendEnabled &&
        _auth.isReady &&
        _auth.isSignedIn &&
        isBackendId(id)) {
      try {
        final updated =
            await _volunteeringRepo.reject(id, approvalNote: note);
        if (updated != null) {
          _volunteerRequests[idx] = updated;
          _recomputeVolunteerHours();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
      return false;
    }

    if (req.status == VolunteerRequestStatus.approved && !req.isEnrollment) {
      _volunteerHours = (_volunteerHours - req.hours).clamp(0, 999999);
    }
    _volunteerRequests[idx] = req.copyWith(
      status: VolunteerRequestStatus.rejected,
      approvalNote: note,
    );
    notifyListeners();
    await _save();
    return true;
  }

  /// Staff: revert an approved/rejected decision back to pending review.
  Future<bool> withdrawVolunteerDecision(String id) async {
    final idx = _volunteerRequests.indexWhere((r) => r.id == id);
    if (idx == -1) return false;
    final req = _volunteerRequests[idx];
    if (req.status == VolunteerRequestStatus.pending) return true;

    if (AppConfig.backendEnabled &&
        _auth.isReady &&
        _auth.isSignedIn &&
        isBackendId(id)) {
      try {
        final updated = await _volunteeringRepo.withdraw(id);
        if (updated != null) {
          _volunteerRequests[idx] = updated;
          _recomputeVolunteerHours();
          notifyListeners();
          await _save();
          return true;
        }
      } catch (_) {
        return false;
      }
      return false;
    }

    if (req.status == VolunteerRequestStatus.approved && !req.isEnrollment) {
      _volunteerHours = (_volunteerHours - req.hours).clamp(0, 999999);
    }
    _volunteerRequests[idx] = req.copyWith(
      status: VolunteerRequestStatus.pending,
      approvalNote: null,
    );
    notifyListeners();
    await _save();
    return true;
  }

  /// Enrolled / joined events (reservation or local join), most-recent first.
  List<({Event event, DateTime at})> joinedEventsSorted() {
    final out = <({Event event, DateTime at})>[];
    for (final id in _joinedEventIds) {
      final matches = allEvents.where((e) => e.id == id);
      if (matches.isEmpty) continue;
      final reservation = _eventReservations[id];
      final at = _attendedAt[id] ??
          DateTime.tryParse(reservation?['reserved_at']?.toString() ?? '') ??
          DateTime.tryParse(reservation?['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      out.add((event: matches.first, at: at));
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  /// Attended events (with timestamps), most-recent first, joined onto
  /// the master Event list.
  List<({Event event, DateTime at})> attendedEventsSorted() {
    final out = <({Event event, DateTime at})>[];
    for (final id in _attendedAt.keys) {
      final ev = allEvents.where((e) => e.id == id);
      if (ev.isNotEmpty) {
        out.add((event: ev.first, at: _attendedAt[id]!));
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  Future<void> resetAll() async {
    _authenticated = false;
    _onboarded = false;
    _profile = null;
    _joinedEventIds.clear();
    _joinedClubIds.clear();
    _joinedSessionIds.clear();
    _completedGoals.clear();
    _attendedAt.clear();
    _ownedShopItemIds.clear();
    _connectionIds.clear();
    _favoriteEventIds.clear();
    _publishedSessionIds.clear();
    _cvPinnedEventIds.clear();
    _customSessions.clear();
    _createdClubs.clear();
    _ledClubIds.clear();
    _publishedEvents.clear();
    _volunteerRequests.clear();
    _pendingVolunteerJoinToken = null;
    _pendingEventJoinToken = null;
    _earnedBadgeIds.clear();
    _points = 0;
    _volunteerHours = 0;
    _backendEvents.clear();
    _backendClubs.clear();
    _backendStudySessions.clear();
    _recommendedEventIds.clear();
    _eventReservations.clear();
    _notifications.clear();
    _backendCourses.clear();
    _backendDeadlines.clear();
    _backendStudyPlans.clear();
    _backendStudyPlanCourses.clear();
    _leaderboardEntries.clear();
    _volunteeringOpportunities.clear();
    _managedVolunteerOpportunities.clear();
    _backendShopItems.clear();
    _suggestedConnections.clear();
    _myConnections.clear();
    _peerConversations.clear();
    _peerMessagesByUserId.clear();
    _clubMemberRoles.clear();
    _skillProgress = [];
    _semesterGoals = [];
    _myClubRequests.clear();
    _clubRequestQueue.clear();
    _clubRequestEligibility = null;
    _cvUrl = null;
    _cvFileName = null;
    _studySessionMembershipIds.clear();
    _gamificationRowId = null;
    _clubMembershipIds.clear();
    _useBackendData = false;
    notifyListeners();
    await _save();
  }

  Map<String, dynamic> _sessionToJson(StudySession s) => {
        'id': s.id,
        'course': s.course,
        'type': s.type.name,
        'details': s.details,
        'when': s.when,
        'seatsLeft': s.seatsLeft,
        'host': s.host,
        if (s.startsAt != null) 'startsAt': s.startsAt!.toIso8601String(),
        if (s.endsAt != null) 'endsAt': s.endsAt!.toIso8601String(),
        if (s.hostId != null) 'hostId': s.hostId,
      };

  StudySession _sessionFromJson(Map<String, dynamic> m) => StudySession(
        id: m['id'] as String,
        course: m['course'] as String,
        type: StudySessionType.values
            .firstWhere((t) => t.name == m['type'],
                orElse: () => StudySessionType.publicTogether),
        details: m['details'] as String,
        when: m['when'] as String,
        seatsLeft: m['seatsLeft'] == null
            ? null
            : (m['seatsLeft'] as num).toInt(),
        host: m['host'] as String,
        startsAt: m['startsAt'] != null
            ? DateTime.tryParse(m['startsAt'] as String)
            : null,
        endsAt:
            m['endsAt'] != null ? DateTime.tryParse(m['endsAt'] as String) : null,
        hostId: m['hostId'] as String?,
      );

  Map<String, dynamic> _clubToJson(Club c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'focus': c.focus,
        'members': c.members,
        'eventsHeld': c.eventsHeld,
        'activityLevel': c.activityLevel.name,
        'category': c.category.name,
        'nextEvent': c.nextEvent,
        'roles': c.roles,
        'organizerId': c.organizerId,
        'isActive': c.isActive,
      };

  Club _clubFromJson(Map<String, dynamic> m) => Club(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        focus: m['focus'] as String,
        members: (m['members'] as num).toInt(),
        eventsHeld: (m['eventsHeld'] as num).toInt(),
        activityLevel: ClubActivityLevel.values.firstWhere(
          (a) => a.name == m['activityLevel'],
          orElse: () => ClubActivityLevel.active,
        ),
        category: ClubCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => ClubCategory.academic,
        ),
        nextEvent: m['nextEvent'] as String?,
        roles: (m['roles'] as List?)?.cast<String>() ?? const [],
        organizerId: m['organizerId'] as String?,
        isActive: m['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> _eventToJson(Event e) => {
        'id': e.id,
        'title': e.title,
        'organizer': e.organizer,
        'organizerRole': e.organizerRole,
        'about': e.about,
        'location': e.location,
        'date': e.date,
        'duration': e.duration,
        'participants': e.participants,
        'format': e.format,
        'category': e.category.name,
        'points': e.points,
        'tags': e.tags,
        'capacity': e.capacity,
        'targetMajors': e.targetMajors,
        'targetYears': e.targetYears,
        'targetInterests': e.targetInterests,
        'clubId': e.clubId,
        'promotionLevel': e.promotionLevel,
      };

  Event _eventFromJson(Map<String, dynamic> m) {
    final points = (m['points'] as num?)?.toInt() ?? 10;
    return Event(
      id: m['id'] as String,
      title: m['title'] as String,
      organizer: m['organizer'] as String,
      organizerRole: m['organizerRole'] as String? ?? 'Organizer',
      about: m['about'] as String? ?? '',
      location: m['location'] as String? ?? '',
      date: m['date'] as String? ?? '',
      duration: m['duration'] as String? ?? '',
      participants: m['participants'] as String? ?? '',
      format: m['format'] as String? ?? '',
      category: EventCategory.values.firstWhere(
        (c) => c.name == m['category'],
        orElse: () => EventCategory.learn,
      ),
      points: points,
      rewards: [
        EventReward(
          label: '+$points Points',
          detail: 'Displayed on Profile',
          icon: Icons.stars_outlined,
        ),
      ],
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      capacity: (m['capacity'] as num?)?.toInt() ?? 60,
      targetMajors: (m['targetMajors'] as List?)?.cast<String>() ?? const [],
      targetYears: (m['targetYears'] as List?)?.cast<String>() ?? const [],
      targetInterests:
          (m['targetInterests'] as List?)?.cast<String>() ?? const [],
      clubId: m['clubId'] as String?,
      promotionLevel: (m['promotionLevel'] as num?)?.toInt() ?? 2,
    );
  }
}
