# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter Wheel of Fortune widget for the FlutterNL Community meetup talk (April 2025). This project aims to create a highly optimized custom Flutter widget with advanced CustomPaint implementations and animations. The talk focuses on building "the perfect custom Flutter widget" showcasing Flutter's low-level rendering capabilities.

**Learning Goal**: Study Jeremiah Ogbomo's custom UI component patterns from https://saturdays-are-for-flutter.vercel.app/ to understand advanced CustomPaint techniques and achieve expert-level implementation.

## Development Commands

```bash
# Run the app
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d chrome

# Analyze code
flutter analyze

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Format code
dart format lib/

# Get dependencies
flutter pub get
```

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

## Reference Resources

- Jeremiah's Flutter UI examples: https://saturdays-are-for-flutter.vercel.app/
- Flutter CustomPaint docs: https://api.flutter.dev/flutter/widgets/CustomPaint-class.html
- Canvas class: https://api.flutter.dev/flutter/dart-ui/Canvas-class.html

## DartPad Compatibility

Final implementations should be exportable as single-file DartPad examples. Keep dependencies minimal (flutter SDK only when possible) for easy sharing.
