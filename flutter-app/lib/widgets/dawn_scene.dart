import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Night palette.
const Color _skyTop = Color(0xFF3A2470);
const Color _skyMid = Color(0xFF2C1856);
const Color _skyDeep = Color(0xFF160A29);

// Dawn palette (from the supplied colour study).
const Color _dawnTop = Color(0xFFFBE4D8);
const Color _dawnMid = Color(0xFFDFB6B2);
const Color _dawnLow = Color(0xFF854F6C);
const Color _ink = Color(0xFF3D2350);

/// A single dreamy sky scene shared by the welcome screen and the auth page.
///
/// [reveal] morphs the scene from night (0.0) to a warm sunrise (1.0): the moon
/// sinks behind the hills, the sun rises in its place, stars fade, and the day
/// elements (warm gradient, distant birds, clouds, hills) settle in. Because
/// both screens render the same scene, the welcome -> auth hand-off is seamless.
///
/// An internal looping controller drives gentle ambient motion (drifting
/// sparkle dust, slowly gliding clouds/birds, soft god-rays).
class DawnScene extends StatefulWidget {
  final double reveal;
  const DawnScene({super.key, required this.reveal});

  @override
  State<DawnScene> createState() => _DawnSceneState();
}

class _DawnSceneState extends State<DawnScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  late final List<_Star> _stars;
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _stars = List.generate(80, (_) {
      return _Star(
        dx: rng.nextDouble(),
        dy: rng.nextDouble() * 0.5,
        radius: 0.5 + rng.nextDouble() * 1.5,
        phase: rng.nextDouble() * math.pi * 2,
        freq: 0.4 + rng.nextDouble() * 2.1,
      );
    });
    _motes = List.generate(22, (_) {
      return _Mote(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 1.8,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 0.4 + rng.nextDouble() * 0.9,
        twFreq: 0.6 + rng.nextDouble() * 1.8,
      );
    });
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
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
              painter: _DawnScenePainter(
                reveal: widget.reveal.clamp(0.0, 1.0),
                t: _ambient.value,
                stars: _stars,
                motes: _motes,
              ),
            );
          },
        ),
      ),
    );
  }
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

class _DawnScenePainter extends CustomPainter {
  final double reveal;
  final double t;
  final List<_Star> stars;
  final List<_Mote> motes;

