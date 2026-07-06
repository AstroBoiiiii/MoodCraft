import '../utils/json_utils.dart';
import 'enums.dart';

/// `sessions/{sessionId}` — one completed activity run. Note there is no
/// "score" that can drop and no failure state; [correctCount]/[retries] are
/// neutral telemetry for the teacher, never shown to the child as a penalty.
class Session {
  const Session({
    required this.id,
    required this.studentId,
    required this.activityType,
    required this.timestamp,
    this.emotionsShown = const [],
    this.responses = const [],
    this.correctCount = 0,
    this.retries = 0,
    this.durationMs = 0,
    this.note,
    this.syncStatus = SyncStatus.pending,
  });

  final String id;
  final String studentId;
  final ActivityType activityType;
  final List<Emotion> emotionsShown;
  final List<String> responses;
  final int correctCount;
  final int retries;
  final int durationMs;

  /// Optional AI-written observation for the teacher (FR3 teaching rounds,
  /// e.g. "Mixed up angry with sad on attempt 1, needed the body clue").
  final String? note;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  Session copyWith({
    String? id,
    String? studentId,
    ActivityType? activityType,
    List<Emotion>? emotionsShown,
    List<String>? responses,
    int? correctCount,
    int? retries,
    int? durationMs,
    String? note,
    DateTime? timestamp,
    SyncStatus? syncStatus,
  }) {
    return Session(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      activityType: activityType ?? this.activityType,
      emotionsShown: emotionsShown ?? this.emotionsShown,
      responses: responses ?? this.responses,
      correctCount: correctCount ?? this.correctCount,
      retries: retries ?? this.retries,
      durationMs: durationMs ?? this.durationMs,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'activityType': activityType.name,
    'emotionsShown': emotionsShown.map((e) => e.name).toList(),
    'responses': responses,
    'correctCount': correctCount,
    'retries': retries,
    'durationMs': durationMs,
    if (note != null) 'note': note,
    'timestamp': dateTimeToJson(timestamp),
    'syncStatus': syncStatus.name,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: (json['id'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    activityType: enumFromName(
      ActivityType.values,
      json['activityType'],
      ActivityType.quiz,
    ),
    emotionsShown:
        (json['emotionsShown'] as List? ?? const [])
            .map((e) => enumFromName(Emotion.values, e, Emotion.neutral))
            .toList(),
    responses: stringListFromJson(json['responses']),
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    retries: (json['retries'] as num?)?.toInt() ?? 0,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    note: json['note'] as String?,
    timestamp: dateTimeFromJson(json['timestamp']),
    syncStatus: enumFromName(
      SyncStatus.values,
      json['syncStatus'],
      SyncStatus.pending,
    ),
  );
}
