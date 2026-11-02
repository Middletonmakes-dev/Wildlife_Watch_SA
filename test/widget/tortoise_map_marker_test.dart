import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/map/presentation/tortoise_map_marker.dart';

void main() {
  test('maps sighting conditions to the requested marker colours', () {
    expect(TortoiseMarkerConditionX.fromCode('alive_crossing_road'),
        TortoiseMarkerCondition.alive);
    expect(TortoiseMarkerConditionX.fromCode('alive_near_road'),
        TortoiseMarkerCondition.alive);
    expect(TortoiseMarkerConditionX.fromCode('injured'),
        TortoiseMarkerCondition.injured);
    expect(TortoiseMarkerConditionX.fromCode('dead_roadkill'),
        TortoiseMarkerCondition.dead);
    expect(TortoiseMarkerCondition.alive.color, const Color(0xFF2E7D32));
    expect(TortoiseMarkerCondition.injured.color, const Color(0xFFF9A825));
    expect(TortoiseMarkerCondition.dead.color, const Color(0xFFC62828));
  });

  testWidgets('renders the supplied SVG on a light backing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: TortoiseMapMarker(
            condition: TortoiseMarkerCondition.injured,
            selected: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final marker = tester.widget<TortoiseMapMarker>(
      find.byType(TortoiseMapMarker),
    );
    expect(marker.selected, isTrue);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.width == TortoiseMapMarker.iconSize &&
            widget.height == TortoiseMapMarker.iconSize,
      ),
      findsOneWidget,
    );
  });
}
