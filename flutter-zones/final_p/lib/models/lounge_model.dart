import 'package:flutter/material.dart';

import 'booking_stop_status.dart';

enum DeviceType { ps5, pc, vr, xbox }

extension DeviceTypeFilterUi on DeviceType {
  String get filterLabel {
    switch (this) {
      case DeviceType.ps5:
        return 'PS5';
      case DeviceType.pc:
        return 'PC';
      case DeviceType.vr:
        return 'VR';
      case DeviceType.xbox:
        return 'Xbox';
    }
  }

  IconData get filterIcon {
    switch (this) {
      case DeviceType.ps5:
        return Icons.sports_esports_outlined;
      case DeviceType.pc:
        return Icons.computer_outlined;
      case DeviceType.vr:
        return Icons.view_in_ar_outlined;
      case DeviceType.xbox:
        return Icons.videogame_asset_outlined;
    }
  }
}

enum RatingCategory {
  general,
  ps5,
  pc,
  vr,
  xbox;

  String get labelAr {
    switch (this) {
      case RatingCategory.general:
        return 'الصالة العامة';
      case RatingCategory.ps5:
        return 'أجهزة PS5';
      case RatingCategory.pc:
        return 'أجهزة PC';
      case RatingCategory.vr:
        return 'أجهزة VR';
      case RatingCategory.xbox:
        return 'أجهزة Xbox';
    }
  }

  DeviceType? get deviceType {
    switch (this) {
      case RatingCategory.general:
        return null;
      case RatingCategory.ps5:
        return DeviceType.ps5;
      case RatingCategory.pc:
        return DeviceType.pc;
      case RatingCategory.vr:
        return DeviceType.vr;
      case RatingCategory.xbox:
        return DeviceType.xbox;
    }
  }

  static RatingCategory? fromDeviceType(DeviceType type) {
    switch (type) {
      case DeviceType.ps5:
        return RatingCategory.ps5;
      case DeviceType.pc:
        return RatingCategory.pc;
      case DeviceType.vr:
        return RatingCategory.vr;
      case DeviceType.xbox:
        return RatingCategory.xbox;
    }
  }
}

class DevicePackage {
  const DevicePackage({
    required this.id,
    required this.type,
    required this.nameAr,
    required this.icon,
    required this.hourlyRate,
    required this.averageRating,
    required this.availableCount,
    this.ratingsCount = 0,
    this.userRating,
    this.specs,
  });

  final String id;
  final DeviceType type;
  final String nameAr;
  final IconData icon;
  final double hourlyRate;
  final double averageRating;
  final int availableCount;
  final int ratingsCount;
  final int? userRating;
  final String? specs;

  bool get isAvailable => availableCount > 0;

  DevicePackage copyWith({
    double? averageRating,
    int? availableCount,
    int? ratingsCount,
    int? userRating,
    bool clearUserRating = false,
  }) {
    return DevicePackage(
      id: id,
      type: type,
      nameAr: nameAr,
      icon: icon,
      hourlyRate: hourlyRate,
      averageRating: averageRating ?? this.averageRating,
      availableCount: availableCount ?? this.availableCount,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      userRating: clearUserRating ? null : (userRating ?? this.userRating),
      specs: specs,
    );
  }
}

class LoungeModel {
  const LoungeModel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.loungeAverageRating,
    required this.reviewCount,
    required this.devices,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.isOpen = true,
    this.services = const [],
    this.opensAt,
    this.closesAt,
    this.distanceMeters,
    this.userHallRating,
    this.bookingStop,
    this.bookingsBlocked = false,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final double loungeAverageRating;
  final int reviewCount;
  final List<DevicePackage> devices;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isOpen;
  final List<String> services;
  final String? opensAt;
  final String? closesAt;
  final int? distanceMeters;
  final int? userHallRating;
  final BookingStopStatus? bookingStop;
  final bool bookingsBlocked;

  String get workHoursLabel {
    if (opensAt == null || closesAt == null) return '';
    return '${_formatHourAr(opensAt!)} - ${_formatHourAr(closesAt!)}';
  }

  static String _formatHourAr(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    if (hour == 0) return '12:00 ص';
    if (hour == 12) return '12:00 م';
    if (hour < 12) return '$hour:00 ص';
    if (hour == 13) return '1:00 م';
    if (hour == 14) return '2:00 م';
    return '${hour - 12}:00 م';
  }

  int get totalDevices =>
      availableDevices.fold(0, (sum, d) => sum + d.availableCount);

  int get startingPrice => availableDevices.isEmpty
      ? 0
      : availableDevices
          .map((d) => d.hourlyRate)
          .reduce((a, b) => a < b ? a : b)
          .round();

  /// Devices with stock — the only packages shown in booking.
  List<DevicePackage> get availableDevices =>
      devices.where((d) => d.isAvailable).toList();

  /// Whether this lounge officially offers a device type with available stock.
  bool offersDeviceType(DeviceType type) {
    final device = deviceByType(type);
    return device != null && device.isAvailable;
  }

  /// AND filter — lounge must offer every requested type.
  bool matchesAllDeviceTypes(Iterable<DeviceType> types) {
    for (final type in types) {
      if (!offersDeviceType(type)) return false;
    }
    return true;
  }

  /// Rating tracks bound to devices this lounge actually offers (+ general).
  List<RatingCategory> get supportedRatingCategories {
    final categories = <RatingCategory>[RatingCategory.general];
    for (final device in devices) {
      final category = RatingCategory.fromDeviceType(device.type);
      if (category != null && device.isAvailable) {
        categories.add(category);
      }
    }
    return categories;
  }

  /// Active packages for this hall — loaded dynamically from Laravel.
  List<DevicePackage> get catalogPackages => devices;

  DevicePackage? deviceById(String packageId) {
    for (final device in devices) {
      if (device.id == packageId) return device;
    }
    return null;
  }

  DevicePackage? deviceByType(DeviceType type) {
    for (final device in devices) {
      if (device.type == type) return device;
    }
    return null;
  }

  LoungeModel copyWith({
    double? loungeAverageRating,
    int? reviewCount,
    List<DevicePackage>? devices,
    bool? isOpen,
    List<String>? services,
    String? opensAt,
    String? closesAt,
    int? distanceMeters,
    int? userHallRating,
  }) {
    return LoungeModel(
      id: id,
      name: name,
      location: location,
      description: description,
      loungeAverageRating: loungeAverageRating ?? this.loungeAverageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      devices: devices ?? this.devices,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      isOpen: isOpen ?? this.isOpen,
      services: services ?? this.services,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      userHallRating: userHallRating ?? this.userHallRating,
    );
  }
}

class HourlyTimeSlot {
  const HourlyTimeSlot({
    required this.id,
    required this.label,
    required this.startDateTime,
    required this.isAvailable,
    this.deviceId,
    this.deviceCode,
    this.deviceName,
    this.packageId,
    this.hour,
    this.hourTo,
    this.totalPrice,
    this.originalTotalPrice,
    this.discountPercent,
    this.endDateTime,
  });

  final String id;
  final String label;
  final DateTime startDateTime;
  final bool isAvailable;
  final int? deviceId;
  final String? deviceCode;
  final String? deviceName;
  final int? packageId;
  final String? hour;
  final String? hourTo;
  final double? totalPrice;
  final double? originalTotalPrice;
  final int? discountPercent;
  final DateTime? endDateTime;
}

class AvailabilityResult {
  const AvailabilityResult({
    required this.isAvailable,
    this.slots = const [],
    this.message,
  });

  final bool isAvailable;
  final List<HourlyTimeSlot> slots;
  final String? message;
}
