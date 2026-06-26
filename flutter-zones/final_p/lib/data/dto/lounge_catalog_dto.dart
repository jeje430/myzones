import 'package:flutter/material.dart';

import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';
import '../../models/lounge_comment.dart';
import '../../models/booking_stop_status.dart';
import '../../core/utils/media_url_resolver.dart';

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
    this.latitude,
    this.longitude,
    this.averageRating,
    this.reviewsCount,
    this.isOpen,
    this.services = const [],
    this.opensAt,
    this.closesAt,
    this.distanceKm,
    this.distanceMeters,
    this.userHallRating,
    this.comments = const [],
    this.bookingStop,
    this.bookingsBlocked = false,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final List<DeviceCatalogDto> devices;
  final List<ReviewCatalogDto> reviews;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int? reviewsCount;
  final bool? isOpen;
  final List<LoungeServiceDto> services;
  final String? opensAt;
  final String? closesAt;
  final double? distanceKm;
  final int? distanceMeters;
  final int? userHallRating;
  final List<CommentCatalogDto> comments;
  final BookingStopStatus? bookingStop;
  final bool bookingsBlocked;

  factory LoungeCatalogDto.fromJson(Map<String, dynamic> json) {
    return LoungeCatalogDto(
      id: json['id'].toString(),
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int?,
      isOpen: json['is_open'] as bool?,
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      distanceMeters: json['distance_meters'] as int?,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => LoungeServiceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      devices: (json['devices'] as List<dynamic>? ?? [])
          .map((e) => DeviceCatalogDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => ReviewCatalogDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      userHallRating: json['user_hall_rating'] as int?,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => CommentCatalogDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookingStop: json['booking_stop'] is Map<String, dynamic>
          ? BookingStopStatus.fromJson(json['booking_stop'] as Map<String, dynamic>)
          : null,
      bookingsBlocked: json['bookings_blocked'] as bool? ?? false,
    );
  }
}

class LoungeServiceDto {
  const LoungeServiceDto({
    required this.key,
    required this.label,
    this.shortLabel,
  });

  final String key;
  final String label;
  final String? shortLabel;

  factory LoungeServiceDto.fromJson(Map<String, dynamic> json) {
    return LoungeServiceDto(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      shortLabel: json['shortLabel'] as String?,
    );
  }
}

/// Device/package row nested under a lounge — only listed devices exist for that lounge.
class DeviceCatalogDto {
  const DeviceCatalogDto({
    required this.id,
    required this.type,
    required this.nameAr,
    required this.hourlyRate,
    required this.availableCount,
    required this.averageRating,
    this.ratingsCount = 0,
    this.userRating,
    this.specs,
  });

  final String id;
  final DeviceType type;
  final String nameAr;
  final double hourlyRate;
  final int availableCount;
  final double averageRating;
  final int ratingsCount;
  final int? userRating;
  final String? specs;

  factory DeviceCatalogDto.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String? ?? 'ps5';
    final id = json['id']?.toString() ?? json['package_id']?.toString() ?? typeRaw;

    return DeviceCatalogDto(
      id: id,
      type: _parseDeviceType(typeRaw),
      nameAr: json['name_ar'] as String? ?? json['name'] as String? ?? '',
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0,
      availableCount: json['available_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      userRating: json['user_rating'] as int?,
      specs: json['specs'] as String?,
    );
  }

  DevicePackage toDomain() {
    return DevicePackage(
      id: id,
      type: type,
      nameAr: nameAr,
      icon: _iconForType(type),
      hourlyRate: hourlyRate,
      averageRating: averageRating,
      availableCount: availableCount,
      ratingsCount: ratingsCount,
      userRating: userRating,
      specs: specs,
    );
  }
}

class ReviewCatalogDto {
  const ReviewCatalogDto({
    required this.category,
    required this.stars,
    this.submittedAt,
  });

  final RatingCategory category;
  final int stars;
  final DateTime? submittedAt;

  factory ReviewCatalogDto.fromJson(Map<String, dynamic> json) {
    return ReviewCatalogDto(
      category: _parseRatingCategory(json['category'] as String),
      stars: json['stars'] as int,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
    );
  }
}

class CommentCatalogDto {
  const CommentCatalogDto({
    required this.id,
    required this.body,
    required this.customerName,
    this.authorUserId,
    this.profileImage,
    this.submittedAt,
    this.editedAt,
    this.updatedAt,
    this.canEdit = false,
    this.managerReply,
  });

