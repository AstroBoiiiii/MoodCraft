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
  String get roleStudent => 'Pelajar';

  @override
  String get roleTeacher => 'Guru';

  @override
  String get roleParent => 'Ibu Bapa';

  @override
  String get signOut => 'Log keluar';

  @override
  String get sensorySettings => 'Tetapan deria';

  @override
  String get colourTheme => 'Tema warna';

  @override
  String get music => 'Muzik latar';

  @override
  String get musicTrack => 'Pilih lagu';

  @override
  String get musicTrack1 => 'Loceng Tenang';

  @override
  String get musicTrack2 => 'Bunyi Alam';

  @override
  String get musicTrack3 => 'Piano Lembut';

  @override
  String get musicVolume => 'Kelantangan';

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
  String get navProgress => 'Kemajuan';

  @override
  String get arMobileOnly => 'AR boleh didapati pada aplikasi mudah alih.';

  @override
  String get companionMobileOnly => 'Rakan boleh didapati pada aplikasi mudah alih.';

  @override
  String get arStarting => 'Sedang menyediakan kamera.';

  @override
  String get arCameraNeeded => 'MoodCraft memerlukan kamera untuk menunjukkan AR. Sila benarkan akses kamera.';

  @override
  String get arAllowCamera => 'Benarkan kamera';

  @override
  String get signIn => 'Log masuk';

  @override
  String get signInWelcome => 'Selamat kembali. Log masuk untuk teruskan.';

  @override
  String get registerTitle => 'Cipta akaun';

  @override
  String get nameLabel => 'Nama anda';

  @override
  String get emailLabel => 'E-mel';

  @override
  String get passwordLabel => 'Kata laluan';

  @override
  String get showPassword => 'Tunjuk kata laluan';

  @override
  String get hidePassword => 'Sembunyikan kata laluan';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get toRegister => 'Baru di sini? Cipta akaun';

  @override
  String get toLogin => 'Sudah ada akaun? Log masuk';

  @override
  String get errName => 'Sila masukkan nama anda';

  @override
  String get errEmail => 'Sila masukkan e-mel yang sah';

  @override
  String get errPassword => 'Kata laluan mesti sekurang-kurangnya 6 aksara';

  @override
  String get devSignIn => 'Log masuk pantas pembangun';

  @override
  String get phoneLabel => 'Nombor telefon';

  @override
  String get errPhone => 'Sila masukkan nombor telefon yang sah';

  @override
  String get classCodeLabel => 'Kod kelas';

  @override
  String get errClassCode => 'Sila masukkan kod kelas daripada guru anda';

  @override
  String get parentEmailLabel => 'E-mel ibu bapa';

  @override
  String get childEmailLabel => 'E-mel anak';

  @override
  String get classNameLabel => 'Nama kelas (pilihan)';

  @override
  String get classCodeNotFound => 'Kami tidak menemui kod kelas itu. Guru anda boleh menambah anda kemudian.';

  @override
  String get yourClassCode => 'Kod kelas';

  @override
  String get classLabel => 'Kelas';

  @override
  String get showCode => 'Tunjuk';

  @override
  String get hideCode => 'Sembunyikan';

  @override
  String get webMobileOnlyTitle => 'Aplikasi mudah alih';

  @override
  String get webMobileOnlyBody => 'Sila gunakan aplikasi mudah alih MoodCraft untuk meneruskan. Aplikasi web adalah untuk guru.';

  @override
  String get usernameLabel => 'Nama pengguna';

  @override
  String get errUsername => 'Huruf, nombor dan garis bawah sahaja';

  @override
  String get emailOrUsername => 'E-mel atau nama pengguna';

  @override
  String get editProfile => 'Sunting';

  @override
  String get confirmEdit => 'Sahkan';

  @override
  String get cancelEdit => 'Batal';

  @override
  String get contactsSection => 'Kenalan';

  @override
  String get teacherLabel => 'Guru';

  @override
  String get parentLabel => 'Ibu Bapa';

  @override
  String get profileTitle => 'Profil Saya';

  @override
  String get roleLabel => 'Peranan';

  @override
  String get saveProfile => 'Simpan perubahan';

  @override
  String get profileSaveError => 'Tidak dapat menyimpan. Sila cuba lagi.';

  @override
  String levelStars(int level, int stars) {
    return 'Tahap $level · $stars bintang';
  }

  @override
  String get noStudentsYet => 'Belum ada pelajar berdaftar';

  @override
  String get noChildLinked => 'Belum ada anak dikaitkan';

  @override
  String get colourThemeCalmBlue => 'Biru Tenang';

  @override
  String get colourThemeSoftGreen => 'Hijau Lembut';

  @override
  String get colourThemeWarmNeutral => 'Hangat';

  @override
  String get colourThemeLowStimGrey => 'Kelabu Rendah';

  @override
  String get studentProfile => 'Profil Pelajar';

  @override
  String get childProfile => 'Profil Anak';

  @override
  String get tabOverview => 'Ringkasan';

  @override
  String get tabSchedule => 'Jadual';

  @override
  String get progressReport => 'Laporan kemajuan';

  @override
  String get progressReportSoon => 'Laporan kemajuan untuk pelajar ini akan tersedia tidak lama lagi.';

  @override
  String get selectStudentHint => 'Pilih seorang pelajar untuk melihat butirannya';

  @override
  String get homeTodayHeading => 'Hari ini';

  @override
  String get msgNoConversations => 'Belum ada perbualan';

  @override
  String get msgNoLinkedTeacher => 'Belum ada guru dikaitkan';

  @override
  String get msgNewMessage => 'Mesej baharu';

  @override
  String get msgStartConversation => 'Mulakan perbualan';

  @override
  String get msgNoParentsToMessage => 'Belum ada ibu bapa dikaitkan dengan pelajar anda';

  @override
  String get msgTypeHere => 'Taip mesej…';

  @override
  String get msgSend => 'Hantar';

  @override
  String get msgYou => 'Anda';

  @override
  String get msgDeleteMessage => 'Padam mesej';

  @override
  String get msgDeleteConfirm => 'Padam mesej ini? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get msgDeleted => 'Mesej dipadam';

  @override
  String msgAboutChild(String childName) {
    return 'Tentang $childName';
  }

  @override
  String msgConversationTitle(String parentName, String studentName) {
    return '$parentName · $studentName';
  }

  @override
  String get navTasks => 'Tugasan';

  @override
  String get taskNewTitle => 'Tugasan baharu';

  @override
  String get taskName => 'Nama tugasan';

  @override
  String get taskNameHint => 'cth. Latihan minggu ini';

  @override
  String get taskUntitled => 'Kerja rumah';

  @override
  String get taskNoteLabel => 'Nota (pilihan)';

  @override
  String get taskNoteHint => 'Apa sahaja yang anda mahu beritahu mereka';

  @override
  String get taskAudienceQuestion => 'Untuk siapa tugasan ini?';

  @override
  String get taskAudienceClass => 'Seluruh kelas';

  @override
  String get taskAudienceStudents => 'Pelajar terpilih';

  @override
  String get taskActivitiesHeading => 'Aktiviti untuk dilakukan';

  @override
  String get taskStudentsHeading => 'Pilih pelajar';

  @override
  String get taskHandOut => 'Berikan tugasan';

  @override
  String get taskAnnouncement => 'Pengumuman';

  @override
  String get taskPersonal => 'Peribadi';

  @override
  String get taskForClass => 'Seluruh kelas';

  @override
  String taskForStudents(int count) {
    return '$count pelajar';
  }

  @override
  String taskDoneOf(int done, int total) {
    return '$done daripada $total selesai';
  }

  @override
  String taskStudentsFinished(int done, int total) {
    return '$done/$total telah selesaikannya';
  }

  @override
  String get taskEmptyTeacher => 'Belum ada tugasan. Berikan satu dengan butang di bawah.';

  @override
  String get taskEmptyParent => 'Belum ada tugasan daripada guru.';

  @override
  String get homeworkHeading => 'Kerja rumah';

  @override
  String get taskProgressHeading => 'Siapa yang telah selesai';

  @override
  String get taskDelete => 'Padam tugasan';

  @override
  String get taskDeleteConfirm => 'Padam tugasan ini untuk semua orang? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get taskCreated => 'Tugasan telah diberikan';

  @override
  String get taskDeleted => 'Tugasan dipadam';

  @override
  String get taskNeedActivity => 'Pilih sekurang-kurangnya satu aktiviti';

  @override
  String get taskNeedStudent => 'Pilih sekurang-kurangnya seorang pelajar';

  @override
  String get taskNoStudentsInClass => 'Belum ada pelajar dalam kelas anda';

  @override
  String get todoHeading => 'Perkara untuk dilakukan';

  @override
  String get todoAllDone => 'Semua selesai. Syabas!';

  @override
  String get messageParent => 'Mesej';

  @override
  String get ageLabel => 'Umur';

  @override
  String get errAge => 'Sila masukkan umur yang sah (3 hingga 18)';

  @override
  String ageYearsOld(int age) {
    return '$age tahun';
  }

  @override
  String get studentDelete => 'Padam pelajar';

  @override
  String studentDeleteConfirm(String name) {
    return 'Keluarkan $name daripada kelas anda? Tindakan ini tidak boleh dibatalkan.';
  }

  @override
  String get studentDeleted => 'Pelajar dikeluarkan';

  @override
  String get parentRemove => 'Keluarkan ibu bapa';

  @override
  String parentRemoveConfirm(String name) {
    return 'Keluarkan $name sebagai ibu bapa pelajar ini?';
  }

  @override
  String get actionDelete => 'Padam';

  @override
  String get actionRemove => 'Keluarkan';

  @override
  String get scheduleTitle => 'Jadual hari ini';

  @override
  String get scheduleSectionTitle => 'Rutin harian';

  @override
  String get scheduleEmpty => 'Belum ada rutin ditetapkan';

  @override
  String get scheduleAddActivity => 'Tambah aktiviti';

  @override
  String get scheduleActivityHint => 'Nama aktiviti';

  @override
  String get schedulePictureOptional => 'Gambar (pilihan)';

  @override
  String get schedulePictureNone => 'Tiada';

  @override
  String get scheduleTimeLabel => 'Mula';

  @override
  String get scheduleEndTimeLabel => 'Tamat';

  @override
  String get scheduleNow => 'Sekarang';

  @override
  String get scheduleNext => 'Seterusnya';

  @override
  String get scheduleFreeNow => 'Anda bebas sekarang. Cuba salah satu aktiviti kami!';

  @override
  String get scheduleClashError => 'Masa itu bertindih dengan aktiviti lain';

  @override
  String get scheduleEndError => 'Masa tamat mesti selepas masa mula';

  @override
  String get scheduleSaveError => 'Tidak dapat menyimpan. Sila cuba lagi.';

  @override
  String get scheduleUnavailable => 'Jadual tidak tersedia sekarang';

  @override
  String get classScheduleAction => 'Tetapkan jadual kelas';

  @override
  String get classScheduleTitle => 'Jadual kelas';

  @override
  String get classScheduleHint => 'Jadual ini akan menggantikan rutin semasa setiap pelajar dalam kelas anda.';

  @override
  String get classScheduleSaved => 'Jadual kelas disimpan untuk setiap pelajar';

  @override
  String get journalHowAreYou => 'Bagaimana perasaan anda hari ini?';

  @override
  String get journalContextPrompt => 'Di mana anda? (pilihan)';

  @override
  String get journalNotePrompt => 'Mahu cerita lebih lanjut? (pilihan)';

  @override
  String get journalNoteHint => 'Tulis sedikit tentang perasaan anda';

  @override
  String get journalSave => 'Simpan perasaan saya';

  @override
  String get journalSaved => 'Disimpan. Terima kasih kerana berkongsi.';

  @override
  String get journalSaveError => 'Tidak dapat menyimpan. Sila cuba lagi.';

  @override
  String get journalDeleteTitle => 'Keluarkan perasaan ini?';

  @override
  String get journalDeleteConfirm => 'Ini akan mengeluarkannya daripada jurnal anda.';

  @override
  String get journalDeleted => 'Dikeluarkan daripada jurnal anda.';

  @override
  String get journalEmpty => 'Belum ada perasaan dicatat';

  @override
  String get journalUnavailable => 'Jurnal tidak tersedia sekarang';

  @override
  String get journalSectionTitle => 'Jurnal perasaan';

  @override
  String get journalToday => 'Hari ini';

  @override
  String get journalYesterday => 'Semalam';

  @override
  String get journalCommentTitle => 'Tambah komen';

  @override
  String get journalCommentHint => 'Komen ringkas tentang perasaan ini (pilihan)';

  @override
  String get journalSearchStudents => 'Cari pelajar';

  @override
  String get journalLatestEntries => 'Catatan terkini';

  @override
  String get journalAllStudents => 'Semua pelajar';

  @override
  String get emotionHappy => 'Gembira';

  @override
  String get emotionSad => 'Sedih';

  @override
  String get emotionScared => 'Takut';

  @override
  String get emotionAngry => 'Marah';

  @override
  String get emotionSurprised => 'Terkejut';

  @override
  String get emotionOkay => 'Okey';

  @override
  String get journalCtxHome => 'Rumah';

  @override
  String get journalCtxClass => 'Kelas';

  @override
  String get journalCtxPlay => 'Bermain';

  @override
  String get journalCtxOutside => 'Luar';

  @override
  String get journalCtxMeal => 'Waktu Makan';

  @override
  String get journalCtxFriends => 'Kawan-kawan';

  @override
  String get homeActivities => 'Aktiviti';

  @override
  String get dashStarLeader => 'Peneraju bintang';

  @override
  String get dashStarLeaderEmpty => 'Bintang akan muncul di sini apabila kelas anda bermain.';

  @override
  String dashStudentsEarned(int done, int total) {
    return '$done daripada $total';
  }

  @override
  String get dashBadgeNoOneYet => 'Belum ada sesiapa yang memperoleh lencana ini.';

  @override
  String get dashViewAll => 'Lihat semua';

  @override
  String get dashNoTasks => 'Belum ada tugasan diberikan.';

  @override
  String get actionClose => 'Tutup';

  @override
  String get previewClassroom => 'Paparkan satu aktiviti kepada seluruh kelas dari sini.';

  @override
  String get previewRewards => 'Bintang dan lencana akan muncul di sini apabila anda bermain.';

  @override
  String rewardStarsEarned(int count) {
    return 'Anda memperoleh $count bintang';
  }

  @override
  String get rewardNewBadge => 'Lencana baharu!';

  @override
  String get rewardStarTotal => 'Jumlah bintang setakat ini';

  @override
  String get rewardBadgesTitle => 'Lencana anda';

  @override
  String rewardBadgesCount(int earned, int total) {
    return '$earned daripada $total lencana';
  }

  @override
  String get rewardBadgeAllStories => 'Semua Cerita';

  @override
  String get rewardBadgeAllMatched => 'Semua Dipadan';

  @override
  String get rewardBadgeAllQuizzes => 'Semua Kuiz';

  @override
  String get rewardBadgeAllFeelings => 'Semua Perasaan';

  @override
  String get rewardProgressTitle => 'Teruskan usaha';

  @override
  String rewardProgressCount(int done, int total) {
    return '$done daripada $total';
  }

  @override
  String get rewardActivityDone => 'Semua selesai!';

  @override
  String get rewardTopBadgeTitle => 'Lencana Agung';

  @override
  String get rewardGrandBadgeHint => 'Buka keempat-empat lencana untuk memperoleh lencana istimewa ini';

  @override
  String get rewardAllBadges => 'Anda telah memperoleh semuanya!';

  @override
  String rewardLevelLabel(int level) {
    return 'Tahap $level';
  }

  @override
  String rewardStarsToNext(int count) {
    return '$count lagi bintang untuk naik tahap';
  }

  @override
  String get rewardTopLevel => 'Tahap tertinggi dicapai!';

  @override
  String get rewardNewTitle => 'Gelaran baharu!';

  @override
  String get rewardTitle1 => 'Tunas';

  @override
  String get rewardTitle2 => 'Kawan';

  @override
  String get rewardTitle3 => 'Peneroka';

  @override
  String get rewardTitle4 => 'Pembantu';

  @override
  String get rewardTitle5 => 'Pemandu';

  @override
  String get rewardTitle6 => 'Wira';

  @override
  String get rewardTitle7 => 'Juara';

  @override
  String get rewardTitle8 => 'Legenda';

  @override
  String get progressTitle => 'Kemajuan';

  @override
  String get progressStarsCaption => 'Bintang';

  @override
  String get progressBadgesCaption => 'Lencana';

  @override
  String get progressFeelingsTitle => 'Perasaan yang dilatih';

  @override
  String get progressRecentTitle => 'Aktiviti terkini';

  @override
  String get progressNoActivity => 'Belum ada aktiviti.';

  @override
  String get previewMatch => 'Padankan wajah dengan perasaan di sini.';

  @override
  String get companionGreeting => 'Hai! Saya Luna. Kita boleh belajar tentang perasaan bersama-sama.';

  @override
  String get companionPickFeeling => 'Perasaan mana yang kita nak belajar?';

  @override
  String get companionNext => 'Seterusnya';

  @override
  String get companionLessonDone => 'Syabas! Sekarang anda sudah tahu semua tentang perasaan ini. Terima kasih kerana beritahu saya.';

  @override
  String get companionAwaitingAnswerHint => 'Beritahu saya dalam kotak di bawah, atau ketik mikrofon.';

  @override
  String get companionThinking => 'Biar saya fikir sebentar.';

  @override
  String get companionRestLine => 'Sembang saya sedang berehat sekejap. Mari kita belajar tentang perasaan bersama-sama.';

  @override
  String get companionInputHint => 'Tanya saya tentang sesuatu perasaan';

  @override
  String get companionSend => 'Hantar';

  @override
  String get companionHearAgain => 'Dengar sekali lagi';

  @override
  String get companionTalk => 'Bercakap dengan saya';

  @override
  String get companionListening => 'Saya sedang mendengar';

  @override
  String get companionPlayRound => 'Teka perasaan saya';

  @override
  String get companionRoundAsk => 'Lihat saya. Apakah perasaan saya?';

  @override
  String get companionRoundPick => 'Ketik perasaan yang anda nampak, atau beritahu saya';

  @override
  String get companionStopRound => 'Berhenti bermain';

  @override
  String get previewQuiz => 'Kuiz perasaan yang tenang tanpa pemasa dan tanpa markah.';

  @override
  String get accountSection => 'Akaun';

  @override
  String get detailsSection => 'Butiran';

  @override
  String get mixMatchIntro => 'Pilih satu cara untuk memadankan perasaan.';

  @override
  String get mixMatchBadgeHint => 'Selesaikan semua soalan untuk memperoleh lencana';

  @override
  String get mixMatchAllDoneHint => 'Semua selesai! Anda telah memperoleh lencana anda';

  @override
  String get mixMatchTypeFace => 'Wajah';

  @override
  String get mixMatchTypeBody => 'Badan';

  @override
  String get mixMatchTypeSituation => 'Situasi';

  @override
  String get mixMatchTypeStory => 'Cerita';

  @override
  String get mixMatchPrompt => 'Seret ke perasaan yang betul.';

  @override
  String get mixMatchTryAgain => 'Tidak mengapa. Cuba perasaan lain.';

  @override
  String get mixMatchDone => 'Semua selesai!';

  @override
  String get mixMatchDoneBody => 'Padanan yang bagus. Anda boleh bermain lagi bila-bila masa.';

  @override
  String get mixMatchDoneButton => 'Selesai';

  @override
  String get mixMatchClassroomHint => 'Pilih satu cara untuk bermain pada skrin kelas.';

  @override
  String get mixMatchListen => 'Dengar';

  @override
  String get mixMatchListening => 'Sedang dimainkan';

  @override
  String get quizAskLook => 'Siapa yang berasa begini?';

  @override
  String get quizAskListen => 'Bagaimana perasaan ini?';

  @override
  String get quizAskStory => 'Bagaimana perasaan mereka?';

  @override
  String get quizListen => 'Dengar';

  @override
  String get quizPlaying => 'Sedang dimainkan';

  @override
  String get quizTryAgain => 'Tidak mengapa. Lihat sekali lagi.';

  @override
  String get quizNext => 'Seterusnya';

  @override
  String get quizFinish => 'Selesai';

  @override
  String get quizDone => 'Semua selesai!';

  @override
  String get quizDoneBody => 'Bagus mengecam perasaan. Anda boleh bermain lagi bila-bila masa.';

  @override
  String get quizDoneButton => 'Selesai';

  @override
  String get quizStart => 'Mula kuiz';

  @override
  String get quizClassroomHint => 'Mainkan kuiz perasaan yang tenang pada skrin kelas.';

  @override
  String get quizPickDay => 'Pilih satu hari untuk bermain.';

  @override
  String get quizToday => 'Hari ini';

  @override
  String get quizYesterday => 'Semalam';

  @override
  String get quizDayBefore => 'Hari sebelumnya';

  @override
  String get storyIntro => 'Pilih satu cerita untuk ditonton.';

  @override
  String storyEpisode(int n) {
    return 'Episod $n';
  }

  @override
  String get storyTryAgain => 'Tidak mengapa. Lihat sekali lagi.';

  @override
  String get storyContinue => 'Teruskan';

  @override
  String get storyDone => 'Tamat!';

  @override
  String get storyDoneBody => 'Bagus menonton. Episod seterusnya sedia apabila anda bersedia.';

  @override
  String get storyDoneButton => 'Selesai';

  @override
  String get storyNextEpisode => 'Episod Seterusnya';

  @override
  String get feedbackNarration => 'Sebut maklum balas selepas jawapan';

  @override
  String get quizMuteVoice => 'Matikan suara';

  @override
  String get quizUnmuteVoice => 'Hidupkan suara';

  @override
  String get storyVideoUnavailable => 'Cerita ini sedang disediakan. Sila cuba satu lagi.';

  @override
  String get storyClassroomHint => 'Mainkan satu episod cerita pada skrin kelas.';

  @override
  String get weeklyContentThisWeek => 'Kandungan minggu ini';

  @override
  String get weeklyContentPastWeeks => 'Minggu lepas';

  @override
  String get weeklyContentNoneYetTitle => 'Belum ada minggu lepas';

  @override
  String get weeklyContentNoneYetBody => 'Ini ialah minggu pertama. Kandungan baharu tiba setiap minggu, jadi datang lagi tidak lama lagi!';

  @override
  String weeklyContentWeekLabel(int n) {
    return 'Minggu $n';
  }
}
