import '../utils/json_utils.dart';
import 'enums.dart';

/// Who a homework task was handed to: the whole class as an announcement, or a
/// hand-picked set of students.
enum AssignmentAudience { announcement, personalized }

/// `assignments/{id}` — one homework task a teacher hands out: a named bundle of
/// in-app activities for either the whole class (an announcement) or a chosen
/// set of students (personalized).
///
/// Completion is deliberately **not** stored here. It is read live from the
/// child's [Session]s: a task activity counts as done once the child finishes
/// that activity (writes a session of that type) after [createdAt]. So only the
/// teacher ever writes this document; parents and the child only read it. That
/// keeps the child out of yet another writeable collection and reuses the
/// participation the app already records (FR8/FR11 tie-in).
class Assignment {
  const Assignment({
    required this.id,
    required this.teacherId,
    required this.audience,
    required this.title,
    required this.studentIds,
    required this.activities,
    required this.createdAt,
    this.classId,
    this.note = '',
    this.syncStatus = SyncStatus.pending,
  });

  final String id;
  final String teacherId;

  /// Set for an announcement (the class it went out to); null for a personalized
  /// task. Purely informational — [studentIds] is the authoritative target list.
  final String? classId;
  final AssignmentAudience audience;

  /// Short name the teacher gives the homework, e.g. "This week's practice".
  final String title;

  /// Optional free-text instructions shown to the parent and child.
  final String note;

  /// The students this task was handed to — a snapshot taken at creation time
  /// (an announcement snapshots the class roster then), so the target never
  /// shifts under the teacher after they hand it out.
  final List<String> studentIds;

  /// The in-app activities to do. Auto-completion matches a finished [Session]
  /// against each activity type.
  final List<ActivityType> activities;

  final DateTime createdAt;
  final SyncStatus syncStatus;

  Assignment copyWith({
    String? id,
    String? teacherId,
    String? classId,
    AssignmentAudience? audience,
    String? title,
    String? note,
    List<String>? studentIds,
    List<ActivityType>? activities,
    DateTime? createdAt,
    SyncStatus? syncStatus,
  }) {
    return Assignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      audience: audience ?? this.audience,
      title: title ?? this.title,
      note: note ?? this.note,
      studentIds: studentIds ?? this.studentIds,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherId': teacherId,
    if (classId != null) 'classId': classId,
    'audience': audience.name,
    'title': title,
    'note': note,
    'studentIds': studentIds,
    'activities': activities.map((a) => a.name).toList(),
    'createdAt': dateTimeToJson(createdAt),
    'syncStatus': syncStatus.name,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: (json['id'] as String?) ?? '',
    teacherId: (json['teacherId'] as String?) ?? '',
    classId: json['classId'] as String?,
    audience: enumFromName(
      AssignmentAudience.values,
      json['audience'],
      AssignmentAudience.personalized,
    ),
    title: (json['title'] as String?) ?? '',
    note: (json['note'] as String?) ?? '',
    studentIds: stringListFromJson(json['studentIds']),
    activities:
        (json['activities'] as List? ?? const [])
            .map((e) => enumFromName(ActivityType.values, e, ActivityType.quiz))
            .toList(),
    createdAt: dateTimeFromJson(json['createdAt']),
    syncStatus: enumFromName(
      SyncStatus.values,
      json['syncStatus'],
      SyncStatus.pending,
    ),
  );
}
