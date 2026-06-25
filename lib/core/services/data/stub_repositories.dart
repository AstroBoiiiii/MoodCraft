import 'dart:async';

import '../../models/app_user.dart';
import '../../models/journal_entry.dart';
import '../../models/message.dart';
import '../../models/session.dart';
import '../../models/student.dart';
import 'dev_seed.dart';
import 'repositories.dart';

// In-memory repositories used in dev/stub mode. They persist for the life of
// the app session so adding a journal entry shows up immediately.

class StubUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {
    DevSeed.studentUid: DevSeed.studentUser,
    DevSeed.teacherUid: DevSeed.teacherUser,
    DevSeed.parentUid: DevSeed.parentUser,
  };

  @override
  Future<AppUser?> getUser(String uid) async => _users[uid];

  @override
  Future<List<AppUser>> getUsersFor(List<String> uids) async =>
      uids.map((id) => _users[id]).whereType<AppUser>().toList();

  @override
  Future<void> upsert(AppUser user) async => _users[user.uid] = user;
}

class StubStudentRepository implements StudentRepository {
  final Map<String, Student> _students = {DevSeed.student.id: DevSeed.student};

  @override
  Future<List<Student>> studentsFor(List<String> ids) async =>
      ids.map((id) => _students[id]).whereType<Student>().toList();

  @override
  Future<Student?> getStudent(String id) async => _students[id];

  @override
  Future<void> upsert(Student student) async => _students[student.id] = student;
}

class StubJournalRepository implements JournalRepository {
  StubJournalRepository() {
    _entries.addAll(DevSeed.journalEntries());
  }

  final List<JournalEntry> _entries = [];
  final StreamController<List<JournalEntry>> _controller =
      StreamController<List<JournalEntry>>.broadcast();

  List<JournalEntry> _forStudent(String studentId) {
    final list =
        _entries.where((e) => e.studentId == studentId).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<JournalEntry>> watchForStudent(String studentId) async* {
    yield _forStudent(studentId);
    yield* _controller.stream.map((_) => _forStudent(studentId));
  }

  @override
  Future<void> add(JournalEntry entry) async {
    _entries.add(entry);
    _controller.add(_entries);
  }

  void dispose() => _controller.close();
}

class StubSessionRepository implements SessionRepository {
  final List<Session> _sessions = [];
  final StreamController<List<Session>> _controller =
      StreamController<List<Session>>.broadcast();

  List<Session> _forStudent(String studentId) => List.unmodifiable(
    _sessions.where((s) => s.studentId == studentId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
  );

  @override
  Stream<List<Session>> watchForStudent(String studentId) async* {
    yield _forStudent(studentId);
    yield* _controller.stream.map((_) => _forStudent(studentId));
  }

  @override
  Future<void> add(Session session) async {
    _sessions.add(session);
    _controller.add(_sessions);
  }

  void dispose() => _controller.close();
}

class StubMessageRepository implements MessageRepository {
  final List<Message> _messages = [];
  final StreamController<List<Message>> _controller =
      StreamController<List<Message>>.broadcast();

  List<Message> _forStudent(String studentId) => List.unmodifiable(
    _messages.where((m) => m.studentId == studentId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
  );

  @override
  Stream<List<Message>> watchThread(String studentId) async* {
    yield _forStudent(studentId);
    yield* _controller.stream.map((_) => _forStudent(studentId));
  }

  @override
  Future<void> send(Message message) async {
    _messages.add(message);
    _controller.add(_messages);
  }

  void dispose() => _controller.close();
}
