import 'package:flutter/foundation.dart';

import '../models/zones_models.dart';

import '../services/zones_api_service.dart';



class ZonesDataProvider extends ChangeNotifier {

  final ZonesApiService _api = ZonesApiService.instance;



  List<OfferModel> offers = [];

  UserModel? user;

  bool isLoadingOffers = false;

  bool isLoadingProfile = false;

  String? offersError;

  String? profileError;



  List<OfferModel> get activeOffers =>

      offers.where((o) => !o.isExpired).toList();



  Future<void> loadOffers() async {

    if (isLoadingOffers) return;

    isLoadingOffers = true;

    offersError = null;

    notifyListeners();



    try {

      offers = await _api.fetchOffers();

    } catch (e) {

      offersError = e.toString();

    } finally {

      isLoadingOffers = false;

      notifyListeners();

    }

  }



  void refreshOffersExpiry() {

    final before = offers.length;

    offers = offers.where((o) => !o.isExpired).toList();

    if (offers.length != before) notifyListeners();

  }



  Future<List<TimeSlotModel>> fetchTimeSlots(int offerId) {

    return _api.fetchTimeSlots(offerId);

  }



  double getOfferPrice(int offerId) => _api.getOfferPrice(offerId);



  Future<BookingConfirmation> confirmBooking({

    required int offerId,

    required int timeSlotId,

    required String loungeName,

  }) {

    return _api.confirmBooking(

      offerId: offerId,

      timeSlotId: timeSlotId,

      loungeName: loungeName,

    );

  }



  Future<void> loadUserProfile() async {

    if (isLoadingProfile) return;

    isLoadingProfile = true;

    profileError = null;

    notifyListeners();



    try {

      user = await _api.fetchUserProfile();

    } catch (e) {

      profileError = e.toString();

    } finally {

      isLoadingProfile = false;

      notifyListeners();

    }

  }



  Future<bool> updateUserProfile({

    required String name,

    required String phone,

    required String email,

  }) async {

    if (user == null) return false;



    try {

      user = await _api.updateUserProfile(

        user!.copyWith(name: name, phone: phone, email: email),

      );

      notifyListeners();

      return true;

    } catch (_) {

      return false;

    }

  }

}

