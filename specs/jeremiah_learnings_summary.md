# Jeremiah Ogbomo Flutter UI Patterns - Master Learnings Summary

## Overview

This document synthesizes the key patterns and techniques learned from analyzing Jeremiah Ogbomo's 19 Flutter UI component examples from "Saturdays are for Flutter". These learnings directly inform the implementation of an expert-level Wheel of Fortune widget.

---

## 1. Architecture Patterns

### 1.1 LeafRenderObjectWidget vs CustomPainter

**Preferred Pattern**: `LeafRenderObjectWidget` with custom `RenderBox`

| Approach | When to Use |
|----------|-------------|
| `LeafRenderObjectWidget` | Complex interactive widgets with state, gestures, animations |
| `CustomPainter` | Simple, stateless decorative painting |

**Why LeafRenderObjectWidget is better for WoF**:
- Direct access to gesture handling via `handleEvent`
- Can manage AnimationControllers internally
- Fine-grained control over `shouldRepaint` equivalent via `markNeedsPaint()`
- Proper integration with Flutter's render pipeline

```dart
class WheelOfFortune extends LeafRenderObjectWidget {
  @override
  RenderWheelOfFortune createRenderObject(BuildContext context) =>
      RenderWheelOfFortune();
}

class RenderWheelOfFortune extends RenderBox {
  // Full control over painting, hit testing, and gestures
}
```

### 1.2 isRepaintBoundary = true

**CRITICAL for performance** - Used in every interactive example:

```dart
@override
bool get isRepaintBoundary => true;
```

**Effect**: Creates a separate compositing layer, isolating repaints to this widget only. Without this, parent widgets repaint on every animation frame.

### 1.3 sizedByParent Optimization

When widget size depends only on constraints (not content):

```dart
@override
bool get sizedByParent => true;

@override
Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
```

**Effect**: Enables layout caching - Flutter can skip layout when only paint changes.

---

## 2. Circular Geometry Patterns

### 2.1 Polar Coordinate Helpers

Every circular component uses these core utilities:

```dart
// Convert angle to position on circle
Offset toPolar(Offset center, double angle, double radius) {
  return center + Offset(
    radius * math.cos(angle),
    radius * math.sin(angle),
  );
}

// Convert position to angle from center
double toAngle(Offset position, Offset center) {
  return (position - center).direction;
}

// Alternative using Dart's built-in
Offset toPolarAlt(Offset center, double angle, double radius) {
  return center + Offset.fromDirection(angle, radius);
}
```

### 2.2 Angle Normalization

Prevent angle accumulation and handle wrap-around:

```dart
extension AngleExtension on double {
  static const twoPi = math.pi * 2.0;

  double get normalizeAngle => (this % twoPi + twoPi) % twoPi;

  double get degrees => (this * 180.0) / math.pi;
  double get radians => (this * math.pi) / 180.0;
}
```

### 2.3 Start Angle Convention

Standard practice: Start at "12 o'clock" position:

```dart
static const startAngle = -math.pi / 2;  // -90 degrees
```

---

## 3. Segment Drawing Patterns

### 3.1 Pie Slice Path Construction (FROM ACTIVITY RINGS)

**Most important pattern for WoF** - Create filled pie segments:

```dart
Path createPieSegment({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
}) {
  final endAngle = startAngle + sweepAngle;
  final isLargeArc = sweepAngle >= math.pi;  // CRITICAL!

  final startOuter = toPolar(center, startAngle, outerRadius);
  final endOuter = toPolar(center, endAngle, outerRadius);
  final startInner = toPolar(center, startAngle, innerRadius);
  final endInner = toPolar(center, endAngle, innerRadius);

  return Path()
    ..moveTo(startOuter.dx, startOuter.dy)
    ..arcToPoint(
      endOuter,
      radius: Radius.circular(outerRadius),
      largeArc: isLargeArc,  // Required for arcs > 180°
    )
    ..lineTo(endInner.dx, endInner.dy)
    ..arcToPoint(
      startInner,
      radius: Radius.circular(innerRadius),
      largeArc: isLargeArc,
      clockwise: false,  // Opposite direction for inner arc
    )
    ..close();
}
```

