/// Ripples
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 6bcc57b1c6b919e68905618787b66c36
/// DartPad: https://dartpad.dev/?id=6bcc57b1c6b919e68905618787b66c36
///
/// Features: Animated concentric circles, fading opacity, continuous animation
/// Techniques: CustomPainter with repaint listenable, AnimationController.repeat(), shouldRepaint optimization

import 'dart:math' as math;

import 'package:flutter/material.dart';

const MaterialColor primaryAccent = MaterialColor(
  0xFF121212,
  <int, Color>{
    50: Color(0xFFf7f7f7),
    100: Color(0xFFeeeeee),
    200: Color(0xFFe2e2e2),
    300: Color(0xFFd0d0d0),
    400: Color(0xFFababab),
    500: Color(0xFF8a8a8a),
    600: Color(0xFF636363),
    700: Color(0xFF505050),
    800: Color(0xFF323232),
    900: Color(0xFF121212),
  },
);
const MaterialColor secondaryAccent = MaterialColor(
  0xFF03dac4,
  <int, Color>{
    50: Color(0xFFd4f6f2),
    100: Color(0xFF92e9dc),
    200: Color(0xFF03dac4),
    300: Color(0xFF00c7ab),
    400: Color(0xFF00b798),
    500: Color(0xFF00a885),
    600: Color(0xFF009a77),
    700: Color(0xFF008966),
    800: Color(0xFF007957),
    900: Color(0xFF005b39),
  },
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: primaryAccent),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Ripples(),
        ),
      ),
    );
  }
}

class Ripples extends StatefulWidget {
  const Ripples({
    super.key,
    this.size = 240.0,
    this.color = secondaryAccent,
  });

  final double size;
  final Color color;

  @override
  _RipplesState createState() => _RipplesState();
}

class _RipplesState extends State<Ripples> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CirclePainter(_controller, color: widget.color),
      size: Size.square(widget.size * 2.125),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter(
    this._animation, {
    required this.color,
  }) : super(repaint: _animation);

  final Color color;
  final Animation<double> _animation;

  void circle(Canvas canvas, Rect rect, double value) {
    final area = math.pow(rect.width / 2, 2);
    final radius = math.sqrt(area * value / 4);

    final opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    final _color = color.withOpacity(opacity);
    canvas.drawCircle(rect.center, radius, Paint()..color = _color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) => color != oldDelegate.color;
}
