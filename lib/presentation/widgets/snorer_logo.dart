import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The Snorer mark, rendered from the active theme instead of a fixed bitmap.
class SnorerLogo extends StatelessWidget {
  const SnorerLogo({super.key, this.size = 48, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final logo = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SnorerLogoPainter(
          colors: colors,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: logo);
    }
    return Semantics(image: true, label: semanticLabel, child: logo);
  }
}

class _SnorerLogoPainter extends CustomPainter {
  const _SnorerLogoPainter({required this.colors, required this.isDark});

  final SnorerThemePalette colors;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide * 0.22;
    final night = isDark
        ? colors.background
        : Color.lerp(colors.primaryDark, colors.text, 0.06)!;
    final nightEdge = Color.lerp(night, colors.secondary, 0.24)!;
    final star = isDark
        ? Color.lerp(colors.text, colors.surface, 0.12)!
        : colors.surface;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [night, nightEdge],
        ).createShader(rect),
    );

    _drawSparkle(
      canvas,
      _point(size, 0.22, 0.29),
      size.shortestSide * 0.055,
      star,
    );
    _drawSparkle(
      canvas,
      _point(size, 0.76, 0.20),
      size.shortestSide * 0.075,
      star,
    );
    _drawDot(
      canvas,
      _point(size, 0.65, 0.39),
      size.shortestSide * 0.012,
      colors.secondary,
    );
    _drawDot(
      canvas,
      _point(size, 0.25, 0.49),
      size.shortestSide * 0.010,
      colors.primary,
    );
    _drawDot(canvas, _point(size, 0.85, 0.58), size.shortestSide * 0.010, star);

    final moon = _moonPath(size);
    canvas.drawPath(
      moon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            star,
            Color.lerp(star, colors.secondary, 0.38)!,
            Color.lerp(colors.secondary, colors.primary, 0.35)!,
          ],
          stops: const [0, 0.52, 1],
        ).createShader(rect),
    );

    final rearWave = _rearWavePath(size);
    canvas.drawPath(
      rearWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colors.secondary, night, 0.38)!,
            Color.lerp(colors.primaryDark, night, 0.18)!,
          ],
        ).createShader(rect),
    );

    final frontWave = _frontWavePath(size);
    canvas.drawPath(
      frontWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.primaryDark, colors.secondary, 0.35)!,
            colors.primaryDark,
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  Offset _point(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  Path _moonPath(Size size) {
    double x(double value) => size.width * value;
    double y(double value) => size.height * value;

    return Path()
      ..moveTo(x(0.53), y(0.20))
      ..cubicTo(x(0.36), y(0.24), x(0.24), y(0.40), x(0.24), y(0.57))
      ..cubicTo(x(0.24), y(0.76), x(0.39), y(0.89), x(0.57), y(0.89))
      ..cubicTo(x(0.71), y(0.89), x(0.82), y(0.80), x(0.86), y(0.67))
      ..cubicTo(x(0.78), y(0.73), x(0.70), y(0.75), x(0.62), y(0.74))
      ..cubicTo(x(0.47), y(0.72), x(0.37), y(0.61), x(0.37), y(0.48))
      ..cubicTo(x(0.37), y(0.35), x(0.43), y(0.26), x(0.53), y(0.20))
      ..close();
  }

  Path _rearWavePath(Size size) {
    double x(double value) => size.width * value;
    double y(double value) => size.height * value;

    return Path()
      ..moveTo(x(0), y(0.78))
      ..cubicTo(x(0.17), y(0.68), x(0.30), y(0.75), x(0.46), y(0.87))
      ..cubicTo(x(0.61), y(0.98), x(0.71), y(0.88), x(0.85), y(0.79))
      ..cubicTo(x(0.94), y(0.73), x(0.99), y(0.74), x(1), y(0.75))
      ..lineTo(x(1), y(1))
      ..lineTo(x(0), y(1))
      ..close();
  }

  Path _frontWavePath(Size size) {
    double x(double value) => size.width * value;
    double y(double value) => size.height * value;

    return Path()
      ..moveTo(x(0), y(0.88))
      ..cubicTo(x(0.16), y(0.78), x(0.29), y(0.84), x(0.44), y(0.94))
      ..cubicTo(x(0.59), y(1.04), x(0.75), y(1.02), x(1), y(0.85))
      ..lineTo(x(1), y(1))
      ..lineTo(x(0), y(1))
      ..close();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final inner = radius * 0.25;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..cubicTo(
        center.dx + inner,
        center.dy - inner,
        center.dx + inner,
        center.dy - inner,
        center.dx + radius,
        center.dy,
      )
      ..cubicTo(
        center.dx + inner,
        center.dy + inner,
        center.dx + inner,
        center.dy + inner,
        center.dx,
        center.dy + radius,
      )
      ..cubicTo(
        center.dx - inner,
        center.dy + inner,
        center.dx - inner,
        center.dy + inner,
        center.dx - radius,
        center.dy,
      )
      ..cubicTo(
        center.dx - inner,
        center.dy - inner,
        center.dx - inner,
        center.dy - inner,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawDot(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SnorerLogoPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.isDark != isDark;
}
