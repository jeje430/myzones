import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart' show Color, Icons;



import '../models/booking.dart';

import '../models/lounge_model.dart';

import '../models/notification_model.dart';

import '../models/reward_milestone.dart';



class AppStateProvider extends ChangeNotifier {

  String userName = 'أحمد محمد';

  String userPhone = '+218 91 234 5678';

  bool pushNotificationsEnabled = true;

  bool bookingRemindersEnabled = true;

  int bottomNavIndex = 0;

  int loyaltyPoints = 850;

  Uint8List? profileAvatarBytes;

  final List<String> redeemedCoupons = [];



  final Set<String> favoriteLoungeNames = {};

  final List<Booking> _currentBookings = [];

  final List<Booking> _pastBookings = [

    Booking(

      id: 'past-1',

      title: 'PlayStation 5',

      day: 'الأحد 18 مايو',

      time: '6:00 م',

      price: 50,

      status: BookingStatus.past,

      loungeName: 'Game Zone Arena',

      deviceName: 'PlayStation 5',

      deviceType: DeviceType.ps5,

      paymentStatus: PaymentStatus.paid,

      earnedPoints: 50,

    ),

  ];

  final List<AppNotification> _notifications = [];

  final Set<String> _notificationIds = {};



  AppNotification? _latestBannerNotification;



  List<Booking> get currentBookings => List.unmodifiable(_currentBookings);

  List<Booking> get pastBookings => List.unmodifiable(_pastBookings);

  /// Lounge device bookings only — tournaments live in [TournamentHistoryScreen].
  List<Booking> get currentLoungeBookings => _currentBookings
      .where((b) => !b.isTournament)
      .toList(growable: false);

  List<Booking> get pastLoungeBookings =>
      _pastBookings.where((b) => !b.isTournament).toList(growable: false);

  List<Booking> get currentTournamentParticipations => _currentBookings
      .where((b) => b.isTournament && !b.isCancelled)
      .toList(growable: false);

  List<Booking> get pastTournamentParticipations =>
      _pastBookings.where((b) => b.isTournament).toList(growable: false);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  AppNotification? get latestBannerNotification => _latestBannerNotification;



  int get nextMilestonePoints {

    for (final milestone in kRewardMilestones) {

      if (loyaltyPoints < milestone.pointsRequired) {

        return milestone.pointsRequired;

      }

    }

    return kRewardMilestones.last.pointsRequired;

  }



  double get loyaltyProgress {

    final next = nextMilestonePoints;

    if (next <= 0) return 1.0;

    return (loyaltyPoints / next).clamp(0.0, 1.0);

  }

  /// True when the loyalty progress bar is full (100%) — unlocks pay-with-points.
  bool get canPayWithPoints => loyaltyProgress >= 1.0;

  void resetLoyaltyPointsAfterRedemption() {
    loyaltyPoints = 0;
    notifyListeners();
  }



  Booking? getBookingById(String id) {

    for (final b in _currentBookings) {

      if (b.id == id) return b;

    }

    for (final b in _pastBookings) {

      if (b.id == id) return b;

    }

    return null;

  }



  void setBottomNavIndex(int index) {

    if (bottomNavIndex == index) return;

    bottomNavIndex = index;

    notifyListeners();

  }



  void updateProfile({required String name, required String phone}) {

    userName = name;

    userPhone = phone;

    notifyListeners();

  }



  void setPushNotifications(bool enabled) {

    pushNotificationsEnabled = enabled;

    notifyListeners();

  }



  void setBookingReminders(bool enabled) {

    bookingRemindersEnabled = enabled;

    notifyListeners();

  }



  void toggleFavorite(String loungeName) {

    if (favoriteLoungeNames.contains(loungeName)) {

      favoriteLoungeNames.remove(loungeName);

    } else {

      favoriteLoungeNames.add(loungeName);

    }

    notifyListeners();

  }



  bool isFavorite(String loungeName) =>

      favoriteLoungeNames.contains(loungeName);



  bool hasNotification(String id) => _notificationIds.contains(id);



  void pushNotification(AppNotification notification) {

    if (!pushNotificationsEnabled) return;

    if (_notificationIds.contains(notification.id)) return;



    _notificationIds.add(notification.id);

    _notifications.insert(0, notification);

    _latestBannerNotification = notification;

    notifyListeners();

  }



  void dismissBannerNotification() {

    _latestBannerNotification = null;

    notifyListeners();

  }



  void markNotificationRead(String id) {

    final index = _notifications.indexWhere((n) => n.id == id);

    if (index == -1) return;

    _notifications[index] = _notifications[index].markRead();

    notifyListeners();

  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _notificationIds.remove(id);
    if (_latestBannerNotification?.id == id) {
      _latestBannerNotification = null;
    }
    notifyListeners();
  }

