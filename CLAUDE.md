# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter Wheel of Fortune widget for the FlutterNL Community meetup talk (April 2025). This project aims to create a highly optimized custom Flutter widget with advanced CustomPaint implementations and animations. The talk focuses on building "the perfect custom Flutter widget" showcasing Flutter's low-level rendering capabilities.

**Learning Goal**: Study Jeremiah Ogbomo's custom UI component patterns from https://saturdays-are-for-flutter.vercel.app/ to understand advanced CustomPaint techniques and achieve expert-level implementation.

## Technical Focus Areas

This project emphasizes:
- **CustomPainter**: Efficient canvas drawing with `paint()` and `shouldRepaint()`
- **Canvas API**: `drawArc()`, `drawPath()`, `drawCircle()`, rotation transforms
- **Animation Controllers**: Spinning physics, easing curves, momentum-based deceleration
- **Performance Optimization**: Minimizing repaints, layer caching, `RepaintBoundary`
- **Hit Testing**: Custom `hitTest` for interactive wheel segments

## Key Flutter Concepts for Wheel of Fortune

### CustomPaint Structure
```dart
CustomPaint(
  painter: WheelPainter(...),  // Background/static elements
  foregroundPainter: ...,       // Overlay elements (pointer)
  child: ...,                   // Optional child widget
)
```

### Animation Pattern
```dart
// Use AnimationController with TickerProviderStateMixin
// Apply physics-based curves for realistic spin deceleration
// Consider: CurvedAnimation, Curves.decelerate, custom Simulation
```

## Development Commands

```bash
flutter run                    # Run the app
flutter test                   # Run tests
flutter analyze                # Analyze code
dart format lib/               # Format code
```

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── jeremiah_examples/         # Reference implementations (19 examples)
│   └── README.md              # Index with DartPad links
specs/
├── plan.md                    # Implementation plan
├── jeremiah_learnings_summary.md    # Synthesized patterns
├── wheel_of_fortune_architecture.md # WoF implementation guide
└── jeremiah_analysis/         # Per-component PROS/CONS analysis
```

## Key Learnings from Jeremiah's Examples

### Architecture
- Use `LeafRenderObjectWidget` instead of `CustomPainter` for complex interactive widgets
- Always set `isRepaintBoundary = true` for animated/interactive components
- Use `sizedByParent = true` with `computeDryLayout` for layout optimization

### Segment Drawing (from Activity Rings)
```dart
// CRITICAL: Use filled paths, not stroked arcs for pie segments
Path createPieSegment(Offset center, double innerRadius, double outerRadius,
                      double startAngle, double sweepAngle) {
  final isLargeArc = sweepAngle >= math.pi;  // Required for arcs > 180°
  // ... arcToPoint with largeArc flag
}
```

### Spring Physics (from Time of Day Picker)
```dart
// For natural wheel deceleration
_controller.animateWith(SpringSimulation(
  SpringDescription(mass: 30.0, stiffness: 1.0, damping: 1.0),
  currentAngle, targetAngle, velocity,
));
```

### Gesture Handling
```dart
// Drag-to-rotate pattern
void _onDragUpdate(DragUpdateDetails details) {
  final center = size.center(Offset.zero);
  final previousAngle = toAngle(_lastPosition, center);
  final currentAngle = toAngle(details.localPosition, center);
  _rotation += currentAngle - previousAngle;
}
```

## Reference Resources

- Jeremiah's Flutter UI examples: https://saturdays-are-for-flutter.vercel.app/
- Local examples: `lib/jeremiah_examples/` (with DartPad links in README.md)
- Analysis documents: `specs/jeremiah_analysis/`
- Flutter CustomPaint docs: https://api.flutter.dev/flutter/widgets/CustomPaint-class.html

## DartPad Compatibility

Final implementations should be exportable as single-file DartPad examples. Keep dependencies minimal (flutter SDK only when possible) for easy sharing.
