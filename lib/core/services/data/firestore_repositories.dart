import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/assignment.dart';
import '../../models/journal_entry.dart';
import '../../models/message.dart';
import '../../models/session.dart';
import '../../models/student.dart';
import '../../models/visual_schedule.dart';
import 'repositories.dart';

// Firestore repository implementations — wired up via repository_providers.dart.
// The pattern: store `model.toJson()` (minus id); on read, merge the doc id back
// in and convert any Firestore Timestamp to DateTime so the model `fromJson`
// factories work unchanged. Where a list is filtered by one field and ordered by
// another, we sort client-side instead of `orderBy` to avoid requiring a
// deployed composite index (keeps the demo robust offline/first-run).

Map<String, dynamic> _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = Map<String, dynamic>.from(doc.data() ?? const {});
  data['id'] = doc.id;
  data.updateAll((key, value) => value is Timestamp ? value.toDate() : value);
  return data;
}

Map<String, dynamic> _encode(Map<String, dynamic> json) =>
    Map<String, dynamic>.from(json)..remove('id');

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.users);

  @override
  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['uid'] = doc.id;
    return AppUser.fromJson(data);
  }

  @override
  Future<List<AppUser>> getUsersFor(List<String> uids) async {
    final docs = await Future.wait(uids.map((id) => _col.doc(id).get()));
    return docs.where((d) => d.exists).map((d) {
      final data = Map<String, dynamic>.from(d.data()!);
      data['uid'] = d.id;
      return AppUser.fromJson(data);
    }).toList();
  }

  @override
  Stream<AppUser?> watchUser(String uid) =>
      _col.doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = doc.id;
        return AppUser.fromJson(data);
      });

  @override
  Future<void> upsert(AppUser user) {
    final json = Map<String, dynamic>.from(user.toJson())..remove('uid');
    return _col.doc(user.uid).set(json, SetOptions(merge: true));
  }
}

class FirestoreStudentRepository implements StudentRepository {
  FirestoreStudentRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.students);

  @override
  Future<List<Student>> studentsFor(List<String> ids) async {
    final docs = await Future.wait(ids.map((id) => _col.doc(id).get()));
    return docs
        .where((d) => d.exists)
        .map((d) => Student.fromJson(_decode(d)))
        .toList();
  }

  @override
  Future<Student?> getStudent(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Student.fromJson(_decode(doc)) : null;
  }

  @override
  Stream<Student?> watchStudent(String id) => _col
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Student.fromJson(_decode(doc)) : null);

  @override
  Future<void> upsert(Student student) =>
      _col.doc(student.id).set(_encode(student.toJson()));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}

class FirestoreJournalRepository implements JournalRepository {
  FirestoreJournalRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.journalEntries);

  @override
  Stream<List<JournalEntry>> watchForStudent(String studentId) =>
      _col.where('studentId', isEqualTo: studentId).snapshots().map((s) {
        final entries =
            s.docs.map((d) => JournalEntry.fromJson(_decode(d))).toList();
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest
        return entries;
      });

  @override
  Future<void> add(JournalEntry entry) =>
      _col.doc(entry.id).set(_encode(entry.toJson()));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.sessions);

  @override
  Stream<List<Session>> watchForStudent(String studentId) =>
      _col.where('studentId', isEqualTo: studentId).snapshots().map((s) {
        final sessions =
            s.docs.map((d) => Session.fromJson(_decode(d))).toList();
        sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest
        return sessions;
      });

  @override
  Future<void> add(Session session) =>
      _col.doc(session.id).set(_encode(session.toJson()));
}

class FirestoreMessageRepository implements MessageRepository {
  FirestoreMessageRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.messages);

  @override
  Stream<List<Message>> watchInbox(String uid) =>
      _col.where('participants', arrayContains: uid).snapshots().map((s) {
        final msgs = s.docs.map((d) => Message.fromJson(_decode(d))).toList();
        msgs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return msgs;
      });

  @override
  Stream<List<Message>> watchThread(String conversationId) => _col
      .where('conversationId', isEqualTo: conversationId)
      .snapshots()
      .map((s) {
        final msgs = s.docs.map((d) => Message.fromJson(_decode(d))).toList();
        msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return msgs;
      });

  @override
  Future<void> send(Message message) =>
      _col.doc(message.id).set(_encode(message.toJson()));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<void> markThreadRead(String conversationId, String myUid) async {
    final snap =
        await _col
            .where('conversationId', isEqualTo: conversationId)
            .where('toUid', isEqualTo: myUid)
            .where('read', isEqualTo: false)
            .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

class FirestoreAssignmentRepository implements AssignmentRepository {
  FirestoreAssignmentRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.assignments);

  @override
  Stream<List<Assignment>> watchForTeacher(String teacherId) =>
      _col.where('teacherId', isEqualTo: teacherId).snapshots().map((s) {
        final items =
            s.docs.map((d) => Assignment.fromJson(_decode(d))).toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest
        return items;
      });

  @override
  Stream<List<Assignment>> watchForStudent(String studentId) =>
      _col.where('studentIds', arrayContains: studentId).snapshots().map((s) {
        final items =
            s.docs.map((d) => Assignment.fromJson(_decode(d))).toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest
        return items;
      });

  @override
  Future<void> upsert(Assignment assignment) =>
      _col.doc(assignment.id).set(_encode(assignment.toJson()));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}

class FirestoreVisualScheduleRepository implements VisualScheduleRepository {
  FirestoreVisualScheduleRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.visualSchedules);

  @override
  Stream<VisualSchedule?> watchSchedule(String studentId) => _col
      .doc(studentId)
      .snapshots()
      .map((doc) => doc.exists ? VisualSchedule.fromJson(_decode(doc)) : null);

  @override
  Future<VisualSchedule?> getSchedule(String studentId) async {
    final doc = await _col.doc(studentId).get();
    return doc.exists ? VisualSchedule.fromJson(_decode(doc)) : null;
  }

  @override
  Future<void> upsert(VisualSchedule schedule) =>
      _col.doc(schedule.studentId).set(_encode(schedule.toJson()));

  @override
  Future<void> reconcile({
    required String studentId,
    required String createdBy,
    required List<ScheduleItem> baseline,
    required List<ScheduleItem> draft,
  }) {
    final ref = _col.doc(studentId);
    // Read-merge-write inside a transaction so concurrent teacher/parent saves
    // can't lose each other's activities. reconcileScheduleItems throws
    // ScheduleConflictException on an overlapping slot, aborting the commit.
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final server =
          snap.exists
              ? VisualSchedule.fromJson(_decode(snap)).items
              : const <ScheduleItem>[];
      final merged = reconcileScheduleItems(
        baseline: baseline,
        draft: draft,
        server: server,
      );
      tx.set(
        ref,
        _encode(
          VisualSchedule(
            id: studentId,
            studentId: studentId,
            createdBy: createdBy,
            items: merged,
          ).toJson(),
        ),
      );
    });
  }
}
