import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/models/models.dart';
import 'package:moodcraft/core/services/auth/stub_auth_service.dart';

void main() {
  test(
    'signInAsRole emits a user with the chosen role, signOut clears it',
    () async {
      final service = StubAuthService();
      addTearDown(service.dispose);

      final emissions = <AppUser?>[];
      final sub = service.authStateChanges().listen(emissions.add);
      await Future<void>.delayed(Duration.zero); // let initial null emit

      await service.signInAsRole(UserRole.teacher);
      await Future<void>.delayed(Duration.zero);
      expect(service.currentUser?.role, UserRole.teacher);
      expect(emissions.last?.role, UserRole.teacher);

      await service.signInAsRole(UserRole.student);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last?.role, UserRole.student);
      expect(emissions.last?.linkedStudentIds, isNotEmpty);

      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(service.currentUser, isNull);
      expect(emissions.last, isNull);

      await sub.cancel();
    },
  );
}
