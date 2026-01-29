/// Wheel of Fortune - FlutterNL Community Edition
/// Built using patterns from Jeremiah Ogbomo's "Saturdays are for Flutter"
/// DartPad compatible - single file implementation
///
/// Key techniques from analysis:
/// - LeafRenderObjectWidget for direct RenderBox control
/// - isRepaintBoundary for performance isolation
/// - SpringSimulation for natural deceleration
/// - Path-based segment drawing with largeArc handling
/// - Drag-to-rotate gesture with velocity-based spin

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        debugShowCheckedModeBanner: false,
        home: const WheelOfFortuneDemo(),
      ),
    );

// ============================================================================
// DEMO APP
// ============================================================================

class WheelOfFortuneDemo extends StatefulWidget {
  const WheelOfFortuneDemo({super.key});

  @override
  State<WheelOfFortuneDemo> createState() => _WheelOfFortuneDemoState();
}

class _WheelOfFortuneDemoState extends State<WheelOfFortuneDemo>
    with TickerProviderStateMixin {
  WheelSegment? _winner;
  bool _isSpinning = false;

  final segments = const [
    WheelSegment(label: '🎉 100', color: Color(0xFFE91E63), value: 100),
    WheelSegment(label: '💎 500', color: Color(0xFF9C27B0), value: 500),
    WheelSegment(label: '🔥 200', color: Color(0xFFFF5722), value: 200),
    WheelSegment(label: '⭐ 1000', color: Color(0xFFFFEB3B), value: 1000),
    WheelSegment(label: '💰 300', color: Color(0xFF4CAF50), value: 300),
    WheelSegment(label: '🚀 750', color: Color(0xFF2196F3), value: 750),
    WheelSegment(label: '🎯 150', color: Color(0xFF00BCD4), value: 150),
    WheelSegment(label: '👑 JACKPOT', color: Color(0xFFFF9800), value: 5000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'WHEEL OF FORTUNE',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe to spin!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: WheelOfFortune(
                      vsync: this,
                      segments: segments,
                      onSpinStart: () {
                        setState(() {
                          _isSpinning = true;
                          _winner = null;
                        });
                      },
                      onSpinComplete: (segment) {
                        setState(() {
                          _isSpinning = false;
                          _winner = segment;
                        });
                        HapticFeedback.heavyImpact();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 80,
              child: _winner != null
                  ? Column(
                      children: [
                        Text(
                          'YOU WON!',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _winner!.label,
                          style:
                              Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: _winner!.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    )
                  : _isSpinning
                      ? const CircularProgressIndicator(color: Colors.white54)
                      : const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODEL
// ============================================================================

class WheelSegment {
  const WheelSegment({
    required this.label,
    required this.color,
    this.value,
  });

  final String label;
  final Color color;
  final dynamic value;
}

// ============================================================================
// WHEEL WIDGET (LeafRenderObjectWidget)
// ============================================================================

class WheelOfFortune extends LeafRenderObjectWidget {
  const WheelOfFortune({
    super.key,
    required this.vsync,
    required this.segments,
    this.onSpinStart,
    this.onSpinComplete,
    this.innerRadiusRatio = 0.25,
    this.pointerColor = const Color(0xFFFFFFFF),
  });

  final TickerProvider vsync;
  final List<WheelSegment> segments;
  final VoidCallback? onSpinStart;
  final ValueChanged<WheelSegment>? onSpinComplete;
  final double innerRadiusRatio;
  final Color pointerColor;

  @override
  RenderWheelOfFortune createRenderObject(BuildContext context) {
    return RenderWheelOfFortune(
      vsync: vsync,
      segments: segments,
      innerRadiusRatio: innerRadiusRatio,
      pointerColor: pointerColor,
    )
      .._onSpinStart = onSpinStart
      .._onSpinComplete = onSpinComplete;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderWheelOfFortune renderObject) {
    renderObject
      ..vsync = vsync
      ..segments = segments
      ..innerRadiusRatio = innerRadiusRatio
      ..pointerColor = pointerColor
      .._onSpinStart = onSpinStart
      .._onSpinComplete = onSpinComplete;
  }
}

// ============================================================================
// RENDER BOX IMPLEMENTATION
// ============================================================================

class RenderWheelOfFortune extends RenderBox {
  RenderWheelOfFortune({
    required TickerProvider vsync,
    required List<WheelSegment> segments,
    required double innerRadiusRatio,
    required Color pointerColor,
  })  : _vsync = vsync,
        _segments = segments,
        _innerRadiusRatio = innerRadiusRatio,
        _pointerColor = pointerColor;

  // ========== Properties ==========
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    if (_vsync == value) return;
    _vsync = value;
    _spinController.resync(_vsync);
  }

  List<WheelSegment> _segments;
  set segments(List<WheelSegment> value) {
    if (_segments == value) return;
    _segments = value;
    markNeedsPaint();
  }

  double _innerRadiusRatio;
  set innerRadiusRatio(double value) {
    if (_innerRadiusRatio == value) return;
    _innerRadiusRatio = value;
    markNeedsPaint();
  }

  Color _pointerColor;
  set pointerColor(Color value) {
    if (_pointerColor == value) return;
    _pointerColor = value;
    markNeedsPaint();
  }

  // ========== Callbacks ==========
  VoidCallback? _onSpinStart;
  ValueChanged<WheelSegment>? _onSpinComplete;

  // ========== State ==========
  double _rotation = 0.0;
  int? _lastHapticSegment;
  bool _isSpinning = false;

  // ========== Animation ==========
  late AnimationController _spinController;

  // ========== Gestures ==========
  late PanGestureRecognizer _drag;
  Offset _lastDragPosition = Offset.zero;

  // ========== Constants ==========
  static const double _startAngle = -math.pi / 2; // Start at 12 o'clock
  static const double _pointerAngle = -math.pi / 2; // Pointer at top

  // ========== Lifecycle ==========
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _spinController = AnimationController.unbounded(vsync: _vsync)
      ..addListener(_onAnimationTick);
    _drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd;
  }

  @override
  void detach() {
    _spinController.removeListener(_onAnimationTick);
    _spinController.dispose();
    _drag.dispose();
    super.detach();
  }

  // ========== Performance Optimizations ==========
  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final side = constraints.biggest.shortestSide;
    return Size.square(side);
  }

  // ========== Hit Testing ==========
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && !_isSpinning) {
      _drag.addPointer(event);
    }
  }

  // ========== Gesture Handlers ==========
  void _onDragStart(DragStartDetails details) {
    _lastDragPosition = details.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final center = size.center(Offset.zero);
    final previousAngle = _toAngle(_lastDragPosition, center);
    final currentAngle = _toAngle(details.localPosition, center);

    _rotation += currentAngle - previousAngle;
    _lastDragPosition = details.localPosition;

    _maybeHapticOnSegmentChange();
    markNeedsPaint();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final radius = size.shortestSide / 2;

    // Calculate angular velocity from linear velocity
    // Cross product gives rotation direction
    final center = size.center(Offset.zero);
    final toPointer = _lastDragPosition - center;
    final cross = toPointer.dx * velocity.dy - toPointer.dy * velocity.dx;
    final angularVelocity = cross / (radius * radius);

    if (angularVelocity.abs() > 2.0) {
      _startSpin(angularVelocity);
    }
  }

  // ========== Spin Animation ==========
  void _startSpin(double angularVelocity) {
    _isSpinning = true;
    _onSpinStart?.call();

    // Calculate target rotation with deceleration
    final direction = angularVelocity.sign;
    final speed = angularVelocity.abs();

    // More velocity = more rotations
    final minRotations = 3;
    final extraRotations = (speed / 8).clamp(0.0, 5.0);
    final totalRadians = (minRotations + extraRotations) * 2 * math.pi * direction;

    // Add random offset for landing position
    final randomOffset = (math.Random().nextDouble() - 0.5) * math.pi;
    final targetRotation = _rotation + totalRadians + randomOffset;

    // Use spring simulation for natural deceleration
    final simulation = SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: 0.5,
        damping: 1.0,
      ),
      _rotation,
      targetRotation,
      angularVelocity,
    );

    _spinController.animateWith(simulation).then((_) {
      _isSpinning = false;
      final winningIndex = _getSegmentAtPointer();
      _onSpinComplete?.call(_segments[winningIndex]);
    });
  }

  void _onAnimationTick() {
    _rotation = _spinController.value;
    _maybeHapticOnSegmentChange();
    markNeedsPaint();
  }

  // ========== Segment Detection ==========
  int _getSegmentAtPointer() {
    final segmentAngle = 2 * math.pi / _segments.length;

    // Normalize rotation to 0..2π
    final normalizedRotation = _normalizeAngle(_rotation);

    // Calculate which segment is at the pointer
    // The pointer is at _pointerAngle, and the wheel has rotated by normalizedRotation
    final effectiveAngle = _normalizeAngle(_pointerAngle - normalizedRotation - _startAngle);

    return (effectiveAngle / segmentAngle).floor() % _segments.length;
  }

  void _maybeHapticOnSegmentChange() {
    final currentSegment = _getSegmentAtPointer();
    if (currentSegment != _lastHapticSegment) {
      HapticFeedback.selectionClick();
      _lastHapticSegment = currentSegment;
    }
  }

  // ========== Painting ==========
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final center = size.center(offset);
    final outerRadius = size.shortestSide / 2 - 20; // Padding for pointer
    final innerRadius = outerRadius * _innerRadiusRatio;

    // Save canvas state and apply rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);
    canvas.translate(-center.dx, -center.dy);

    // Draw segments
    final segmentAngle = 2 * math.pi / _segments.length;

    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final startAngle = _startAngle + (i * segmentAngle);

      _drawSegment(
        canvas,
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: segmentAngle,
        color: segment.color,
        label: segment.label,
      );
    }

    canvas.restore();

    // Draw center cap (doesn't rotate)
    _drawCenterCap(canvas, center, innerRadius);

    // Draw pointer (doesn't rotate)
    _drawPointer(canvas, center, outerRadius);
  }

  void _drawSegment(
    Canvas canvas, {
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required String label,
  }) {
    final path = _createSegmentPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    // Draw segment fill with gradient
    final midAngle = startAngle + sweepAngle / 2;
    final gradientStart = _toPolar(center, midAngle, innerRadius);
    final gradientEnd = _toPolar(center, midAngle, outerRadius);

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          gradientStart,
          gradientEnd,
          [
            Color.lerp(color, Colors.white, 0.2)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // Draw segment border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw label
    _drawSegmentLabel(
      canvas,
      label: label,
      center: center,
      radius: (innerRadius + outerRadius) / 2,
      angle: midAngle,
    );
  }

  Path _createSegmentPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final endAngle = startAngle + sweepAngle;
    // CRITICAL: largeArc flag required for arcs > 180°
    final isLargeArc = sweepAngle >= math.pi;

    final startOuter = _toPolar(center, startAngle, outerRadius);
    final endOuter = _toPolar(center, endAngle, outerRadius);
    final startInner = _toPolar(center, startAngle, innerRadius);
    final endInner = _toPolar(center, endAngle, innerRadius);

    return Path()
      ..moveTo(startInner.dx, startInner.dy)
      ..lineTo(startOuter.dx, startOuter.dy)
      ..arcToPoint(
        endOuter,
        radius: Radius.circular(outerRadius),
        largeArc: isLargeArc,
      )
      ..lineTo(endInner.dx, endInner.dy)
      ..arcToPoint(
        startInner,
        radius: Radius.circular(innerRadius),
        largeArc: isLargeArc,
        clockwise: false,
      )
      ..close();
  }

  void _drawSegmentLabel(
    Canvas canvas, {
    required String label,
    required Offset center,
    required double radius,
    required double angle,
  }) {
    canvas.save();

    final labelPosition = _toPolar(center, angle, radius);
    canvas.translate(labelPosition.dx, labelPosition.dy);

    // Rotate text to be readable
    double textRotation = angle + math.pi / 2;
    // Flip text if on bottom half so it's not upside down
    if (angle > 0 && angle < math.pi) {
      textRotation += math.pi;
    }
    canvas.rotate(textRotation);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  void _drawCenterCap(Canvas canvas, Offset center, double innerRadius) {
    final capRadius = innerRadius * 0.8;

    // Shadow
    canvas.drawCircle(
      center.translate(2, 2),
      capRadius,
      Paint()..color = Colors.black26,
    );

    // Gradient cap
    canvas.drawCircle(
      center,
      capRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-capRadius * 0.3, -capRadius * 0.3),
          capRadius * 2,
          [Colors.white, const Color(0xFFE0E0E0)],
        ),
    );

    // Border
    canvas.drawCircle(
      center,
      capRadius,
      Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner highlight
    canvas.drawCircle(
      center.translate(-capRadius * 0.2, -capRadius * 0.2),
      capRadius * 0.3,
      Paint()..color = Colors.white.withOpacity(0.5),
    );
  }

  void _drawPointer(Canvas canvas, Offset center, double radius) {
    final pointerLength = 30.0;
    final pointerWidth = 24.0;

    final pointerTip = _toPolar(center, _pointerAngle, radius + pointerLength);
    final pointerBase1 =
        _toPolar(center, _pointerAngle - 0.15, radius - pointerWidth / 2);
    final pointerBase2 =
        _toPolar(center, _pointerAngle + 0.15, radius - pointerWidth / 2);

    final pointerPath = Path()
      ..moveTo(pointerTip.dx, pointerTip.dy)
      ..lineTo(pointerBase1.dx, pointerBase1.dy)
      ..quadraticBezierTo(
        _toPolar(center, _pointerAngle, radius - pointerWidth).dx,
        _toPolar(center, _pointerAngle, radius - pointerWidth).dy,
        pointerBase2.dx,
        pointerBase2.dy,
      )
      ..close();

    // Shadow
    canvas.drawPath(
      pointerPath.shift(const Offset(2, 2)),
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Gradient fill
    canvas.drawPath(
      pointerPath,
      Paint()
        ..shader = ui.Gradient.linear(
          pointerTip,
          _toPolar(center, _pointerAngle, radius - pointerWidth),
          [_pointerColor, Color.lerp(_pointerColor, Colors.grey, 0.3)!],
        ),
    );

    // Border
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ========== Utilities ==========
  Offset _toPolar(Offset center, double angle, double radius) {
    return center + Offset(radius * math.cos(angle), radius * math.sin(angle));
  }

  double _toAngle(Offset position, Offset center) {
    return (position - center).direction;
  }

  double _normalizeAngle(double angle) {
    const twoPi = math.pi * 2.0;
    return (angle % twoPi + twoPi) % twoPi;
  }
}
