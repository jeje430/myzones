import 'package:flutter/material.dart';

import '../../models/lounge_model.dart';

/// Device-type filter helpers for lounge search (multi-select AND).
class LoungeDeviceFilter {
  LoungeDeviceFilter([Set<DeviceType>? active]) : _active = active ?? {};

  final Set<DeviceType> _active;

  Set<DeviceType> get activeTypes => Set.unmodifiable(_active);

  bool get hasActiveFilters => _active.isNotEmpty;

  bool isActive(DeviceType type) => _active.contains(type);

  LoungeDeviceFilter toggle(DeviceType type) {
    final next = Set<DeviceType>.from(_active);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    return LoungeDeviceFilter(next);
  }

  LoungeDeviceFilter clear() => LoungeDeviceFilter();

  bool matches(LoungeModel lounge) {
    if (_active.isEmpty) return true;
    return lounge.matchesAllDeviceTypes(_active);
  }

  List<LoungeModel> apply(Iterable<LoungeModel> lounges) =>
      lounges.where(matches).toList();
}

/// All device types offered with stock across the catalog — mirrors API aggregation.
List<DeviceType> aggregateAvailableDeviceTypes(Iterable<LoungeModel> lounges) {
  final types = <DeviceType>{};
  for (final lounge in lounges) {
    for (final device in lounge.availableDevices) {
      types.add(device.type);
    }
  }
  final ordered = DeviceType.values.where(types.contains).toList();
  return ordered;
}

/// Device metadata for filter UI — prefers catalog names when available.
DeviceFilterMeta deviceFilterMeta(
  DeviceType type,
  Iterable<LoungeModel> lounges,
) {
  for (final lounge in lounges) {
    final pkg = lounge.deviceByType(type);
    if (pkg != null && pkg.isAvailable) {
      return DeviceFilterMeta(
        type: type,
        label: pkg.nameAr,
        icon: pkg.icon,
        loungeCount: lounges.where((l) => l.offersDeviceType(type)).length,
      );
    }
  }
  return DeviceFilterMeta(
    type: type,
    label: type.filterLabel,
    icon: type.filterIcon,
    loungeCount: lounges.where((l) => l.offersDeviceType(type)).length,
  );
}

class DeviceFilterMeta {
  const DeviceFilterMeta({
    required this.type,
    required this.label,
    required this.icon,
    required this.loungeCount,
  });

  final DeviceType type;
  final String label;
  final IconData icon;
  final int loungeCount;
}

/// Search + device filter pipeline.
List<LoungeModel> filterLounges({
  required List<LoungeModel> lounges,
  required String nameQuery,
  required LoungeDeviceFilter deviceFilter,
}) {
  var result = deviceFilter.apply(lounges);

  if (nameQuery.isEmpty) return result;

  final q = nameQuery.toLowerCase();
  return result
      .where((l) => l.name.toLowerCase().contains(q))
      .toList();
}
