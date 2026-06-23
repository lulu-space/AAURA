import 'package:flutter/material.dart';

import '../models/campus_person.dart';
import '../theme/app_theme.dart';

class CampusPeopleList extends StatelessWidget {
  final List<CampusPerson> people;
  final String emptyMessage;
  final Color accent;

  const CampusPeopleList({
    super.key,
    required this.people,
    required this.emptyMessage,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return Column(
      children: [
        for (final person in people) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Text(
                person.initial,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              person.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            subtitle: Text(
              '${person.major} · ${person.year}'
              '${person.statusLabel != null ? ' · ${person.statusLabel}' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            trailing: person.isHost
                ? Chip(
                    label: const Text('Host'),
                    backgroundColor: accent.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: accent, fontSize: 11),
                  )
                : null,
          ),
          if (person != people.last)
            Divider(color: AppColors.divider.withValues(alpha: 0.6)),
        ],
      ],
    );
  }
}
