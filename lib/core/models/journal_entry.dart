import '../utils/json_utils.dart';
import 'enums.dart';

/// A single role-labelled comment on a [JournalEntry]. Teacher, parent and (
/// optionally) the child can each leave one — kept separate so the history shows
/// "Teacher: …" and "Parent: …" distinctly rather than one shared note.
class JournalComment {
  const JournalComment({
    required this.authorUid,
    required this.authorRole,
    required this.authorName,
    required this.text,
    required this.timestamp,
  });

  final String authorUid;
  final UserRole authorRole;
  final String authorName;
  final String text;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'authorUid': authorUid,
    'authorRole': authorRole.name,
    'authorName': authorName,
    'text': text,
    'timestamp': dateTimeToJson(timestamp),
  };

  factory JournalComment.fromJson(Map<String, dynamic> json) => JournalComment(
    authorUid: (json['authorUid'] as String?) ?? '',
    authorRole: enumFromName(
      UserRole.values,
      json['authorRole'],
      UserRole.teacher,
    ),
    authorName: (json['authorName'] as String?) ?? '',
    text: (json['text'] as String?) ?? '',
    timestamp: dateTimeFromJson(json['timestamp']),
  );
}

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
    this.comments = const [],
    this.syncStatus = SyncStatus.pending,
  });

  final String id;
  final String studentId;
  final Emotion emotionIcon;

  /// Optional context icon key (e.g. "home", "class").
  final String? contextIcon;

  /// Optional free-text note the child (or whoever logs the entry) can add to
  /// say a bit more in their own words. Never required — the journal stays
  /// icon-led and usable without any reading/writing.
  final String? note;

  /// Role-labelled comments (teacher/parent/child). Never required.
  final List<JournalComment> comments;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  JournalEntry copyWith({
    String? id,
    String? studentId,
    Emotion? emotionIcon,
    String? contextIcon,
    String? note,
    List<JournalComment>? comments,
    DateTime? timestamp,
    SyncStatus? syncStatus,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      emotionIcon: emotionIcon ?? this.emotionIcon,
      contextIcon: contextIcon ?? this.contextIcon,
      note: note ?? this.note,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// The current comment for [role], if any (at most one per role).
  JournalComment? commentBy(UserRole role) {
    for (final c in comments) {
      if (c.authorRole == role) return c;
    }
    return null;
  }

  /// Returns a copy with [comment] replacing any existing comment by the same
  /// role; an empty [comment.text] clears that role's comment instead.
  JournalEntry withComment(JournalComment comment) {
    final others =
        comments.where((c) => c.authorRole != comment.authorRole).toList();
    return copyWith(
      comments: comment.text.trim().isEmpty ? others : [...others, comment],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'emotionIcon': emotionIcon.name,
    'contextIcon': contextIcon,
    'note': note,
    'comments': comments.map((c) => c.toJson()).toList(),
    'timestamp': dateTimeToJson(timestamp),
    'syncStatus': syncStatus.name,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: (json['id'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    emotionIcon: enumFromName(
      Emotion.values,
      json['emotionIcon'],
      Emotion.neutral,
    ),
    contextIcon: json['contextIcon'] as String?,
    note: json['note'] as String?,
    comments:
        (json['comments'] is List)
            ? (json['comments'] as List)
                .whereType<Map>()
                .map(
                  (e) => JournalComment.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
            : const [],
    timestamp: dateTimeFromJson(json['timestamp']),
    syncStatus: enumFromName(
      SyncStatus.values,
      json['syncStatus'],
      SyncStatus.pending,
    ),
  );
}
