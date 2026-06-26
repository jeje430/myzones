import '../../core/config/api_config.dart';
import '../../core/http/api_client.dart';

class DeviceTokenRepository {
  DeviceTokenRepository._();
  static final DeviceTokenRepository instance = DeviceTokenRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _api.post(
      ApiConfig.deviceTokens,
      body: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
