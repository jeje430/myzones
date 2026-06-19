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

/// Simulated Laravel API layer — swap method bodies for HTTP when backend is ready.
class ZonesApiService {
  ZonesApiService._();
  static final ZonesApiService instance = ZonesApiService._();

  static const _baseUrl = 'https://api.zones.app';

  final OfferCatalogRepository _offers = OfferCatalogRepository.instance;

  UserModel _user = UserModel(
    name: 'أحمد محمد',
    phone: '+218 91 234 5678',
    email: 'ahmed@zones.com',
  );

  Future<void> _simulateNetworkDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  Future<List<OfferModel>> fetchOffers() async {
    await _simulateNetworkDelay();
    return _offers.fetchActiveOffers();
  }

  Future<List<TimeSlotModel>> fetchTimeSlots(int offerId) async {
    await _simulateNetworkDelay();
    return _offers.fetchTimeSlots(offerId);
  }

  double getOfferPrice(int offerId) => _offers.getOfferPrice(offerId);

  Future<BookingConfirmation> confirmBooking({
    required int offerId,
    required int timeSlotId,
    required String loungeName,
  }) async {
    await _simulateNetworkDelay();

    final bookingId = await _offers.confirmSlotBooking(
      offerId: offerId,
      timeSlotId: timeSlotId,
    );

    // ignore: avoid_print
    print('POST $_baseUrl/api/bookings → booking_id: $bookingId');

    return BookingConfirmation(
      bookingId: bookingId,
      finalPrice: getOfferPrice(offerId),
    );
  }

  Future<UserModel> fetchUserProfile() async {
    await _simulateNetworkDelay();
    return _user;
  }

  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    await _simulateNetworkDelay();
    // ignore: avoid_print
    print('PUT $_baseUrl/api/profile → ${updatedUser.toJson()}');
    _user = updatedUser;
    return _user;
  }

  void setCurrentUser(UserModel user) {
    _user = user;
  }
}
