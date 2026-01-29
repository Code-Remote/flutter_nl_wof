/// Simple Discrete Slider
/// Jeremiah Ogbomo - Saturdays are for Flutter
/// Gist ID: 7ffb6c9c64ef6ec203c1253a21a565b3
/// DartPad: https://dartpad.dev/?id=7ffb6c9c64ef6ec203c1253a21a565b3
///
/// Features: Discrete value slider, tick marks, snap-to-value behavior
/// Techniques: HorizontalDragGestureRecognizer, sizedByParent, ParagraphBuilder, haptic feedback

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ValueNotifier<double> valueNotifier = ValueNotifier<double>(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ValueListenableBuilder(
                valueListenable: valueNotifier,
                builder: (_, value, __) => Text("${value.toStringAsFixed(1)}",
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white)),
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 72,
                width: 360,
                child: SliderWidget(
                  maxLabel: "10k",
                  minLabel: "0",
                  onChanged: (value) {
                    valueNotifier.value = value * 10000;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SliderWidget extends LeafRenderObjectWidget {
  const SliderWidget({
    super.key,
    required this.minLabel,
    required this.maxLabel,
    this.selectedIndex = 0,
    this.divisions = 30,
    this.onChanged,
  });

  final int selectedIndex;
  final int divisions;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double>? onChanged;

  @override
  SliderRenderObject createRenderObject(BuildContext context) {
    return SliderRenderObject(
      selectedIndex: selectedIndex,
      divisions: divisions,
      minLabel: minLabel,
      maxLabel: maxLabel,
      onChanged: onChanged,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, SliderRenderObject renderObject) {
    renderObject
      ..selectedIndex = selectedIndex
      ..divisions = divisions
      ..minLabel = minLabel
      ..maxLabel = maxLabel
      ..onChanged = onChanged;
  }
}

class SliderRenderObject extends RenderBox {
  SliderRenderObject({
    required int selectedIndex,
    required int divisions,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double>? onChanged,
  })  : _selectedIndex = selectedIndex,
        _divisions = divisions,
        _minLabel = minLabel,
        _maxLabel = maxLabel,
        _onChanged = onChanged {
    _recognizer = HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onEnd = ((_) => _handleDragCancel())
      ..onUpdate = _handleDragUpdate
      ..onCancel = _handleDragCancel;
  }

  late int _selectedIndex;

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int selectedIndex) {
    _selectedIndex = selectedIndex;
    markNeedsPaint();
  }

  late int _divisions = 30;

  int get divisions => _divisions;

  set divisions(int divisions) {
    _divisions = divisions;
    markNeedsPaint();
  }

  late String _minLabel;

  String get minLabel => _minLabel;

  set minLabel(String minLabel) {
    _minLabel = minLabel;
    markNeedsPaint();
  }

  late String _maxLabel;

  String get maxLabel => _maxLabel;

  set maxLabel(String maxLabel) {
    _maxLabel = maxLabel;
    markNeedsPaint();
  }

  late ValueChanged<double>? _onChanged;

  ValueChanged<double>? get onChanged => _onChanged;

  set onChanged(ValueChanged<double>? onChange) {
    _onChanged = onChange;
    markNeedsPaint();
  }

  double _currentDragValue = 0.0;
  late final HorizontalDragGestureRecognizer _recognizer;

  double _getValueFromGlobalPosition(Offset position) =>
      globalToLocal(position).dx / size.width;

  void _handleDragStart(DragStartDetails details) {
    _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final valueDelta = details.primaryDelta! / size.width;
    _currentDragValue += valueDelta;
    _onRangeChanged(_currentDragValue.clamp(0.0, 1.0));
  }

  void _handleDragCancel() => _currentDragValue = 0.0;

  void _onRangeChanged(double value) {
    _selectedIndex = (value * divisions).round();
    HapticFeedback.selectionClick();
    onChanged?.call(_selectedIndex / divisions);
    markNeedsPaint();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool get sizedByParent => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _recognizer.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final space = size.width / divisions;
    final verticalSpaceRadius = math.min(4.0, size.height * .1 / 2);
    final labelHeight =
        math.min(14.0, (size.height - verticalSpaceRadius) * .25);
    final selectedTickHeight = size.height - verticalSpaceRadius - labelHeight;
    final mediumTickHeight = selectedTickHeight * .5;
    final smallTickHeight = selectedTickHeight * .325;

    for (int i = 0; i < (divisions + 1); i++) {
      final color = i <= selectedIndex
          ? const Color(0xFF0599FF)
          : const Color(0xFFDEDEDE);
      final strokeWidth = i == selectedIndex ? 4.0 : 2.0;
      final height = i == selectedIndex
          ? selectedTickHeight
          : i % 10 == 0
              ? mediumTickHeight
              : smallTickHeight;
      final originDx = i * space;
      final originDy = selectedTickHeight / 2 - height / 2;

      canvas.drawLine(
        offset + Offset(originDx, originDy),
        offset + Offset(originDx, originDy + height),
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth,
      );
    }

    final minLabelParagraph = _buildParagraph(_minLabel);
    final maxLabelParagraph = _buildParagraph(_maxLabel);
    final bottomOffset = offset + Offset(0, size.height - labelHeight);
    canvas
      ..drawParagraph(
        minLabelParagraph,
        bottomOffset + Offset(-minLabelParagraph.maxIntrinsicWidth / 2, 0),
      )
      ..drawParagraph(
        maxLabelParagraph,
        bottomOffset +
            Offset(size.width - maxLabelParagraph.maxIntrinsicWidth / 2, 0),
      );
  }

  ui.Paragraph _buildParagraph(String text) {
    final ui.TextStyle style = ui.TextStyle(
        fontStyle: FontStyle.normal,
        fontSize: 12.0,
        color: const Color(0xFFFFFFFF),
        height: 1.24,
        letterSpacing: 1.25,
        fontWeight: FontWeight.w600);
    final label = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(style)
      ..addText(text)
      ..pop();
    return label.build()..layout(ui.ParagraphConstraints(width: size.width));
  }
}
