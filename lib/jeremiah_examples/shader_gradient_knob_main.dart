/// Shader Progress Knob
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 56e8d96c30a603e4afd548ab8d11d09d
/// DartPad: https://dartpad.dev/?id=56e8d96c30a603e4afd548ab8d11d09d
///
/// Features: Rotatable temperature dial, glow effect on progress arc, tick marks around edge
/// Techniques: Custom RenderBox, PanGestureRecognizer, SweepGradient, ImageFilter blur, shadow drawing

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const Playground(),
      ),
    );

class Playground extends StatefulWidget {
  const Playground({Key? key}) : super(key: key);

  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2F3E),
      body: Center(
        child: ProgressDial(
          onChanged: (value) {
            // print(value);
          },
        ),
      ),
    );
  }
}

class ProgressDial extends LeafRenderObjectWidget {
  const ProgressDial({Key? key, this.onChanged}) : super(key: key);

  final ValueChanged<int>? onChanged;

  @override
  RenderProgressDial createRenderObject(BuildContext context) {
    return RenderProgressDial().._onChanged = onChanged;
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderProgressDial renderObject) =>
      renderObject.._onChanged = onChanged;
}

class RenderProgressDial extends RenderBox {
  RenderProgressDial() {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
    valueBuilder = interpolate(inputMax: totalAngle, outputMin: 0, outputMax: 40);
  }

  late final DragGestureRecognizer drag;
  late Rect knobRect;
  late final double Function(double input) valueBuilder;

  static final totalAngle = 360.radians;
  static final startAngle = -90.radians;
  static const shadowColor = Color(0xFF272A39);
  static final labelColor = Colors.white30;
  static const titleFontRadius = 30.0;
  static const labelFontRadius = titleFontRadius / 4.5;

  static const minRadius = 100.0;
  static const maxRadius = 180.0;

  ValueChanged<int>? _onChanged;

  Offset _currentDragOffset = Offset.zero;
  double _currentAngle = 0.0;
  int? _value;

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = globalToLocal(details.globalPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final diffInAngle = toAngle(_currentDragOffset, knobRect.radius) - toAngle(previousOffset, knobRect.radius);
    _onAngleChanged((_currentAngle + diffInAngle).normalize(totalAngle).toDouble());
  }

  void _onDragCancel() {
    _currentDragOffset = Offset.zero;
  }

  void _onDragEnd(DragEndDetails details) {
    _onDragCancel();
  }

  void _onAngleChanged(double value) {
    if (value == _currentAngle) {
      return;
    }
    _currentAngle = value;
    _onSelect(valueBuilder(value).round());
    markNeedsPaint();
  }

