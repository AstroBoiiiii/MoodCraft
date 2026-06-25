import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../models/classroom.dart';
import '../../models/enums.dart';

/// Handles the relationship-building side of registration (FR1): creating a
/// teacher's class, resolving a class code, and linking parents and students by
/// email — including the "pending invite" case where the counterpart hasn't
/// registered yet, which is resolved automatically when they do.
///
/// Access between accounts is granted by the *parent/teacher* having the
/// student's id in their `linkedStudentIds` (see firestore.rules `isLinkedTo`),
/// so every link ultimately appends a student id there. A signed-in user may
/// append only their own uid to someone else's `linkedStudentIds`, which is
/// what makes either registration order work without a Cloud Function.
abstract interface class LinkingService {
  /// Publish `email -> {uid, role}` and `username -> {uid, email}` so
  /// counterparts and the sign-in flow can find this user.
  Future<void> recordDirectoryEntry({
    required String uid,
    required UserRole role,
    required String email,
    required String username,
  });

  /// Create a class for [teacherUid] with a freshly generated unique code.
  Future<Classroom> createClassForTeacher({
    required String teacherUid,
    required String className,
  });

  /// Link a student to the teacher who owns [classCode]. Returns false (without
  /// throwing) when the code matches no class, so registration can continue with
  /// a calm message instead of a failure.
  Future<bool> joinClassByCode({
    required String studentUid,
    required String classCode,
  });

  /// A student names their parent by email. Links now if the parent already
  /// exists, otherwise records a pending invite resolved when the parent joins.
  Future<void> linkStudentToParent({
    required String studentUid,
    required String studentEmail,
    required String parentEmail,
  });

  /// A parent names their child by email. Links now if the student already
  /// exists, otherwise records a pending invite resolved when the student joins.
  Future<void> linkParentToChild({
    required String parentUid,
    required String parentEmail,
    required String childEmail,
  });

  /// Resolve any pending invites that named this user's email, now that they
  /// have an account.
  Future<void> resolvePendingLinks({
    required String uid,
    required UserRole role,
    required String email,
  });
}

/// No-op implementation for the in-memory stub auth path (dev/offline). The stub
/// has no backend to link against.
class StubLinkingService implements LinkingService {
  const StubLinkingService();

  @override
  Future<void> recordDirectoryEntry({
    required String uid,
    required UserRole role,
    required String email,
    required String username,
  }) async {}

  @override
  Future<Classroom> createClassForTeacher({
    required String teacherUid,
    required String className,
  }) async => Classroom(
    id: 'stub-class',
    name: className,
    classCode: 'DEMO12',
    teacherId: teacherUid,
  );

  @override
  Future<bool> joinClassByCode({
    required String studentUid,
    required String classCode,
  }) async => true;

  @override
  Future<void> linkStudentToParent({
    required String studentUid,
    required String studentEmail,
    required String parentEmail,
  }) async {}

  @override
  Future<void> linkParentToChild({
    required String parentUid,
    required String parentEmail,
    required String childEmail,
  }) async {}

  @override
  Future<void> resolvePendingLinks({
    required String uid,
    required UserRole role,
    required String email,
  }) async {}
}

/// Firestore-backed implementation.
class FirebaseLinkingService implements LinkingService {
  FirebaseLinkingService({FirebaseFirestore? firestore, Random? random})
    : _db = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random();

  final FirebaseFirestore _db;
  final Random _random;

  // Unambiguous alphabet: no 0/O, 1/I/L to keep codes easy to read aloud.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection(FirestoreCollections.classes);
  CollectionReference<Map<String, dynamic>> get _pendingLinks =>
      _db.collection(FirestoreCollections.pendingLinks);
  CollectionReference<Map<String, dynamic>> get _directory =>
      _db.collection(FirestoreCollections.emailDirectory);

  String _normalize(String email) => email.trim().toLowerCase();

  CollectionReference<Map<String, dynamic>> get _usernameDir =>
      _db.collection(FirestoreCollections.usernameDirectory);

  @override
  Future<void> recordDirectoryEntry({
    required String uid,
    required UserRole role,
    required String email,
    required String username,
  }) async {
    await _directory.doc(_normalize(email)).set({'uid': uid, 'role': role.name});
    if (username.isNotEmpty) {
      await _usernameDir
          .doc(username.toLowerCase())
          .set({'uid': uid, 'email': _normalize(email)});
    }
  }

  @override
  Future<Classroom> createClassForTeacher({
    required String teacherUid,
    required String className,
  }) async {
    final code = await _generateUniqueCode();
    final doc = _classes.doc();
    final classroom = Classroom(
      id: doc.id,
      name: className.trim(),
      classCode: code,
      teacherId: teacherUid,
    );
    await doc.set(classroom.toJson()..remove('id'));
    return classroom;
  }

  @override
  Future<bool> joinClassByCode({
    required String studentUid,
    required String classCode,
  }) async {
    final classroom = await _findClassByCode(classCode);
    if (classroom == null) return false;
    await _linkTeacherToStudent(
      teacherUid: classroom.teacherId,
      studentUid: studentUid,
    );
    return true;
  }

