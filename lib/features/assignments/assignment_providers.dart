import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/assignment.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/services/data/firestore_repositories.dart';
import '../../core/services/data/repositories.dart';

/// Homework tasks (assignments) live behind the same Firestore-backed repository
/// pattern as every other feature, so teacher (web) and parent/child (mobile)
/// see the same tasks in real time and offline persistence (FR14) comes free.
final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => FirestoreAssignmentRepository(FirebaseFirestore.instance),
);

/// The signed-in teacher's created tasks, newest-first.
final teacherAssignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.teacher) {
    return Stream.value(const []);
  }
  return ref.watch(assignmentRepositoryProvider).watchForTeacher(user.uid);
});

/// Tasks handed to one student, newest-first. Shared by the parent's task view
/// and the child's "to do" card.
final studentAssignmentsProvider =
    StreamProvider.family<List<Assignment>, String>((ref, studentId) {
      return ref.watch(assignmentRepositoryProvider).watchForStudent(studentId);
    });

/// A student's activity sessions, newest-first — the raw material for deciding,
/// live, which task activities a child has already finished.
final studentSessionsProvider = StreamProvider.family<List<Session>, String>((
  ref,
  studentId,
) {
  return ref.watch(sessionRepositoryProvider).watchForStudent(studentId);
});

/// True when [student] has finished [activity] as part of [assignment] — i.e.
/// there is a completed session of that type dated on or after the task was
/// handed out. Participation-based, exactly like the rest of the app: doing the
/// activity is the whole bar, never getting answers "right".
bool activityDoneFor({
  required Assignment assignment,
  required ActivityType activity,
  required List<Session> sessions,
}) {
  for (final s in sessions) {
    if (s.activityType == activity &&
        !s.timestamp.isBefore(assignment.createdAt)) {
      return true;
    }
  }
  return false;
}

/// How many of [assignment]'s activities [sessions] show as done (0..activities).
int completedCountFor(Assignment assignment, List<Session> sessions) {
  var done = 0;
  for (final a in assignment.activities) {
    if (activityDoneFor(
      assignment: assignment,
      activity: a,
      sessions: sessions,
    )) {
      done++;
    }
  }
  return done;
}

/// True once every activity in [assignment] is done for the child behind
/// [sessions].
bool isAssignmentComplete(Assignment assignment, List<Session> sessions) =>
    assignment.activities.isNotEmpty &&
    completedCountFor(assignment, sessions) == assignment.activities.length;
