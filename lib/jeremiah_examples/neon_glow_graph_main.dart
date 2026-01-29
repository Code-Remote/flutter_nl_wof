/// Neon Glow Graph
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 2a7faa9b6c80e49214896be06b587d6a
/// DartPad: https://dartpad.dev/?id=2a7faa9b6c80e49214896be06b587d6a
///
/// Features: Horizontal scrollable bar graph, quadratic bezier curve, neon glow effect, value labels
/// Techniques: Custom RenderBox, ContainerRenderObjectMixin, MaskFilter blur, gradient shader

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const kBarWidth = 72.0;
const kBarSpacing = 4.0;
const kLabelHeight = 32.0;
const kTrackHeight = 32.0;
const kMaxValue = 540.0;
const kStrokeWidth = 8.0;

const MaterialColor primaryAccent = MaterialColor(
  0xFF121212,
  <int, Color>{
    50: Color(0xFFf7f7f7),
    100: Color(0xFFeeeeee),
    200: Color(0xFFe2e2e2),
    300: Color(0xFFd0d0d0),
    400: Color(0xFFababab),
    500: Color(0xFF8a8a8a),
    600: Color(0xFF636363),
    700: Color(0xFF505050),
    800: Color(0xFF323232),
    900: Color(0xFF121212),
  },
);
const MaterialColor secondaryAccent = MaterialColor(
  0xFF03dac4,
  <int, Color>{
    50: Color(0xFFd4f6f2),
    100: Color(0xFF92e9dc),
    200: Color(0xFF03dac4),
    300: Color(0xFF00c7ab),
    400: Color(0xFF00b798),
    500: Color(0xFF00a885),
    600: Color(0xFF009a77),
    700: Color(0xFF008966),
    800: Color(0xFF007957),
    900: Color(0xFF005b39),
  },
);
final List<double> values = List.generate(100, (_) => math.Random().nextDouble() * kMaxValue);

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const Playground(),
      ),
    );

class Playground extends StatelessWidget {
  const Playground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(height: kMaxValue, child: GraphView(values: values)),
      ),
    );
  }
}

class GraphView extends BoxScrollView {
  const GraphView({Key? key, required this.values}) : super(key: key, scrollDirection: Axis.horizontal);

  final List<double> values;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverToBoxAdapter(child: GraphWidget(values: values));
  }
}

class GraphWidget extends LeafRenderObjectWidget {
  const GraphWidget({Key? key, required this.values}) : super(key: key);

  final List<double> values;

  @override
  RenderGraphBox createRenderObject(BuildContext context) => RenderGraphBox(values: values);

  @override
  void updateRenderObject(BuildContext context, RenderGraphBox renderObject) => renderObject..values = values;
}

class GraphParentData extends ContainerBoxParentData<GraphItemBar> {}

