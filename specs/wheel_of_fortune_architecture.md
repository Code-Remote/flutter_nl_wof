# Wheel of Fortune - Implementation Architecture

Based on analysis of Jeremiah Ogbomo's Flutter UI patterns, this document provides the architectural blueprint for building an expert-level Wheel of Fortune widget.

---

## Goals

1. **Performance**: 60fps spinning animation, minimal repaints
2. **Accuracy**: Precise segment boundaries, correct winner detection
3. **Feel**: Physics-based deceleration, haptic feedback
4. **Flexibility**: Configurable segments, colors, and behavior

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    WheelOfFortune Widget                     │
│  (LeafRenderObjectWidget)                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              RenderWheelOfFortune                    │   │
│  │  (RenderBox)                                         │   │
│  │                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐                 │   │
│  │  │ WheelPainter │  │PointerPainter│                 │   │
│  │  │ (segments)   │  │ (indicator)  │                 │   │
│  │  └──────────────┘  └──────────────┘                 │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │           Animation System                    │   │   │
│  │  │  • SpinSimulation (custom physics)           │   │   │
│  │  │  • AnimationController                       │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │           Gesture Handling                    │   │   │
│  │  │  • PanGestureRecognizer (drag to spin)       │   │   │
│  │  │  • Velocity tracking                         │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Classes

### 1. WheelSegment Data Model

```dart
class WheelSegment {
  const WheelSegment({
    required this.label,
    required this.color,
    this.icon,
    this.value,
    this.weight = 1.0,  // For weighted probability
  });

  final String label;
  final Color color;
  final IconData? icon;
  final dynamic value;
  final double weight;
}
```

### 2. WheelController

```dart
class WheelController extends ChangeNotifier {
  WheelState _state = WheelState.idle;
  int? _targetSegment;

  WheelState get state => _state;

  /// Spin to a specific segment (for rigged results)
  void spinTo(int segmentIndex) {
    _targetSegment = segmentIndex;
    _state = WheelState.spinning;
    notifyListeners();
  }

  /// Spin with random result
  void spin() {
    _targetSegment = null;
    _state = WheelState.spinning;
    notifyListeners();
  }

  /// Called internally when spin completes
  void _onSpinComplete(int winningSegment) {
    _state = WheelState.idle;
    _targetSegment = winningSegment;
    notifyListeners();
  }
}

enum WheelState { idle, spinning, stopped }
```

### 3. Main Widget

```dart
class WheelOfFortune extends LeafRenderObjectWidget {
  const WheelOfFortune({
    super.key,
    required this.segments,
    this.controller,
    this.onSpinStart,
    this.onSpinComplete,
    this.pointerPosition = WheelPointerPosition.top,
    this.pointerColor,
    this.innerRadius = 0.3,  // Ratio of outer radius
  });

  final List<WheelSegment> segments;
  final WheelController? controller;
  final VoidCallback? onSpinStart;
  final ValueChanged<WheelSegment>? onSpinComplete;
  final WheelPointerPosition pointerPosition;
  final Color? pointerColor;
  final double innerRadius;

  @override
  RenderWheelOfFortune createRenderObject(BuildContext context) {
    return RenderWheelOfFortune(
      segments: segments,
      controller: controller,
      pointerPosition: pointerPosition,
      pointerColor: pointerColor ?? Theme.of(context).colorScheme.primary,
      innerRadius: innerRadius,
    )
      .._onSpinStart = onSpinStart
      .._onSpinComplete = onSpinComplete;
  }

  @override
  void updateRenderObject(BuildContext context, RenderWheelOfFortune renderObject) {
    renderObject
      ..segments = segments
      ..controller = controller
      ..pointerPosition = pointerPosition
      ..pointerColor = pointerColor ?? Theme.of(context).colorScheme.primary
      ..innerRadius = innerRadius
      .._onSpinStart = onSpinStart
      .._onSpinComplete = onSpinComplete;
  }
}

enum WheelPointerPosition { top, right, bottom, left }
```

---

## RenderBox Implementation

### Core Structure

```dart
class RenderWheelOfFortune extends RenderBox {
  RenderWheelOfFortune({
    required List<WheelSegment> segments,
    WheelController? controller,
    required WheelPointerPosition pointerPosition,
    required Color pointerColor,
    required double innerRadius,
  })  : _segments = segments,
        _controller = controller,
        _pointerPosition = pointerPosition,
        _pointerColor = pointerColor,
        _innerRadius = innerRadius {
    _setupGestures();
  }

  // ============ State ============
  List<WheelSegment> _segments;
  WheelController? _controller;
  WheelPointerPosition _pointerPosition;
  Color _pointerColor;
  double _innerRadius;

  double _rotation = 0.0;
  final Map<int, Path> _segmentPaths = {};

  VoidCallback? _onSpinStart;
  ValueChanged<WheelSegment>? _onSpinComplete;

  // ============ Animation ============
  late AnimationController _spinController;
  SpinSimulation? _currentSimulation;

  // ============ Gestures ============
  late PanGestureRecognizer _drag;
  Offset _lastDragPosition = Offset.zero;
  double _dragStartRotation = 0.0;

  // ============ Lifecycle ============
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _spinController = AnimationController.unbounded(vsync: _vsync)
      ..addListener(_onAnimationTick);
    _controller?.addListener(_onControllerUpdate);
  }

  @override
  void detach() {
    _spinController.dispose();
    _drag.dispose();
    _controller?.removeListener(_onControllerUpdate);
    super.detach();
  }

  // ============ Performance ============
  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final size = constraints.biggest.shortestSide;
    return Size.square(size);
  }
}
```

