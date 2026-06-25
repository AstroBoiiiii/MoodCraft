import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/journal_entry.dart';
import '../../models/student.dart';

/// In-memory demo data used by the stub services so all three role shells have
/// something to show before Firebase is configured. One student ("Adam") linked
/// to one teacher and one parent.
class DevSeed {
  DevSeed._();

  static const String studentId = 'student-adam';
  static const String studentUid = 'dev-student';
  static const String teacherUid = 'dev-teacher';
  static const String parentUid = 'dev-parent';

  static const Student student = Student(
    id: studentId,
    name: 'Adam',
    avatar: 'avatar_01',
    teacherIds: [teacherUid],
    parentIds: [parentUid],
    level: 2,
    stars: 5,
  );

  // A student's own profile id is included in linkedStudentIds so the same
  // "is linked to this student" check covers the child themselves.
  static const AppUser studentUser = AppUser(
    uid: studentUid,
    role: UserRole.student,
    name: 'Adam',
    email: 'adam@demo.com',
    username: 'adam_student',
    phone: '0123456789',
    linkedStudentIds: [studentId],
  );

  static const AppUser teacherUser = AppUser(
    uid: teacherUid,
    role: UserRole.teacher,
    name: 'Ms Aida',
    email: 'teacher@demo.com',
    username: 'ms_aida',
    phone: '0111234567',
    linkedStudentIds: [studentId],
  );

  static const AppUser parentUser = AppUser(
    uid: parentUid,
    role: UserRole.parent,
    name: "Adam's Parent",
    email: 'parent@demo.com',
    username: 'adams_parent',
    phone: '0199876543',
    linkedStudentIds: [studentId],
  );

  static AppUser userForRole(UserRole role) => switch (role) {
    UserRole.student => studentUser,
    UserRole.teacher => teacherUser,
    UserRole.parent => parentUser,
  };

  static List<JournalEntry> journalEntries() => [
    JournalEntry(
      id: 'j-seed-1',
      studentId: studentId,
      emotionIcon: Emotion.happy,
      contextIcon: 'class',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      syncStatus: SyncStatus.synced,
    ),
    JournalEntry(
      id: 'j-seed-2',
      studentId: studentId,
      emotionIcon: Emotion.neutral,
      contextIcon: 'home',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      syncStatus: SyncStatus.synced,
    ),
  ];
}
