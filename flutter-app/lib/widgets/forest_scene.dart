import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Night mountain/forest tones (deep purple silhouettes).
const Color _nHillBack = Color(0xFF2A1B4D);
const Color _nHillMid = Color(0xFF1F1340);
const Color _nHillFront = Color(0xFF160D2E);
const Color _nForest = Color(0xFF100A22);

// Dawn mountain/forest tones (warm rose -> mauve silhouettes).
const Color _dHillBack = Color(0xFFC99AA2);
const Color _dHillMid = Color(0xFF9E6B82);
const Color _dHillFront = Color(0xFF6E4463);
const Color _dForest = Color(0xFF4A2C49);

/// A dreamy mountain illustration used as the dashboard "Discover" hero.
///
/// [reveal] morphs the scene from night (0.0) to morning (1.0): the sky lerps
/// from deep purple to warm dawn, a moon crossfades into a glowing sun, stars
/// fade out, and the layered mountains/treeline warm from violet to rose. An
/// internal looping controller drives slow ambient motion (mist, motes, a
/// gliding bird).
class ForestScene extends StatefulWidget {
  final double reveal;
  const ForestScene({super.key, required this.reveal});

  @override
  State<ForestScene> createState() => _ForestSceneState();
}

class _ForestSceneState extends State<ForestScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  late final List<_Mote> _motes;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(11);
    _motes = List.generate(16, (_) {
      return _Mote(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 0.4 + rng.nextDouble() * 0.9,
        twFreq: 0.6 + rng.nextDouble() * 1.6,
      );
    });
    _stars = List.generate(46, (_) {
      return _Star(
        dx: rng.nextDouble(),
        dy: rng.nextDouble() * 0.55,
        radius: 0.5 + rng.nextDouble() * 1.4,
        phase: rng.nextDouble() * math.pi * 2,
        freq: 0.4 + rng.nextDouble() * 2.0,
      );
    });
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ambient,
          builder: (_, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ForestScenePainter(
                t: _ambient.value,
                reveal: widget.reveal.clamp(0.0, 1.0),
                motes: _motes,
                stars: _stars,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Mote {
  final double dx, dy, radius, phase, speed, twFreq;
  const _Mote({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.twFreq,
  });
}

class _Star {
  final double dx, dy, radius, phase, freq;
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.freq,
  });
}

class _ForestScenePainter extends CustomPainter {
  final double t;
  final double reveal;
  final List<_Mote> motes;
  final List<_Star> stars;

