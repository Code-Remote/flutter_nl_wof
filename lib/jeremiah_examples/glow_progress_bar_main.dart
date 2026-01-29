/// Glow Progress Bar
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 1079588b40eb19c559480eb5f6aa5d2f
/// DartPad: https://dartpad.dev/?id=1079588b40eb19c559480eb5f6aa5d2f
///
/// Features: Animated progress bar with shimmer/glow effect, rounded corners, repeating animation
/// Techniques: CustomPainter with repaint listener, AnimationController, LinearGradient, BlendMode.screen, canvas clipping

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: UploadProgressBar(),
        ),
      ),
    );
  }
}

class UploadProgressBar extends StatefulWidget {
  @override
  _UploadProgressBarState createState() => _UploadProgressBarState();
}

class _UploadProgressBarState extends State<UploadProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: 500,
      child: CustomPaint(
        painter: _ProgressPainter(animation: _controller),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({required this.animation}) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(12),
    );
    canvas.clipRRect(shape);

    canvas.drawRRect(shape, Paint()..color = Colors.pink);

    final value = interpolate(input: animation.value, outputMax: size.width);
    final thumbWidth = size.width / 5;
    final thumbRect = Rect.fromLTWH(
      value - (thumbWidth / 2),
      0,
      thumbWidth,
      size.height,
    );
    canvas.drawRect(
      thumbRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(thumbRect.left, 0),
          Offset(thumbRect.right, 0),
          [Color(0x00FFFFFF), Colors.white38, Color(0x00FFFFFF)],
          [0, .5, 1],
        )
        ..blendMode = BlendMode.screen,
    );

    canvas.clipRRect(
      RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(12)),
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// https://math.stackexchange.com/questions/377169/going-from-a-value-inside-1-1-to-a-value-in-another-range/377174#377174
double interpolate({
  required double input,
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
  Curve curve = Curves.linear,
}) {
  double result = math.max(inputMin, input);

  if (outputMin == outputMax) {
    return outputMin;
  }

  if (input <= inputMin) {
    return outputMin;
  }

  if (inputMin == inputMax) {
    return outputMax;
  }

  // Input Range
  if (inputMin == -double.infinity) {
    result = -result;
  } else if (inputMax == double.infinity) {
    result = result - inputMin;
  } else {
    result = (result - inputMin) / (inputMax - inputMin);
  }

  // Easing
  result = curve.transform(result);

  // Output Range
  if (outputMin == -double.infinity) {
    result = -result;
  } else if (outputMax == double.infinity) {
    result = result + outputMin;
  } else {
    result = result * (outputMax - outputMin) + outputMin;
  }

  return result;
}
