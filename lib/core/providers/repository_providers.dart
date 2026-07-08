import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/classroom.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../models/message.dart';
import '../models/student.dart';
import '../models/visual_schedule.dart';
import '../services/data/firestore_repositories.dart';
import '../services/data/repositories.dart';
import 'auth_provider.dart';
import 'sensory_settings_provider.dart';

class ParentChildDetail {
  const ParentChildDetail({required this.student, required this.teachers});
  final Student student;
  final List<AppUser> teachers;
}

/// Summarises one teacher↔parent conversation for the teacher inbox list.
class ConversationSummary {
  const ConversationSummary({
    required this.conversationId,
    required this.studentId,
    required this.studentName,
    required this.parentUid,
    required this.parentName,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String conversationId;
  final String studentId;
  final String studentName;
  final String parentUid;
  final String parentName;
  final Message lastMessage;
  final int unreadCount;
}

/// Repository bindings — all Firestore-backed so every role shares one source
/// of truth and offline persistence/sync (FR14) comes for free. The in-memory
/// `Stub*` services exist only for auth in dev mode (see [kUseStubAuth]).

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirestoreUserRepository(FirebaseFirestore.instance),
);

/// The signed-in user's persisted profile. Invalidate after a profile save.
final userProfileProvider = FutureProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);
  return ref.read(userRepositoryProvider).getUser(user.uid);
});

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => FirestoreStudentRepository(FirebaseFirestore.instance),
);

/// Emotion journal (FR12). Firestore-backed so a child's entry syncs to their
/// teacher and parent, and persists offline via Firestore caching (FR14).
final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => FirestoreJournalRepository(FirebaseFirestore.instance),
);

/// Live newest-first journal entries for a student (FR12). Shared by the child's
/// journal tab and the teacher/parent child-detail screens.
final studentJournalProvider =
    StreamProvider.family<List<JournalEntry>, String>((ref, studentId) {
      return ref.watch(journalRepositoryProvider).watchForStudent(studentId);
    });

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => FirestoreSessionRepository(FirebaseFirestore.instance),
);

/// Messages use the real Firestore implementation so teacher (web) and parent
/// (mobile) see each other's messages in real time via Firestore snapshots.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirestoreMessageRepository(FirebaseFirestore.instance);
});

/// Visual schedules (FR13) use Firestore directly so a schedule set on the
/// teacher/parent device syncs live to the student's device.
final visualScheduleRepositoryProvider = Provider<VisualScheduleRepository>(
  (ref) => FirestoreVisualScheduleRepository(FirebaseFirestore.instance),
);

/// Live picture schedule for a given student (FR13).
final studentScheduleProvider = StreamProvider.family<VisualSchedule?, String>((
  ref,
  studentId,
) {
  return ref.watch(visualScheduleRepositoryProvider).watchSchedule(studentId);
});

/// The student currently in focus — for a student/parent that is the first
/// linked student. Convenience for shells and dashboards.
///
/// A live stream (not a one-shot read) so progress written mid-session — e.g.
/// unlocking the next Mix-and-Match level — refreshes the UI immediately,
/// without a sign-out/in.
final activeStudentProvider = StreamProvider<Student?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.linkedStudentIds.isEmpty) {
    return Stream.value(null);
  }
  return ref
      .watch(studentRepositoryProvider)
      .watchStudent(user.linkedStudentIds.first);
});

/// All students linked to the signed-in teacher (for classroom roster).
/// Kept for non-teacher callers (parent monitoring) that still resolve via
/// linkedStudentIds.
final classStudentsProvider = FutureProvider<List<Student>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  return ref.read(studentRepositoryProvider).studentsFor(user.linkedStudentIds);
});

/// Real-time stream of students whose `teacherIds` contains the current
/// teacher's uid. Queries Firestore directly so the classroom roster updates
/// immediately when a new student joins with a class code — without requiring
/// the teacher to sign out and back in.
final classStudentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.teacher) {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.students)
      .where('teacherIds', arrayContains: user.uid)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) {
              final data =
                  Map<String, dynamic>.from(d.data())
                    ..['id'] = d.id
                    ..updateAll((_, v) => v is Timestamp ? v.toDate() : v);
              return Student.fromJson(data);
            }).toList(),
      );
});

/// Bundles the active student + their linked teacher profiles for the parent
/// monitoring screen. Streams the student document so name/age changes made by
/// the teacher are reflected live without a restart.
final parentChildDetailProvider = StreamProvider<ParentChildDetail?>((
  ref,
) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.linkedStudentIds.isEmpty) {
    yield null;
    return;
  }
  final studentRepo = ref.read(studentRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  await for (final student in studentRepo.watchStudent(
    user.linkedStudentIds.first,
  )) {
    if (student == null) {
      yield null;
      continue;
    }
    final teachers = await userRepo.getUsersFor(student.teacherIds);
    yield ParentChildDetail(student: student, teachers: teachers);
  }
});

