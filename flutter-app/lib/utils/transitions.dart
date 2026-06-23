import 'package:flutter/material.dart';

/// Slide-from-right + fade route used across the app.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (ctx, _, _) => builder(ctx),
          transitionsBuilder: (_, anim, _, child) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Pure cross-fade route — used for the seamless dawn handoff from the
/// welcome screen into the auth page (no slide so the sky appears continuous).
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 520),
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 320),
          opaque: false,
          pageBuilder: (ctx, _, _) => builder(ctx),
          transitionsBuilder: (_, anim, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            );
          },
        );
}

extension AauraNav on NavigatorState {
  Future<T?> pushFade<T>(WidgetBuilder builder) =>
      push<T>(FadeSlidePageRoute<T>(builder: builder));
}