### 3.2 Segment with Gaps (FROM GAUGE METER)

Add visual separation between segments:

```dart
void drawSegmentsWithGaps(Canvas canvas, int count, double gapAngle) {
  final segmentSweep = (2 * math.pi / count) - gapAngle;

  for (int i = 0; i < count; i++) {
    final startAngle = (i * 2 * math.pi / count) + (gapAngle / 2);

    canvas.drawArc(
      rect,
      startAngle,
      segmentSweep,
      true,  // useCenter for pie slice
      Paint()..color = colors[i],
    );
  }
}
```

### 3.3 Path Storage for Hit Testing (FROM ACTIVITY RINGS)

Store segment paths for later hit detection:

```dart
final Map<int, Path> segmentPaths = {};

@override
void paint(PaintingContext context, Offset offset) {
  for (int i = 0; i < segments.length; i++) {
    final path = createPieSegment(...);
    segmentPaths[i] = path;
    canvas.drawPath(path, Paint()..color = segments[i].color);
  }
}

@override
bool hitTestSelf(Offset position) {
  for (final entry in segmentPaths.entries) {
    if (entry.value.contains(position)) {
      _hitSegmentIndex = entry.key;
      return true;
    }
  }
  return false;
}
```

---

## 4. Animation Patterns

### 4.1 Spring Physics for Natural Deceleration (FROM TIME OF DAY PICKER)

**Perfect for WoF spin stopping**:

```dart
void spinToStop(Offset velocity) {
  final simulation = SpringSimulation(
    SpringDescription(
      mass: 30.0,      // Higher = slower deceleration
      stiffness: 1.0,  // Lower = bouncier
      damping: 1.0,    // Lower = more oscillation
    ),
    currentAngle,      // start
    targetAngle,       // end
    velocity.distance, // initial velocity
  );

  _controller.animateWith(simulation);
}
```

### 4.2 Repaint Listenable (FROM RIPPLES)

**Efficient animation repainting** - Let Flutter handle the repaint scheduling:

```dart
class WheelPainter extends CustomPainter {
  WheelPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    // Use animation.value directly
    final rotation = animation.value;
    canvas.rotate(rotation);
    // ...
  }

  @override
  bool shouldRepaint(WheelPainter old) => false;  // Animation handles repaints!
}
```

### 4.3 Staggered Animation (FROM ACTIVITY RINGS)

Animate multiple elements with offsets:

```dart
for (int i = 0; i < segments.length; i++) {
  final interval = Interval(
    i / segments.length,
    (i + 1) / segments.length,
    curve: Curves.easeOut,
  );
  final segmentProgress = interval.transform(animation.value);
  // Use segmentProgress for this segment
}
```

---

## 5. Gesture Handling Patterns

### 5.1 Drag-to-Rotation (FROM CIRCULAR MOOD PICKER, TIME OF DAY PICKER)

Convert drag gestures to rotation:

```dart
late PanGestureRecognizer _drag;
Offset _lastDragPosition = Offset.zero;

@override
void attach(PipelineOwner owner) {
  super.attach(owner);
  _drag = PanGestureRecognizer()
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = _onDragEnd;
}

void _onDragStart(DragStartDetails details) {
  _lastDragPosition = details.localPosition;
}

void _onDragUpdate(DragUpdateDetails details) {
  final center = size.center(Offset.zero);
  final previousAngle = toAngle(_lastDragPosition, center);
  final currentAngle = toAngle(details.localPosition, center);

  _rotation += currentAngle - previousAngle;
  _rotation = _rotation.normalizeAngle;

  _lastDragPosition = details.localPosition;
  markNeedsPaint();
}

void _onDragEnd(DragEndDetails details) {
  // Calculate velocity for physics-based animation
  final velocity = details.velocity.pixelsPerSecond;
  _animateWithVelocity(velocity);
}

@override
void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
  if (event is PointerDownEvent) {
    _drag.addPointer(event);
  }
}
```

