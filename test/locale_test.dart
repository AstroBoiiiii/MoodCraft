import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/app/app.dart';
import 'package:moodcraft/core/models/app_user.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/core/providers/auth_provider.dart';

// FR15: the app's UI locale must follow the signed-in user's saved
// [AppLanguage], not the device locale (app.dart wires appLocaleProvider's
// value into MaterialApp.router's `locale:`).
void main() {
  testWidgets('a signed-in user whose language is Malay gets the Malay locale', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      role: UserRole.teacher,
      name: 'Cikgu Aida',
      email: 'cikgu@test.com',
      language: AppLanguage.ms,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(user)],
        child: const MoodCraftApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ms'));
  });

  testWidgets(
    'a signed-in user whose language is English gets the English locale',
    (tester) async {
      const user = AppUser(
        uid: 'u2',
        role: UserRole.teacher,
        name: 'Teacher',
        email: 'teacher@test.com',
        language: AppLanguage.en,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(user)],
          child: const MoodCraftApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
    },
  );

  testWidgets('signed out follows the device locale (null override)', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MoodCraftApp()));
    await tester.pump();
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, isNull);
  });
}
