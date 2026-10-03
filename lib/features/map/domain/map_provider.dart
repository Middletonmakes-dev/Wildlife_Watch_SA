abstract interface class MapProvider {
  String get tileUrl;
  String get attribution;
}

class OpenStreetMapProvider implements MapProvider {
  const OpenStreetMapProvider();

  @override
  String get tileUrl => const String.fromEnvironment('MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

  @override
  String get attribution => const String.fromEnvironment('MAP_ATTRIBUTION',
      defaultValue: '© OpenStreetMap contributors');
}
