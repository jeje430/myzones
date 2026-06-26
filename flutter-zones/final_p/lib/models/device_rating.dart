import 'lounge_model.dart';

/// Input for rating a catalog device (package) — stars are optional until submit.
class DeviceRatingInput {
  const DeviceRatingInput({
    required this.device,
    this.stars = 0,
    this.comment = '',
  });

  final DevicePackage device;
  final int stars;
  final String comment;

  DeviceRatingInput copyWith({int? stars, String? comment}) {
    return DeviceRatingInput(
      device: device,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
    );
  }

  bool get isValid => stars >= 1 && stars <= 5;

  String get deviceId => device.id;
}

class DeviceRatingSubmission {
  const DeviceRatingSubmission({
    required this.loungeId,
    required this.ratings,
  });

  final String loungeId;
  final List<DeviceRatingInput> ratings;
}
