import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_theme.dart';

/// North-up direction control. The unselected arrow is only a drag affordance;
/// it never supplies a bearing until the resident interacts with the wheel.
class DirectionWheel extends StatefulWidget {
  const DirectionWheel(
      {super.key, required this.bearing, required this.onChanged});
  final double? bearing;
  final ValueChanged<double> onChanged;

  @override
  State<DirectionWheel> createState() => _DirectionWheelState();
}

class _DirectionWheelState extends State<DirectionWheel> {
  int? _activePointer;
  double? get bearing => widget.bearing;

  void _select(Offset position) {
    final delta = position - const Offset(84, 84);
    if (delta.distance < 20)
      return; // The centre is the location, not a direction.
    widget.onChanged(
        (math.atan2(delta.dx, -delta.dy) * 180 / math.pi + 360) % 360);
  }

  void _adjust(double step) =>
      widget.onChanged(((bearing ?? 0) + step + 360) % 360);

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Direction of travel',
        value: bearing == null ? 'Not selected' : directionLabel(bearing!),
        increasedValue: directionLabel(((bearing ?? 0) + 45) % 360),
        decreasedValue: directionLabel(((bearing ?? 0) + 315) % 360),
        hint: 'Drag or tap the wheel. Arrow keys adjust direction.',
        onIncrease: () => _adjust(45),
        onDecrease: () => _adjust(-45),
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final value = switch (event.logicalKey) {
              LogicalKeyboardKey.arrowUp => 0.0,
              LogicalKeyboardKey.arrowRight => 90.0,
              LogicalKeyboardKey.arrowDown => 180.0,
              LogicalKeyboardKey.arrowLeft => 270.0,
              _ => null,
            };
            if (value == null) return KeyEventResult.ignored;
            widget.onChanged(value);
            return KeyEventResult.handled;
          },
          child: RawGestureDetector(
            key: const Key('direction-wheel'),
            behavior: HitTestBehavior.opaque,
            // Claim only touches beginning inside the wheel before the page's
            // vertical drag recognizer can take a slow direction adjustment.
            gestures: {
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                      EagerGestureRecognizer.new, (_) {}),
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (_activePointer != null) return;
                _activePointer = event.pointer;
                _select(event.localPosition);
              },
              onPointerMove: (event) {
                if (event.pointer == _activePointer)
                  _select(event.localPosition);
              },
              onPointerUp: (event) {
                if (event.pointer == _activePointer) _activePointer = null;
              },
              onPointerCancel: (event) {
                if (event.pointer == _activePointer) _activePointer = null;
              },
              child: SizedBox(
                  width: 168,
                  height: 168,
                  child: CustomPaint(painter: _WheelPainter(bearing))),
            ),
          ),
        ),
      );
}

String directionLabel(double bearing) {
  const labels = [
    'North',
    'Northeast',
    'East',
    'Southeast',
    'South',
    'Southwest',
    'West',
    'Northwest'
  ];
  return labels[((bearing + 22.5) ~/ 45) % 8];
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.bearing);
  final double? bearing;
  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final colour = bearing == null ? const Color(0xFF626E64) : AppTheme.rust;
    canvas.drawCircle(
        centre, 70, Paint()..color = Colors.white.withValues(alpha: .7));
    canvas.drawCircle(
        centre,
        70,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final vector = Offset(math.sin(angle), -math.cos(angle));
      canvas.drawLine(
          centre + vector * 60,
          centre + vector * 70,
          Paint()
            ..color = colour
            ..strokeWidth = 2);
    }
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate((bearing ?? 45) * math.pi / 180);
    // A large shaft and 48px touch grip remain visible over roads.
    canvas.drawLine(
        const Offset(0, 0),
        const Offset(0, -58),
        Paint()
          ..color = colour
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
    final head = Path()
      ..moveTo(0, -74)
      ..lineTo(-17, -48)
      ..lineTo(17, -48)
      ..close();
    canvas.drawPath(head, Paint()..color = colour);
    canvas.drawCircle(const Offset(0, -57), 24,
        Paint()..color = colour.withValues(alpha: .13));
    canvas.restore();
    canvas.drawCircle(centre, 8, Paint()..color = AppTheme.rust);
    canvas.drawCircle(centre, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.bearing != bearing;
}