### Painting

```dart
@override
void paint(PaintingContext context, Offset offset) {
  final canvas = context.canvas;
  final center = size.center(offset);
  final outerRadius = size.shortestSide / 2;
  final innerRadiusActual = outerRadius * _innerRadius;

  // Save and rotate canvas for wheel rotation
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(_rotation);
  canvas.translate(-center.dx, -center.dy);

  // Draw segments
  _segmentPaths.clear();
  final segmentAngle = 2 * math.pi / _segments.length;

  for (int i = 0; i < _segments.length; i++) {
    final segment = _segments[i];
    final startAngle = _startAngle + (i * segmentAngle);

    final path = _createSegmentPath(
      center: center,
      innerRadius: innerRadiusActual,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: segmentAngle,
    );

    _segmentPaths[i] = path;

    // Draw segment fill
    canvas.drawPath(path, Paint()..color = segment.color);

    // Draw segment border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw label
    _drawSegmentLabel(canvas, segment, center, outerRadius, startAngle, segmentAngle);
  }

  canvas.restore();

  // Draw center cap
  canvas.drawCircle(center, innerRadiusActual * 0.8, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    innerRadiusActual * 0.8,
    Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  // Draw pointer (doesn't rotate)
  _drawPointer(canvas, center, outerRadius);
}

Path _createSegmentPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
}) {
  final endAngle = startAngle + sweepAngle;
  final isLargeArc = sweepAngle >= math.pi;

  final startOuter = _toPolar(center, startAngle, outerRadius);
  final endOuter = _toPolar(center, endAngle, outerRadius);
  final startInner = _toPolar(center, startAngle, innerRadius);
  final endInner = _toPolar(center, endAngle, innerRadius);

  return Path()
    ..moveTo(startInner.dx, startInner.dy)
    ..lineTo(startOuter.dx, startOuter.dy)
    ..arcToPoint(endOuter, radius: Radius.circular(outerRadius), largeArc: isLargeArc)
    ..lineTo(endInner.dx, endInner.dy)
    ..arcToPoint(startInner, radius: Radius.circular(innerRadius), largeArc: isLargeArc, clockwise: false)
    ..close();
}

void _drawPointer(Canvas canvas, Offset center, double radius) {
  final pointerAngle = _pointerAngleFromPosition(_pointerPosition);
  final pointerTip = _toPolar(center, pointerAngle, radius + 10);
  final pointerBase1 = _toPolar(center, pointerAngle - 0.15, radius - 20);
  final pointerBase2 = _toPolar(center, pointerAngle + 0.15, radius - 20);

  final pointerPath = Path()
    ..moveTo(pointerTip.dx, pointerTip.dy)
    ..lineTo(pointerBase1.dx, pointerBase1.dy)
    ..lineTo(pointerBase2.dx, pointerBase2.dy)
    ..close();

  canvas.drawPath(
    pointerPath,
    Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawPath(pointerPath, Paint()..color = _pointerColor);
}
```

### Gesture Handling

```dart
void _setupGestures() {
  _drag = PanGestureRecognizer()
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = _onDragEnd
    ..onCancel = _onDragCancel;
}

@override
bool hitTestSelf(Offset position) => true;

@override
void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
  if (event is PointerDownEvent && _spinController.isAnimating == false) {
    _drag.addPointer(event);
  }
}

void _onDragStart(DragStartDetails details) {
  _lastDragPosition = details.localPosition;
  _dragStartRotation = _rotation;
}

void _onDragUpdate(DragUpdateDetails details) {
  final center = size.center(Offset.zero);
  final previousAngle = _toAngle(_lastDragPosition, center);
  final currentAngle = _toAngle(details.localPosition, center);

  _rotation += currentAngle - previousAngle;
  _lastDragPosition = details.localPosition;

  _maybeHapticOnSegmentChange();
  markNeedsPaint();
}

void _onDragEnd(DragEndDetails details) {
  final velocity = details.velocity.pixelsPerSecond;
  final angularVelocity = velocity.distance / (size.shortestSide / 2);

  if (angularVelocity > 1.0) {  // Minimum velocity threshold
    _startSpin(angularVelocity);
  }
}

void _onDragCancel() {
  _lastDragPosition = Offset.zero;
}
```

### Spin Animation

