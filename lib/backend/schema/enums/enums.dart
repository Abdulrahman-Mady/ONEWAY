import 'package:collection/collection.dart';

/// Enum ReportStatus
enum ReportStatus {
  submitted,
  underReview,
  verified,
  resolved,
  rejected,
}

/// Enum PlaceVerificationStatus
enum PlaceVerificationStatus {
  needsUpdate,
  incomplete,
  underReview,
  verified,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (ReportStatus):
      return ReportStatus.values.deserialize(value) as T?;
    case (PlaceVerificationStatus):
      return PlaceVerificationStatus.values.deserialize(value) as T?;
    default:
      return null;
  }
}
