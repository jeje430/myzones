import 'package:flutter/material.dart';

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
    required this.type,
    required this.nameAr,
    required this.icon,
    required this.hourlyRate,
    required this.averageRating,
    required this.availableCount,
    this.specs,
  });

  final DeviceType type;
  final String nameAr;
  final IconData icon;
  final double hourlyRate;
  final double averageRating;
  final int availableCount;
  final String? specs;

  bool get isAvailable => availableCount > 0;

  DevicePackage copyWith({
    double? averageRating,
    int? availableCount,
  }) {
    return DevicePackage(
      type: type,
      nameAr: nameAr,
      icon: icon,
      hourlyRate: hourlyRate,
      averageRating: averageRating ?? this.averageRating,
      availableCount: availableCount ?? this.availableCount,
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
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final double loungeAverageRating;
  final int reviewCount;
  final List<DevicePackage> devices;
  final String? imageUrl;

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
    );
  }
}

class HourlyTimeSlot {
  const HourlyTimeSlot({
    required this.id,
    required this.label,
    required this.startDateTime,
    required this.isAvailable,
  });

  final String id;
  final String label;
  final DateTime startDateTime;
  final bool isAvailable;
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
