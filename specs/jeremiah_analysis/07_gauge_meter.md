# Gauge Meter Analysis

## Metadata
- **Gist ID**: b6213599b8c63c8249fc2b50e934bff4
- **DartPad URL**: https://dartpad.dev/?id=b6213599b8c63c8249fc2b50e934bff4
- **Relevance to Wheel of Fortune**: 🟡 MEDIUM

## Overview
A semi-circular gauge meter with colored divisions, draggable cursor, and value labels. Shows proper arc rendering with gaps between segments, cursor positioning on arc path, and interpolation between value ranges. Useful for WoF pointer mechanics and arc-based segment rendering.

## PROS (Good Patterns)

### 1. Arc Segments with Spacing
- **What**: Draws multiple arc segments with small gaps between them using `spacingAngle`
- **Why it's good**: Clean visual separation between divisions without complex path operations. Simply adjust start angle by spacing amount
- **Code reference**:
```dart
final spacingAngle = (strokeWidth / 2.5).clamp(4.0, 8.0).radians;
for (var i = 0; i < _divisions.length; i++) {
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
```

### 2. Cursor Positioning on Arc
- **What**: Uses `toPolar()` to position cursor exactly on the arc path
- **Why it's good**: Cursor always sits on the track regardless of angle. Essential pattern for WoF pointer that needs to point at arc edge
- **Code reference**:
```dart
final cursorOffset = toPolar(gaugeBounds.center, angleOffset + _currentDragAngle, bounds.width / 2);
```

### 3. Division-Based Color Selection
- **What**: Iterates through divisions to find correct color based on current percentage
- **Why it's good**: Clean way to map value ranges to colors. Extensible to any number of divisions
- **Code reference**:
```dart
Pair<String, Color> _deriveSelectedPair(double value) {
  for (final item in _divisions) {
    if (item.a >= value) {
      return Pair(item.b, item.c);
    }
  }
  return Pair(_divisions[0].b, _divisions[0].c);
}
```

### 4. Angle Clamping and Normalization
- **What**: Uses `shiftAngle()` extension to handle angle wraparound, then clamps to valid range
- **Why it's good**: Robust handling of angle math edge cases. Prevents negative angles or values beyond sweep
- **Code reference**:
```dart
_currentDragAngle = currentAngle
    .shiftAngle(maxSweepAngle / 2)
    .clamp(0.0, maxSweepAngle)
    .toDouble();
```

### 5. Responsive Size with Constraints
- **What**: Calculates preferred size based on shortest side with clamp bounds
- **Why it's good**: Adapts to available space while maintaining aspect ratio and usability
- **Code reference**:
```dart
final preferredWidth = (size.shortestSide * .9).clamp(200.0, 800.0).toDouble();
```

### 6. Flexible Division Data Structure
- **What**: Uses `Pair2<double, String, Color>` for divisions with fraction, label, and color
- **Why it's good**: Self-contained data model for each division. Easy to modify colors/labels without changing rendering code
- **Code reference**:
```dart
divisions: [
  Pair2(0.33, 'Bad', Color(0xFFFF524F)),
  Pair2(0.56, 'Average', Color(0xFFFAD64C)),
  Pair2(0.8, 'Good', Color(0xFFB2FF59)),
  Pair2(1.0, 'Excellent', Color(0xFF51AD54)),
],
```

## CONS (Anti-patterns or Improvements)

### 1. No Animation for Value Changes
- **What**: Value changes update immediately without transition
- **Why it's problematic**: Feels abrupt when dragging or when value is set programmatically
- **Better approach**: Animate `_currentDragAngle` to new value using `AnimationController`

### 2. Hit Test on Cursor Only
- **What**: Only the cursor is hit-testable, not the track
- **Why it's problematic**: Users might expect to tap on track to set value (common slider pattern)
- **Better approach**: Add track hit testing with tap gesture recognizer

### 3. TextPainter Without Caching
- **What**: Creates new `TextPainter` for each label on every paint
- **Why it's problematic**: Allocates memory and performs layout calculations on each frame
- **Better approach**: Cache `TextPainter` instances and only rebuild when text/style changes

### 4. Static 180° Sweep
- **What**: Hardcoded to half-circle gauge (180°)
- **Why it's problematic**: Not reusable for other gauge types (270°, full circle)
- **Better approach**: Accept `maxSweepAngle` as widget parameter

### 5. Interpolate Function in Global Scope
- **What**: Long interpolate function defined at file level
- **Why it's problematic**: Clutters file, hard to test, not clearly associated with gauge
- **Better approach**: Move to utility file or extension method

## Key Techniques Extracted

1. **Arc with gaps**: Subtract spacing angle from sweep angle
2. **Polar positioning**: `toPolar(center, angle, radius)` for points on arc
3. **Fraction-based divisions**: Store divisions as fractions 0-1, multiply by total for actual values
4. **Angle shifting**: Handle negative angles with `(angle / twoPi).ceil() * twoPi` adjustment
5. **Drag-to-angle conversion**: `toAngle(position, center)` for gesture handling

## Applicable to Wheel of Fortune

- [x] **Segment drawing approach** - Arc drawing with gaps pattern useful for separated segments
- [ ] **Animation technique** - NEEDS IMPROVEMENT: No animation in this example
- [x] **Gesture handling** - Drag-to-angle conversion pattern is valuable
- [x] **Performance pattern** - Proper hit testing on specific regions

## Key Insights for WoF Implementation

1. **Pointer positioning**: The `toPolar()` pattern is exactly what WoF needs for positioning:
   - The pointer/indicator at the edge of the wheel
   - Prize icons at segment centers

2. **Segment gap rendering**: For visual separation between WoF segments:
   ```dart
   final segmentAngle = (360 / numberOfSegments).radians;
   final gapAngle = 2.radians; // Small gap
   for (int i = 0; i < numberOfSegments; i++) {
     canvas.drawArc(
       rect,
       startAngle + (i * segmentAngle) + (gapAngle / 2),
       segmentAngle - gapAngle,
       true, // Use center for pie slice
       Paint()..color = colors[i],
     );
   }
   ```

3. **Value-to-segment mapping**: The division lookup pattern can determine winning segment:
   ```dart
   int getWinningSegment(double normalizedAngle) {
     final segmentSize = 1.0 / numberOfSegments;
     for (int i = 0; i < numberOfSegments; i++) {
       if (normalizedAngle < (i + 1) * segmentSize) {
         return i;
       }
     }
     return 0;
   }
   ```

## Helper Functions Worth Copying

```dart
// Convert offset to angle relative to center
double toAngle(Offset position, Offset center) {
  return (position - center).direction;
}

// Convert angle to offset on circle
Offset toPolar(Offset center, double radians, double radius) {
  return center + Offset(radius * math.cos(radians), radius * math.sin(radians));
}

// Shift angle to positive range
extension on num {
  double shiftAngle(num shift) =>
      toDouble() + ((-this - shift) / (math.pi * 2)).ceil() * (math.pi * 2);
}
```
