// نموذج بيانات العروض

class OfferModel {

  final int id;

  final String title;

  final String offerImage;

  final String description;

  final DateTime? validFrom;

  final DateTime? expiresAt;

  final double? originalPrice;

  final double? discountedPrice;

  final int? discountPercent;

  final int? stationId;

  final int? packageId;

  final String stationName;

  final String packageName;

  final List<String> terms;



  OfferModel({

    required this.id,

    required this.title,

    required this.offerImage,

    required this.description,

    this.validFrom,

    this.expiresAt,

    this.originalPrice,

    this.discountedPrice,

    this.discountPercent,

    this.stationId,

    this.packageId,

    this.stationName = '',

    this.packageName = '',

    this.terms = const [],

  });



  bool get isBookable => stationId != null && packageId != null && stationId! > 0 && packageId! > 0;



  DateTime get promoStart {

    final from = validFrom ?? DateTime.now();

    return DateTime(from.year, from.month, from.day);

  }



  DateTime get promoEnd {

    final end = expiresAt ?? promoStart.add(const Duration(days: 7));

    return DateTime(end.year, end.month, end.day);

  }



  String get validityRangeLabel {

    String fmt(DateTime d) =>

        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    return 'العرض يبدأ من ${fmt(promoStart)} إلى ${fmt(promoEnd)}';

  }



  bool isDateInPromoWindow(DateTime date) {

    final d = DateTime(date.year, date.month, date.day);

    return !d.isBefore(promoStart) && !d.isAfter(promoEnd);

  }



  bool get isExpired =>

      expiresAt != null && DateTime.now().isAfter(expiresAt!);



  Duration? get remainingTime {

    if (expiresAt == null) return null;

    final remaining = expiresAt!.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;

  }



  String get countdownLabel {

    final remaining = remainingTime;

    if (remaining == null) return '';

    if (remaining == Duration.zero) return 'انتهى العرض';



    final days = remaining.inDays;

    final hours = remaining.inHours % 24;

    if (days > 0) {

      return '⏰ ينتهي العرض بعد $days ${days == 1 ? 'يوم' : 'أيام'} و $hours ${hours == 1 ? 'ساعة' : 'ساعات'}';

    }

    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {

      return '⏰ ينتهي العرض بعد $hours ${hours == 1 ? 'ساعة' : 'ساعات'} و $minutes دقيقة';

    }

    return '⏰ ينتهي العرض بعد $minutes دقيقة';

  }



  factory OfferModel.fromJson(Map<String, dynamic> json) {

    return OfferModel(

      id: json['id'] ?? 0,

      title: json['title'] ?? '',

      offerImage: json['offer_image'] ?? '',

      description: json['description'] ?? '',

      expiresAt: json['expires_at'] != null

          ? DateTime.tryParse(json['expires_at'].toString())

          : null,

      validFrom: json['valid_from'] != null

          ? DateTime.tryParse(json['valid_from'].toString())

          : null,

      originalPrice: (json['original_price'] as num?)?.toDouble(),

      discountedPrice: (json['discounted_price'] as num?)?.toDouble(),

      discountPercent: (json['discount_percent'] as num?)?.toInt(),

      stationId: (json['station_id'] as num?)?.toInt(),

      packageId: (json['package_id'] as num?)?.toInt(),

      stationName: json['station_name']?.toString() ?? '',

      packageName: json['package_name']?.toString() ?? '',

      terms: (json['terms'] as List<dynamic>?)

              ?.map((e) => e.toString())

              .toList() ??

          const [],

    );

  }

}



// نموذج بيانات أوقات الحجز (الباقات)

class TimeSlotModel {

  final int id;

  final String timeRange;

  bool isAvailable;



  TimeSlotModel({

    required this.id,

    required this.timeRange,

    required this.isAvailable,

  });



  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {

    return TimeSlotModel(

      id: json['id'] ?? 0,

      timeRange: json['time_range'] ?? '',

      isAvailable: json['is_available'] ?? true,

    );

  }

}



// نموذج بيانات المستخدم (الملف الشخصي)

class UserModel {

  final int? id;

  final String name;

  final String phone;

  final String email;

  final String? profileImage;



  UserModel({

    this.id,

    required this.name,

    required this.phone,

    required this.email,

    this.profileImage,

  });



  factory UserModel.fromJson(Map<String, dynamic> json) {

    return UserModel(

      id: json['id'] as int?,

      name: (json['name'] ?? json['full_name'] ?? '') as String,

      phone: (json['phone'] ?? '') as String,

      email: (json['email'] ?? '') as String,

      profileImage: json['profile_image'] as String?,

    );

  }



  Map<String, dynamic> toJson() => {

        'name': name,

        'phone': phone,

        'email': email,

        if (profileImage != null) 'profile_image': profileImage,

      };



  UserModel copyWith({String? name, String? phone, String? email, String? profileImage}) {

    return UserModel(

      name: name ?? this.name,

      phone: phone ?? this.phone,

      email: email ?? this.email,

      profileImage: profileImage ?? this.profileImage,

    );

  }

}