  final int id;
  final String body;
  final String customerName;
  final int? authorUserId;
  final String? profileImage;
  final DateTime? submittedAt;
  final DateTime? editedAt;
  final DateTime? updatedAt;
  final bool canEdit;
  final ManagerReplyCatalogDto? managerReply;

  factory CommentCatalogDto.fromJson(Map<String, dynamic> json) {
    ManagerReplyCatalogDto? reply;
    final rawReply = json['manager_reply'];
    if (rawReply is Map<String, dynamic>) {
      reply = ManagerReplyCatalogDto.fromJson(rawReply);
    }

    final rawUser = json['user'];
    int? authorUserId;
    if (rawUser is Map<String, dynamic>) {
      authorUserId = rawUser['id'] as int?;
    }

    return CommentCatalogDto(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'زبون',
      authorUserId: authorUserId,
      profileImage: json['profile_image'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : (json['edited_at'] != null
              ? DateTime.tryParse(json['edited_at'] as String)
              : (json['submitted_at'] != null
                  ? DateTime.tryParse(json['submitted_at'] as String)
                  : null)),
      canEdit: json['can_edit'] as bool? ?? false,
      managerReply: reply,
    );
  }

  LoungeComment toDomain() {
    return LoungeComment(
      id: id,
      body: body,
      customerName: customerName,
      authorUserId: authorUserId,
      profileImage: profileImage,
      submittedAt: submittedAt ?? updatedAt,
      editedAt: editedAt ?? updatedAt,
      canEdit: canEdit,
      managerReply: managerReply?.toDomain(),
    );
  }
}

class ManagerReplyCatalogDto {
  const ManagerReplyCatalogDto({
    required this.id,
    required this.body,
    required this.managerName,
    this.profileImage,
    this.repliedAt,
  });

  final int id;
  final String body;
  final String managerName;
  final String? profileImage;
  final DateTime? repliedAt;

  factory ManagerReplyCatalogDto.fromJson(Map<String, dynamic> json) {
    return ManagerReplyCatalogDto(
      id: json['id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      managerName: json['manager_name'] as String? ?? 'مدير الصالة',
      profileImage: json['profile_image'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.tryParse(json['replied_at'] as String)
          : null,
    );
  }

  ManagerCommentReply toDomain() {
    return ManagerCommentReply(
      id: id,
      body: body,
      managerName: managerName,
      profileImage: profileImage,
      repliedAt: repliedAt,
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
    case 'simulator':
      return DeviceType.pc;
    case 'vip':
      return DeviceType.ps5;
    default:
      return DeviceType.ps5;
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
    final generalAvg = dto.averageRating ??
        (generalReviews.isEmpty
            ? 0.0
            : generalReviews.map((r) => r.stars).reduce((a, b) => a + b) /
                generalReviews.length);

    return LoungeModel(
      id: dto.id,
      name: dto.name,
      location: dto.location,
      description: dto.description,
      loungeAverageRating: generalAvg > 0
          ? double.parse(generalAvg.toStringAsFixed(1))
          : 0,
      reviewCount: dto.reviewsCount ?? generalReviews.length,
      imageUrl: MediaUrlResolver.resolve(dto.imageUrl),
      devices: devices,
      latitude: dto.latitude,
      longitude: dto.longitude,
      isOpen: dto.isOpen ?? true,
      services: dto.services
          .map((s) => s.shortLabel?.isNotEmpty == true ? s.shortLabel! : s.label)
          .where((s) => s.isNotEmpty)
          .toList(),
      opensAt: dto.opensAt,
      closesAt: dto.closesAt,
      distanceMeters: dto.distanceMeters,
      userHallRating: dto.userHallRating,
      bookingStop: dto.bookingStop,
      bookingsBlocked: dto.bookingsBlocked || dto.bookingStop != null,
    );
  }

  static List<LoungeComment> toStoredComments(LoungeCatalogDto dto) {
    return dto.comments.map((c) => c.toDomain()).toList();
  }

  static List<StoredCategoryRating> toStoredReviews(LoungeCatalogDto dto) {
    return dto.reviews
        .map(
          (r) => StoredCategoryRating(
            category: r.category,
            stars: r.stars,
            submittedAt: r.submittedAt,
          ),
        )
        .toList();
  }
}

