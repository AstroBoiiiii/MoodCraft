// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MoodCraft';

  @override
  String get chooseRole => 'Who is using MoodCraft?';

  @override
  String get roleStudent => 'I am a student';

  @override
  String get roleTeacher => 'I am a teacher';

  @override
  String get roleParent => 'I am a parent';

  @override
  String get signOut => 'Sign out';

  @override
  String get sensorySettings => 'Sensory settings';

  @override
  String get colourTheme => 'Colour theme';

  @override
  String get animation => 'Animation';

  @override
  String get animationFull => 'Full';

  @override
  String get animationReduced => 'Reduced';

  @override
  String get animationOff => 'Off';

  @override
  String get music => 'Background music';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String greeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navJournal => 'Journal';

  @override
  String get navRewards => 'Rewards';

  @override
  String get navCompanion => 'Companion';

  @override
  String get navAr => 'AR';

  @override
  String get navStories => 'Stories';

  @override
  String get navMatch => 'Match';

  @override
  String get navQuiz => 'Quiz';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navStudents => 'Students';

  @override
  String get navClassroom => 'Classroom';

  @override
  String get navMessages => 'Messages';

  @override
  String get navReports => 'Reports';

  @override
  String get navProgress => 'Progress';

  @override
  String get arMobileOnly => 'AR is available on the mobile app.';

  @override
  String get arPlaceholder => 'AR placeholder — a 3D character will act out a feeling here.';
}
