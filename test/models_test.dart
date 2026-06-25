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

  test('SensorySettings round-trips and equals', () {
    const settings = SensorySettings(
      musicEnabled: true,
      masterVolume: 0.3,
      colorTheme: AppColorTheme.softGreen,
      animationIntensity: AnimationIntensity.reduced,
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
      sensorySettings: SensorySettings(animationIntensity: AnimationIntensity.off),
      level: 3,
      stars: 12,
    );
    expect(Student.fromJson(student.toJson()).toJson(), student.toJson());
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

  test('ObservationReport round-trips', () {
    final report = ObservationReport(
      id: 'r1',
      studentId: 's1',
      generatedText: 'Calm and engaged this week.',
      basedOnSessionIds: const ['sess1', 'sess2'],
      rangeStart: when.subtract(const Duration(days: 7)),
      rangeEnd: when,
      createdBy: 't1',
      timestamp: when,
    );
    expect(
      ObservationReport.fromJson(report.toJson()).toJson(),
      report.toJson(),
    );
  });

  test('EmotionContent round-trips', () {
    const content = EmotionContent(
      id: 'c1',
      emotion: Emotion.angry,
      prompt: 'How does the boy feel?',
      options: ['angry', 'happy'],
      feedback: 'Yes — his face is scrunched up.',
    );
    expect(EmotionContent.fromJson(content.toJson()).toJson(), content.toJson());
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

  test('VisualSchedule.sortedItems orders by start time; minutesOfDay parses', () {
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
    expect(
      schedule.sortedItems.map((e) => e.label).toList(),
      ['Arrive', 'Lunch', 'Whenever'],
    );
    expect(
      const ScheduleItem(time: '08:30', endTime: '09:00', label: 'x')
          .minutesOfDay,
      510,
    );
    expect(
      const ScheduleItem(time: '', endTime: '', label: 'x').minutesOfDay,
      greaterThan(24 * 60),
    );
  });

  test('ScheduleItem.overlaps detects clashes but allows touching intervals', () {
    const a = ScheduleItem(time: '09:00', endTime: '10:00', label: 'A');
    const overlapping =
        ScheduleItem(time: '09:30', endTime: '10:30', label: 'B');
    const touching = ScheduleItem(time: '10:00', endTime: '11:00', label: 'C');
    const separate = ScheduleItem(time: '11:00', endTime: '12:00', label: 'D');
    expect(a.overlaps(overlapping), isTrue);
    expect(a.overlaps(touching), isFalse); // back-to-back is fine
    expect(a.overlaps(separate), isFalse);
  });

  test('enumFromName falls back on unknown value', () {
    expect(enumFromName(Emotion.values, 'banana', Emotion.neutral), Emotion.neutral);
    expect(enumFromName(Emotion.values, 'happy', Emotion.neutral), Emotion.happy);
  });
}
