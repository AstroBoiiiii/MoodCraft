import '../utils/json_utils.dart';

/// `messages/{messageId}` — a note between a teacher and a parent about a
/// specific student.
class Message {
  const Message({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.studentId,
    required this.conversationId,
    required this.participants,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final String studentId;

  /// Deterministic ID for the teacher-parent-student thread.
  /// Format: `"${studentId}__${sortedUid1}__${sortedUid2}"`
  final String conversationId;

  /// [fromUid, toUid] — enables `array-contains` queries on Firestore.
  final List<String> participants;

  final String text;
  final DateTime timestamp;
  final bool read;

  /// Builds the canonical conversation identifier from either side.
  static String buildConversationId(
    String studentId,
    String uid1,
    String uid2,
  ) {
    final sorted = [uid1, uid2]..sort();
    return '${studentId}__${sorted[0]}__${sorted[1]}';
  }

  Message copyWith({
    String? id,
    String? fromUid,
    String? toUid,
    String? studentId,
    String? conversationId,
    List<String>? participants,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return Message(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      studentId: studentId ?? this.studentId,
      conversationId: conversationId ?? this.conversationId,
      participants: participants ?? this.participants,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUid': fromUid,
    'toUid': toUid,
    'studentId': studentId,
    'conversationId': conversationId,
    'participants': participants,
    'text': text,
    'timestamp': dateTimeToJson(timestamp),
    'read': read,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: (json['id'] as String?) ?? '',
    fromUid: (json['fromUid'] as String?) ?? '',
    toUid: (json['toUid'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    conversationId: (json['conversationId'] as String?) ?? '',
    participants:
        (json['participants'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    text: (json['text'] as String?) ?? '',
    timestamp: dateTimeFromJson(json['timestamp']),
    read: (json['read'] as bool?) ?? false,
  );
}