/// Live stream of the signed-in user's own account doc. Unlike
/// [currentUserProvider] (stable across a session), this re-emits on every
/// write to the record, so UI can react to the user's own doc changing
/// mid-session — used for the parent's Progress-tab "new achievement" dot,
/// which reads the per-child seen-badge marker the shell writes back.
final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

/// The reward badges the parent's active child has earned but the parent has not
/// yet seen (FR9-lite, in-app). Because badges are append-only and monotonic,
/// the unseen ones are simply the tail of `student.badges` past the count the
/// parent last acknowledged. Drives both the red count on the Progress tab and
/// the "your child earned a new badge" popup; acknowledging (closing the popup)
/// catches the seen count up so this goes empty. Never a fail state — it can
/// only ever mean "something new to celebrate".
final parentUnseenBadgesProvider = Provider<List<String>>((ref) {
  final child = ref.watch(activeStudentProvider).value;
  final me = ref.watch(currentUserDocProvider).value;
  if (child == null || me == null) return const [];
  final seen = (me.seenBadgeCounts[child.id] ?? 0).clamp(
    0,
    child.badges.length,
  );
  if (child.badges.length <= seen) return const [];
  return child.badges.sublist(seen);
});

/// The active child's current personal level (FR11 title ladder) if it is
/// higher than the level the parent last saw, or null when there is nothing
/// new. `rewardLevel` only ever goes up (it is derived from monotonic stars),
/// so "new" is simply "higher than last seen" — mirrors
/// [parentUnseenBadgesProvider] for the level-up half of the FR9-lite popup.
/// Levels start at 1 (0 stars), so an unset seen count defaults to 1, never
/// firing for a brand-new child who hasn't earned a single star yet.
final parentUnseenLevelProvider = Provider<int?>((ref) {
  final child = ref.watch(activeStudentProvider).value;
  final me = ref.watch(currentUserDocProvider).value;
  if (child == null || me == null) return null;
  final seen = me.seenLevelCounts[child.id] ?? 1;
  return child.level > seen ? child.level : null;
});

/// Emotion journal entries (FR12) the active child has logged that the parent
/// has not yet seen, newest first. [studentJournalProvider] streams newest
/// first, so the new ones are simply the leading slice past the count the
/// parent last acknowledged — mirrors [parentUnseenBadgesProvider] for the
/// journal half of the FR9-lite popup.
final parentUnseenJournalProvider = Provider<List<JournalEntry>>((ref) {
  final child = ref.watch(activeStudentProvider).value;
  final me = ref.watch(currentUserDocProvider).value;
  if (child == null || me == null) return const [];
  final entries = ref.watch(studentJournalProvider(child.id)).value ?? const [];
  final seen = (me.seenJournalCounts[child.id] ?? 0).clamp(0, entries.length);
  final unseenCount = entries.length - seen;
  if (unseenCount <= 0) return const [];
  return entries.sublist(0, unseenCount);
});

