/// Formats distance for explore map and hall cards.
abstract final class DistanceFormatter {
  static String formatMeters(double meters) {
    if (meters < 1000) {
      return '${meters.round()} م';
    }

    final km = meters / 1000;
    if (km < 10) {
      return '${km.toStringAsFixed(1)} كم';
    }

    return '${km.round()} كم';
  }

  static String? fromMeters(int? meters) {
    if (meters == null || meters < 0) return null;
    return formatMeters(meters.toDouble());
  }
}
