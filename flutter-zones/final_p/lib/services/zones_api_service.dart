import '../core/config/api_config.dart';
import '../core/http/api_client.dart';
import '../data/repositories/offer_catalog_repository.dart';
import '../models/zones_models.dart';

class BookingConfirmation {
  const BookingConfirmation({
    required this.bookingId,
    required this.finalPrice,
  });

  final String bookingId;
  final double finalPrice;
}

/// Laravel API layer for offers and profile.
class ZonesApiService {
  ZonesApiService._();
  static final ZonesApiService instance = ZonesApiService._();

  final ApiClient _api = ApiClient.instance;
  final OfferCatalogRepository _offers = OfferCatalogRepository.instance;

  UserModel? _user;

  Future<List<OfferModel>> fetchOffers({bool forceRefresh = false}) =>
      _offers.fetchActiveOffers(forceRefresh: forceRefresh);

  Future<List<TimeSlotModel>> fetchTimeSlots(int offerId) =>
      _offers.fetchTimeSlots(offerId);

  double getOfferPrice(int offerId) => _offers.getOfferPrice(offerId);

  Future<BookingConfirmation> confirmBooking({
    required int offerId,
    required int timeSlotId,
    required String loungeName,
  }) async {
    final bookingId = await _offers.confirmSlotBooking(
      offerId: offerId,
      timeSlotId: timeSlotId,
    );

    return BookingConfirmation(
      bookingId: bookingId,
      finalPrice: getOfferPrice(offerId),
    );
  }

  Future<UserModel> fetchUserProfile() async {
    final body = await _api.get(ApiConfig.profile) as Map<String, dynamic>;
    final userJson = body['user'] as Map<String, dynamic>;
    _user = _userFromJson(userJson);
    return _user!;
  }

  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    final body = await _api.put(
      ApiConfig.profileUpdate,
      body: {
        'name': updatedUser.name,
        'phone': updatedUser.phone,
      },
    ) as Map<String, dynamic>;

    final userJson = body['user'] as Map<String, dynamic>;
    _user = _userFromJson(userJson);
    return _user!;
  }

  void setCurrentUser(UserModel user) {
    _user = user;
  }

  UserModel _userFromJson(Map<String, dynamic> json) {
    return UserModel(
      name: (json['name'] ?? json['full_name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      profileImage: json['profile_image'] as String?,
    );
  }

  Future<UserModel> uploadProfileAvatar(List<int> bytes, {String filename = 'avatar.jpg'}) async {
    final body = await _api.postMultipart(
      ApiConfig.profileAvatar,
      fieldName: 'avatar',
      bytes: bytes,
      filename: filename,
    ) as Map<String, dynamic>;

    final avatarUrl = body['avatar_url'] as String?;
    final userJson = body['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw ApiException(statusCode: 500, message: 'استجابة غير متوقعة من الخادم');
    }

    _user = _userFromJson(userJson);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      _user = _user!.copyWith(profileImage: avatarUrl);
    }
    return _user!;
  }

  Future<UserModel> deleteProfileAvatar() async {
    final body = await _api.delete(ApiConfig.profileAvatar) as Map<String, dynamic>;
    final userJson = body['user'] as Map<String, dynamic>;
    _user = _userFromJson(userJson);
    return _user!;
  }
}
