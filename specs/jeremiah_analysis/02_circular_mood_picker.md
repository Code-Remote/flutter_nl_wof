# Circular Mood Picker Analysis

## Metadata
- **Gist ID**: ddf1e4eefcd2f10fd4292f8be6e1fedc
- **DartPad URL**: https://dartpad.dev/?id=ddf1e4eefcd2f10fd4292f8be6e1fedc
- **Relevance to Wheel of Fortune**: 🟡 MEDIUM

## Overview
A circular picker where users drag a handle around an arc to select a mood (color). Features emoji rendering at positions, gradient arc track, and smooth gesture handling. Useful for understanding circular gesture mechanics and visual feedback.

## PROS (Good Patterns)

### 1. LeafRenderObjectWidget for Performance
- **What**: Extends `LeafRenderObjectWidget` instead of using `CustomPainter` inside a `StatefulWidget`
- **Why it's good**: More direct control over the render layer. Avoids unnecessary widget rebuilds. The render object can manage its own state efficiently
- **Code reference**:
```dart
class CircularMoodPicker extends LeafRenderObjectWidget {
  @override
  RenderCircularMoodPicker createRenderObject(BuildContext context) =>
      RenderCircularMoodPicker();
}
```

### 2. Drag-Based Arc Interaction
- **What**: Uses `PanGestureRecognizer` with `onDragUpdate` to convert drag deltas to angle changes
- **Why it's good**: Natural interaction for circular controls. Previous/current offset comparison gives precise angle delta
- **Code reference**:
```dart
void _onDragUpdate(DragUpdateDetails details) {
  final previousOffset = _currentDragOffset;
  _currentDragOffset += details.delta;
  final diffInAngle = toAngle(_currentDragOffset, center) - toAngle(previousOffset, center);
  _onChangeAngle(_currentAngle + diffInAngle);
}
```

### 3. isRepaintBoundary = true
- **What**: Declares render object as repaint boundary
- **Why it's good**: Isolates repaints to just this widget. Critical for smooth 60fps animation/interaction. Parent widgets won't repaint when this changes
- **Code reference**:
```dart
@override
bool get isRepaintBoundary => true;
```

### 4. Angle Normalization Helper
- **What**: Uses extension method `.normalizeAngle` to keep angles in 0-2π range
- **Why it's good**: Prevents accumulating massive angle values during continuous dragging. Clean, reusable pattern
- **Code reference**:
```dart
double get normalizeAngle => normalize(fullAngle as T).toDouble();
// Where: T normalize(T max) => (this % max + max) % max as T;
```

### 5. Handle Position from Angle
- **What**: Computes handle position using `Offset.fromDirection(angle, radius)`
- **Why it's good**: Built-in Dart method, cleaner than manual `cos`/`sin` calculation
- **Code reference**:
```dart
final handleCenter = center + Offset.fromDirection(_currentAngle, arcRadius);
```

## CONS (Anti-patterns or Improvements)

### 1. No Tap-to-Position Support
- **What**: Only supports drag interaction, not tap to set position
- **Why it's problematic**: Users might expect to tap on the arc to jump to that position
- **Better approach**: Add `TapGestureRecognizer` with angle calculation from tap position

### 2. Fixed Mood Emojis
- **What**: Mood options/emojis are hardcoded in the render object
- **Why it's problematic**: Can't customize moods without modifying render code
- **Better approach**: Accept mood data as widget parameter

### 3. Gesture Recognizer Leaks
- **What**: Creates `PanGestureRecognizer` in constructor, no explicit disposal
- **Why it's problematic**: Could cause memory leaks if not properly cleaned up
- **Better approach**: Create in `attach()`, dispose in `detach()`

### 4. No Animation for Handle
- **What**: Handle moves immediately with finger
- **Why it's problematic**: If programmatically setting mood, there's no smooth transition
- **Better approach**: Add optional animation when value is set externally

### 5. Magic Arc Radius Calculation
- **What**: Uses `size.radius * 0.65` for arc radius
- **Why it's problematic**: Not clear why 0.65, might not work well at all sizes
- **Better approach**: Document or make configurable

## Key Techniques Extracted

1. **Offset.fromDirection()**: Built-in polar-to-cartesian conversion
2. **toAngle()**: `(offset - center).direction` for cartesian-to-polar
3. **Angle delta from drag**: Compare previous/current offset angles for rotation amount
4. **Emoji rendering on canvas**: Use `TextPainter` with emoji text at calculated positions
5. **Arc handle visualization**: Draw indicator at calculated position + visual feedback

## Applicable to Wheel of Fortune

- [ ] **Segment drawing approach** - Not segment-based, uses continuous arc
- [ ] **Animation technique** - No animation patterns here
- [x] **Gesture handling** - Drag-to-angle delta calculation is exactly what WoF needs
- [x] **Performance pattern** - isRepaintBoundary usage

## Key Insights for WoF Implementation

1. **Angle delta calculation is key**: For spinning the wheel with drag gesture:
   ```dart
   void onDragUpdate(DragUpdateDetails details) {
     final previousOffset = _currentDragOffset;
     _currentDragOffset += details.delta;

     final center = size.center(Offset.zero);
     final angleDelta = (previousOffset - center).direction -
                        (_currentDragOffset - center).direction;

     _wheelRotation += angleDelta;
     markNeedsPaint();
   }
   ```

2. **Use Offset.fromDirection for positioning**: Cleaner than manual math:
   ```dart
   // Instead of:
   Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle))
   // Use:
   center + Offset.fromDirection(angle, radius)
   ```

3. **Handle wrap-around**: The normalize pattern handles when angle crosses 0/2π boundary

## Pattern for WoF Drag Rotation

```dart
class WheelGestureHandler {
  Offset _lastDragPosition = Offset.zero;
  double _currentRotation = 0.0;

  void onDragStart(DragStartDetails details) {
    _lastDragPosition = details.localPosition;
  }

  void onDragUpdate(DragUpdateDetails details, Offset wheelCenter) {
    final currentPosition = details.localPosition;

    // Calculate angle change
    final lastAngle = (wheelCenter - _lastDragPosition).direction;
    final currentAngle = (wheelCenter - currentPosition).direction;

    // Add difference (with sign handling for rotation direction)
    _currentRotation += currentAngle - lastAngle;

    // Normalize to 0-2π
    _currentRotation = _currentRotation % (2 * pi);
    if (_currentRotation < 0) _currentRotation += 2 * pi;

    _lastDragPosition = currentPosition;
  }
}
```
