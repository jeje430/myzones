import 'lounge_model.dart';

enum BookingStatus { active, past, cancelled }

enum PaymentStatus { paid, unpaid, payOnArrival, electronic, payWithPoints }

enum BookingType { lounge, tournament }

class Booking {
  const Booking({
    required this.id,
    required this.title,
    required this.day,
    required this.time,
    required this.price,
    required this.status,
    this.loungeName,
    this.deviceName,
    this.deviceType,
    this.paymentStatus = PaymentStatus.paid,
    this.startDateTime,
    this.checkedIn = false,
    this.earnedPoints,
    this.type = BookingType.lounge,
    this.tournamentId,
    this.loungeId,
    this.gameName,
  });

  final String id;
  final String title;
  final String day;
  final String time;
  final double price;
  final BookingStatus status;
  final String? loungeName;
  final String? deviceName;
  final DeviceType? deviceType;
  final PaymentStatus paymentStatus;
  final DateTime? startDateTime;
  final bool checkedIn;
  final int? earnedPoints;
  final BookingType type;
  final String? tournamentId;
  final String? loungeId;
  final String? gameName;

  bool get isActive => status == BookingStatus.active;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isTournament => type == BookingType.tournament;
  bool get isLounge => type == BookingType.lounge;

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.unpaid:
        return 'غير مدفوع';
      case PaymentStatus.payOnArrival:
        return 'الدفع نقداً';
      case PaymentStatus.electronic:
        return 'الدفع الإلكتروني';
      case PaymentStatus.payWithPoints:
        return 'دفع بالنقاط — مجاني';
    }
  }

  Booking copyWith({
    String? id,
    String? title,
    String? day,
    String? time,
    double? price,
    BookingStatus? status,
    String? loungeName,
    String? deviceName,
    DeviceType? deviceType,
    PaymentStatus? paymentStatus,
    DateTime? startDateTime,
    bool? checkedIn,
    int? earnedPoints,
    BookingType? type,
    String? tournamentId,
    String? loungeId,
    String? gameName,
  }) {
    return Booking(
      id: id ?? this.id,
      title: title ?? this.title,
      day: day ?? this.day,
      time: time ?? this.time,
      price: price ?? this.price,
      status: status ?? this.status,
      loungeName: loungeName ?? this.loungeName,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      startDateTime: startDateTime ?? this.startDateTime,
      checkedIn: checkedIn ?? this.checkedIn,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      type: type ?? this.type,
      tournamentId: tournamentId ?? this.tournamentId,
      loungeId: loungeId ?? this.loungeId,
      gameName: gameName ?? this.gameName,
    );
  }
}
