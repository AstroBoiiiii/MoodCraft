/// Small JSON (de)serialisation helpers shared by data models. Keeping models
/// free of any Firebase import — the repository layer adapts Firestore
/// Timestamps to these plain maps.
library;

/// Serialise a [DateTime] as a UTC ISO-8601 string.
String dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();

/// Parse a [DateTime] from an ISO-8601 string (or pass through a [DateTime]).
/// Falls back to the epoch when null/unparseable (defensive).
DateTime dateTimeFromJson(Object? value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// Cast a dynamic JSON value to a typed `List<String>` defensively.
List<String> stringListFromJson(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];
