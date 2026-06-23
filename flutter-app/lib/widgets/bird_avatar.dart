import 'package:flutter/material.dart';

// Dawn palette tone reused for the mascot's soft glow (matches dawn_scene.dart
// and the auth screen).
const Color _dawnLow = Color(0xFF854F6C);

const String _kSheet = 'assets/images/aaura_bird_sheet.png';
const int _kCols = 3;
const int _kRows = 6;

// Keep RGB, derive alpha from (roughly) luminance: out.a = (R+G+B) - 30.
// Pure black -> 0 (transparent); the bird's bright lavender/white stays
// opaque; very dark purple outlines go a touch soft (accepted tradeoff).
const ColorFilter _kKnockoutBlack = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  1, 1, 1, 0, -30, //
]);

// Show slightly less than a full cell so the neighbouring sticker (esp. the
// row above) is clipped out instead of bleeding into the frame.
const double _kCellInset = 0.88;

/// Alignment that isolates cell ([row], [col]) when used with an [Align] whose
/// `widthFactor`/`heightFactor` are `_kCellInset / cols` and `_kCellInset / rows`.
/// The visible window stays centered on the cell while it shrinks, trimming the
/// neighbour bleed.
Alignment _cellAlignment(int row, int col) {
  double axis(int i, int n) {
    if (n <= 1) return 0;
    final f = _kCellInset / n; // visible fraction of the whole sheet
    final center = (i + 0.5) / n; // cell center, 0..1
    return 2 * (center - f / 2) / (1 - f) - 1;
  }

  return Alignment(axis(col, _kCols), axis(row, _kRows));
}

/// The Shams mascot avatar: the top-left bird from the sticker sheet, cropped
/// out of the 3-column x 6-row grid and shown inside a soft frosted coin.
///
/// The sheet ships on a solid black background, so we knock the black out with
/// a luminance-keyed alpha [ColorFilter] — bright bird pixels stay opaque while
/// the black becomes transparent, letting the bird float on the dawn sky.
class BirdAvatar extends StatelessWidget {
  final double size;

  const BirdAvatar({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Frosted coin behind the bird so the knocked-out areas read as a soft
        // halo rather than a hole in the sky.
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _dawnLow.withValues(alpha: 0.30),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          _kSheet,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return FittedBox(
              fit: BoxFit.cover,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  widthFactor: 1 / _kCols,
                  heightFactor: 1 / _kRows,
                  child: ColorFiltered(
                    colorFilter: _kKnockoutBlack,
                    child: child,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Padding(
            padding: EdgeInsets.all(size * 0.14),
            child: CustomPaint(painter: _PaintedBirdPainter()),
          ),
        ),
      ),
    );
  }
}

/// A bare (coin-less) cropped bird from the sticker sheet — black knocked out so
/// it floats. Used for the mascot peeking from a screen corner.
class BirdSticker extends StatelessWidget {
  final double size;
  final int row;
  final int col;

  const BirdSticker({
    super.key,
    this.size = 140,
    this.row = 0,
    this.col = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _kSheet,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return FittedBox(
            fit: BoxFit.contain,
            child: ClipRect(
              child: Align(
                alignment: _cellAlignment(row, col),
                widthFactor: _kCellInset / _kCols,
                heightFactor: _kCellInset / _kRows,
                child: ColorFiltered(
                  colorFilter: _kKnockoutBlack,
                  child: child,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) =>
            CustomPaint(painter: _PaintedBirdPainter()),
      ),
    );
  }
}

/// Painted stand-in used only if the sticker sheet fails to load.
class _PaintedBirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = const Color(0xFF4B3A6B);
    final belly = Paint()..color = const Color(0xFFCBB6EE);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.6), width: w * 0.7, height: h * 0.7),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.7), width: w * 0.46, height: h * 0.44),
      belly,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.36), w * 0.28, body);
    final white = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF231039);
    for (final dx in [-0.1, 0.1]) {
      final c = Offset(w * (0.5 + dx), h * 0.36);
      canvas.drawCircle(c, w * 0.08, white);
      canvas.drawCircle(c, w * 0.045, pupil);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