  _DawnScenePainter({
    required this.reveal,
    required this.t,
    required this.stars,
    required this.motes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final p = Curves.easeInOut.transform(reveal);
    final night = 1.0 - reveal;

    // 1. Sky gradient (night -> dawn).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            Color.lerp(_skyTop, _dawnTop, p)!,
            Color.lerp(_skyMid, _dawnMid, p)!,
            Color.lerp(_skyDeep, _dawnLow, p)!,
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    final cx = w * 0.5;
    final orbR = w * 0.17;

    // 2. Moon — sinks behind the hills.
    final moonY = (0.30 + reveal * 1.05) * h;
    if (night > 0.02) _drawMoon(canvas, Offset(cx, moonY), orbR, night);

    // 3. Sun — rises into place, with halo + soft god-rays.
    final sunY = (1.35 - p * 1.07) * h;
    _drawSun(canvas, Offset(cx, sunY), orbR, p, h);

    // 4. Stars + the occasional shooting star (night only).
    if (night > 0.01) {
      final star = Paint()..style = PaintingStyle.fill;
      for (final s in stars) {
        final raw = math.sin(t * 2 * math.pi * s.freq + s.phase);
        final sparkle = math.pow(math.max(0.0, raw), 4.0).toDouble();
        final a = (0.12 + 0.88 * sparkle) * night;
        final pos = Offset(s.dx * w, s.dy * h);
        star.color = Colors.white.withValues(alpha: a);
        canvas.drawCircle(pos, s.radius, star);
      }
      final shoot = t % 1.0;
      if (shoot < 0.28) {
        final sp = shoot / 0.28;
        final head = Offset(w * (0.88 - sp * 0.52), h * (0.06 + sp * 0.11));
        final tail = head.translate(w * 0.10, -h * 0.037);
        canvas.drawLine(
          head,
          tail,
          Paint()
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: (1 - sp) * 0.8 * night),
        );
      }
    }

    // 5. Clouds — slowly drift; tint from night silhouette toward warm white.
    final cloudColor = Color.lerp(
      const Color(0x44120726),
      const Color(0x66FFFFFF),
      p,
    )!;
    final drift = math.sin(t * 2 * math.pi) * w * 0.02;
    _cloud(canvas, Offset(w * 0.22 + drift, h * 0.13), w * 0.44, cloudColor);
    _cloud(canvas, Offset(w * 0.84 - drift, h * 0.085), w * 0.36,
        cloudColor.withValues(alpha: cloudColor.a * 0.8));
    _cloud(canvas, Offset(w * 0.7 + drift * 0.6, h * 0.275), w * 0.30,
        cloudColor.withValues(alpha: cloudColor.a * 0.7));

    // 6. Warm horizon glow where hills meet the sky.
    final horizonY = h * 0.66;
    if (p > 0.01) {
      canvas.drawRect(
        Rect.fromLTWH(0, horizonY - h * 0.14, w, h * 0.28),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, horizonY),
            w * 0.7,
            [
              const Color(0xFFFFD9A0).withValues(alpha: 0.42 * p),
              const Color(0x00FFD9A0),
            ],
          ),
      );
    }

    // 7. Distant birds — a few off to the side, away from the sun. Fade in
    //    with the day and bob gently.
    final birdA = p;
    if (birdA > 0.02) {
      final birdPaint = Paint()
        ..color = _ink.withValues(alpha: 0.5 * birdA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      const flock = <List<double>>[
        [0.20, 0.16, 14],
        [0.28, 0.225, 11],
        [0.15, 0.205, 8],
      ];
      for (var i = 0; i < flock.length; i++) {
        final b = flock[i];
        final bob = math.sin(t * 2 * math.pi + i) * h * 0.006;
        _bird(canvas, Offset(w * b[0], h * b[1] + bob), b[2], birdPaint);
      }
    }

    // 8. Layered hills (night silhouette -> warm day).
    _hill(canvas, size,
        baseY: h * 0.70,
        peak: -h * 0.05,
        dip: h * 0.02,
        color: Color.lerp(const Color(0xFF241A40), const Color(0xFFB98198), p)!);
    _hill(canvas, size,
        baseY: h * 0.76,
        peak: h * 0.02,
        dip: -h * 0.04,
        color: Color.lerp(const Color(0xFF1C1433), _dawnLow, p)!);
    final frontTop = h * 0.82;
    _hill(canvas, size,
        baseY: frontTop,
        peak: -h * 0.03,
        dip: h * 0.03,
        color: Color.lerp(const Color(0xFF120D24), const Color(0xFF5C3450), p)!);

    // 9. Two pine trees on the front ridge (left side only).
    final treeColor =
        Color.lerp(const Color(0xFF0E0A1C), const Color(0xFF4A2A41), p)!;
    final treePaint = Paint()..color = treeColor;
    _pine(canvas, Offset(w * 0.16, frontTop + h * 0.012), h * 0.07, treePaint);
    _pine(canvas, Offset(w * 0.27, frontTop + h * 0.028), h * 0.055, treePaint);

    // 10. Floating sparkle dust — drifts up and twinkles.
    final moteBase = 0.35 + 0.65 * p;
    for (final m in motes) {
      final fy = (m.dy - t * 0.06 * m.speed) % 1.0;
      final fx = m.dx + 0.02 * math.sin(t * 2 * math.pi * m.speed + m.phase);
      final tw = math.pow(
        math.max(0.0, math.sin(t * 2 * math.pi * m.twFreq + m.phase)),
        2.0,
      ).toDouble();
      final a = (0.12 + 0.6 * tw) * moteBase;
      canvas.drawCircle(
        Offset(fx * w, fy * h),
        m.radius,
        Paint()..color = const Color(0xFFFFF3D6).withValues(alpha: a),
      );
    }

    // 11. Warm vignette for depth.
    final vignetteEdge =
        Color.lerp(const Color(0xFF160A29), const Color(0xFF5C3450), p)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, h * 0.42),
          math.max(w, h) * 0.72,
          [
            vignetteEdge.withValues(alpha: 0.0),
            vignetteEdge.withValues(alpha: 0.28),
          ],
          const [0.62, 1.0],
        ),
    );
  }

  void _drawMoon(Canvas canvas, Offset c, double r, double a) {
    canvas.drawCircle(
      c,
      r * 3.2,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 3.2, [
          const Color(0xFFFFF3D6).withValues(alpha: 0.55 * a),
          const Color(0xFFE9C9F5).withValues(alpha: 0.18 * a),
          const Color(0x00E9C9F5),
        ], const [0.0, 0.45, 1.0]),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          Color.lerp(const Color(0xFFFFF7E6), _skyDeep, 1 - a)!,
          Color.lerp(const Color(0xFFF3DCC2), _skyDeep, 1 - a)!,
        ]),
    );
    final crater = Paint()..color = Color(0x22B89A86).withValues(alpha: 0.13 * a);
    canvas.drawCircle(c.translate(-r * 0.3, -r * 0.2), r * 0.18, crater);
    canvas.drawCircle(c.translate(r * 0.35, r * 0.25), r * 0.12, crater);
  }

  void _drawSun(Canvas canvas, Offset c, double r, double p, double h) {
    if (p <= 0.01) return;
    // Soft god-rays behind the disc.
    final rayPaint = Paint()
      ..color = const Color(0xFFFFF1C4).withValues(alpha: 0.045 * p);
    const n = 9;
    final baseRot = t * 2 * math.pi * 0.015;
    final len = h * 0.6;
    const rayHalf = 16.0;
    for (var i = 0; i < n; i++) {
      final ang = baseRot + i * (2 * math.pi / n);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ang);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(-rayHalf, -len)
          ..lineTo(rayHalf, -len)
          ..close(),
        rayPaint,
      );
      canvas.restore();
    }
    // Halo.
    canvas.drawCircle(
      c,
      r * 4.0,
      Paint()
        ..shader = ui.Gradient.radial(c, r * 4.0, [
          const Color(0xFFFFE6A8).withValues(alpha: 0.65 * p),
          const Color(0xFFFFC78A).withValues(alpha: 0.22 * p),
          const Color(0x00FFC78A),
        ], const [0.0, 0.4, 1.0]),
    );
    // Disc.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
            c, r, [const Color(0xFFFFF4C2), const Color(0xFFFFC15A)]),
    );
  }

  void _bird(Canvas canvas, Offset c, double span, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - span, c.dy)
        ..quadraticBezierTo(c.dx - span * 0.45, c.dy - span * 0.6, c.dx, c.dy)
        ..quadraticBezierTo(
            c.dx + span * 0.45, c.dy - span * 0.6, c.dx + span, c.dy),
      paint,
    );
  }

  void _cloud(Canvas canvas, Offset center, double width, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final hgt = width * 0.32;
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCenter(center: center, width: width, height: hgt))
        ..addOval(Rect.fromCenter(
            center: center.translate(-width * 0.28, hgt * 0.20),
            width: width * 0.6,
            height: hgt * 0.8))
        ..addOval(Rect.fromCenter(
            center: center.translate(width * 0.28, hgt * 0.16),
            width: width * 0.62,
            height: hgt * 0.82)),
      paint,
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
        ..quadraticBezierTo(w * 0.28, baseY + peak, w * 0.5, baseY + dip)
        ..quadraticBezierTo(w * 0.78, baseY - peak, w, baseY + dip * 0.5)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color,
    );
  }

  void _pine(Canvas canvas, Offset base, double height, Paint paint) {
    final half = height * 0.32;
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
  bool shouldRepaint(covariant _DawnScenePainter old) =>
      old.t != t || old.reveal != reveal;
}
