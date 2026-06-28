/// Repository interfaces. The rest of the app depends only on these; concrete
/// `Stub*` (in-memory) and `Firestore*` implementations sit behind them.
library;

import '../../models/app_user.dart';
import '../../models/journal_entry.dart';
import '../../models/message.dart';
import '../../models/session.dart';
import '../../models/student.dart';
import '../../models/visual_schedule.dart';

abstract interface class UserRepository {
  Future<AppUser?> getUser(String uid);
  Future<List<AppUser>> getUsersFor(List<String> uids);
  Future<void> upsert(AppUser user);
}

abstract interface class StudentRepository {
  Future<List<Student>> studentsFor(List<String> ids);
  Future<Student?> getStudent(String id);
  Stream<Student?> watchStudent(String id);
  Future<void> upsert(Student student);

  /// Removes a student record (teacher action). Linked teachers/parents should
  /// drop the id from their own `linkedStudentIds` separately.
  Future<void> delete(String id);
}

abstract interface class JournalRepository {
  /// Newest-first journal entries for a student.
  Stream<List<JournalEntry>> watchForStudent(String studentId);
  Future<void> add(JournalEntry entry);
  Future<void> delete(String id);
}

abstract interface class SessionRepository {
  Stream<List<Session>> watchForStudent(String studentId);
  Future<void> add(Session session);
}

abstract interface class MessageRepository {
  /// All messages involving [uid], newest-first — drives both the teacher
  /// inbox list and the parent thread.
  Stream<List<Message>> watchInbox(String uid);

  /// Oldest-first ordered messages for one conversation thread.
  Stream<List<Message>> watchThread(String conversationId);

  Future<void> send(Message message);

  /// Deletes a single message (only the sender may do this).
  Future<void> delete(String id);

  /// Marks all messages in [conversationId] addressed to [myUid] as read.
  Future<void> markThreadRead(String conversationId, String myUid);
}

abstract interface class VisualScheduleRepository {
  /// Live picture schedule for a student (FR13), or null if none set yet.
  Stream<VisualSchedule?> watchSchedule(String studentId);

  /// One-shot read of a student's schedule.
  Future<VisualSchedule?> getSchedule(String studentId);

  /// Create or replace a student's schedule (doc id = studentId).
  Future<void> upsert(VisualSchedule schedule);

  /// Atomically rebase one editor's changes onto the latest server schedule so
  /// a teacher and a parent editing the same child never clobber each other
  /// (FR13). [baseline] is the schedule the editor opened with, [draft] is what
  /// they want to save. Throws [ScheduleConflictException] if an added activity
  /// overlaps one saved meanwhile.
  Future<void> reconcile({
    required String studentId,
    required String createdBy,
    required List<ScheduleItem> baseline,
    required List<ScheduleItem> draft,
  });
}
