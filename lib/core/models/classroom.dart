/// `classes/{classId}` — a teacher's class. Students join by entering the
/// [classCode] at registration, which links them to [teacherId] (FR1).
class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.classCode,
    required this.teacherId,
  });

  final String id;
  final String name;

  /// Short, human-readable code the teacher shares so students can join.
  final String classCode;
  final String teacherId;

  Classroom copyWith({
    String? id,
    String? name,
    String? classCode,
    String? teacherId,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      classCode: classCode ?? this.classCode,
      teacherId: teacherId ?? this.teacherId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'classCode': classCode,
    'teacherId': teacherId,
  };

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    classCode: (json['classCode'] as String?) ?? '',
    teacherId: (json['teacherId'] as String?) ?? '',
  );
}
