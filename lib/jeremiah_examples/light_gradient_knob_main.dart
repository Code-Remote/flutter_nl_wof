/// Light Gradient Knob
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: aa1880d8627f4d8c1fb87cd3a7422e1e
/// DartPad: https://dartpad.dev/?id=aa1880d8627f4d8c1fb87cd3a7422e1e
///
/// Features: Rotatable color picker knob, gradient arc track, dynamic indicator pointer
/// Techniques: Custom RenderBox, PanGestureRecognizer, LinearGradient, ImageFilter blur, angle clamping

import 'dart:math' as math;
import 'dart:ui';

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

class _PlaygroundState extends State<Playground> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width, 600.0);
    return Scaffold(
      backgroundColor: const Color(0xFFEAEBEA),
      body: Center(
        child: SizedBox.fromSize(
          size: Size.square(width),
          child: LightGradientKnob(
            range: const Range(Colors.blueAccent, Colors.redAccent),
            onChanged: (Color color) {
              // print(color);
            },
          ),
        ),
      ),
    );
  }
}

class LightGradientKnob extends LeafRenderObjectWidget {
  const LightGradientKnob({Key? key, this.color, this.knobColor, required this.range, this.onChanged})
      : super(key: key);

  final Color? color;
  final Color? knobColor;
  final Range<Color> range;
  final ValueChanged<Color>? onChanged;

  @override
  RenderLightGradientKnob createRenderObject(BuildContext context) =>
      RenderLightGradientKnob(color: color, knobColor: knobColor, range: range).._onChanged = onChanged;

  @override
  void updateRenderObject(BuildContext context, covariant RenderLightGradientKnob renderObject) => renderObject
    ..range = range
    ..knobColor = knobColor
    .._onChanged = onChanged;
}

class RenderLightGradientKnob extends RenderBox {
  RenderLightGradientKnob({
    required Color? color,
    required Color? knobColor,
    required Range<Color> range,
  })  : _selectedAngle = _resolveAngleFromColor(range, color),
        _knobColor = knobColor ?? _defaultKnobColor,
        _range = range {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
  }

  static const _aspectRatio = 1.125;
  static final _lowerLimitAngle = 225.radians;
  static final _upperLimitAngle = 315.radians;
  static const _defaultKnobColor = Color(0xFFFFFFFF);
  static final double Function(double input) _angleToColor =
      interpolate(inputMin: _lowerLimitAngle, inputMax: _upperLimitAngle);

  static double _resolveAngleFromColor(Range<Color> range, Color? color) {
    if (color == null) {
      return _lowerLimitAngle;
    }
    final colorToAngle = interpolate(
        inputMin: range.start.value.toDouble(),
        inputMax: range.end.value.toDouble(),
        outputMin: _lowerLimitAngle,
        outputMax: _upperLimitAngle);
    return colorToAngle(color.value.toDouble());
  }

  late final List<Color> colorsSpectrum;
  late final PanGestureRecognizer drag;

  Color get knobColor => _knobColor;
  Color _knobColor;

  set knobColor(Color? knobColor) {
    if (_knobColor == knobColor) {
      return;
    }

    _knobColor = knobColor ?? _defaultKnobColor;
    markNeedsPaint();
  }

  Range<Color> get range => _range;
  Range<Color> _range;

  set range(Range<Color> range) {
    if (_range == range) {
      return;
    }

    _range = range;
    markNeedsPaint();
  }

  double get selectedAngle => _selectedAngle;
  double _selectedAngle;

  set selectedAngle(double selectedAngle) {
    final angle = selectedAngle.clamp(_lowerLimitAngle, _upperLimitAngle);
    if (_selectedAngle == angle) {
      return;
    }

    _selectedAngle = angle;
    markNeedsPaint();
  }

  Color get _color => Color.lerp(range.start, range.end, _angleToColor(selectedAngle))!;

  ValueChanged<Color>? _onChanged;

  Offset _currentDragOffset = Offset.zero;

  Size get _knobSize => Size.fromRadius(size.radius / _aspectRatio);

  late Rect _knobBounds;

