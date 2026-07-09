/// Small JSON (de)serialisation helpers shared by data models. Keeping models
/// free of any Firebase import — the repository layer adapts Firestore
/// Timestamps to these plain maps.
library;

/// Serialise a [DateTime] as a UTC ISO-8601 string.
String dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();

/// Parse a [DateTime] from an ISO-8601 string (or pass through a [DateTime]),
/// always returned in **local** time. Timestamps are stored as UTC (see
/// [dateTimeToJson]); `DateTime.parse` of a `…Z` string yields a UTC instant, so
/// without `toLocal()` the wall-clock day is off by the timezone offset and an
/// entry logged this morning can read as "Yesterday" (UTC+8). Falls back to the
/// epoch when null/unparseable (defensive).
DateTime dateTimeFromJson(Object? value) {
  if (value is DateTime) return value.toLocal();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// Cast a dynamic JSON value to a typed `List<String>` defensively.
List<String> stringListFromJson(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

/// Cast a dynamic JSON value to a typed `Map<String, int>` defensively,
/// skipping any entry whose value is not a number.
Map<String, int> intMapFromJson(Object? value) {
  if (value is! Map) return const {};
  final out = <String, int>{};
  value.forEach((k, v) {
    if (v is num) out[k.toString()] = v.toInt();
  });
  return out;
}
