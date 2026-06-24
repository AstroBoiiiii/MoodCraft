import '../utils/json_utils.dart';

/// `visualSchedules/{scheduleId}` — a picture-based daily schedule to reduce
/// transition anxiety, configured by the teacher per student. [items] are
/// ordered icon/step keys.
class VisualSchedule {
  const VisualSchedule({
    required this.id,
    required this.studentId,
    required this.createdBy,
    this.items = const [],
  });

  final String id;
  final String studentId;
  final List<String> items;

  /// uid of the teacher who created it.
  final String createdBy;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'items': items,
    'createdBy': createdBy,
  };

  factory VisualSchedule.fromJson(Map<String, dynamic> json) => VisualSchedule(
    id: (json['id'] as String?) ?? '',
    studentId: (json['studentId'] as String?) ?? '',
    items: stringListFromJson(json['items']),
    createdBy: (json['createdBy'] as String?) ?? '',
  );
}
