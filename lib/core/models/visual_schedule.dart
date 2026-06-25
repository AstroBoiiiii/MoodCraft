/// Minutes since midnight parsed from a zero-padded 24h `"HH:mm"` string.
/// Blank/invalid returns a large sentinel so it sorts last and never counts as
/// the current activity.
int scheduleMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 24 * 60 + 1;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return 24 * 60 + 1;
  }
  return h * 60 + m;
}

/// One activity in a [VisualSchedule]'s daily routine: it runs from [time] to
/// [endTime] (zero-padded 24h `"HH:mm"`, so lexicographic order is
/// chronological), has a short free-text [label] the teacher/parent types
/// (e.g. "Speech therapy"), and an optional [iconKey] picture (resolved against
/// `kScheduleIconCatalog`). Activities in one schedule never overlap.
class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.endTime,
    required this.label,
    this.iconKey,
  });

  final String time;
  final String endTime;
  final String label;

  /// Optional picture key; null/empty means "no picture, label only".
  final String? iconKey;

  /// Start minutes since midnight (sentinel if blank/invalid).
  int get minutesOfDay => scheduleMinutes(time);

  /// End minutes since midnight (sentinel if blank/invalid).
  int get endMinutesOfDay => scheduleMinutes(endTime);

  /// Whether this activity's [start,end) interval overlaps [other]'s.
  bool overlaps(ScheduleItem other) =>
      minutesOfDay < other.endMinutesOfDay &&
      other.minutesOfDay < endMinutesOfDay;

  ScheduleItem copyWith({
    String? time,
    String? endTime,
    String? label,
    String? iconKey,
  }) => ScheduleItem(
    time: time ?? this.time,
    endTime: endTime ?? this.endTime,
    label: label ?? this.label,
    iconKey: iconKey ?? this.iconKey,
  );

  Map<String, dynamic> toJson() => {
    'time': time,
    'endTime': endTime,
    'label': label,
    'iconKey': iconKey,
  };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    time: (json['time'] as String?) ?? '',
    endTime: (json['endTime'] as String?) ?? '',
    label: (json['label'] as String?) ?? '',
    iconKey: json['iconKey'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is ScheduleItem &&
      other.time == time &&
      other.endTime == endTime &&
      other.label == label &&
      other.iconKey == iconKey;

  @override
  int get hashCode => Object.hash(time, endTime, label, iconKey);
}

/// `visualSchedules/{studentId}` — a picture-based daily schedule to reduce
/// transition anxiety, configured by the teacher or parent per student (FR13).
/// [items] are ordered steps the child can see top-to-bottom. The document id
/// is the studentId: one "what's next" schedule per child.
class VisualSchedule {
  const VisualSchedule({
    required this.id,
    required this.studentId,
    required this.createdBy,
    this.items = const [],
  });

  final String id;
  final String studentId;
  final List<ScheduleItem> items;

  /// uid of the teacher or parent who last saved it.
  final String createdBy;

  /// Items ordered by time of day (untimed/invalid sort last).
  List<ScheduleItem> get sortedItems {
    final list = List<ScheduleItem>.from(items);
    list.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return list;
  }

  VisualSchedule copyWith({
    String? id,
    String? studentId,
    String? createdBy,
    List<ScheduleItem>? items,
  }) {
    return VisualSchedule(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'items': items.map((e) => e.toJson()).toList(),
    'createdBy': createdBy,
  };

  factory VisualSchedule.fromJson(Map<String, dynamic> json) => VisualSchedule(
    id: (json['id'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    items:
        (json['items'] is List)
            ? (json['items'] as List)
                .whereType<Map>()
                .map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
    createdBy: (json['createdBy'] as String?) ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is VisualSchedule &&
      other.id == id &&
      other.studentId == studentId &&
      other.createdBy == createdBy &&
      _listEquals(other.items, items);

  @override
  int get hashCode =>
      Object.hash(id, studentId, createdBy, Object.hashAll(items));
}

bool _listEquals(List<ScheduleItem> a, List<ScheduleItem> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
