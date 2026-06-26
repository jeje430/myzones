/// Dark Carto basemap tuned for ZONEZ neon UI (matches app dark pages).
abstract final class ZonezExploreMapConfig {
  static const tileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const tileSubdomains = ['a', 'b', 'c', 'd'];

  static const userAgent = 'com.example.final_p';

  static const minZoom = 5.0;
  static const maxZoom = 19.0;
  static const defaultZoom = 13.5;
}