  _onSelect(int value) {
    if (value == _value) {
      return;
    }
    _value = value;
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      HapticFeedback.selectionClick();
      _onChanged?.call(_value!);
    });
  }

  @override
  bool hitTestSelf(ui.Offset position) {
    return knobRect.contains(localToGlobal(position));
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final effectiveConstraints = constraints.enforce(const BoxConstraints(
      minHeight: minRadius * 2,
      minWidth: minRadius * 2,
      maxHeight: maxRadius * 2,
      maxWidth: maxRadius * 2,
    ));
    final effectiveSize = Size.square(effectiveConstraints.constrainWidth());

    size = effectiveSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final center = size.center(offset);
    final segment = size.radius / 6;

    // Base
    final outerRadius = segment * 6;
    const division = 10;
    for (int i = 0; i < division; i++) {
      final it = (i * totalAngle.degrees / division).radians;
      _drawParagraph(
        canvas,
        valueBuilder(it).round().toString(),
        offset: toPolar(center, it + startAngle, outerRadius),
        color: labelColor,
        fontSize: labelFontRadius * 2,
      );
    }

    // Mid-region
    final midCircleRadius = segment * 5;
    final midRect = Rect.fromCircle(center: center, radius: midCircleRadius);
    _drawShadow(canvas, midRect, shadowColor);
    canvas.drawCircle(center, midCircleRadius, Paint()..color = const Color(0xFF323544));

    // Progress
    final angle = _currentAngle;
    final sweepAngle = math.max(angle, 0.001);
    final gradientShader = SweepGradient(
      endAngle: sweepAngle,
      tileMode: TileMode.mirror,
      transform: GradientRotation(startAngle),
      colors: const [Color(0xFF626BFC), Colors.purpleAccent],
    ).createShader(midRect);
    final strokeWidth = segment / 3;
    final progressShadowElevation = strokeWidth * .15;
    // Progress arc glow
    canvas.drawArc(
      midRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: progressShadowElevation, sigmaY: progressShadowElevation)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradientShader,
    );
    // Progress arc
    canvas.drawArc(
      midRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradientShader,
    );

    // Progress Indicator
    final progressIndicatorRadius = strokeWidth / 2;
    final progressIndicatorCenter = toPolar(center, startAngle, midRect.radius);
    _drawShadow(
      canvas,
      Rect.fromCircle(center: progressIndicatorCenter, radius: progressIndicatorRadius),
      Colors.white,
      useCenter: true,
      elevation: progressIndicatorRadius * 3,
    );
    canvas.drawCircle(progressIndicatorCenter, progressIndicatorRadius * 2, Paint()..color = const Color(0xFF626BFC));
    canvas.drawCircle(progressIndicatorCenter, progressIndicatorRadius, Paint()..color = Colors.white);

    // Knob
    final knobRadius = segment * 3.5;
    knobRect = Rect.fromCircle(center: center, radius: knobRadius);
    _drawShadow(canvas, knobRect, shadowColor);
    canvas.drawCircle(
      center,
      knobRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4A4C62), Color(0xFF37384B)],
        ).createShader(knobRect),
    );

    // Indicator
    final indicatorRadius = strokeWidth / 3;
    final indicatorCenter = toPolar(center, angle + startAngle, knobRadius - 16.0);
    _drawShadow(
      canvas,
      Rect.fromCircle(center: indicatorCenter, radius: indicatorRadius),
      Colors.white,
      useCenter: true,
      elevation: indicatorRadius * 3,
    );
    canvas.drawCircle(indicatorCenter, indicatorRadius, Paint()..color = Colors.white);

    // Value
    final titleRect = _drawParagraph(
      canvas,
      valueBuilder(angle).round().toString(),
      offset: center - const Offset(0, titleFontRadius),
      color: Colors.white,
      fontSize: titleFontRadius * 2,
    );
    _drawParagraph(
      canvas,
      "C",
      offset: titleRect.topRight + const Offset(labelFontRadius * 2, labelFontRadius * 2),
      color: labelColor,
      fontSize: labelFontRadius * 2,
    );
    _drawParagraph(
      canvas,
      "ROOM\nTEMPERATURE",
      offset: center + const Offset(0, 16.0),
      color: labelColor,
      fontSize: labelFontRadius * 2,
    );
  }

  void _drawShadow(Canvas canvas, Rect rect, Color color, {bool useCenter = false, double? elevation}) {
    elevation ??= rect.radius * .25;
    canvas.drawShadow(Path()..addOval(rect.translate(0, useCenter ? -elevation : 0)), color, elevation, false);
  }

  Rect _drawParagraph(Canvas canvas, String text,
      {required Offset offset, required Color color, required double fontSize}) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600))
      ..addText(text);
    final paragraph = builder.build();
    final constraints = ui.ParagraphConstraints(width: (fontSize / 1.25) * text.length);
    final finalOffset = offset - Offset(constraints.width / 2, fontSize / 2);
    canvas.drawParagraph(paragraph..layout(constraints), finalOffset);
    return Rect.fromLTWH(finalOffset.dx, finalOffset.dy, paragraph.longestLine, paragraph.height);
  }
}

extension on num {
  double get radians => (this * math.pi) / 180.0;

  double get degrees => (this * 180.0) / math.pi;

  num normalize(num max) => (this % max + max) % max;
}

extension on Size {
  double get radius => shortestSide / 2;
}

extension on Rect {
  double get radius => shortestSide / 2;
}

double toAngle(Offset coords, double radius) {
  return (coords - Offset(radius, radius)).direction;
}

Offset toPolar(Offset center, double radians, double radius) {
  return center + Offset(radius * math.cos(radians), radius * math.sin(radians));
}

// https://stackoverflow.com/a/55088673/8236404
double Function(double input) interpolate({
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
}) {
  assert(inputMin != inputMax || outputMin != outputMax);

  final diff = (outputMax - outputMin) / (inputMax - inputMin);
  return (input) => ((input - inputMin) * diff) + outputMin;
}
