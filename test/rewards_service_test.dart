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

  test('finishing a round always grants the same stars (participation)', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    final out = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.mixmatch,
      emotionsShown: const [Emotion.happy],
    );

    expect(out.starsEarned, kStarsPerRound);
    expect((await repo.getStudent('s1'))!.stars, kStarsPerRound);
  });

  test('stars only ever go up across rounds (never lost)', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.quiz,
      emotionsShown: const [Emotion.sad],
    );
    await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.quiz,
      emotionsShown: const [Emotion.sad],
    );

    final student = (await repo.getStudent('s1'))!;
    expect(student.stars, kStarsPerRound * 2);
    expect(student.level, rewardLevel(kStarsPerRound * 2));
  });

  test('activity + feeling badges are granted, and only once', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    final first = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.story,
      emotionsShown: const [Emotion.happy, Emotion.sad],
    );
    expect(
      first.newBadges,
      containsAll(<String>['act_story', 'feel_happy', 'feel_sad']),
    );

    // Replaying the same activity/feelings earns no duplicate badges.
    final second = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.story,
      emotionsShown: const [Emotion.happy, Emotion.sad],
    );
    expect(second.newBadges, isEmpty);

    final student = (await repo.getStudent('s1'))!;
    // No duplicates in the stored list.
    expect(student.badges.toSet().length, student.badges.length);
    expect(student.badges, containsAll(<String>['act_story', 'feel_happy', 'feel_sad']));
  });

  test('neutral earns no feeling badge', () async {
    final repo = _FakeStudents(base);
    final service = RewardsService(repo);

    final out = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.companion,
      emotionsShown: const [Emotion.neutral],
    );

    expect(out.newBadges, ['act_companion']);
    expect((await repo.getStudent('s1'))!.badges, ['act_companion']);
  });

  test('a failed read degrades to a no-op outcome (never blocks the child)', () async {
    final repo = _FakeStudents(base)..throwOnRead = true;
    final service = RewardsService(repo);

    final out = await service.awardForSession(
      studentId: 's1',
      activity: ActivityType.mixmatch,
      emotionsShown: const [Emotion.happy],
    );

    expect(out.isEmpty, isTrue);
    expect(out.starsEarned, 0);
    expect(out.newBadges, isEmpty);
  });
}