```dart
void _startSpin(double angularVelocity) {
  _onSpinStart?.call();

  // Calculate target rotation (multiple full rotations + landing position)
  final minRotations = 3;
  final extraRotations = (angularVelocity / 10).clamp(0, 5);
  final totalRotations = minRotations + extraRotations;

  // Optionally land on specific segment
  final targetSegment = _controller?._targetSegment;
  double targetRotation;

  if (targetSegment != null) {
    final segmentAngle = 2 * math.pi / _segments.length;
    final segmentCenter = _startAngle + (targetSegment * segmentAngle) + (segmentAngle / 2);
    final pointerAngle = _pointerAngleFromPosition(_pointerPosition);
    targetRotation = _rotation + (totalRotations * 2 * math.pi) + (pointerAngle - segmentCenter);
  } else {
    targetRotation = _rotation + (totalRotations * 2 * math.pi) + math.Random().nextDouble() * 2 * math.pi;
  }

  _currentSimulation = SpinSimulation(
    start: _rotation,
    end: targetRotation,
    velocity: angularVelocity,
  );

  _spinController.animateWith(_currentSimulation!).then((_) => _onSpinComplete());
}

void _onAnimationTick() {
  _rotation = _spinController.value;
  _maybeHapticOnSegmentChange();
  markNeedsPaint();
}

void _onSpinComplete() {
  final winningIndex = _getSegmentAtPointer();
  _controller?._onSpinComplete(winningIndex);
  _onSpinComplete?.call(_segments[winningIndex]);
}

int _getSegmentAtPointer() {
  final pointerAngle = _pointerAngleFromPosition(_pointerPosition);
  final normalizedRotation = (_rotation % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
  final effectivePointerAngle = (pointerAngle - normalizedRotation + 2 * math.pi) % (2 * math.pi);

  final segmentAngle = 2 * math.pi / _segments.length;
  final adjustedAngle = (effectivePointerAngle - _startAngle + 2 * math.pi) % (2 * math.pi);

  return (adjustedAngle / segmentAngle).floor() % _segments.length;
}
```

### Custom Spin Simulation

```dart
class SpinSimulation extends Simulation {
  SpinSimulation({
    required this.start,
    required this.end,
    required this.velocity,
  }) : _distance = end - start;

  final double start;
  final double end;
  final double velocity;
  final double _distance;

  // Deceleration curve parameters
  static const friction = 0.015;

  @override
  double x(double time) {
    // Custom deceleration curve
    final t = _progress(time);
    return start + (_distance * _easeOutCubic(t));
  }

  @override
  double dx(double time) {
    final t = _progress(time);
    return _distance * _easeOutCubicDerivative(t) * friction;
  }

  double _progress(double time) {
    return (time * friction).clamp(0.0, 1.0);
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3);

  double _easeOutCubicDerivative(double t) => 3 * math.pow(1 - t, 2);

  @override
  bool isDone(double time) => _progress(time) >= 1.0;
}
```

---

## Usage Example

```dart
class WheelDemo extends StatefulWidget {
  @override
  State<WheelDemo> createState() => _WheelDemoState();
}

class _WheelDemoState extends State<WheelDemo> {
  final _controller = WheelController();

  final segments = [
    WheelSegment(label: '100', color: Colors.red),
    WheelSegment(label: '200', color: Colors.blue),
    WheelSegment(label: '300', color: Colors.green),
    WheelSegment(label: 'JACKPOT', color: Colors.amber),
    WheelSegment(label: '50', color: Colors.purple),
    WheelSegment(label: '150', color: Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: WheelOfFortune(
                segments: segments,
                controller: _controller,
                onSpinComplete: (segment) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You won: ${segment.label}!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _controller.spin(),
              child: const Text('SPIN!'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Implementation Checklist

### Phase 1: Core Rendering
- [ ] Create WheelSegment data model
- [ ] Implement LeafRenderObjectWidget structure
- [ ] Implement segment path drawing with correct arc handling
- [ ] Draw segment labels/icons
- [ ] Draw pointer indicator
- [ ] Add isRepaintBoundary optimization

### Phase 2: Interaction
- [ ] Implement drag-to-spin gesture
- [ ] Calculate angular velocity from drag
- [ ] Add haptic feedback on segment boundary crossing
- [ ] Implement hit testing for tap interactions

### Phase 3: Animation
- [ ] Create SpinSimulation class
- [ ] Implement natural deceleration curve
- [ ] Add winning segment calculation
- [ ] Implement WheelController for programmatic control
- [ ] Add callbacks for spin start/complete

### Phase 4: Polish
- [ ] Add segment shadows/depth effect
- [ ] Implement celebration animation on win
- [ ] Add sound support (optional)
- [ ] Performance testing and optimization
- [ ] DartPad-compatible single-file export

---

## DartPad Export Notes

For sharing as a single-file DartPad example:
1. Keep all classes in one file
2. Remove external package dependencies
3. Use only `flutter/material.dart` and `dart:math`, `dart:ui`
4. Inline all helper extensions
5. Add main() with a complete demo app
