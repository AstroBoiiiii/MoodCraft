import '../../models/app_user.dart';
import '../../models/enums.dart';

/// Canned accounts for dev mode. [StubAuthService] maps "sign in as a role" to
/// one of these so role-based routing and all three shells can be exercised
/// without a backend. One student ("Adam") linked to one teacher and one parent.
class DevSeed {
  DevSeed._();

  static const String studentId = 'student-adam';
  static const String studentUid = 'dev-student';
  static const String teacherUid = 'dev-teacher';
  static const String parentUid = 'dev-parent';

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
}
