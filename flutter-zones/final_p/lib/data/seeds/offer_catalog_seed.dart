/// Simulated GET /api/offers — dates computed at load time for active promos.
List<Map<String, dynamic>> buildOfferCatalogApiPayload() {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 5));

  String iso(DateTime d) => d.toIso8601String();

  return [
    {
      'id': 1,
      'title': 'احجز 2 واحصل على 1 مجاناً!',
      'offer_image': 'https://picsum.photos/seed/zonez1/400/200',
      'description':
          'عرض محدود على جميع الصالات — احجز ساعتين واحصل على ساعة ثالثة مجاناً. مثالي للعب الجماعي مع الأصدقاء.',
      'valid_from': iso(start),
      'expires_at': iso(end),
      'original_price': 75,
      'discounted_price': 50,
      'terms': [
        'العرض ساري على الحجوزات المتاحة فقط.',
        'لا يمكن الجمع بين هذا العرض وعروض أخرى.',
        'يجب الحضور في الوقت المحدد لتفعيل العرض.',
        'الساعة المجانية تُضاف تلقائياً بعد إتمام الحجز.',
      ],
      'time_slots': [
        {'id': 101, 'time_range': 'من 5:00 م إلى 8:00 م', 'is_available': true},
        {'id': 102, 'time_range': 'من 8:00 م إلى 11:00 م', 'is_available': true},
        {'id': 103, 'time_range': 'من 11:00 م إلى 2:00 ص', 'is_available': true},
        {'id': 104, 'time_range': 'من 2:00 ص إلى 5:00 ص', 'is_available': false},
      ],
    },
    {
      'id': 2,
      'title': 'خصم 30% على الحجز المسائي',
      'offer_image': 'https://picsum.photos/seed/zonez2/400/200',
      'description':
          'استمتع بخصم 30% على جميع الحجوزات من 6 مساءً حتى 12 ليلاً في Pro Gaming Lounge.',
      'valid_from': iso(start),
      'expires_at': iso(start.add(const Duration(days: 7))),
      'original_price': 70,
      'discounted_price': 52,
      'terms': ['ساري أيام الأسبوع', 'حجز مسبق مطلوب'],
      'time_slots': [
        {'id': 201, 'time_range': 'من 6:00 م إلى 8:00 م', 'is_available': true},
        {'id': 202, 'time_range': 'من 8:00 م إلى 10:00 م', 'is_available': false},
        {'id': 203, 'time_range': 'من 10:00 م إلى 12:00 ص', 'is_available': true},
      ],
    },
    {
      'id': 3,
      'title': 'باقة نهاية الأسبوع',
      'offer_image': 'https://picsum.photos/seed/zonez3/400/200',
      'description': '3 ساعات بسعر ساعتين — العرض ساري أيام الجمعة والسبت في Elite Play Station.',
      'valid_from': iso(start),
      'expires_at': iso(start.add(const Duration(days: 5))),
      'original_price': 120,
      'discounted_price': 90,
      'terms': ['الجمعة والسبت فقط'],
      'time_slots': [
        {'id': 301, 'time_range': 'من 1:00 م إلى 4:00 م', 'is_available': true},
        {'id': 304, 'time_range': 'من 4:00 م إلى 7:00 م', 'is_available': true},
        {'id': 303, 'time_range': 'من 7:00 م إلى 10:00 م', 'is_available': true},
      ],
    },
    {
      'id': 4,
      'title': 'أول حجز مجاني لمدة ساعة',
      'offer_image': 'https://picsum.photos/seed/zonez4/400/200',
      'description': 'للمستخدمين الجدد فقط — ساعة لعب مجانية في أول حجز.',
      'valid_from': iso(start),
      'expires_at': iso(start.add(const Duration(days: 14))),
      'original_price': 25,
      'discounted_price': 0,
      'terms': ['للمستخدمين الجدد فقط', 'مرة واحدة لكل حساب'],
      'time_slots': [
        {'id': 401, 'time_range': 'من 10:00 ص إلى 11:00 ص', 'is_available': true},
        {'id': 402, 'time_range': 'من 2:00 م إلى 3:00 م', 'is_available': false},
      ],
    },
    {
      'id': 5,
      'title': 'بطولة الأسبوع — دخول مجاني',
      'offer_image': 'https://picsum.photos/seed/zonez5/400/200',
      'description': 'سجل الآن واحجز مقعدك في بطولة الأسبوع مع دخول مجاني.',
      'valid_from': iso(start),
      'expires_at': iso(start.add(const Duration(days: 2))),
      'original_price': 30,
      'discounted_price': 25,
      'terms': ['يشمل الدخول للبطولة فقط'],
      'time_slots': [
        {'id': 501, 'time_range': 'من 4:00 م إلى 6:00 م', 'is_available': true},
        {'id': 502, 'time_range': 'من 6:00 م إلى 8:00 م', 'is_available': true},
      ],
    },
  ];
}
