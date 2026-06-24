import '../utils/json_utils.dart';

/// `messages/{messageId}` — a note between a teacher and a parent about a
/// specific student.
class Message {
  const Message({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.studentId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final String studentId;
  final String text;
  final DateTime timestamp;
  final bool read;

  Message copyWith({
    String? id,
    String? fromUid,
    String? toUid,
    String? studentId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return Message(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      studentId: studentId ?? this.studentId,
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
    'text': text,
    'timestamp': dateTimeToJson(timestamp),
    'read': read,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: (json['id'] as String?) ?? '',
    fromUid: (json['fromUid'] as String?) ?? '',
    toUid: (json['toUid'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    text: (json['text'] as String?) ?? '',
    timestamp: dateTimeFromJson(json['timestamp']),
    read: (json['read'] as bool?) ?? false,
  );
}
