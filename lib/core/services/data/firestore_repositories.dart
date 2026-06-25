import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/journal_entry.dart';
import '../../models/message.dart';
import '../../models/session.dart';
import '../../models/student.dart';
import 'repositories.dart';

// Real Firestore implementations. Present and compiling, but NOT wired yet
// (providers use the Stub* versions until `flutterfire configure`). They show
// the intended pattern: store `model.toJson()` (minus id), and on read merge
// the doc id back in and convert any Firestore Timestamp to DateTime so the
// model `fromJson` factories work unchanged.

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
  Future<void> upsert(Student student) =>
      _col.doc(student.id).set(_encode(student.toJson()));
}

class FirestoreJournalRepository implements JournalRepository {
  FirestoreJournalRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.journalEntries);

  @override
  Stream<List<JournalEntry>> watchForStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => JournalEntry.fromJson(_decode(d))).toList(),
      );

  @override
  Future<void> add(JournalEntry entry) =>
      _col.doc(entry.id).set(_encode(entry.toJson()));
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.sessions);

  @override
  Stream<List<Session>> watchForStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Session.fromJson(_decode(d))).toList());

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
  Stream<List<Message>> watchThread(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map((d) => Message.fromJson(_decode(d))).toList());

  @override
  Future<void> send(Message message) =>
      _col.doc(message.id).set(_encode(message.toJson()));
}
