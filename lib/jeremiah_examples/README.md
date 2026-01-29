# Jeremiah Ogbomo Flutter UI Examples

Collection of Flutter UI components from [Saturdays are for Flutter](https://saturdays-are-for-flutter.vercel.app/) by Jeremiah Ogbomo.

These examples serve as reference implementations for building the Wheel of Fortune widget.

## Examples Index

| # | Example | DartPad | Relevance | Key Techniques |
|---|---------|---------|-----------|----------------|
| 1 | Studio | [Open](https://dartpad.dev/?id=7f5aa471859a2237f80b83aefeb62da7) | Medium | Level meters, knob control, gesture handling |
| 2 | Circular Mood Picker | [Open](https://dartpad.dev/?id=ddf1e4eefcd2f10fd4292f8be6e1fedc) | Medium | Drag-to-rotate, angle calculation |
| 3 | Bed Time | [Open](https://dartpad.dev/?id=59efa9b1ac3fab64fb6ce251c8575862) | Medium | Dual-handle circular slider |
| 4 | Light Gradient Knob | [Open](https://dartpad.dev/?id=aa1880d8627f4d8c1fb87cd3a7422e1e) | Low | Gradient shaders, custom render object |
| 5 | Circular Color Slider | [Open](https://dartpad.dev/?id=d085c121045c83c9e903f82086758a65) | Medium | Color wheel, sweep gradient |
| 6 | **Time of Day Picker** | [Open](https://dartpad.dev/?id=eb2777d101bbed1081f2afaca4f1c729) | 🔴 HIGH | Spring physics, segment interaction |
| 7 | Gauge Meter | [Open](https://dartpad.dev/?id=b6213599b8c63c8249fc2b50e934bff4) | Medium | Arc segments with gaps, cursor positioning |
| 8 | Graph with Selector | [Open](https://dartpad.dev/?id=3b6d8504c68db0ce9458d3fb320c9178) | Low | Sliver rendering, curved paths |
| 9 | Ripples | [Open](https://dartpad.dev/?id=6bcc57b1c6b919e68905618787b66c36) | Medium | Animation repaint listenable |
| 10 | Neon Glow Graph | [Open](https://dartpad.dev/?id=2a7faa9b6c80e49214896be06b587d6a) | Low | Glow effects, MaskFilter |
| 11 | Slide to Send Button | [Open](https://dartpad.dev/?id=9a26cdbf0e3acb2fca51368544fed994) | Low | Gesture-driven animation |
| 12 | Shader Gradient Knob | [Open](https://dartpad.dev/?id=56e8d96c30a603e4afd548ab8d11d09d) | Low | Fragment shaders |
| 13 | Measure Slider | [Open](https://dartpad.dev/?id=574eeb1dea4474204f7fbe42c1eeead3) | Low | Tick rendering, scrollable |
| 14 | Knob Progress | [Open](https://dartpad.dev/?id=5e5dea1685a897a4bebe5a9b43899dba) | Medium | Circular progress, drag interaction |
| 15 | Slide Color Picker | [Open](https://dartpad.dev/?id=01d2587083a76a22e40d1e30976336b9) | Low | Linear gradient picker |
| 16 | **Activity Rings** | [Open](https://dartpad.dev/?id=fa12224ecdaf51b0281b2e8120afc2f1) | 🔴 HIGH | Arc path construction, hit testing |
| 17 | Vertical Slider | [Open](https://dartpad.dev/?id=9816d45610bbd567f6eae12b1d5e4b04) | Low | Vertical orientation |
| 18 | Glow Progress Bar | [Open](https://dartpad.dev/?id=1079588b40eb19c559480eb5f6aa5d2f) | Low | Animated glow effect |
| 19 | **Simple Discrete Slider** | [Open](https://dartpad.dev/?id=7ffb6c9c64ef6ec203c1253a21a565b3) | 🔴 HIGH | Snap-to-value logic |

## Priority Study Order for Wheel of Fortune

1. **time_of_day_picker_main.dart** - Spring physics, segment-based rotation
2. **activity_rings_main.dart** - Arc path construction, `largeArc` handling
3. **simple_discrete_slider_main.dart** - Discrete value snapping
4. **gauge_meter_main.dart** - Cursor positioning on arc
5. **ripples_main.dart** - Efficient animation patterns
6. **circular_mood_picker_main.dart** - Drag-to-rotate gesture

## Common Patterns

All examples use these key patterns:

```dart
// LeafRenderObjectWidget for direct render control
class MyWidget extends LeafRenderObjectWidget {
  @override
  RenderMyWidget createRenderObject(BuildContext context) => RenderMyWidget();
}

// isRepaintBoundary for performance isolation
@override
bool get isRepaintBoundary => true;

// Polar coordinate conversion
Offset toPolar(Offset center, double angle, double radius) {
  return center + Offset.fromDirection(angle, radius);
}

// Angle normalization
double normalizeAngle(double angle) {
  const twoPi = math.pi * 2.0;
  return (angle % twoPi + twoPi) % twoPi;
}
```

## Analysis Documents

Detailed PROS/CONS analysis for each component is available in:
`specs/jeremiah_analysis/`

## Credits

All examples by [Jeremiah Ogbomo](https://saturdays-are-for-flutter.vercel.app/)