  void deleteAllNotifications() {
    _notifications.clear();
    _notificationIds.clear();
    _latestBannerNotification = null;
    notifyListeners();
  }

  void setProfileAvatar(Uint8List bytes) {
    profileAvatarBytes = bytes;
    notifyListeners();
  }



  void addBooking({

    required String id,

    required String title,

    required String day,

    required String time,

    required double price,

    String? loungeName,

    String? deviceName,

    DeviceType? deviceType,

    PaymentStatus paymentStatus = PaymentStatus.paid,

    DateTime? startDateTime,

    int? earnedPoints,

  }) {

    _currentBookings.insert(

      0,

      Booking(

        id: id,

        title: title,

        day: day,

        time: time,

        price: price,

        status: BookingStatus.active,

        loungeName: loungeName,

        deviceName: deviceName,

        deviceType: deviceType,

        paymentStatus: paymentStatus,

        startDateTime: startDateTime,

        earnedPoints: earnedPoints,

      ),

    );



    notifyListeners();

  }

  void addTournamentBooking({
    required String id,
    required String tournamentTitle,
    required String day,
    required String time,
    required double entryFee,
    required String loungeName,
    required String loungeId,
    required String tournamentId,
    required String gameName,
    required PaymentStatus paymentStatus,
    required DateTime startDateTime,
  }) {
    _currentBookings.insert(
      0,
      Booking(
        id: id,
        title: tournamentTitle,
        day: day,
        time: time,
        price: entryFee,
        status: BookingStatus.active,
        loungeName: loungeName,
        paymentStatus: paymentStatus,
        startDateTime: startDateTime,
        type: BookingType.tournament,
        tournamentId: tournamentId,
        loungeId: loungeId,
        gameName: gameName,
      ),
    );
    notifyListeners();
  }

  void moveTournamentBookingToPast(String bookingId) {
    final index = _currentBookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final booking = _currentBookings.removeAt(index).copyWith(
          status: BookingStatus.past,
        );
    _pastBookings.insert(0, booking);
    notifyListeners();
  }

  void cancelTournamentBooking(String bookingId) {
    final index = _currentBookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final booking = _currentBookings.removeAt(index).copyWith(
          status: BookingStatus.cancelled,
        );
    _pastBookings.insert(0, booking);
    notifyListeners();
  }

  void cancelBooking(String bookingId) {

    final index = _currentBookings.indexWhere((b) => b.id == bookingId);

    if (index == -1) return;



    final booking = _currentBookings.removeAt(index).copyWith(

          status: BookingStatus.cancelled,

        );

    _pastBookings.insert(0, booking);

    notifyListeners();

  }



  void autoCancelBooking(String bookingId) {

    final index = _currentBookings.indexWhere((b) => b.id == bookingId);

    if (index == -1) return;



    final booking = _currentBookings.removeAt(index).copyWith(

          status: BookingStatus.cancelled,

        );

    _pastBookings.insert(0, booking);

    notifyListeners();

  }



  void checkInBooking(String bookingId) {

    final index = _currentBookings.indexWhere((b) => b.id == bookingId);

    if (index == -1) return;



    const earnedPoints = 90;

    final booking = _currentBookings.removeAt(index).copyWith(

          status: BookingStatus.past,

          checkedIn: true,

          earnedPoints: earnedPoints,

        );

    _pastBookings.insert(0, booking);

    loyaltyPoints += earnedPoints;



    pushNotification(

      AppNotification(

        id: 'points-$bookingId',

        title: 'نقاط مكافأة',

        body: 'النقاط المكتسبة: +$earnedPoints نقطة',

        createdAt: DateTime.now(),

        icon: Icons.card_giftcard,

        color: const Color(0xFFFFD700),

        type: NotificationType.reward,

      ),

    );



    notifyListeners();

  }



  String? redeemReward(RewardMilestone milestone) {

    if (loyaltyPoints < milestone.pointsRequired) return null;



    loyaltyPoints -= milestone.pointsRequired;

    final code =

        '${milestone.couponPrefix}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    redeemedCoupons.insert(0, code);

    notifyListeners();

    return code;

  }



  void deleteAccount() {

    userName = '';

    userPhone = '';

    loyaltyPoints = 0;

    redeemedCoupons.clear();

    favoriteLoungeNames.clear();

    _currentBookings.clear();

    _pastBookings.clear();

    _notifications.clear();

    _notificationIds.clear();

    _latestBannerNotification = null;

    bottomNavIndex = 0;

    notifyListeners();

  }

}


