import 'package:flutter/foundation.dart';

import 'api_env.dart';

/// Laravel API — remote-first (any network) with optional local dev fallback.
class ApiConfig {
  ApiConfig._();

  static const int devPort = 8000;
  static const String herdHost = 'zones-backend-laravel.test';

  /// PC LAN IP — same Wi‑Fi as the phone. Update when your network changes.
  static const String localDevIp = '192.168.1.44';

  /// Resolved public API root (no trailing slash, no `/api` suffix).
  static String? get _publicRoot {
    final candidates = [
      kZonezPublicApiRootFromDefine.trim(),
      kZonezPublicApiRoot.trim(),
    ];
    for (final raw in candidates) {
      if (raw.isEmpty) continue;
      return _normalizeRoot(raw);
    }
    return null;
  }

  static String _normalizeRoot(String raw) {
    var value = raw.trim();
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith('/api')) {
      value = value.substring(0, value.length - 4);
    }
    return value;
  }

  /// True when the app talks to a public server (works on any Wi‑Fi / mobile data).
  static bool get usesPublicApi => _publicRoot != null;

  /// Site root — `https://api.example.com` or local `http://…`.
  static String get baseUrl {
    final public = _publicRoot;
    if (public != null) return public;

    const hostOverride = String.fromEnvironment('ZONEZ_API_HOST');
    if (hostOverride.isNotEmpty) {
      return 'http://$hostOverride:$devPort';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:$devPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'http://$localDevIp:$devPort';
      default:
        return 'http://$herdHost';
    }
  }

  static String get apiUrl => '$baseUrl/api';

  /// Helpful in debug when login fails on a phone.
  static String get connectivityHint {
    if (usesPublicApi) {
      return 'يتصل بـ $apiUrl (سيرفر عام — أي شبكة)';
    }
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'تطوير محلي: $apiUrl — الهاتف والكمبيوتر على نفس Wi‑Fi + artisan serve';
    }
    return 'تطوير محلي: $apiUrl';
  }

  static const String lounges = '/lounges';
  static const String loungesNearby = '/lounges/nearby';
  static const String offers = '/offers';
  static const String tournaments = '/tournaments';

  static const String profile = '/profile';
  static const String profileUpdate = '/profile/update';
  static const String profileAvatar = '/profile/avatar';

  static const String loyaltyStatus = '/loyalty/status';

  static const String publicBrandingSettings = '/public/branding-settings';

  static String loyaltyNotificationRead(int id) => '/loyalty/notifications/$id/read';

  static String tournamentRegister(int id) => '/tournaments/$id/register';

  static String tournamentUnregister(int id) => '/tournaments/$id/unregister';

  static const String myTournamentRegistrations = '/tournaments/my/registrations';

  static const String myActiveTournamentRegistrations =
      '/tournaments/my/registrations/active';

  static const String myTournamentParticipationHistory =
      '/tournaments/my/registrations/history';

  static String tournamentBracket(int id) => '/tournaments/$id/bracket';

  static const String deviceTokens = '/device-tokens';

  static const String authGoogle = '/auth/google';

  static const String plutuLocalBankCreate = '/payments/plutu/local-bank/create';

  static String loungeAvailability(int stationId) =>
      '/lounges/$stationId/availability';

  static String loungeBookingStop(int stationId) => '/lounges/$stationId/booking-stop';

  static const String bookings = '/bookings';

  static String booking(int id) => '/bookings/$id';

  static String bookingCancel(int id) => '/bookings/$id/cancel';

  static String bookingSyncPayment(int id) => '/bookings/$id/sync-payment';

  static String bookingReceiptPdf(int id) => '/bookings/$id/receipt/pdf';

  static String get paymentCallbackUrl => '$baseUrl/payment/callback';
}
