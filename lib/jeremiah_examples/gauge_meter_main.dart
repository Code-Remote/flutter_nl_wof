/// Gauge Meter
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: b6213599b8c63c8249fc2b50e934bff4
/// DartPad: https://dartpad.dev/?id=b6213599b8c63c8249fc2b50e934bff4
///
/// Features: Semi-circular gauge with colored divisions, draggable cursor, status labels
/// Techniques: Custom RenderBox, PanGestureRecognizer, arc drawing, angle interpolation, TextPainter

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: Playground(),
      ),
    );

class Playground extends StatefulWidget {
  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: GaugeMeterWidget(
            value: 30,
            min: 0,
            max: 100,
            divisions: [
              Pair2(0.33, 'Bad', Color(0xFFFF524F)),
              Pair2(0.56, 'Average', Color(0xFFFAD64C)),
              Pair2(0.8, 'Good', Color(0xFFB2FF59)),
              Pair2(1.0, 'Excellent', Color(0xFF51AD54)),
            ],
            onChanged: (value) {
              print(value);
            },
          ),
        ),
      ),
    );
  }
}

class GaugeMeterWidget extends LeafRenderObjectWidget {
  GaugeMeterWidget({
    required this.value,
    required this.min,
    required this.max,
    this.divisions = const [],
    this.onChanged,
  })  : assert(value >= min && value <= max),
        assert(divisions.isNotEmpty);

  final double value;
  final double min;
  final double max;
  final List<Pair2<double, String, Color>> divisions;
  final ValueChanged<double>? onChanged;

  @override
  RenderGaugeMeter createRenderObject(BuildContext context) {
    return RenderGaugeMeter(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderGaugeMeter renderObject,
  ) {
    renderObject
      ..value = value
      ..min = min
      ..max = max
      ..divisions = divisions
      ..onChanged = onChanged;
  }
}

class RenderGaugeMeter extends RenderBox {
  RenderGaugeMeter({
    required double value,
    required double min,
    required double max,
    required List<Pair2<double, String, Color>> divisions,
    ValueChanged<double>? onChanged,
  })  : _value = value,
        _min = min,
        _max = max,
        _divisions = divisions,
        _onChanged = onChanged,
        _currentPercentage = _valueToPercentage(value, min: min, max: max),
        _currentDragAngle = _valueToAngle(value, min: min, max: max) {
    drag = PanGestureRecognizer()
      ..onStart = _onStartDrag
      ..onUpdate = _onUpdateDrag;
  }

  late final PanGestureRecognizer drag;
  late Rect gaugeBounds;
  late Rect cursorBounds;

  late double _currentPercentage;
  late double _value;

  set value(double value) {
    if (value == _value) {
      return;
    }
    _value = value;
    markNeedsPaint();
  }

  late double _min;

  set min(double min) {
    if (min == _min) {
      return;
    }
    _min = min;
    markNeedsPaint();
  }

  late double _max;

  set max(double max) {
    if (max == _max) {
      return;
    }
    _max = max;
    markNeedsPaint();
  }

  late List<Pair2<double, String, Color>> _divisions;

  set divisions(List<Pair2<double, String, Color>> divisions) {
    if (divisions == _divisions) {
      return;
    }
    _divisions = divisions;
    markNeedsPaint();
  }

  ValueChanged<double>? _onChanged;

  set onChanged(ValueChanged<double>? onChanged) {
    _onChanged = onChanged;
  }

  static const cursorColor = Color(0xFF303030);
  static const selectionColor = Color(0xFFFF524F);
  static const trackColor = Color(0xFFD8D8DA);
  static const labelFontColor = Color(0xFFFFFFFF);

  static final angleOffset = -180.radians;
  static final maxSweepAngle = 180.radians;

  double _currentDragAngle = 0.0;
  Offset _currentDragOffset = Offset.zero;

  void _onStartDrag(DragStartDetails details) {
    _currentDragOffset = details.localPosition;
  }

