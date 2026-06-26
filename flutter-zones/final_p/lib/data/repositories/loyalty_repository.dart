import '../../core/config/api_config.dart';
import '../../core/http/api_client.dart';
import '../../models/loyalty_status.dart';

class LoyaltyRepository {
  LoyaltyRepository._();
  static final LoyaltyRepository instance = LoyaltyRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<({LoyaltyStatus loyalty, List<LoyaltyNotificationDto> notifications})>
      fetchStatus() async {
    final body = await _api.get(ApiConfig.loyaltyStatus) as Map<String, dynamic>;
    final loyaltyJson = body['loyalty'] as Map<String, dynamic>? ?? {};
    final notificationsJson = body['notifications'] as List<dynamic>? ?? [];

    return (
      loyalty: LoyaltyStatus.fromJson(loyaltyJson),
      notifications: notificationsJson
          .map((e) => LoyaltyNotificationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _api.post(ApiConfig.loyaltyNotificationRead(notificationId));
  }
}
