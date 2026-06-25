import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/app/app.dart';

void main() {
  testWidgets('boots to the sign-in screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodCraftApp()));
    await tester.pumpAndSettle();

    // Signed out -> the calm email/password sign-in screen.
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });

  testWidgets('can open the create-account form with all roles', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoodCraftApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    // Registration offers all three roles (labels are "Student"/"Teacher"/
    // "Parent" per CLAUDE.md — never "I am a student" style copy).
    expect(find.text('Who is using MoodCraft?'), findsOneWidget);
    expect(find.text('Student'), findsWidgets);
    expect(find.text('Teacher'), findsWidgets);
    expect(find.text('Parent'), findsWidgets);
  });
}