  void _onUpdateDrag(DragUpdateDetails details) {
    _currentDragOffset += details.delta;
    final currentAngle =
        toAngle(_currentDragOffset, gaugeBounds.center) + maxSweepAngle;
    _currentDragAngle = currentAngle
        .shiftAngle(maxSweepAngle / 2)
        .clamp(0.0, maxSweepAngle)
        .toDouble();
    _currentPercentage = _currentDragAngle / maxSweepAngle;
    _value = _percentageToValue(_currentPercentage, min: _min, max: _max);
    _onChanged?.call(_value);
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => cursorBounds.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final preferredWidth =
        (size.shortestSide * .9).clamp(200.0, 800.0).toDouble();
    final bounds = Rect.fromCenter(
      center: size.center(offset),
      width: preferredWidth,
      height: preferredWidth / 2,
    );

    // Draw background arc with spacing
    gaugeBounds =
        bounds.topLeft & Size(bounds.size.width, bounds.size.height * 2);
    final strokeWidth = gaugeBounds.radius / 24;
    final spacingAngle = (strokeWidth / 2.5).clamp(4.0, 8.0).radians;
    final backgroundPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var prevFraction = 0.0;
    for (var i = 0; i < _divisions.length; i++) {
      final fraction = _divisions[i].a;
      final offset = i == 0.0 ? 0.0 : spacingAngle;
      canvas.drawArc(
        gaugeBounds,
        angleOffset + (prevFraction * maxSweepAngle) + offset,
        (maxSweepAngle * (fraction - prevFraction)) - offset,
        false,
        backgroundPaint,
      );

      prevFraction = fraction;
    }

    // Draw selection arc
    final selectedPair = _deriveSelectedPair(_currentPercentage);
    final selectedColor = selectedPair.b;
    canvas.drawArc(
      gaugeBounds,
      angleOffset,
      _currentDragAngle,
      false,
      Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw cursor
    final cursorRadius = strokeWidth * 1.75;
    final cursorOffset = toPolar(
        gaugeBounds.center, angleOffset + _currentDragAngle, bounds.width / 2);
    cursorBounds =
        Rect.fromCircle(center: cursorOffset, radius: cursorRadius * 1.5);
    canvas.drawCircle(cursorOffset, cursorRadius, Paint()..color = cursorColor);
    canvas.drawCircle(
      cursorOffset,
      cursorRadius,
      Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth * .7
        ..style = PaintingStyle.stroke,
    );

    // Draw min and max labels
    final labelFontSize = strokeWidth * 2.5;
    final labelOffset = Offset(0, labelFontSize * 1.85);
    _drawLabel(
      canvas,
      _min.toInt().toString(),
      fontSize: labelFontSize,
      center: gaugeBounds.centerLeft + labelOffset,
      color: labelFontColor,
    );
    _drawLabel(
      canvas,
      _max.toInt().toString(),
      fontSize: labelFontSize,
      center: gaugeBounds.centerRight + labelOffset,
      color: labelFontColor,
    );

    // Draw status label
    final statusFontSize = labelFontSize * 1.75;
    _drawLabel(
      canvas,
      selectedPair.a,
      fontSize: statusFontSize,
      center: gaugeBounds.center.translate(0, statusFontSize / 1.25),
      color: selectedColor,
    );

    // Draw value label
    _drawLabel(
      canvas,
      _value.round().toString(),
      fontSize: gaugeBounds.radius / 2.25,
      center: gaugeBounds.center.translate(0, -gaugeBounds.radius / 3.5),
      color: labelFontColor,
    );
  }

  static double _valueToPercentage(
    double value, {
    required double min,
    required double max,
  }) {
    return interpolate(inputMin: min, inputMax: max)(value);
  }

  static double _valueToAngle(
    double value, {
    required double min,
    required double max,
  }) {
    return _valueToPercentage(value, min: min, max: max) * maxSweepAngle;
  }

  static double _percentageToValue(
    double value, {
    required double min,
    required double max,
  }) {
    return interpolate(outputMin: min, outputMax: max)(value);
  }

  Pair<String, Color> _deriveSelectedPair(double value) {
    for (final item in _divisions) {
      if (item.a >= value) {
        return Pair(item.b, item.c);
      }
      continue;
    }
    return Pair(_divisions[0].b, _divisions[0].c);
  }

  void _drawLabel(
    Canvas canvas,
    String text, {
    required double fontSize,
    required Offset center,
    required Color color,
  }) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      )
      ..layout();
    final bounds = (center & textPainter.size)
        .translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, bounds.topLeft);
  }
}

extension NumX<T extends num> on T {
  static double twoPi = math.pi * 2.0;

  double get radians => (this * math.pi) / 180.0;

  double shiftAngle(T shift) =>
      toDouble() + ((-this - shift) / twoPi).ceil() * twoPi;
}

extension RectX on ui.Rect {
  double get radius => shortestSide / 2;

  ui.Rect shrink({
    double top = 0.0,
    double left = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    return ui.Rect.fromLTRB(this.left + left, this.top + top,
        this.right - right, this.bottom - bottom);
  }
}

double toAngle(ui.Offset position, ui.Offset center) {
  return (position - center).direction;
}

ui.Offset toPolar(ui.Offset center, double radians, double radius) {
  return center +
      ui.Offset(radius * math.cos(radians), radius * math.sin(radians));
}

class Pair<A, B> {
  const Pair(this.a, this.b);

  final A a;
  final B b;
}

class Pair2<A, B, C> {
  const Pair2(this.a, this.b, this.c);

  final A a;
  final B b;
  final C c;
}

// https://stackoverflow.com/a/55088673/8236404
double Function(double input) interpolate({
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
}) {
  //range check
  if (inputMin == inputMax) {
    print("Warning: Zero input range");
    return (_) => 0.0;
  }

  if (outputMin == outputMax) {
    print("Warning: Zero output range");
    return (_) => 0.0;
  }

  //check reversed input range
  var reverseInput = false;
  final oldMin = math.min(inputMin, inputMax);
  final oldMax = math.max(inputMin, inputMax);
  if (oldMin != inputMin) {
    reverseInput = true;
  }

  //check reversed output range
  var reverseOutput = false;
  final newMin = math.min(outputMin, outputMax);
  final newMax = math.max(outputMin, outputMax);
  if (newMin != outputMin) {
    reverseOutput = true;
  }

  // Hot-rod the most common case.
  if (!reverseInput && !reverseOutput) {
    final dNew = newMax - newMin;
    final dOld = oldMax - oldMin;
    return (double x) {
      return ((x - oldMin) * dNew / dOld) + newMin;
    };
  }

  return (double x) {
    double portion;
    if (reverseInput) {
      portion = (oldMax - x) * (newMax - newMin) / (oldMax - oldMin);
    } else {
      portion = (x - oldMin) * (newMax - newMin) / (oldMax - oldMin);
    }
    double result;
    if (reverseOutput) {
      result = newMax - portion;
    } else {
      result = portion + newMin;
    }

    return result;
  };
}
