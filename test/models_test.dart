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

  test('VisualSchedule round-trips', () {
    const schedule = VisualSchedule(
      id: 'v1',
      studentId: 's1',
      items: ['arrive', 'circle_time', 'snack'],
      createdBy: 't1',
    );
    expect(VisualSchedule.fromJson(schedule.toJson()).toJson(), schedule.toJson());
  });

  test('enumFromName falls back on unknown value', () {
    expect(enumFromName(Emotion.values, 'banana', Emotion.neutral), Emotion.neutral);
    expect(enumFromName(Emotion.values, 'happy', Emotion.neutral), Emotion.happy);
  });
}
