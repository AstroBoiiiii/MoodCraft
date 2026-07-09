import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/models/models.dart';

/// Each model must survive a toJson -> fromJson round-trip unchanged. We compare
/// the re-serialised maps so we don't need `==` on every model.
void main() {
  final when = DateTime.utc(2026, 6, 24, 10, 30);

  test('AppUser round-trips', () {
    const user = AppUser(
      uid: 'u1',
      role: UserRole.teacher,
      name: 'Ms Aida',
      email: 'aida@example.com',
      language: AppLanguage.ms,
      linkedStudentIds: ['s1', 's2'],
    );
    expect(AppUser.fromJson(user.toJson()).toJson(), user.toJson());
  });

  test('Assignment round-trips', () {
    final assignment = Assignment(
      id: 'a1',
      teacherId: 't1',
      classId: 'c1',
      audience: AssignmentAudience.announcement,
      title: "This week's practice",
      note: 'Try the story before bed',
      studentIds: ['s1', 's2'],
      activities: [ActivityType.story, ActivityType.quiz],
      createdAt: when,
    );
    expect(
      Assignment.fromJson(assignment.toJson()).toJson(),
      assignment.toJson(),
    );
  });

  test('SensorySettings round-trips and equals', () {
    const settings = SensorySettings(
      musicEnabled: true,
      masterVolume: 0.3,
      colorTheme: AppColorTheme.softGreen,
    );
    expect(SensorySettings.fromJson(settings.toJson()), settings);
  });

  test('SensorySettings.fromJson(null) falls back to defaults', () {
    expect(SensorySettings.fromJson(null), SensorySettings.defaults);
  });

  test('Student round-trips (with nested sensory settings)', () {
    const student = Student(
      id: 's1',
      name: 'Adam',
      avatar: 'avatar_01',
      teacherIds: ['t1'],
      parentIds: ['p1'],
      sensorySettings: SensorySettings(masterVolume: 0.4),
      level: 3,
      stars: 12,
      badges: ['all_story'],
      companionLessonsDone: ['happy', 'sad'],
      mixMatchRounds: {
        'face': MixMatchRound(
          placed: 1,
          cards: [
            MixMatchRoundCard(
              answer: Emotion.happy,
              assetPath: 'a/happy_1.png',
            ),
            MixMatchRoundCard(answer: Emotion.sad, text: 'A sad little story'),
          ],
        ),
      },
      quizRounds: {
        '0': QuizRound(
          answered: 1,
          questions: [
            QuizRoundQuestion(
              modality: QuizModality.look,
              answer: Emotion.happy,
              options: [Emotion.happy, Emotion.sad, Emotion.angry],
              feedback: 'Yes! A big smile means happy.',
              assetPath: 'assets/images/quiz/look/set1/happy_1.png',
            ),
            QuizRoundQuestion(
              modality: QuizModality.story,
              answer: Emotion.scared,
              options: [Emotion.scared, Emotion.surprised, Emotion.happy],
              feedback: '',
              text: 'The lights went out.',
            ),
          ],
        ),
      },
      storyProgress: {
        'lost_ball': StoryProgress(
          levelsDone: 1,
          pausesDone: 1,
          positionMs: 3000,
        ),
        'new_puppy': StoryProgress(),
      },
    );
    expect(Student.fromJson(student.toJson()).toJson(), student.toJson());
  });

  test('StoryProgress map parses defensively', () {
    expect(storyProgressFromJson(null), isEmpty);
    expect(storyProgressFromJson('junk'), isEmpty);
    final parsed = storyProgressFromJson({
      'lost_ball': {'levelsDone': 2, 'pausesDone': 1, 'positionMs': 7000},
      'bad': 'not a map',
    });
    expect(parsed.keys, ['lost_ball']);
    expect(parsed['lost_ball']!.levelsDone, 2);
    expect(parsed['lost_ball']!.pausesDone, 1);
    expect(parsed['lost_ball']!.positionMs, 7000);
  });

  test('Session round-trips', () {
    final session = Session(
      id: 'sess1',
      studentId: 's1',
      activityType: ActivityType.companion,
      emotionsShown: const [Emotion.happy, Emotion.sad],
      responses: const ['happy'],
      correctCount: 1,
      retries: 2,
      durationMs: 45000,
      timestamp: when,
    );
    expect(Session.fromJson(session.toJson()).toJson(), session.toJson());
  });

  test('JournalEntry round-trips (optional fields null)', () {
    final entry = JournalEntry(
      id: 'j1',
      studentId: 's1',
      emotionIcon: Emotion.surprised,
      timestamp: when,
    );
    expect(JournalEntry.fromJson(entry.toJson()).toJson(), entry.toJson());
  });

  test('Message round-trips', () {
    final message = Message(
      id: 'm1',
      fromUid: 't1',
      toUid: 'p1',
      studentId: 's1',
      conversationId: Message.buildConversationId('s1', 't1', 'p1'),
      participants: ['t1', 'p1'],
      text: 'Adam did great today.',
      timestamp: when,
      read: true,
    );
    expect(Message.fromJson(message.toJson()).toJson(), message.toJson());
  });

  test('EmotionContent round-trips', () {
    const content = EmotionContent(
      id: 'c1',
      emotion: Emotion.angry,
      prompt: 'How does the boy feel?',
      options: ['angry', 'happy'],
      feedback: 'Yes — his face is scrunched up.',
    );
    expect(
      EmotionContent.fromJson(content.toJson()).toJson(),
      content.toJson(),
    );
  });

  test('VisualSchedule round-trips (time-ranged items, optional icon)', () {
    const schedule = VisualSchedule(
      id: 'v1',
      studentId: 's1',
      items: [
        ScheduleItem(
          time: '08:30',
          endTime: '09:00',
          label: 'Arrive',
          iconKey: 'breakfast',
        ),
        ScheduleItem(
          time: '10:00',
          endTime: '10:45',
          label: 'Speech therapy',
        ), // no icon
        ScheduleItem(
          time: '12:00',
          endTime: '12:30',
          label: 'Lunch',
          iconKey: 'lunch',
        ),
      ],
      createdBy: 't1',
    );
    final restored = VisualSchedule.fromJson(schedule.toJson());
    expect(restored.toJson(), schedule.toJson());
    expect(restored, schedule);
  });

  test(
    'VisualSchedule.sortedItems orders by start time; minutesOfDay parses',
    () {
      const schedule = VisualSchedule(
        id: 'v1',
        studentId: 's1',
        items: [
          ScheduleItem(time: '12:00', endTime: '12:30', label: 'Lunch'),
          ScheduleItem(time: '08:30', endTime: '09:00', label: 'Arrive'),
          ScheduleItem(time: '', endTime: '', label: 'Whenever'), // sorts last
        ],
        createdBy: 't1',
      );
      expect(schedule.sortedItems.map((e) => e.label).toList(), [
        'Arrive',
        'Lunch',
        'Whenever',
      ]);
      expect(
        const ScheduleItem(
          time: '08:30',
          endTime: '09:00',
          label: 'x',
        ).minutesOfDay,
        510,
      );
      expect(
        const ScheduleItem(time: '', endTime: '', label: 'x').minutesOfDay,
        greaterThan(24 * 60),
      );
    },
  );

  test(
    'ScheduleItem.overlaps detects clashes but allows touching intervals',
    () {
      const a = ScheduleItem(time: '09:00', endTime: '10:00', label: 'A');
      const overlapping = ScheduleItem(
        time: '09:30',
        endTime: '10:30',
        label: 'B',
      );
      const touching = ScheduleItem(
        time: '10:00',
        endTime: '11:00',
        label: 'C',
      );
      const separate = ScheduleItem(
        time: '11:00',
        endTime: '12:00',
        label: 'D',
      );
      expect(a.overlaps(overlapping), isTrue);
      expect(a.overlaps(touching), isFalse); // back-to-back is fine
      expect(a.overlaps(separate), isFalse);
    },
  );

  test('enumFromName falls back on unknown value', () {
    expect(
      enumFromName(Emotion.values, 'banana', Emotion.neutral),
      Emotion.neutral,
    );
    expect(
      enumFromName(Emotion.values, 'happy', Emotion.neutral),
      Emotion.happy,
    );
  });
}
