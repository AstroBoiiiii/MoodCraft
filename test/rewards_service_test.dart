import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/constants/app_constants.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/core/models/student.dart';
import 'package:moodcraft/core/services/data/repositories.dart';
import 'package:moodcraft/core/services/rewards_service.dart';

/// Minimal in-memory [StudentRepository] for the reward rules. Only the two
/// methods the service touches (getStudent/upsert) do anything; [throwOnRead]
/// simulates an offline read so we can check the service degrades to a no-op.
class _FakeStudents implements StudentRepository {
  _FakeStudents(this._student);

  Student? _student;
  bool throwOnRead = false;

  @override
  Future<Student?> getStudent(String id) async {
    if (throwOnRead) throw Exception('offline');
    return _student;
  }

  @override
  Future<void> upsert(Student student) async => _student = student;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Student>> studentsFor(List<String> ids) async => [
    if (_student != null) _student!,
  ];

  @override
  Stream<Student?> watchStudent(String id) => Stream.value(_student);
}

void main() {
  const base = Student(id: 's1', name: 'Adam');

  test(
    'finishing a round always grants the same stars (participation)',
    () async {
      final repo = _FakeStudents(base);
      final service = RewardsService(repo);

      final out = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.mixmatch,
      );

      expect(out.starsEarned, kStarsPerRound);
      expect((await repo.getStudent('s1'))!.stars, kStarsPerRound);
    },
  );

  test('stars only ever go up across rounds (never lost)', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    await service.awardForSession(studentId: 's1', activity: ActivityType.quiz);
    await service.awardForSession(studentId: 's1', activity: ActivityType.quiz);

    final student = (await repo.getStudent('s1'))!;
    expect(student.stars, kStarsPerRound * 2);
    expect(student.level, rewardLevel(kStarsPerRound * 2));
  });

  test(
    'crossing a 10-star boundary reports a level-up with the new level',
    () async {
      // One star short of level 2; the next round tips them over.
      final repo = _FakeStudents(
        const Student(id: 's1', name: 'Adam', stars: kStarsPerLevel - 1),
      );
      final service = RewardsService(repo);

      final out = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.quiz,
      );
      expect(out.leveledUp, isTrue);
      expect(out.level, 2);
      expect((await repo.getStudent('s1'))!.level, 2);
    },
  );

  test(
    'a round that stays inside the current level is not a level-up',
    () async {
      final repo = _FakeStudents(base); // 0 stars → level 1
      final service = RewardsService(repo);

      final out = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.quiz,
      );
      expect(out.leveledUp, isFalse);
      expect(out.level, 1);
    },
  );

  test('a round that does not finish the activity earns no badge', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    // Finishing one round (no activityCompleted) fills the progress bar and
    // grants stars, but is not itself an achievement — no badge.
    final out = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.story,
    );
    expect(out.starsEarned, kStarsPerRound);
    expect(out.newBadges, isEmpty);
    expect((await repo.getStudent('s1'))!.badges, isEmpty);
  });

  test(
    'the activity badge is granted only when it is fully done, once',
    () async {
      final repo = _FakeStudents(base);
      final service = RewardsService(repo);

      // The finishing round (activityCompleted) earns the one activity badge; a
      // later completed round adds nothing new.
      final out = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.mixmatch,
        activityCompleted: true,
      );
      expect(out.newBadges, ['all_mixmatch']);

      final again = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.mixmatch,
        activityCompleted: true,
      );
      expect(again.newBadges, isEmpty);

      final student = (await repo.getStudent('s1'))!;
      expect(student.badges, ['all_mixmatch']);
    },
  );

  test(
    'a failed read degrades to a no-op outcome (never blocks the child)',
    () async {
      final repo = _FakeStudents(base)..throwOnRead = true;
      final service = RewardsService(repo);

      final out = await service.awardForSession(
        studentId: 's1',
        activity: ActivityType.mixmatch,
      );

      expect(out.isEmpty, isTrue);
      expect(out.starsEarned, 0);
      expect(out.newBadges, isEmpty);
    },
  );
}
