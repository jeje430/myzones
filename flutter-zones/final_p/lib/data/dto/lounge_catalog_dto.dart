import 'package:flutter/material.dart';

import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';

/// REST-shaped lounge row — mirrors the future Laravel dashboard API payload.
class LoungeCatalogDto {
  const LoungeCatalogDto({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.devices,
    required this.reviews,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final List<DeviceCatalogDto> devices;
  final List<ReviewCatalogDto> reviews;

  factory LoungeCatalogDto.fromJson(Map<String, dynamic> json) {
    return LoungeCatalogDto(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      devices: (json['devices'] as List<dynamic>)
          .map((e) => DeviceCatalogDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ReviewCatalogDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Device/package row nested under a lounge — only listed devices exist for that lounge.
class DeviceCatalogDto {
  const DeviceCatalogDto({
    required this.type,
    required this.nameAr,
    required this.hourlyRate,
    required this.availableCount,
    required this.averageRating,
    this.specs,
  });

  final DeviceType type;
  final String nameAr;
  final double hourlyRate;
  final int availableCount;
  final double averageRating;
  final String? specs;

  factory DeviceCatalogDto.fromJson(Map<String, dynamic> json) {
    return DeviceCatalogDto(
      type: _parseDeviceType(json['type'] as String),
      nameAr: json['name_ar'] as String,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      availableCount: json['available_count'] as int,
      averageRating: (json['average_rating'] as num).toDouble(),
      specs: json['specs'] as String?,
    );
  }

  DevicePackage toDomain() {
    return DevicePackage(
      type: type,
      nameAr: nameAr,
      icon: _iconForType(type),
      hourlyRate: hourlyRate,
      averageRating: averageRating,
      availableCount: availableCount,
      specs: specs,
    );
  }
}

class ReviewCatalogDto {
  const ReviewCatalogDto({
    required this.category,
    required this.stars,
    required this.comment,
    this.submittedAt,
  });

  final RatingCategory category;
  final int stars;
  final String comment;
  final DateTime? submittedAt;

  factory ReviewCatalogDto.fromJson(Map<String, dynamic> json) {
    return ReviewCatalogDto(
      category: _parseRatingCategory(json['category'] as String),
      stars: json['stars'] as int,
      comment: json['comment'] as String,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
    );
  }
}

DeviceType _parseDeviceType(String raw) {
  switch (raw) {
    case 'ps5':
      return DeviceType.ps5;
    case 'pc':
      return DeviceType.pc;
    case 'vr':
      return DeviceType.vr;
    case 'xbox':
      return DeviceType.xbox;
    default:
      throw ArgumentError('Unknown device type: $raw');
  }
}

RatingCategory _parseRatingCategory(String raw) {
  switch (raw) {
    case 'general':
      return RatingCategory.general;
    case 'ps5':
      return RatingCategory.ps5;
    case 'pc':
      return RatingCategory.pc;
    case 'vr':
      return RatingCategory.vr;
    case 'xbox':
      return RatingCategory.xbox;
    default:
      throw ArgumentError('Unknown rating category: $raw');
  }
}

IconData _iconForType(DeviceType type) {
  switch (type) {
    case DeviceType.ps5:
      return Icons.videogame_asset;
    case DeviceType.pc:
      return Icons.computer;
    case DeviceType.vr:
      return Icons.view_in_ar;
    case DeviceType.xbox:
      return Icons.sports_esports;
  }
}

/// Maps API DTOs into domain [LoungeModel] instances.
class LoungeCatalogMapper {
  LoungeCatalogMapper._();

  static LoungeModel toLounge(LoungeCatalogDto dto) {
    final devices = dto.devices.map((d) => d.toDomain()).toList();
    final generalReviews =
        dto.reviews.where((r) => r.category == RatingCategory.general).toList();
    final generalAvg = generalReviews.isEmpty
        ? 0.0
        : generalReviews.map((r) => r.stars).reduce((a, b) => a + b) /
            generalReviews.length;

    return LoungeModel(
      id: dto.id,
      name: dto.name,
      location: dto.location,
      description: dto.description,
      loungeAverageRating: generalAvg > 0
          ? double.parse(generalAvg.toStringAsFixed(1))
          : 4.5,
      reviewCount: generalReviews.length,
      imageUrl: dto.imageUrl,
      devices: devices,
    );
  }

  static List<StoredCategoryRating> toStoredReviews(LoungeCatalogDto dto) {
    return dto.reviews
        .map(
          (r) => StoredCategoryRating(
            category: r.category,
            stars: r.stars,
            comment: r.comment,
            submittedAt: r.submittedAt,
          ),
        )
        .toList();
  }
}

