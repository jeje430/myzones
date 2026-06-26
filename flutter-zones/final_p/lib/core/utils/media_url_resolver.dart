import '../config/api_config.dart';

/// Resolves Laravel storage paths to a URL reachable by the current device.
abstract final class MediaUrlResolver {
  static String? resolve(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    final value = pathOrUrl.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      const marker = '/storage/';
      final index = value.indexOf(marker);
      if (index >= 0) {
        final storagePath = value.substring(index + 1);
        return '${ApiConfig.baseUrl}/$storagePath';
      }
      return value;
    }

    final path = value.replaceFirst(RegExp(r'^/'), '');
    if (path.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$path';
    }

    return '${ApiConfig.baseUrl}/storage/$path';
  }
}
