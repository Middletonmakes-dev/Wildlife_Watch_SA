import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_theme.dart';

class JournalBrand extends StatelessWidget {
  const JournalBrand({super.key});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/SVG/good-spotting-logo.svg',
        height: 44,
        width: 110,
        fit: BoxFit.contain,
        semanticsLabel: 'Good Spotting',
      );
}

class JournalNavigation extends StatelessWidget {
  const JournalNavigation(
      {super.key, required this.selected, required this.demo});
  final int selected;
  final bool demo;
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.rule))),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            for (final item in [
              (label: 'Home', route: '/'),
              (label: 'Report', route: '/report'),
              (label: 'Map', route: '/map'),
              (label: 'Your reports', route: '/your-reports')
            ].indexed)
              Expanded(
                  child: TextButton(
                      onPressed: () => context.go(item.$2.route),
                      child: Text(item.$2.label,
                          style: TextStyle(
                              fontFamily: 'JournalSerif',
                              color: selected == item.$1
                                  ? AppTheme.rust
                                  : AppTheme.ink,
                              decoration: selected == item.$1
                                  ? TextDecoration.underline
                                  : null)))),
          ]),
          if (demo)
            const Text('Demo mode · synthetic data · local reports',
                style: TextStyle(fontSize: 11, color: Color(0xFF626E64))),
        ]),
      ));
}
