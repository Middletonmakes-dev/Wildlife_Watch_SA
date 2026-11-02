import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_theme.dart';

enum TortoiseMarkerCondition { alive, injured, dead, unknown }

extension TortoiseMarkerConditionX on TortoiseMarkerCondition {
  static TortoiseMarkerCondition fromCode(String code) => switch (code) {
        'alive' ||
        'alive_crossing_road' ||
        'alive_near_road' =>
          TortoiseMarkerCondition.alive,
        'injured' => TortoiseMarkerCondition.injured,
        'dead_roadkill' => TortoiseMarkerCondition.dead,
        _ => TortoiseMarkerCondition.unknown,
      };

  Color get color => switch (this) {
        TortoiseMarkerCondition.alive => const Color(0xFF2E7D32),
        TortoiseMarkerCondition.injured => const Color(0xFFF9A825),
        TortoiseMarkerCondition.dead => const Color(0xFFC62828),
        TortoiseMarkerCondition.unknown => AppTheme.ink,
      };
}

class TortoiseMapMarker extends StatelessWidget {
  const TortoiseMapMarker({
    required this.condition,
    this.selected = false,
    super.key,
  });

  static const assetPath = 'assets/SVG/Tortoise.svg';
  static const iconSize = 28.0;

  final TortoiseMarkerCondition condition;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppTheme.rust : Colors.white,
          width: selected ? 2 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: _TortoiseMarkerImage(color: condition.color),
        ),
      ),
    );
  }
}

class _TortoiseMarkerImage extends StatelessWidget {
  const _TortoiseMarkerImage({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      TortoiseMapMarker.assetPath,
      width: TortoiseMapMarker.iconSize,
      height: TortoiseMapMarker.iconSize,
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
      semanticsLabel: 'Tortoise sighting marker',
    );
  }
}
