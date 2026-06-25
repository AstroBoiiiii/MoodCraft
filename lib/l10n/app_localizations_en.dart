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
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleParent => 'Parent';

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
  String get musicTrack => 'Choose a track';

  @override
  String get musicTrack1 => 'Calm Bells';

  @override
  String get musicTrack2 => 'Nature Sounds';

  @override
  String get musicTrack3 => 'Gentle Piano';

  @override
  String get musicVolume => 'Volume';

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

  @override
  String get signIn => 'Sign in';

  @override
  String get registerTitle => 'Create account';

  @override
  String get nameLabel => 'Your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get toRegister => 'New here? Create an account';

  @override
  String get toLogin => 'Already have an account? Sign in';

  @override
  String get errName => 'Please enter your name';

  @override
  String get errEmail => 'Please enter a valid email';

  @override
  String get errPassword => 'Password must be at least 6 characters';

  @override
  String get devSignIn => 'Developer quick sign-in';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get errPhone => 'Please enter a valid phone number';

  @override
  String get classCodeLabel => 'Class code';

  @override
  String get errClassCode => 'Please enter the class code from your teacher';

  @override
  String get parentEmailLabel => 'Parent\'s email';

  @override
  String get childEmailLabel => 'Child\'s email';

  @override
  String get classNameLabel => 'Class name (optional)';

  @override
  String get classCodeNotFound => 'We couldn\'t find that class code. Your teacher can add you later.';

  @override
  String get yourClassCode => 'Class code';

  @override
  String get showCode => 'Show';

  @override
  String get hideCode => 'Hide';

  @override
  String get webMobileOnlyTitle => 'Mobile app';

  @override
  String get webMobileOnlyBody => 'Please use the MoodCraft mobile app to continue. The web app is for teachers.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get errUsername => 'Letters, numbers and underscores only';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get editProfile => 'Edit';

  @override
  String get confirmEdit => 'Confirm';

  @override
  String get cancelEdit => 'Cancel';

  @override
  String get contactsSection => 'Contacts';

  @override
  String get teacherLabel => 'Teacher';

  @override
  String get parentLabel => 'Parent';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get roleLabel => 'Role';

  @override
  String get saveProfile => 'Save changes';

  @override
  String levelStars(int level, int stars) {
    return 'Level $level · $stars stars';
  }

  @override
  String get noStudentsYet => 'No students enrolled yet';

  @override
  String get noChildLinked => 'No child linked yet';

  @override
  String get colourThemeCalmBlue => 'Calm Blue';

  @override
  String get colourThemeSoftGreen => 'Soft Green';

  @override
  String get colourThemeWarmNeutral => 'Warm';

  @override
  String get colourThemeLowStimGrey => 'Low Stim';

  @override
  String get studentProfile => 'Student Profile';

  @override
  String get childProfile => 'Child Profile';

  @override
  String get msgNoConversations => 'No conversations yet';

  @override
  String get msgNoLinkedTeacher => 'No teacher linked yet';

  @override
  String get msgTypeHere => 'Type a message…';

  @override
  String get msgSend => 'Send';

  @override
  String get msgYou => 'You';

  @override
  String msgAboutChild(String childName) {
    return 'About $childName';
  }

  @override
  String msgConversationTitle(String parentName, String studentName) {
    return '$parentName · $studentName';
  }

  @override
  String get ageLabel => 'Age';

  @override
  String get errAge => 'Please enter a valid age (3–18)';

  @override
  String ageYearsOld(int age) {
    return '$age years old';
  }

  @override
  String get scheduleTitle => 'Today\'s schedule';

  @override
  String get scheduleSectionTitle => 'Daily routine';

  @override
  String get scheduleEmpty => 'No routine set yet';

  @override
  String get scheduleAddActivity => 'Add activity';

  @override
  String get scheduleActivityHint => 'Activity name';

  @override
  String get schedulePictureOptional => 'Picture (optional)';

  @override
  String get schedulePictureNone => 'None';

  @override
  String get scheduleTimeLabel => 'Start';

  @override
  String get scheduleEndTimeLabel => 'End';

  @override
  String get scheduleNow => 'Now';

  @override
  String get scheduleNext => 'Next';

  @override
  String get scheduleClashError => 'That time overlaps another activity';

  @override
  String get scheduleEndError => 'End time must be after the start time';

  @override
  String get scheduleSaveError => 'Couldn\'t save — please try again';

  @override
  String get scheduleUnavailable => 'Schedule unavailable right now';

  @override
  String get journalHowAreYou => 'How do you feel today?';

  @override
  String get journalContextPrompt => 'Where are you? (optional)';

  @override
  String get journalSave => 'Save how I feel';

  @override
  String get journalSaved => 'Saved. Thank you for sharing.';

  @override
  String get journalSaveError => 'Couldn\'t save — please try again';

  @override
  String get journalEmpty => 'No feelings logged yet';

  @override
  String get journalUnavailable => 'Journal unavailable right now';

  @override
  String get journalSectionTitle => 'Feelings journal';

  @override
  String get journalToday => 'Today';

  @override
  String get journalYesterday => 'Yesterday';

  @override
  String get journalNoteTitle => 'Add a note';

  @override
  String get journalNoteHint => 'A short note about this feeling (optional)';

  @override
  String get emotionHappy => 'Happy';

  @override
  String get emotionSad => 'Sad';

  @override
  String get emotionScared => 'Scared';

  @override
  String get emotionAngry => 'Angry';

  @override
  String get emotionSurprised => 'Surprised';

  @override
  String get emotionOkay => 'Okay';

  @override
  String get journalCtxHome => 'Home';

  @override
  String get journalCtxClass => 'Class';

  @override
  String get journalCtxPlay => 'Play';

  @override
  String get journalCtxOutside => 'Outside';

  @override
  String get journalCtxMeal => 'Mealtime';

  @override
  String get journalCtxFriends => 'Friends';
}
