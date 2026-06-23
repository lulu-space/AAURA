import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../academics/academics_screen.dart';
import '../clubs/clubs_screen.dart';
import '../events/events_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../dean/dean_clubs_screen.dart';
import '../dean/dean_dashboard_screen.dart';
import '../dean/dean_events_screen.dart';
import '../dean/dean_reports_screen.dart';
import '../admin/admin_analytics_screen.dart';
import '../admin/admin_content_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_settings_screen.dart';
import '../admin/admin_users_screen.dart';
import '../staff/manage_events_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  /// Tab definitions per role. Each entry pairs a nav tab with its body
  /// builder, so the shell can never surface a screen the role shouldn't see.
  List<_TabEntry> _entriesFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          _TabEntry(
            const _Tab('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
            (onNav) => AdminDashboardScreen(onNavigate: onNav),
          ),
          _TabEntry(
            const _Tab('Users', Icons.people_outline, Icons.people),
            (_) => const AdminUsersScreen(),
          ),
          _TabEntry(
            const _Tab('Content', Icons.shield_outlined, Icons.shield),
            (_) => const AdminContentScreen(),
          ),
          _TabEntry(
            const _Tab('Analytics', Icons.insights_outlined, Icons.insights),
            (_) => const AdminAnalyticsScreen(),
          ),
          _TabEntry(
            const _Tab('Settings', Icons.settings_outlined, Icons.settings),
            (_) => const AdminSettingsScreen(),
          ),
        ];
      case UserRole.deanOfFaculty:
        return [
          _TabEntry(
            const _Tab('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
            (onNav) => DeanDashboardScreen(onNavigate: onNav),
          ),
          _TabEntry(
            const _Tab('Events', Icons.event_outlined, Icons.event),
            (_) => const DeanEventsScreen(),
          ),
          _TabEntry(
            const _Tab('Clubs', Icons.groups_outlined, Icons.groups),
            (_) => const DeanClubsScreen(),
          ),
          _TabEntry(
            const _Tab('Reports', Icons.assessment_outlined, Icons.assessment),
            (_) => const DeanReportsScreen(),
          ),
          _TabEntry(
            const _Tab('Profile', Icons.person_outline, Icons.person),
            (_) => const ProfileScreen(),
          ),
        ];
      case UserRole.studentAffairs:
      case UserRole.staff:
        return [
          _TabEntry(
            const _Tab('Home', Icons.home_outlined, Icons.home_rounded),
            (onNav) => HomeScreen(onNavigate: onNav),
          ),
          _TabEntry(
            const _Tab('Events', Icons.event_outlined, Icons.event),
            (_) => const EventsScreen(),
          ),
          _TabEntry(
            const _Tab('Clubs', Icons.groups_outlined, Icons.groups),
            (_) => const ClubsScreen(),
          ),
          _TabEntry(
            const _Tab('Manage', Icons.event_note_outlined, Icons.event_note),
            (_) => const ManageEventsScreen(),
          ),
          _TabEntry(
            const _Tab('Profile', Icons.person_outline, Icons.person),
            (_) => const ProfileScreen(),
          ),
        ];
      case UserRole.student:
        return [
          _TabEntry(
            const _Tab('Home', Icons.home_outlined, Icons.home_rounded),
            (onNav) => HomeScreen(onNavigate: onNav),
          ),
          _TabEntry(
            const _Tab('Events', Icons.event_outlined, Icons.event),
            (_) => const EventsScreen(),
          ),
          _TabEntry(
            const _Tab('Clubs', Icons.groups_outlined, Icons.groups),
            (_) => const ClubsScreen(),
          ),
          _TabEntry(
            const _Tab('Academics', Icons.menu_book_outlined, Icons.menu_book),
            (_) => const AcademicsScreen(),
          ),
          _TabEntry(
            const _Tab('Profile', Icons.person_outline, Icons.person),
            (_) => const ProfileScreen(),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().profile?.role ?? UserRole.student;
    final entries = _entriesFor(role);
    if (_index >= entries.length) _index = 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (final entry in entries)
            entry.builder((idx) => setState(() => _index = idx)),
        ],
      ),
      bottomNavigationBar: _AnimatedBottomNav(
        index: _index,
        tabs: [for (final e in entries) e.tab],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

typedef _BodyBuilder = Widget Function(ValueChanged<int> onNavigate);

class _TabEntry {
  final _Tab tab;
  final _BodyBuilder builder;
  const _TabEntry(this.tab, this.builder);
}

class _AnimatedBottomNav extends StatelessWidget {
  final int index;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;
  const _AnimatedBottomNav({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  static const double _barHeight = 64;
  static const double _innerPadding = 6;

  @override
  Widget build(BuildContext context) {
    // Warm dawn selected pill.
    const selGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4C9A0), Color(0xFFE0A6AB)],
    );
    final selText = AppPalette.ink;
    final unselColor = AppColors.textMuted;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(_innerPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segWidth = constraints.maxWidth / tabs.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: index * segWidth,
                    top: 0,
                    bottom: 0,
                    width: segWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: selGradient,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (int i = 0; i < tabs.length; i++)
                          Expanded(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                              onTap: () => onTap(i),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: Icon(
                                      i == index
                                          ? tabs[i].activeIcon
                                          : tabs[i].icon,
                                      key: ValueKey(
                                          '${tabs[i].label}-$i-${i == index}'),
                                      color: i == index ? selText : unselColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      color: i == index ? selText : unselColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    child: Text(tabs[i].label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.label, this.icon, this.activeIcon);
}
