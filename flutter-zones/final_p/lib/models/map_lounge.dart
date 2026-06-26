import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'lounge_model.dart';

enum LoungeCategory { ps5, pc, mixed }

class MapLounge {
  const MapLounge({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.position,
    required this.category,
    required this.isOpen,
    required this.devices,
    required this.price,
    required this.locationLabel,
    this.imageUrl,
    this.services = const [],
    this.workHoursLabel,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final double rating;
  final int reviews;
  final LatLng position;
  final LoungeCategory category;
  final bool isOpen;
  final int devices;
  final int price;
  final String locationLabel;
  final String? imageUrl;
  final List<String> services;
  final String? workHoursLabel;
  final int? distanceMeters;

  bool matchesFilters({
    required bool ps5Filter,
    required bool pcFilter,
    required bool openNowFilter,
  }) {
    if (openNowFilter && !isOpen) return false;

    if (!ps5Filter && !pcFilter) return true;

    final matchesPs5 =
        ps5Filter && (category == LoungeCategory.ps5 || category == LoungeCategory.mixed);
    final matchesPc =
        pcFilter && (category == LoungeCategory.pc || category == LoungeCategory.mixed);

    return matchesPs5 || matchesPc;
  }

  static MapLounge? fromLoungeModel(LoungeModel lounge) {
    if (lounge.latitude == null || lounge.longitude == null) {
      return null;
    }

    return MapLounge(
      id: lounge.id,
      name: lounge.name,
      rating: lounge.loungeAverageRating,
      reviews: lounge.reviewCount,
      position: LatLng(lounge.latitude!, lounge.longitude!),
      category: _categoryFromDevices(lounge),
      isOpen: lounge.isOpen,
      devices: lounge.totalDevices,
      price: lounge.startingPrice,
      locationLabel: lounge.location,
      imageUrl: lounge.imageUrl,
      services: lounge.services,
      workHoursLabel:
          lounge.workHoursLabel.isNotEmpty ? lounge.workHoursLabel : null,
      distanceMeters: lounge.distanceMeters,
    );
  }

  static LoungeCategory _categoryFromDevices(LoungeModel lounge) {
    final hasPs5 = lounge.offersDeviceType(DeviceType.ps5);
    final hasPc = lounge.offersDeviceType(DeviceType.pc);
    if (hasPs5 && hasPc) return LoungeCategory.mixed;
    if (hasPc) return LoungeCategory.pc;
    return LoungeCategory.ps5;
  }
}

/// Builds map markers from API-backed lounge catalog, preserving distance order.
List<MapLounge> mapLoungesFromCatalog(List<LoungeModel> lounges) {
  return lounges
      .map(MapLounge.fromLoungeModel)
      .whereType<MapLounge>()
      .toList();
}

/// Client-side fallback when the nearby API is unreachable.
List<MapLounge> mapLoungesNearOrigin(
  List<LoungeModel> lounges,
  LatLng origin, {
  double radiusKm = 100,
}) {
  final withDistance = <MapLounge>[];

  for (final lounge in lounges) {
    final base = MapLounge.fromLoungeModel(lounge);
    if (base == null) continue;

    final meters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      base.position.latitude,
      base.position.longitude,
    );

    if (meters > radiusKm * 1000) continue;

    withDistance.add(
      MapLounge(
        id: base.id,
        name: base.name,
        rating: base.rating,
        reviews: base.reviews,
        position: base.position,
        category: base.category,
        isOpen: base.isOpen,
        devices: base.devices,
        price: base.price,
        locationLabel: base.locationLabel,
        imageUrl: base.imageUrl,
        services: base.services,
        workHoursLabel: base.workHoursLabel,
        distanceMeters: meters.round(),
      ),
    );
  }

  withDistance.sort(
    (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
  );

  return withDistance;
}
