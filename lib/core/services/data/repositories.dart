/// Repository interfaces. The rest of the app depends only on these; concrete
/// `Stub*` (in-memory) and `Firestore*` implementations sit behind them.
library;

import '../../models/app_user.dart';
import '../../models/journal_entry.dart';
import '../../models/message.dart';
import '../../models/session.dart';
import '../../models/student.dart';

abstract interface class UserRepository {
  Future<AppUser?> getUser(String uid);
  Future<List<AppUser>> getUsersFor(List<String> uids);
  Future<void> upsert(AppUser user);
}

abstract interface class StudentRepository {
  Future<List<Student>> studentsFor(List<String> ids);
  Future<Student?> getStudent(String id);
  Future<void> upsert(Student student);
}

abstract interface class JournalRepository {
  /// Newest-first journal entries for a student.
  Stream<List<JournalEntry>> watchForStudent(String studentId);
  Future<void> add(JournalEntry entry);
}

abstract interface class SessionRepository {
  Stream<List<Session>> watchForStudent(String studentId);
  Future<void> add(Session session);
}

abstract interface class MessageRepository {
  /// Teacher <-> parent thread about one student.
  Stream<List<Message>> watchThread(String studentId);
  Future<void> send(Message message);
}
