/// Slide to Send Button
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 9a26cdbf0e3acb2fca51368544fed994
/// DartPad: https://dartpad.dev/?id=9a26cdbf0e3acb2fca51368544fed994
///
/// Features: Slide gesture with threshold activation, animated arrow icons, heartbeat animation
/// Techniques: RenderProxyBox, HorizontalDragGestureRecognizer, AnimationController, interpolate

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: Playground(),
      ),
    );

class Playground extends StatefulWidget {
  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF070813),
      body: Center(
        child: SlideButton(
          vsync: this,
          child: Text(
            "SLIDE TO SEND",
            style: TextStyle(
                letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          onSlide: () {
            print("onChanged");
          },
          onTap: () {
            print("onTap");
          },
        ),
      ),
    );
  }
}

class SlideButton extends SingleChildRenderObjectWidget {
  SlideButton({
    super.key,
    super.child,
    required this.onTap,
    required this.onSlide,
    required this.vsync,
  });

  final VoidCallback onTap;
  final VoidCallback onSlide;
  final TickerProvider vsync;

  @override
  RenderSlideButton createRenderObject(BuildContext context) {
    return RenderSlideButton(onTap: onTap, onSlide: onSlide, vsync: vsync);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlideButton renderObject) {
    renderObject
      ..onTap = onTap
      ..onSlide = onSlide
      ..vsync = vsync;
  }
}

class RenderSlideButton extends RenderProxyBox {
  RenderSlideButton({
    RenderBox? child,
    required VoidCallback onTap,
    required VoidCallback onSlide,
    required TickerProvider vsync,
  })  : _onTap = onTap,
        _onSlide = onSlide,
        _vsync = vsync,
        super(child) {
    final physics = BouncingScrollPhysics();
    drag = HorizontalDragGestureRecognizer()
      ..minFlingVelocity = physics.minFlingVelocity
      ..maxFlingVelocity = physics.maxFlingVelocity
      ..minFlingDistance = physics.dragStartDistanceMotionThreshold
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
  }

  static const iconPadding = 8.0;
  static const iconData = Icons.chevron_right_rounded;
  static const iconColor = Colors.white;
  static const iconCount = 3;

  late final DragGestureRecognizer drag;
  late AnimationController slideController;
  late AnimationController heartBeatController;

  late TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    slideController.resync(_vsync);
    heartBeatController.resync(_vsync);
  }

  VoidCallback _onTap;

  set onTap(VoidCallback onTap) {
    if (_onTap == onTap) {
      return;
    }
    _onTap = onTap;
  }

  VoidCallback _onSlide;

  set onSlide(VoidCallback onSlide) {
    if (_onSlide == onSlide) {
      return;
    }
    _onSlide = onSlide;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    slideController = AnimationController.unbounded(
      value: 0.0,
      vsync: _vsync,
      duration: Duration(milliseconds: 350),
    )..addListener(markNeedsPaint);

    heartBeatController = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: 1000),
    )
      ..addListener(markNeedsPaint)
      ..repeat(reverse: true);
  }

  @override
  void detach() {
    slideController.removeListener(markNeedsPaint);
    heartBeatController.removeListener(markNeedsPaint);

    super.detach();
  }

  void _onDragStart(DragStartDetails details) {
    slideController.animateTo(size.width * .05).whenCompleteOrCancel(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _onTap.call();
      });
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    slideController.value += details.primaryDelta ?? 0.0;
  }

  void _onDragCancel() {
    slideController.value = 0.0;
  }

  void _onDragEnd(DragEndDetails details) {
    final threshold = size.width / 4;
    if (slideController.value > threshold) {
      slideController.animateTo(size.width).whenCompleteOrCancel(() {
        _onDragCancel();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _onSlide.call();
        });
      });
      return;
    }
    slideController.animateBack(0.0).whenCompleteOrCancel(_onDragCancel);
  }

  @override
  bool hitTestSelf(ui.Offset position) => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final effectiveConstraints = constraints.enforce(BoxConstraints(
      minHeight: 40,
      maxHeight: 80,
      maxWidth: 400,
    ));
    size = effectiveConstraints.biggest;

    if (child != null) {
      child?.layout(effectiveConstraints.loosen(), parentUsesSize: true);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final value = math.min(size.width, math.max(0.0, slideController.value));
    final t = interpolate(inputMax: size.width)(value);
    final bounds = RRect.fromRectAndRadius(offset & size, Radius.circular(18));

    canvas.clipRRect(bounds);

    canvas.drawRRect(
      bounds,
      Paint()
        ..color = Color.lerp(
          Color(0xFF141224),
          Color(0xFF5A01CB),
          Curves.decelerate.transform(t),
        )!,
    );

    final child = this.child;
    if (child == null) {
      return;
    }

    final childOffset = (size.center(offset) - child.size.center(offset));
    final childRect = childOffset & child.size;
    context.paintChild(
      child,
      (size.center(offset) - child.size.center(offset)).translate(value, 0),
    );

    final iconOffset = childRect.centerLeft.translate(
      -(iconPadding * 2) +
          (4 * heartBeatController.value) +
          (Curves.ease.transform(t) * size.width),
      0,
    );
    for (int i = 0; i < iconCount; i++) {
      _drawParagraph(
        canvas,
        String.fromCharCode(iconData.codePoint),
        offset: iconOffset - Offset(i * iconPadding, 0),
        color: Color.lerp(
          Colors.transparent,
          iconColor.withOpacity(1.0 - (i * 1 / iconCount)),
          1 - t,
        )!,
        fontSize: size.height / 3.5,
        fontFamily: iconData.fontFamily,
        fontWeight: FontWeight.w300,
      );
    }
  }

  Rect _drawParagraph(
    Canvas canvas,
    String text, {
    required Offset offset,
    required Color color,
    required double fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
  }) {
    final builder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            letterSpacing: 1.2,
            fontFamily: fontFamily,
          ))
          ..addText(text);
    final paragraph = builder.build();
    final constraints =
        ui.ParagraphConstraints(width: (fontSize / 1.25) * text.length);
    final finalOffset = offset - Offset(constraints.width / 2, fontSize / 2);
    canvas.drawParagraph(paragraph..layout(constraints), finalOffset);
    return Rect.fromLTWH(finalOffset.dx, finalOffset.dy, paragraph.longestLine,
        paragraph.height);
  }
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
