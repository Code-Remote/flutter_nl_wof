/// Vertical Slider
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 9816d45610bbd567f6eae12b1d5e4b04
/// DartPad: https://dartpad.dev/?id=9816d45610bbd567f6eae12b1d5e4b04
///
/// Features: Battery-themed vertical slider, draggable knob, gradient fill, battery icons with star indicator
/// Techniques: Custom RenderBox, VerticalDragGestureRecognizer, LinearGradient, custom battery/star painting

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 40,
            height: 400,
            child: Slider(),
          ),
        ),
      ),
    );
  }
}

class Slider extends LeafRenderObjectWidget {
  const Slider({super.key});

  @override
  SliderRenderBox createRenderObject(BuildContext context) {
    return SliderRenderBox();
  }
}

class SliderRenderBox extends RenderProxyBox {
  SliderRenderBox() {
    drag = VerticalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onEnd = ((_) => _onDragCancel())
      ..onCancel = _onDragCancel
      ..onUpdate = _onDragUpdate;
  }

  late final DragGestureRecognizer drag;

  double _percentage = 0.0;
  double _currentDragValue = 0.0;

  double _getValueFromGlobalPosition(Offset position) =>
      globalToLocal(position).dy / size.height;

  void _onRangeChanged(double value) {
    final _value = value;
    if (_value == _percentage) {
      return;
    }
    HapticFeedback.selectionClick();
    _percentage = _value;
    markNeedsPaint();
  }

  void _onDragStart(DragStartDetails details) {
    _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
  }

  void _onDragCancel() => _currentDragValue = 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    final valueDelta = details.primaryDelta! / size.height;
    _currentDragValue += valueDelta;
    _onRangeChanged(_currentDragValue.clamp(0.0, 1.0));
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
    final circleRadius = size.width / 2;
    final rect = offset.translate(0, circleRadius) &
        Size(size.width, size.height - (circleRadius * 2));
    final Canvas canvas = context.canvas;

    canvas.drawRect(rect, Paint()..color = Color(0xFFDDDDDD));

    final progressRect = Rect.fromLTRB(rect.left,
        rect.top + _percentage * rect.height, rect.right, rect.bottom);
    canvas.drawRect(
      progressRect,
      Paint()
        ..shader = ui.Gradient.linear(
          progressRect.topCenter,
          progressRect.bottomCenter,
          [Colors.green, Colors.deepOrange],
        ),
    );

    drawLimits(canvas, rect, circleRadius);

    drawKnob(canvas, rect, _percentage);

    super.paint(context, offset);
  }

  void drawKnob(Canvas canvas, Rect rect, double value) {
    final knobHeight = rect.width;
    const knobWidthOffshoot = 10.0;
    final knobRect = Rect.fromCenter(
      center: rect.topCenter.translate(0, _percentage * rect.height),
      height: knobHeight,
      width: size.width + knobWidthOffshoot,
    );
    final knobRRect = RRect.fromRectAndRadius(knobRect, Radius.circular(4));

    canvas.drawShadow(Path()..addRRect(knobRRect), Color(0xAA000000), 4, false);
    canvas.drawRRect(knobRRect, Paint()..color = Colors.white);

    final batterySize = Size(knobHeight / 4, knobHeight / 2);
    BatteryPainter(
      showStar: true,
      color: Color.lerp(Colors.deepOrange, Colors.green, 1 - value)!,
      percent: (1 - value) * 100,
    ).paint(canvas, knobRect.center, batterySize);
  }

  void drawLimits(Canvas canvas, Rect rect, double radius) {
    final circlePaint = Paint()..color = Color(0xFFFFFFFF);
    canvas.drawCircle(rect.topCenter, radius, circlePaint);
    canvas.drawCircle(rect.bottomCenter, radius, circlePaint);

    final batterySize = Size(radius / 2.5, radius / 1.25);
    BatteryPainter(percent: 100).paint(canvas, rect.topCenter, batterySize);
    BatteryPainter(percent: 20, color: Colors.deepOrange)
        .paint(canvas, rect.bottomCenter, batterySize);
  }
}

class BatteryPainter {
  const BatteryPainter({
    this.percent = 100,
    this.color = Colors.green,
    this.showStar = false,
  });

  final double percent;
  final Color color;
  final bool showStar;

  void paint(Canvas canvas, Offset offset, Size size) {
    final maxWidth = size.width;
    final maxHeight = size.height;
    final capWidth = maxWidth * (1 - (2 / 3));
    final capHeight = maxHeight / 20;

    final off = offset - Offset(maxWidth / 2, maxHeight / 2);

    final background = Path();
    background.moveTo(off.dx, off.dy + capHeight);
    background.lineTo(off.dx, off.dy + maxHeight);
    background.lineTo(off.dx + maxWidth, off.dy + maxHeight);
    background.lineTo(off.dx + maxWidth, off.dy + capHeight);
    background.lineTo(off.dx + maxWidth - capWidth, off.dy + capHeight);
    background.lineTo(off.dx + maxWidth - capWidth, off.dy);
    background.lineTo(off.dx + maxWidth - (2 * capWidth), off.dy);
    background.lineTo(off.dx + maxWidth - (2 * capWidth), off.dy + capHeight);
    background.lineTo(off.dx, off.dy + capHeight);

    final fraction = 1 - (percent / 100);
    final content = Path();
    content.moveTo(off.dx, off.dy + (maxHeight * fraction));
    content.lineTo(off.dx, off.dy + maxHeight);
    content.lineTo(off.dx + maxWidth, off.dy + maxHeight);
    content.lineTo(off.dx + maxWidth, off.dy + (maxHeight * fraction));
    content.lineTo(off.dx, off.dy + (maxHeight * fraction));

    canvas.drawPath(
      background,
      Paint()..color = Color.lerp(Colors.white, color, .4)!,
    );

    canvas.drawPath(
      content,
      // This is broken on web. https://github.com/flutter/flutter/issues/44572
      // Path.combine(PathOperation.intersect, content, background),
      Paint()..color = Color.lerp(Colors.black, color, .9)!,
    );

    if (showStar) {
      StarPainter().paint(canvas, (off & size).center, size);
    }
  }
}

class StarPainter {
  void paint(Canvas canvas, Offset offset, Size size) {
    final maxWidth = size.width * (1 - (2 / 5));
    final maxHeight = size.height * (1 - (2 / 5));
    final center = Size(maxWidth, maxHeight).center(Offset.zero);
    final midMargin = maxHeight / 10;

    final off = offset - Offset(maxWidth / 2, maxHeight / 2);

    final star = Path();
    star.moveTo(off.dx + maxWidth * (1 - 1 / 3), off.dy);
    star.lineTo(off.dx, off.dy + center.dy + midMargin);
    star.lineTo(off.dx + center.dx - midMargin, off.dy + center.dy + midMargin);
    star.lineTo(off.dx + center.dx - midMargin, off.dy + maxHeight);
    star.lineTo(off.dx + maxWidth, off.dy + center.dy - midMargin);
    star.lineTo(
        off.dx + maxWidth * (1 - 1 / 3), off.dy + center.dy - midMargin);

    canvas.drawPath(star, Paint()..color = Colors.white);
  }
}