  _ForestScenePainter({
    required this.t,
    required this.reveal,
    required this.motes,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final p = Curves.easeInOut.transform(reveal);
    final night = 1.0 - reveal;

    // Sky (night purple -> dawn peach).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            Color.lerp(AppPalette.nightTop, AppPalette.dawnTop, p)!,
            Color.lerp(AppPalette.nightMid, AppPalette.dawnMid, p)!,
            Color.lerp(AppPalette.nightDeep, AppPalette.dawnLow, p)!,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    final orbC = Offset(w * 0.5, h * 0.30);
    final orbR = w * 0.12;

    // Moon (night) crossfades into the sun (morning).
    if (night > 0.02) _drawMoon(canvas, orbC, orbR, night);
    if (p > 0.02) _drawSun(canvas, orbC, orbR, p);

    // Stars fade out as dawn breaks.
    if (night > 0.01) {
      final star = Paint()..style = PaintingStyle.fill;
      for (final s in stars) {
        final raw = math.sin(t * 2 * math.pi * s.freq + s.phase);
        final sparkle = math.pow(math.max(0.0, raw), 4.0).toDouble();
        final a = (0.10 + 0.85 * sparkle) * night;
        star.color = Colors.white.withValues(alpha: a);
        canvas.drawCircle(Offset(s.dx * w, s.dy * h), s.radius, star);
      }
    }

    // Gliding bird silhouette near the top (the inspo's "drawing").
    final birdX = w * (0.30 + 0.40 * ((t * 0.5) % 1.0));
    final birdY = h * 0.18 + math.sin(t * 2 * math.pi) * h * 0.015;
    final birdColor = Color.lerp(
      Colors.white.withValues(alpha: 0.7),
      AppPalette.ink.withValues(alpha: 0.6),
      p,
    )!;
    _bird(canvas, Offset(birdX, birdY), w * 0.05, birdColor);
    _bird(canvas, Offset(birdX - w * 0.11, birdY + h * 0.05), w * 0.032,
        birdColor);

    // Layered mountains (back -> front).
    _hill(canvas, size,
        baseY: h * 0.50,
        peak: -h * 0.14,
        dip: h * 0.05,
        color: Color.lerp(_nHillBack, _dHillBack, p)!);
    _hill(canvas, size,
        baseY: h * 0.60,
        peak: h * 0.05,
        dip: -h * 0.10,
        color: Color.lerp(_nHillMid, _dHillMid, p)!);

    // Soft mist band drifting across the mid hills.
    final mistY = h * 0.58 + math.sin(t * 2 * math.pi) * h * 0.01;
    final mistShift = math.sin(t * 2 * math.pi) * w * 0.03;
    final mist = Paint()
      ..color = Colors.white.withValues(alpha: 0.13 + 0.05 * p)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.4 + mistShift, mistY),
          width: w * 0.9,
          height: h * 0.10),
      mist,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.78 - mistShift, mistY + h * 0.03),
          width: w * 0.6,
          height: h * 0.08),
      mist,
    );

    _hill(canvas, size,
        baseY: h * 0.70,
        peak: -h * 0.08,
        dip: h * 0.06,
        color: Color.lerp(_nHillFront, _dHillFront, p)!);

    // Dark pine treeline along the bottom.
    final treeBase = h * 0.80;
    final treePaint = Paint()..color = Color.lerp(_nForest, _dForest, p)!;
    canvas.drawRect(Rect.fromLTRB(0, treeBase + h * 0.06, w, h), treePaint);
    final rng = math.Random(3);
    for (double x = -w * 0.02; x < w * 1.02; x += w * 0.062) {
      final ph = treeBase + rng.nextDouble() * h * 0.05;
      final ht = h * (0.12 + rng.nextDouble() * 0.08);
      _pine(canvas, Offset(x, ph + h * 0.06), ht, treePaint);
    }

    // Floating light motes.
    for (final m in motes) {
      final fy = (m.dy - t * 0.05 * m.speed) % 1.0;
      final fx = m.dx + 0.02 * math.sin(t * 2 * math.pi * m.speed + m.phase);
      final tw = math.pow(
        math.max(0.0, math.sin(t * 2 * math.pi * m.twFreq + m.phase)),
        2.0,
      ).toDouble();
      canvas.drawCircle(
        Offset(fx * w, fy * h * 0.82),
        m.radius,
        Paint()
          ..color = const Color(0xFFFBF6D8).withValues(alpha: 0.12 + 0.5 * tw),
      );
    }

    // Gentle vignette.
    final edge = Color.lerp(AppPalette.nightDeep, AppPalette.dawnLow, p)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.42),
          math.max(w, h) * 0.72,
          [edge.withValues(alpha: 0.0), edge.withValues(alpha: 0.30)],
          const [0.6, 1.0],
        ),
    );
  }

  void _drawMoon(Canvas canvas, Offset c, double r, double a) {
    canvas.drawCircle(
      c,
      r * 3.0,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 3.0, [
          const Color(0xFFFFF3D6).withValues(alpha: 0.5 * a),
          const Color(0xFFE9C9F5).withValues(alpha: 0.16 * a),
          const Color(0x00E9C9F5),
        ], const [0.0, 0.45, 1.0]),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          const Color(0xFFFFF7E6).withValues(alpha: a),
          const Color(0xFFF3DCC2).withValues(alpha: a),
        ]),
    );
  }

  void _drawSun(Canvas canvas, Offset c, double r, double p) {
    canvas.drawCircle(
      c,
      r * 3.4,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 3.4, [
          const Color(0xFFFFE6A8).withValues(alpha: 0.6 * p),
          const Color(0xFFFFC78A).withValues(alpha: 0.2 * p),
          const Color(0x00FFC78A),
        ], const [0.0, 0.42, 1.0]),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          const Color(0xFFFFF4C2).withValues(alpha: p),
          const Color(0xFFFFC15A).withValues(alpha: p),
        ]),
    );
  }

  void _bird(Canvas canvas, Offset c, double span, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - span, c.dy)
        ..quadraticBezierTo(c.dx - span * 0.4, c.dy - span * 0.55, c.dx, c.dy)
        ..quadraticBezierTo(
            c.dx + span * 0.4, c.dy - span * 0.55, c.dx + span, c.dy),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _hill(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double peak,
    required double dip,
    required Color color,
  }) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, baseY)
        ..quadraticBezierTo(w * 0.26, baseY + peak, w * 0.5, baseY + dip)
        ..quadraticBezierTo(w * 0.76, baseY - peak, w, baseY + dip * 0.4)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color,
    );
  }

  void _pine(Canvas canvas, Offset base, double height, Paint paint) {
    final half = height * 0.34;
    for (var i = 0; i < 3; i++) {
      final top = base.dy - height + (height * 0.28) * i;
      final spread = half * (1 - i * 0.18);
      final bottom = top + height * 0.5;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, top)
          ..lineTo(base.dx - spread, bottom)
          ..lineTo(base.dx + spread, bottom)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForestScenePainter old) =>
      old.t != t || old.reveal != reveal;
}
