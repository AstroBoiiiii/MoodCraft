import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/core/models/session.dart';
import 'package:moodcraft/core/models/student.dart';
import 'package:moodcraft/core/providers/repository_providers.dart';
import 'package:moodcraft/core/services/data/repositories.dart';
import 'package:moodcraft/core/services/rewards_service.dart';
import 'package:moodcraft/core/widgets/reward_celebration.dart';
import 'package:moodcraft/features/student_detail/student_progress_summary.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// A minimal localised host so the widgets under test get AppLocalizations plus
/// the global Material localizations (for formatMediumDate). Width is kept narrow
/// to surface any RenderFlex overflow the real phone layout would hit. Wrap the
/// result in a ProviderScope at the call site (with overrides when needed).
Widget _app(Widget child, {double width = 360}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

class _FakeSessions implements SessionRepository {
  _FakeSessions(this.sessions);
  final List<Session> sessions;

  @override
  Stream<List<Session>> watchForStudent(String studentId) =>
      Stream.value(sessions);

  @override
  Future<void> add(Session session) async {}
}

void main() {
  testWidgets('celebration reveals the stars and new badges without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          RewardCelebration(
            outcome: const RewardOutcome(
              starsEarned: 3,
              newBadges: ['act_quiz', 'feel_happy'],
            ),
            title: 'All done!',
            body: 'Great feeling spotting.',
            doneLabel: 'Done',
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You earned 3 stars'), findsOneWidget);
    expect(find.text('New badge!'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget); // act_quiz label
    expect(find.text('Happy'), findsOneWidget); // feel_happy label
    expect(tester.takeException(), isNull);
  });

  testWidgets('celebration with a null outcome shows no stars (offline-safe)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          RewardCelebration(
            outcome: null,
            title: 'All done!',
            body: 'body',
            doneLabel: 'Done',
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('stars'), findsNothing);
    expect(find.text('New badge!'), findsNothing);
    expect(find.text('All done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress summary shows stars, badge count, feelings and recent', (
    tester,
  ) async {
    const student = Student(
      id: 's1',
      name: 'Adam',
      stars: 9,
      badges: ['act_quiz', 'feel_happy', 'feel_sad'],
    );
    final sessions = [
      Session(
        id: 'a',
        studentId: 's1',
        activityType: ActivityType.quiz,
        timestamp: DateTime(2026, 6, 24),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(_FakeSessions(sessions)),
        ],
        child: _app(const StudentProgressSummary(student: student)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9'), findsOneWidget); // stars total
    expect(find.text('3/9'), findsOneWidget); // 3 of 9 badges
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget); // recent session label
    expect(tester.takeException(), isNull);
  });
}
