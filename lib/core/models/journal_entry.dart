import '../utils/json_utils.dart';
import 'enums.dart';

/// `journalEntries/{entryId}` — the child logs how they feel using an emotion
/// icon (no reading/writing required), optionally with a context icon.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.studentId,
    required this.emotionIcon,
    required this.timestamp,
    this.contextIcon,
    this.note,
    this.syncStatus = SyncStatus.pending,
  });

  final String id;
  final String studentId;
  final Emotion emotionIcon;

  /// Optional context icon key (e.g. "home", "class").
  final String? contextIcon;

  /// Optional free text (added by teacher/parent, not required of the child).
  final String? note;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  JournalEntry copyWith({
    String? id,
    String? studentId,
    Emotion? emotionIcon,
    String? contextIcon,
    String? note,
    DateTime? timestamp,
    SyncStatus? syncStatus,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      emotionIcon: emotionIcon ?? this.emotionIcon,
      contextIcon: contextIcon ?? this.contextIcon,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'emotionIcon': emotionIcon.name,
    'contextIcon': contextIcon,
    'note': note,
    'timestamp': dateTimeToJson(timestamp),
    'syncStatus': syncStatus.name,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: (json['id'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    emotionIcon: enumFromName(Emotion.values, json['emotionIcon'], Emotion.neutral),
    contextIcon: json['contextIcon'] as String?,
    note: json['note'] as String?,
    timestamp: dateTimeFromJson(json['timestamp']),
    syncStatus: enumFromName(SyncStatus.values, json['syncStatus'], SyncStatus.pending),
  );
}
