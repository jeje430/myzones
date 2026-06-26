import 'package:flutter/foundation.dart';

import '../core/branding/branding_constants.dart';
import '../data/dto/branding_settings_dto.dart';
import '../data/repositories/branding_repository.dart';

/// Global branding state — loaded during app bootstrap (before first frame).
class BrandingProvider extends ChangeNotifier {
  BrandingProvider({BrandingRepository? repository})
      : _repository = repository ?? BrandingRepository.instance;

  final BrandingRepository _repository;

  String _platformName = BrandingConstants.defaultPlatformName;
  String? _logoUrl;
  bool _loading = false;
  bool _initialized = false;

  String get platformName => _platformName;
  String? get logoUrl => _logoUrl;
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get hasRemoteLogo => _logoUrl != null && _logoUrl!.trim().isNotEmpty;

  String get fallbackLogoAsset => BrandingConstants.fallbackLogoAsset;

  Future<void> initialize() async {
    if (_initialized) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

    try {
      final settings = await _repository.fetchPublicSettings();
      _apply(settings);
    } catch (error) {
      debugPrint('BrandingProvider.refresh failed: $error');
      if (!_initialized) {
        _apply(BrandingSettings.fallback());
      }
    } finally {
      _loading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  void applySettings(BrandingSettings settings) {
    _apply(settings);
    _initialized = true;
    notifyListeners();
  }

  void _apply(BrandingSettings settings) {
    _platformName = settings.platformName;
    _logoUrl = settings.logoUrl;
  }
}