  void _onDragStart(DragStartDetails details) => _currentDragOffset = globalToLocal(details.globalPosition);

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final center = size.center(Offset.zero);
    _onChangeAngle(selectedAngle + toAngle(_currentDragOffset, center) - toAngle(previousOffset, center));
  }

  void _onDragCancel() => _currentDragOffset = Offset.zero;

  void _onDragEnd(DragEndDetails details) => _onDragCancel();

  void _onChangeAngle(double angle) {
    selectedAngle = angle.normalizeAngle;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      HapticFeedback.selectionClick();
      _onChanged?.call(_color);
    });
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  BoxConstraints get constraints => super.constraints.loosen();

  @override
  void performLayout() {
    size = _computeSize(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _computeSize(constraints);

  Size _computeSize(BoxConstraints constraints) =>
      Size(constraints.constrainWidth() / _aspectRatio, constraints.constrainWidth());

  @override
  bool hitTestSelf(Offset position) => _knobBounds.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _knobBounds = offset.translate((size.width / 2) - _knobSize.radius, size.height - _knobSize.height) & _knobSize;
    final canvas = context.canvas;
    _drawKnob(canvas);
    _drawTrack(canvas);
  }

  void _drawIndicator(
    Canvas canvas, {
    required double trackWidth,
    required double trackRadius,
  }) {
    final halfLength = trackWidth * 1.5 / 2;
    final unitVector = Offset.fromDirection(selectedAngle);
    final strokeWidth = halfLength / 3;
    final blurRadius = strokeWidth / 3;
    final p1 = _knobBounds.center + (unitVector * (trackRadius + halfLength));
    final p2 = _knobBounds.center + (unitVector * (trackRadius - halfLength));
    canvas
      ..drawLine(
        p1,
        p2,
        Paint()
          ..imageFilter = ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius)
          ..strokeWidth = strokeWidth
          ..color = Colors.black26,
      )
      ..drawLine(
        p1,
        p2,
        Paint()
          ..color = knobColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
  }

  void _drawTrack(Canvas canvas) {
    final radius = _knobBounds.size.radius;
    final center = _knobBounds.center;
    final trackWidth = radius / 5;
    final trackRadius = radius * 1.4;
    final outerRadius = trackRadius + (trackWidth / 2);
    final innerRadius = trackRadius - (trackWidth / 2);
    final startOuterOffset = center + Offset.fromDirection(_lowerLimitAngle, outerRadius);
    final endOuterOffset = center + Offset.fromDirection(_upperLimitAngle, outerRadius);
    final startInnerOffset = center + Offset.fromDirection(_lowerLimitAngle, innerRadius);
    final endInnerOffset = center + Offset.fromDirection(_upperLimitAngle, innerRadius);
    final path = Path()
      ..moveTo(startOuterOffset.dx, startOuterOffset.dy)
      ..arcToPoint(endOuterOffset, radius: Radius.circular(outerRadius))
      ..arcToPoint(endInnerOffset, radius: Radius.circular(trackWidth / 2))
      ..arcToPoint(startInnerOffset, radius: Radius.circular(innerRadius), clockwise: false)
      ..arcToPoint(startOuterOffset, radius: Radius.circular(trackWidth / 2))
      ..close();
    final blurRadius = radius / 6;
    canvas
      ..drawPath(
        path,
        Paint()
          ..imageFilter = ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius)
          ..shader = LinearGradient(colors: [range.start, range.end]).createShader(_knobBounds),
      )
      ..drawPath(
        path,
        Paint()..shader = LinearGradient(colors: [range.start, range.end]).createShader(_knobBounds),
      );

    _drawIndicator(canvas, trackWidth: trackWidth, trackRadius: trackRadius);
  }

  void _drawKnob(Canvas canvas) {
    final radius = _knobBounds.size.radius;
    final center = _knobBounds.center;
    final triangle = 4.radians;
    final magnitude = radius / 12;
    final top = center + Offset.fromDirection(selectedAngle, radius + magnitude);
    final left = center + Offset.fromDirection(selectedAngle - triangle, radius);
    final right = center + Offset.fromDirection(selectedAngle + triangle, radius);
    final arcRadius = Radius.circular(radius);
    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..arcToPoint(center + Offset.fromDirection(selectedAngle + 180.radians, radius), radius: arcRadius)
      ..arcToPoint(left, radius: arcRadius)
      ..close();
    final blurRadius = radius / 2;
    final innerRadius = radius / 3.5;
    canvas
      ..drawPath(
        path,
        Paint()
          ..imageFilter = ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius)
          ..color = Colors.black26,
      )
      ..drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [HSVColor.fromColor(knobColor).withValue(.881).toColor(), knobColor],
            transform: GradientRotation(selectedAngle),
          ).createShader(_knobBounds),
      )
      ..drawCircle(
        center,
        innerRadius,
        Paint()
          ..color = Colors.white
          ..shader = LinearGradient(
            colors: [knobColor, HSVColor.fromColor(knobColor).withValue(.856).toColor()],
            transform: GradientRotation(selectedAngle),
          ).createShader(_knobBounds),
      )
      ..drawCircle(
        center,
        innerRadius,
        Paint()
          ..color = Colors.white60
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.luminosity
          ..strokeWidth = 2,
      );
  }
}

extension SizeX on Size {
  double get radius => shortestSide / 2;
}

const fullAngle = math.pi * 2.0;

extension NumX<T extends num> on T {
  double get radians => (this * math.pi) / 180.0;

  T normalize(T max) => (this % max + max) % max as T;

  double get normalizeAngle => normalize(fullAngle as T).toDouble();
}

double toAngle(Offset position, Offset center) => (position - center).direction;

class Range<T> {
  const Range(this.start, this.end);

  final T start;
  final T end;
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
