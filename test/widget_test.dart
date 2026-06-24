import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/app/app.dart';

void main() {
  testWidgets('boots to the dev role picker', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodCraftApp()));
    await tester.pumpAndSettle();

    // Signed out -> role picker is shown with all three roles.
    expect(find.text('Who is using MoodCraft?'), findsOneWidget);
    expect(find.text('I am a student'), findsOneWidget);
    expect(find.text('I am a teacher'), findsOneWidget);
    expect(find.text('I am a parent'), findsOneWidget);
  });

  testWidgets('signing in as a student lands on the student home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodCraftApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I am a student'));
    await tester.pumpAndSettle();

    // Student bottom-nav destination labels are present.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Journal'), findsWidgets);
    expect(find.text('Rewards'), findsWidgets);
  });
}
