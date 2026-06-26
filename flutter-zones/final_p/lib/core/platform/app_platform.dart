import 'package:flutter/foundation.dart';

/// Platform helpers — Explore Map runs on Android, iOS, and Chrome/Web.
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// flutter_map + geolocator on Android, iOS, and web (Chrome preview).
  static bool get supportsExploreMap => isAndroid || isIOS || isWeb;

  static String get platformLabel {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Desktop';
  }
}