  @override
  Future<void> linkStudentToParent({
    required String studentUid,
    required String studentEmail,
    required String parentEmail,
  }) async {
    final parent = await _lookup(parentEmail);
    if (parent != null && parent.role == UserRole.parent) {
      await _linkParentAndStudent(
        parentUid: parent.uid,
        studentUid: studentUid,
      );
    } else {
      await _recordPending(
        studentEmail: studentEmail,
        parentEmail: parentEmail,
        initiatorUid: studentUid,
        initiatorRole: UserRole.student,
      );
    }
  }

  @override
  Future<void> linkParentToChild({
    required String parentUid,
    required String parentEmail,
    required String childEmail,
  }) async {
    final child = await _lookup(childEmail);
    if (child != null && child.role == UserRole.student) {
      await _linkParentAndStudent(parentUid: parentUid, studentUid: child.uid);
    } else {
      await _recordPending(
        studentEmail: childEmail,
        parentEmail: parentEmail,
        initiatorUid: parentUid,
        initiatorRole: UserRole.parent,
      );
    }
  }

  @override
  Future<void> resolvePendingLinks({
    required String uid,
    required UserRole role,
    required String email,
  }) async {
    // A pending doc named this user as the not-yet-registered counterpart: a
    // parent role resolves invites that named their email; a student role
    // resolves invites that named theirs.
    final field = role == UserRole.parent ? 'parentEmail' : 'studentEmail';
    final snap =
        await _pendingLinks.where(field, isEqualTo: _normalize(email)).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final initiatorUid = (data['initiatorUid'] as String?) ?? '';
      final initiatorRole = enumFromName(
        UserRole.values,
        data['initiatorRole'],
        UserRole.student,
      );
      if (initiatorUid.isEmpty) {
        await doc.reference.delete();
        continue;
      }
      // Whichever of the two is the parent gets the student in linkedStudentIds.
      final parentUid = role == UserRole.parent ? uid : initiatorUid;
      final studentUid = role == UserRole.student ? uid : initiatorUid;
      if (initiatorRole != role) {
        await _linkParentAndStudent(
          parentUid: parentUid,
          studentUid: studentUid,
        );
      }
      await doc.reference.delete();
    }
  }

  // --- internals -----------------------------------------------------------

  Future<_DirectoryEntry?> _lookup(String email) async {
    final snap = await _directory.doc(_normalize(email)).get();
    final data = snap.data();
    if (data == null) return null;
    final uid = (data['uid'] as String?) ?? '';
    if (uid.isEmpty) return null;
    return _DirectoryEntry(
      uid: uid,
      role: enumFromName(UserRole.values, data['role'], UserRole.student),
    );
  }

  Future<Classroom?> _findClassByCode(String classCode) async {
    final snap =
        await _classes
            .where('classCode', isEqualTo: classCode.trim().toUpperCase())
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Classroom.fromJson({...doc.data(), 'id': doc.id});
  }

  Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomCode();
      final existing =
          await _classes.where('classCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    // Astronomically unlikely; fall back to a time-seeded code.
    return _randomCode();
  }

  String _randomCode() =>
      List.generate(
        AppConstants.classCodeLength,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();

  /// The student appends their own uid to the teacher's `linkedStudentIds`
  /// (permitted by the constrained-append rule) and records the teacher on
  /// their own profile.
  Future<void> _linkTeacherToStudent({
    required String teacherUid,
    required String studentUid,
  }) async {
    await _users.doc(teacherUid).set({
      'linkedStudentIds': FieldValue.arrayUnion([studentUid]),
    }, SetOptions(merge: true));
    await _students.doc(studentUid).set({
      'teacherIds': FieldValue.arrayUnion([teacherUid]),
    }, SetOptions(merge: true));
  }

  /// Grant the parent read access to the student by adding the student to the
  /// parent's `linkedStudentIds`, and denormalise onto the student profile
  /// (best-effort — the caller may lack write access to the profile).
  Future<void> _linkParentAndStudent({
    required String parentUid,
    required String studentUid,
  }) async {
    await _users.doc(parentUid).set({
      'linkedStudentIds': FieldValue.arrayUnion([studentUid]),
    }, SetOptions(merge: true));
    try {
      await _students.doc(studentUid).set({
        'parentIds': FieldValue.arrayUnion([parentUid]),
      }, SetOptions(merge: true));
    } catch (_) {
      // Access-driven by the parent's linkedStudentIds above; profile mirror is
      // a convenience only.
    }
  }

  Future<void> _recordPending({
    required String studentEmail,
    required String parentEmail,
    required String initiatorUid,
    required UserRole initiatorRole,
  }) {
    return _pendingLinks.add({
      'studentEmail': _normalize(studentEmail),
      'parentEmail': _normalize(parentEmail),
      'initiatorUid': initiatorUid,
      'initiatorRole': initiatorRole.name,
    });
  }
}

class _DirectoryEntry {
  const _DirectoryEntry({required this.uid, required this.role});
  final String uid;
  final UserRole role;
}
