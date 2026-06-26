class BookingStopStatus {
  const BookingStopStatus({
    required this.id,
    required this.reasonKey,
    required this.reasonLabel,
    required this.startsOn,
    this.endsOn,
    required this.message,
    required this.buttonLabel,
    this.openEnded = false,
  });

  final int id;
  final String reasonKey;
  final String reasonLabel;
  final String startsOn;
  final String? endsOn;
  final String message;
  final String buttonLabel;
  final bool openEnded;

  bool get isActive => true;

  factory BookingStopStatus.fromJson(Map<String, dynamic> json) {
    return BookingStopStatus(
      id: json['id'] as int,
      reasonKey: json['reason_key'] as String? ?? '',
      reasonLabel: json['reason_label'] as String? ?? '',
      startsOn: json['starts_on'] as String? ?? '',
      endsOn: json['ends_on'] as String?,
      message: json['message'] as String? ?? '',
      buttonLabel: json['button_label'] as String? ?? 'الحجز غير متاح مؤقتاً',
      openEnded: json['open_ended'] as bool? ?? json['ends_on'] == null,
    );
  }
}
