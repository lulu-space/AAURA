import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Locks the app to a phone-sized frame on web and desktop runners.
/// On Android and iOS the child is shown full-screen.
class MobileViewport extends StatelessWidget {
  const MobileViewport({super.key, required this.child});

  /// iPhone 14 / 15 logical size (390 × 844 pt).
  static const double phoneWidth = 390;
  static const double phoneHeight = 844;

  final Widget child;

  static bool get shouldConstrain {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return false;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldConstrain) return child;

    final viewportHeight = MediaQuery.sizeOf(context).height;

    return ColoredBox(
      color: const Color(0xFFF0F0F0),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: phoneWidth,
                height: phoneHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(phoneWidth, phoneHeight),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
