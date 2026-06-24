import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student.dart';
import '../services/data/repositories.dart';
import '../services/data/stub_repositories.dart';
import 'auth_provider.dart';

/// Repository bindings. All point at in-memory `Stub*` implementations for now.
///
/// TODO(firebase): after `flutterfire configure`, return the `Firestore*`
/// implementations (passing `FirebaseFirestore.instance`) from
/// services/data/firestore_repositories.dart.

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
  return ref.watch(studentRepositoryProvider).getStudent(
    user.linkedStudentIds.first,
  );
});
