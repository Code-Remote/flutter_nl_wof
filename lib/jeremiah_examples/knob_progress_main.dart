/// Knob Progress
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 5e5dea1685a897a4bebe5a9b43899dba
/// DartPad: https://dartpad.dev/?id=5e5dea1685a897a4bebe5a9b43899dba
///
/// Features: Rotated dial with dot indicators, inner rotation line, value display
/// Techniques: Custom RenderBox, PanGestureRecognizer, Transform.rotate, polar coordinates

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const greyColor = Color(0xFFDDDDE0);
const darkColor = Color(0xFF333333);

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  ValueNotifier<double> valueNotifier = ValueNotifier<double>(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: valueNotifier,
              builder: (_, double value, __) => Text(
                "${value.toStringAsFixed(1)}",
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: darkColor),
                maxLines: 1,
              ),
            ),
            SizedBox(height: 48),
            Center(
              child: Transform.rotate(
                angle: 225.radians,
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Knob(
                    onChanged: (value) {
                      print(value);
                      valueNotifier.value = value;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Knob extends LeafRenderObjectWidget {
  const Knob({super.key, required this.onChanged});

  final ValueChanged<double> onChanged;

  @override
  KnobRenderBox createRenderObject(BuildContext context) {
    return KnobRenderBox(onChanged: onChanged);
  }

  @override
  void updateRenderObject(BuildContext context, KnobRenderBox renderObject) {
    renderObject..onChanged = onChanged;
  }
}

class KnobRenderBox extends RenderProxyBox {
  KnobRenderBox({
    required ValueChanged<double> onChanged,
  }) : _onChanged = onChanged {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onEnd = ((_) => _onDragCancel())
      ..onCancel = _onDragCancel
      ..onUpdate = _onDragUpdate;
  }

  late final DragGestureRecognizer drag;

  double _currentAngle = 0.0;
  Offset _currentDragOffset = Offset.zero;

  final startAngle = 270.radians;
  final sweepAngle = 270.radians;

  final minAngle = -90.radians;

  late ValueChanged<double> _onChanged;

  ValueChanged<double> get onChanged => _onChanged;

  set onChanged(ValueChanged<double> onChange) {
    _onChanged = onChange;
    markNeedsPaint();
  }

  void _onRangeChanged(double value) {
    final _value = value;
    if (_value == _currentAngle) {
      return;
    }
    HapticFeedback.selectionClick();
    _currentAngle = _value;
    onChanged(
      interpolate(inputMin: minAngle, inputMax: minAngle + sweepAngle)(_value),
    );
    markNeedsPaint();
  }

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = globalToLocal(details.globalPosition);
  }

  void _onDragCancel() => _currentDragOffset = Offset.zero;

  void _onDragUpdate(DragUpdateDetails details) {
    final newOffset = _currentDragOffset + details.delta;
    final angle = coordinatesToRadians(newOffset, size.width / 2);
    if (angle >= minAngle) {
      _onRangeChanged(angle);
      _currentDragOffset = newOffset;
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final radius = size.width / 2;
    final center = size.center(offset);
    final circleGap = radius / 7.5;

    const maxCount = 50.0;
    const minCircleRadius = 2.5;
    const preciseFractions = 1;
    final angleMapper = interpolate(
        inputMax: maxCount,
        outputMin: minAngle,
        outputMax: minAngle + sweepAngle);
    for (double i = 0; i <= maxCount; i++) {
      final angle = angleMapper(i);
      final isGreater = _currentAngle.roundFractions(preciseFractions) >=
          angle.roundFractions(preciseFractions);
      final circleRadius = isGreater ? minCircleRadius * 2.0 : minCircleRadius;
      final polarCoord = radiansToCoordinates(center, angle, radius);
      context.canvas.drawCircle(
        polarCoord,
        circleRadius,
        Paint()..color = isGreater ? darkColor : greyColor,
      );
    }

    context.canvas
        .drawCircle(center, radius - circleGap, Paint()..color = greyColor);

    final innerCircleRadius = radius - circleGap * 2;
    context.canvas
        .drawCircle(center, innerCircleRadius, Paint()..color = Colors.white);
    context.canvas.drawLine(
      radiansToCoordinates(
          center, _currentAngle, innerCircleRadius - circleGap),
      radiansToCoordinates(
          center, _currentAngle, innerCircleRadius - circleGap * 2),
      Paint()
        ..color = darkColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }
}

extension on num {
  double get radians => this * math.pi / 180;

  double roundFractions(int fractions) {
    return double.parse(toStringAsFixed(fractions));
  }
}

double coordinatesToRadians(Offset coords, double radius) {
  final offset = coords - Offset(radius, radius);
  return math.atan2(offset.dy, offset.dx);
}

Offset radiansToCoordinates(Offset center, double radians, double radius) {
  return center +
      Offset(radius * math.cos(radians), radius * math.sin(radians));
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
