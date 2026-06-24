// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appName => 'MoodCraft';

  @override
  String get chooseRole => 'Siapa yang menggunakan MoodCraft?';

  @override
  String get roleStudent => 'Saya pelajar';

  @override
  String get roleTeacher => 'Saya guru';

  @override
  String get roleParent => 'Saya ibu bapa';

  @override
  String get signOut => 'Log keluar';

  @override
  String get sensorySettings => 'Tetapan deria';

  @override
  String get colourTheme => 'Tema warna';

  @override
  String get animation => 'Animasi';

  @override
  String get animationFull => 'Penuh';

  @override
  String get animationReduced => 'Kurang';

  @override
  String get animationOff => 'Tutup';

  @override
  String get music => 'Muzik latar';

  @override
  String get comingSoon => 'Akan datang';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get navHome => 'Utama';

  @override
  String get navJournal => 'Jurnal';

  @override
  String get navRewards => 'Ganjaran';

  @override
  String get navCompanion => 'Rakan';

  @override
  String get navAr => 'AR';

  @override
  String get navStories => 'Cerita';

  @override
  String get navMatch => 'Padan';

  @override
  String get navQuiz => 'Kuiz';

  @override
  String get navSchedule => 'Jadual';

  @override
  String get navDashboard => 'Papan Pemuka';

  @override
  String get navStudents => 'Pelajar';

  @override
  String get navClassroom => 'Kelas';

  @override
  String get navMessages => 'Mesej';

  @override
  String get navReports => 'Laporan';

  @override
  String get navProgress => 'Kemajuan';

  @override
  String get arMobileOnly => 'AR boleh didapati pada aplikasi mudah alih.';

  @override
  String get arPlaceholder => 'Ruang AR — watak 3D akan menunjukkan perasaan di sini.';
}
