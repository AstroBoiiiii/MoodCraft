import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/classroom.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/data/repositories.dart';
import '../services/data/stub_repositories.dart';
import 'auth_provider.dart';
import 'sensory_settings_provider.dart';

class ParentChildDetail {
  const ParentChildDetail({required this.student, required this.teachers});
  final Student student;
  final List<AppUser> teachers;
}

/// Repository bindings. All point at in-memory `Stub*` implementations for now.
///
/// TODO(firebase): after `flutterfire configure`, return the `Firestore*`
/// implementations (passing `FirebaseFirestore.instance`) from
/// services/data/firestore_repositories.dart.

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => StubUserRepository(),
);

/// The signed-in user's persisted profile. Invalidate after a profile save.
final userProfileProvider = FutureProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);
  return ref.read(userRepositoryProvider).getUser(user.uid);
});

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => StubStudentRepository(),
);

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final repo = StubJournalRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final repo = StubSessionRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final repo = StubMessageRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// The student currently in focus — for a student/parent that is the first
/// linked student. Convenience for shells and dashboards.
final activeStudentProvider = FutureProvider<Student?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.linkedStudentIds.isEmpty) return null;
  return ref
      .watch(studentRepositoryProvider)
      .getStudent(user.linkedStudentIds.first);
});

/// All students linked to the signed-in teacher (for classroom roster).
final classStudentsProvider = FutureProvider<List<Student>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  return ref.read(studentRepositoryProvider).studentsFor(user.linkedStudentIds);
});

/// Bundles the active student + their linked teacher profiles for the parent
/// monitoring screen.
final parentChildDetailProvider = FutureProvider<ParentChildDetail?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.linkedStudentIds.isEmpty) return null;
  final studentRepo = ref.read(studentRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final student = await studentRepo.getStudent(user.linkedStudentIds.first);
  if (student == null) return null;
  final teachers = await userRepo.getUsersFor(student.teacherIds);
  return ParentChildDetail(student: student, teachers: teachers);
});

/// Hydrates [sensorySettingsProvider] when the signed-in student's profile
/// loads. Must be watched once at app startup (see MoodCraftApp).
final sensoryHydrationProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Student?>>(activeStudentProvider, (_, next) {
    next.whenData((student) {
      if (student != null) {
        ref.read(sensorySettingsProvider.notifier).replace(student.sensorySettings);
      }
    });
  });
});

/// The signed-in teacher's class, or null while loading / if none exists yet.
/// Backs the class-code display the teacher shares with students (FR1).
final teacherClassProvider = StreamProvider<Classroom?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.teacher) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.classes)
      .where('teacherId', isEqualTo: user.uid)
      .limit(1)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        final doc = snap.docs.first;
        return Classroom.fromJson({...doc.data(), 'id': doc.id});
      });
});