class RenderGraphBox extends RenderBox
    with
        ContainerRenderObjectMixin<GraphItemBar, GraphParentData>,
        RenderBoxContainerDefaultsMixin<GraphItemBar, GraphParentData> {
  RenderGraphBox({required List<double> values}) : _values = values {
    addChildren(_values);
  }

  List<double> get values => _values;
  List<double> _values;

  set values(List<double> values) {
    if (_values == values) {
      return;
    }
    _values = values;
    addChildren(_values);
    markNeedsLayout();
  }

  void addChildren(List<double> values) {
    addAll(values.map((value) => GraphItemBar(value: value)).toList());
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GraphParentData) {
      child.parentData = GraphParentData();
    }
  }

  @override
  BoxConstraints get constraints => super.constraints.copyWith(maxWidth: childCount * kBarWidth);

  @override
  void performLayout() {
    final maxHeight = constraints.maxHeight - kTrackHeight - kLabelHeight;
    final maxValue = values.reduce(math.max);

    GraphItemBar? child = firstChild;
    int childCount = 0;
    while (child != null) {
      final height = interpolate(inputMax: maxValue, outputMax: maxHeight)(child.value);
      child.layout(BoxConstraints.tight(Size(kBarWidth - kBarSpacing, height)), parentUsesSize: true);

      final GraphParentData childParentData = child.parentData! as GraphParentData;
      childParentData.offset = Offset(childCount * kBarWidth, maxHeight - height + kLabelHeight);

      child = childParentData.nextSibling;
      childCount++;
    }

    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    GraphItemBar? child = firstChild;
    Offset? prevCenterTop;
    const resolvedChildRadius = (kBarWidth - kBarSpacing) / 2;
    final points = <Offset>[];
    final path = Path();

    while (child != null) {
      final GraphParentData childParentData = child.parentData! as GraphParentData;
      final resolvedChildOffset = childParentData.offset + offset;
      context.paintChild(child, resolvedChildOffset);

      final centerTop = Offset(resolvedChildOffset.dx + resolvedChildRadius, resolvedChildOffset.dy);

      if (prevCenterTop == null) {
        path.moveTo(centerTop.dx, centerTop.dy);
        prevCenterTop = centerTop;
      }

      points.add(centerTop);

      final anchor = (prevCenterTop + centerTop) / 2;
      final pointA = (anchor + prevCenterTop) / 2;
      final pointB = (anchor + centerTop) / 2;
      path.quadraticBezierTo(pointA.dx, prevCenterTop.dy, anchor.dx, anchor.dy);
      path.quadraticBezierTo(pointB.dx, centerTop.dy, centerTop.dx, centerTop.dy);

      child = childParentData.nextSibling;
      prevCenterTop = centerTop;
    }

    final rect = offset & size;
    context.canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kStrokeWidth
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          [secondaryAccent, const Color(0xFFF1B61E)],
        ),
    );

    for (var i = 0; i < points.length; i++) {
      final point = points[i];

      context.canvas.drawCircle(
        point,
        kStrokeWidth * 2,
        Paint()
          ..color = Colors.white38
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kStrokeWidth),
      );
      context.canvas.drawCircle(point, kStrokeWidth / 1.6, Paint()..color = Colors.white);

      const labelTextMargin = kStrokeWidth * 2;
      final labelTextRect = Offset(point.dx - kBarWidth / 2, constraints.maxHeight + labelTextMargin - kTrackHeight) &
          const Size(kBarWidth, kTrackHeight - labelTextMargin);
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textWidthBasis: TextWidthBasis.longestLine,
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: primaryAccent.shade200,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: const [ui.Shadow(blurRadius: 2, offset: Offset(0, 1))],
          ),
        ),
      )..layout(maxWidth: labelTextRect.size.width);
      textPainter.paint(context.canvas, labelTextRect.centerLeft - Offset(0, textPainter.height / 2));

      const valueTextMargin = kStrokeWidth * 2;
      final valueTextRect = Offset(point.dx - kBarWidth / 2, point.dy - kLabelHeight - valueTextMargin) &
          const Size(kBarWidth, kLabelHeight - valueTextMargin);
      final labelTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textWidthBasis: TextWidthBasis.longestLine,
        text: TextSpan(
          text: '\$${values[i].toStringAsFixed(1)}',
          style: TextStyle(
            color: primaryAccent.shade200,
            fontSize: 10,
            shadows: const [ui.Shadow(blurRadius: 2, offset: Offset(0, 1))],
            fontWeight: FontWeight.w700,
          ),
        ),
      )..layout(maxWidth: valueTextRect.size.width);
      labelTextPainter.paint(context.canvas, valueTextRect.centerLeft - Offset(0, labelTextPainter.height / 2));
    }
  }
}

class GraphItemBar extends RenderBox {
  GraphItemBar({required double value}) : _value = value;

  double get value => _value;
  double _value;

  set value(double value) {
    _value = value;
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      print(value);
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
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