### 5.2 Velocity-Based Spin (FOR WoF)

Use drag velocity to determine spin strength:

```dart
void _onDragEnd(DragEndDetails details) {
  final velocity = details.velocity.pixelsPerSecond;
  final angularVelocity = velocity.distance / size.radius;

  // Determine spin direction from drag direction
  final center = size.center(Offset.zero);
  final dragDirection = toAngle(_lastDragPosition, center);
  final velocityDirection = velocity.direction;
  final clockwise = (velocityDirection - dragDirection).normalizeAngle < math.pi;

  // Start spin animation
  _startSpin(
    angularVelocity * (clockwise ? 1 : -1),
    targetSegment: _calculateTargetSegment(angularVelocity),
  );
}
```

---

## 6. Value Interpolation Pattern

Reusable function found in every example:

```dart
double Function(double) interpolate({
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
}) {
  final scale = (outputMax - outputMin) / (inputMax - inputMin);
  return (input) => ((input - inputMin) * scale) + outputMin;
}

// Usage
final angleToSegment = interpolate(
  inputMax: 2 * math.pi,
  outputMax: numberOfSegments.toDouble(),
);
final segment = angleToSegment(currentAngle).floor() % numberOfSegments;
```

---

## 7. Performance Optimization Patterns

### 7.1 Efficient shouldRepaint

Only repaint when necessary:

```dart
@override
bool shouldRepaint(WheelPainter old) =>
    segments != old.segments ||
    pointerColor != old.pointerColor;
    // Animation repaints handled by repaint listenable
```

### 7.2 Path Caching

Cache paths that don't change:

```dart
Path? _cachedWheelPath;
Size? _lastSize;

Path get wheelPath {
  if (_cachedWheelPath == null || _lastSize != size) {
    _cachedWheelPath = _buildWheelPath();
    _lastSize = size;
  }
  return _cachedWheelPath!;
}
```

### 7.3 Haptic Feedback on Value Change

Provide tactile feedback without excessive calls:

```dart
int? _lastHapticSegment;

void _maybeHaptic(int currentSegment) {
  if (currentSegment != _lastHapticSegment) {
    HapticFeedback.selectionClick();
    _lastHapticSegment = currentSegment;
  }
}
```

---

## 8. Wheel of Fortune Specific Recommendations

Based on all analyzed patterns, here's the recommended architecture:

### Architecture
```dart
class WheelOfFortune extends LeafRenderObjectWidget {
  final List<WheelSegment> segments;
  final ValueChanged<WheelSegment>? onSpinComplete;
  final WheelController? controller;

  @override
  RenderWheelOfFortune createRenderObject(BuildContext context) =>
      RenderWheelOfFortune(segments: segments);
}

class RenderWheelOfFortune extends RenderBox {
  // State
  double _rotation = 0.0;
  final Map<int, Path> _segmentPaths = {};

  // Animation
  late AnimationController _spinController;

  // Gestures
  late PanGestureRecognizer _drag;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;
}
```

### Key Implementation Points

1. **Use filled Path segments**, not stroked arcs
2. **Handle largeArc flag** for segments > 180°
3. **Store paths for hit testing** the winning segment
4. **Use SpringSimulation** for natural spin deceleration
5. **Start at -90° (12 o'clock)** for intuitive positioning
6. **Normalize angles** to prevent accumulation
7. **Cache segment paths** when wheel configuration doesn't change
8. **Provide haptic feedback** when pointer passes segment boundaries

---

## Quick Reference: Essential Imports

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
```

---

## Files to Study in Detail

Priority order for WoF implementation:

1. **time_of_day_picker_main.dart** - Spring physics, segment interaction
2. **activity_rings_main.dart** - Arc path construction, hit testing
3. **simple_discrete_slider_main.dart** - Snap-to-value logic
4. **gauge_meter_main.dart** - Cursor positioning, segment colors
5. **ripples_main.dart** - Efficient animation patterns
6. **circular_mood_picker_main.dart** - Drag-to-rotation