/// Hydrates [sensorySettingsProvider] when the signed-in student's profile
/// loads. Must be watched once at app startup (see MoodCraftApp).
///
/// [activeStudentProvider] is a live stream that re-emits on every write to the
/// student record (e.g. saving quiz progress). We only hydrate once per child,
/// tracked by id, so a mid-session change the child makes live (narration
/// toggle, theme, volume) is never clobbered by a routine profile write.
final sensoryHydrationProvider = Provider<void>((ref) {
  String? hydratedFor;
  ref.listen<AsyncValue<Student?>>(activeStudentProvider, (_, next) {
    next.whenData((student) {
      if (student == null) {
        hydratedFor = null;
        return;
      }
      if (student.id == hydratedFor) return; // already loaded this child
      hydratedFor = student.id;
      // Never auto-play on sign-in — user must explicitly enable music each session.
      ref
          .read(sensorySettingsProvider.notifier)
          .replace(student.sensorySettings.copyWith(musicEnabled: false));
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

// ── Messaging providers ──────────────────────────────────────────────────────

/// Ordered messages for one specific conversation thread.
final messageThreadProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  return ref.read(messageRepositoryProvider).watchThread(conversationId);
});

/// Teacher's inbox: all conversations grouped by conversationId, newest first.
final teacherConversationsProvider = StreamProvider<List<ConversationSummary>>((
  ref,
) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final messageRepo = ref.read(messageRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final studentRepo = ref.read(studentRepositoryProvider);

  await for (final messages in messageRepo.watchInbox(user.uid)) {
    // Group by conversationId, keep newest message per group.
    final latestPerConv = <String, Message>{};
    final unreadPerConv = <String, int>{};
    for (final m in messages) {
      final existing = latestPerConv[m.conversationId];
      if (existing == null || m.timestamp.isAfter(existing.timestamp)) {
        latestPerConv[m.conversationId] = m;
      }
      if (m.toUid == user.uid && !m.read) {
        unreadPerConv[m.conversationId] =
            (unreadPerConv[m.conversationId] ?? 0) + 1;
      }
    }

    final summaries = <ConversationSummary>[];
    for (final entry in latestPerConv.entries) {
      final last = entry.value;
      final parentUid = last.fromUid == user.uid ? last.toUid : last.fromUid;

      final student = await studentRepo.getStudent(last.studentId);
      final parent = await userRepo.getUser(parentUid);

      summaries.add(
        ConversationSummary(
          conversationId: entry.key,
          studentId: last.studentId,
          studentName: student?.name ?? last.studentId,
          parentUid: parentUid,
          parentName: parent?.name ?? 'Parent',
          lastMessage: last,
          unreadCount: unreadPerConv[entry.key] ?? 0,
        ),
      );
    }

    summaries.sort(
      (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp),
    );
    yield summaries;
  }
});

/// The class the signed-in student belongs to (resolved via their teacher), so
/// their profile can show the class name. Null if not in a class yet.
final studentClassProvider = FutureProvider<Classroom?>((ref) async {
  final student = await ref.watch(activeStudentProvider.future);
  if (student == null || student.teacherIds.isEmpty) return null;
  final snap =
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.classes)
          .where('teacherId', whereIn: student.teacherIds.take(10).toList())
          .limit(1)
          .get();
  if (snap.docs.isEmpty) return null;
  final doc = snap.docs.first;
  return Classroom.fromJson({...doc.data(), 'id': doc.id});
});

/// The signed-in student's own teacher + parent contacts, so their profile can
/// show who they're linked to (full name, username, phone).
final studentContactsProvider =
    FutureProvider<({List<AppUser> teachers, List<AppUser> parents})>((
      ref,
    ) async {
      final student = await ref.watch(activeStudentProvider.future);
      if (student == null) {
        return (teachers: <AppUser>[], parents: <AppUser>[]);
      }
      final userRepo = ref.read(userRepositoryProvider);
      final teachers = await userRepo.getUsersFor(student.teacherIds);
      final parents = await userRepo.getUsersFor(student.parentIds);
      return (teachers: teachers, parents: parents);
    });

/// One person the teacher can start (or continue) a conversation with — a
/// (student, parent) pair drawn from the teacher's roster. Lets the teacher
/// message first instead of waiting for the parent to write (FR10).
typedef TeacherMessageTarget =
    ({
      String studentId,
      String studentName,
      String parentUid,
      String parentName,
      String conversationId,
    });

/// All parents the signed-in teacher can message, across their linked students.
final teacherMessageTargetsProvider =
    FutureProvider<List<TeacherMessageTarget>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || user.role != UserRole.teacher) return [];
      final students = await ref.watch(classStudentsStreamProvider.future);
      final userRepo = ref.read(userRepositoryProvider);
      final rows = <TeacherMessageTarget>[];
      for (final s in students) {
        if (s.parentIds.isEmpty) continue;
        final parents = await userRepo.getUsersFor(s.parentIds);
        for (final p in parents) {
          rows.add((
            studentId: s.id,
            studentName: s.name,
            parentUid: p.uid,
            parentName: p.name,
            conversationId: Message.buildConversationId(s.id, user.uid, p.uid),
          ));
        }
      }
      rows.sort((a, b) => a.studentName.compareTo(b.studentName));
      return rows;
    });

/// The parent's single conversation with their child's teacher.
/// Returns (conversationId, teacherUid, teacherName, studentId) or null.
///
/// Streams the parent's own user doc so [linkedStudentIds] stays live —
/// handles any registration order without requiring a sign-out. Only the uid
/// is taken from [currentUserProvider] (stable, never changes mid-session).
final parentConversationProvider = StreamProvider<
  ({
    String conversationId,
    String teacherUid,
    String teacherName,
    String studentId,
  })?
>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(null);

  // Stream the parent user doc so linkedStudentIds updates live.
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(uid)
      .snapshots()
      .asyncMap((userSnap) async {
        final linkedIds =
            (userSnap.data()?['linkedStudentIds'] as List?)?.cast<String>() ??
            [];
        if (linkedIds.isEmpty) return null;

        final studentId = linkedIds.first;

        // One-shot reads hit local Firestore cache — fast on repeat opens.
        final studentSnap =
            await FirebaseFirestore.instance
                .collection(FirestoreCollections.students)
                .doc(studentId)
                .get();
        final sData = studentSnap.data();
        if (sData == null) return null;

        final teacherIds = (sData['teacherIds'] as List?)?.cast<String>() ?? [];
        if (teacherIds.isEmpty) return null;

        final teacherUid = teacherIds.first;

        String teacherName = 'Teacher';
        try {
          final tSnap =
              await FirebaseFirestore.instance
                  .collection(FirestoreCollections.users)
                  .doc(teacherUid)
                  .get();
          teacherName = (tSnap.data()?['name'] as String?) ?? teacherName;
        } catch (_) {}

        return (
          conversationId: Message.buildConversationId(
            studentId,
            uid,
            teacherUid,
          ),
          teacherUid: teacherUid,
          teacherName: teacherName,
          studentId: studentId,
        );
      });
});
