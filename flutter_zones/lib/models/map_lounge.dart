import 'package:google_maps_flutter/google_maps_flutter.dart';

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
}

/// Sample lounges near Tripoli, Libya — used on the explore map.
const kSampleMapLounges = [
  MapLounge(
    id: 'game-zone-arena',
    name: 'Game Zone Arena',
    rating: 4.8,
    reviews: 128,
    position: LatLng(32.8924, 13.1848),
    category: LoungeCategory.ps5,
    isOpen: true,
    devices: 12,
    price: 25,
    locationLabel: 'سوق الجمعة',
  ),
  MapLounge(
    id: 'pro-gaming-lounge',
    name: 'Pro Gaming Lounge',
    rating: 4.6,
    reviews: 95,
    position: LatLng(32.8806, 13.1982),
    category: LoungeCategory.pc,
    isOpen: true,
    devices: 8,
    price: 20,
    locationLabel: 'قرقارش',
  ),
];
