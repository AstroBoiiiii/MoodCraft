import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MoodCraft'**
  String get appName;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Who is using MoodCraft?'**
  String get chooseRole;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @sensorySettings.
  ///
  /// In en, this message translates to:
  /// **'Sensory settings'**
  String get sensorySettings;

  /// No description provided for @colourTheme.
  ///
  /// In en, this message translates to:
  /// **'Colour theme'**
  String get colourTheme;

  /// No description provided for @animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// No description provided for @animationFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get animationFull;

  /// No description provided for @animationReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get animationReduced;

  /// No description provided for @animationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get animationOff;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get music;

  /// No description provided for @musicTrack.
  ///
  /// In en, this message translates to:
  /// **'Choose a track'**
  String get musicTrack;

  /// No description provided for @musicTrack1.
  ///
  /// In en, this message translates to:
  /// **'Calm Bells'**
  String get musicTrack1;

  /// No description provided for @musicTrack2.
  ///
  /// In en, this message translates to:
  /// **'Nature Sounds'**
  String get musicTrack2;

  /// No description provided for @musicTrack3.
  ///
  /// In en, this message translates to:
  /// **'Gentle Piano'**
  String get musicTrack3;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get musicVolume;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String greeting(String name);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get navRewards;

  /// No description provided for @navCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get navCompanion;

  /// No description provided for @navAr.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get navAr;

  /// No description provided for @navStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get navStories;

  /// No description provided for @navMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get navMatch;

  /// No description provided for @navQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get navQuiz;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get navStudents;

  /// No description provided for @navClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get navClassroom;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @arMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'AR is available on the mobile app.'**
  String get arMobileOnly;

  /// No description provided for @arPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'AR placeholder. A 3D character will act out a feeling here.'**
  String get arPlaceholder;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get languageMalay;

  /// No description provided for @toRegister.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get toRegister;

  /// No description provided for @toLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get toLogin;

  /// No description provided for @errName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errName;

  /// No description provided for @errEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get errEmail;

  /// No description provided for @errPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errPassword;

  /// No description provided for @devSignIn.
  ///
  /// In en, this message translates to:
  /// **'Developer quick sign-in'**
  String get devSignIn;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @errPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get errPhone;

  /// No description provided for @classCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Class code'**
  String get classCodeLabel;

  /// No description provided for @errClassCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the class code from your teacher'**
  String get errClassCode;

  /// No description provided for @parentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s email'**
  String get parentEmailLabel;

  /// No description provided for @childEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Child\'s email'**
  String get childEmailLabel;

  /// No description provided for @classNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name (optional)'**
  String get classNameLabel;

  /// No description provided for @classCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that class code. Your teacher can add you later.'**
  String get classCodeNotFound;

  /// No description provided for @yourClassCode.
  ///
  /// In en, this message translates to:
  /// **'Class code'**
  String get yourClassCode;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @showCode.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showCode;

  /// No description provided for @hideCode.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideCode;

  /// No description provided for @webMobileOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile app'**
  String get webMobileOnlyTitle;

  /// No description provided for @webMobileOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Please use the MoodCraft mobile app to continue. The web app is for teachers.'**
  String get webMobileOnlyBody;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @errUsername.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers and underscores only'**
  String get errUsername;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfile;

  /// No description provided for @confirmEdit.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmEdit;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelEdit;

  /// No description provided for @contactsSection.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsSection;

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherLabel;

  /// No description provided for @parentLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveProfile;

  /// No description provided for @levelStars.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {stars} stars'**
  String levelStars(int level, int stars);

  /// No description provided for @noStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students enrolled yet'**
  String get noStudentsYet;

  /// No description provided for @noChildLinked.
  ///
  /// In en, this message translates to:
  /// **'No child linked yet'**
  String get noChildLinked;

  /// No description provided for @colourThemeCalmBlue.
  ///
  /// In en, this message translates to:
  /// **'Calm Blue'**
  String get colourThemeCalmBlue;

  /// No description provided for @colourThemeSoftGreen.
  ///
  /// In en, this message translates to:
  /// **'Soft Green'**
  String get colourThemeSoftGreen;

  /// No description provided for @colourThemeWarmNeutral.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get colourThemeWarmNeutral;

  /// No description provided for @colourThemeLowStimGrey.
  ///
  /// In en, this message translates to:
  /// **'Low Stim'**
  String get colourThemeLowStimGrey;

  /// No description provided for @studentProfile.
  ///
  /// In en, this message translates to:
  /// **'Student Profile'**
  String get studentProfile;

  /// No description provided for @childProfile.
  ///
  /// In en, this message translates to:
  /// **'Child Profile'**
  String get childProfile;

  /// No description provided for @msgNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get msgNoConversations;

  /// No description provided for @msgNoLinkedTeacher.
  ///
  /// In en, this message translates to:
  /// **'No teacher linked yet'**
  String get msgNoLinkedTeacher;

  /// No description provided for @msgNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get msgNewMessage;

  /// No description provided for @msgStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get msgStartConversation;

  /// No description provided for @msgNoParentsToMessage.
  ///
  /// In en, this message translates to:
  /// **'No parents linked to your students yet'**
  String get msgNoParentsToMessage;

  /// No description provided for @msgTypeHere.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get msgTypeHere;

  /// No description provided for @msgSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get msgSend;

  /// No description provided for @msgYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get msgYou;

  /// No description provided for @msgDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get msgDeleteMessage;

  /// No description provided for @msgDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this message? This can\'t be undone.'**
  String get msgDeleteConfirm;

  /// No description provided for @msgDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get msgDeleted;

  /// No description provided for @msgAboutChild.
  ///
  /// In en, this message translates to:
  /// **'About {childName}'**
  String msgAboutChild(String childName);

  /// No description provided for @msgConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'{parentName} · {studentName}'**
  String msgConversationTitle(String parentName, String studentName);

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @errAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age (3 to 18)'**
  String get errAge;

  /// No description provided for @ageYearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String ageYearsOld(int age);

  /// No description provided for @studentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete student'**
  String get studentDelete;

  /// No description provided for @studentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your class? This can\'t be undone.'**
  String studentDeleteConfirm(String name);

  /// No description provided for @studentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Student removed'**
  String get studentDeleted;

  /// No description provided for @parentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove parent'**
  String get parentRemove;

  /// No description provided for @parentRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} as a parent of this student?'**
  String parentRemoveConfirm(String name);

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily routine'**
  String get scheduleSectionTitle;

  /// No description provided for @scheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No routine set yet'**
  String get scheduleEmpty;

  /// No description provided for @scheduleAddActivity.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get scheduleAddActivity;

  /// No description provided for @scheduleActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get scheduleActivityHint;

  /// No description provided for @schedulePictureOptional.
  ///
  /// In en, this message translates to:
  /// **'Picture (optional)'**
  String get schedulePictureOptional;

  /// No description provided for @schedulePictureNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get schedulePictureNone;

  /// No description provided for @scheduleTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get scheduleTimeLabel;

  /// No description provided for @scheduleEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get scheduleEndTimeLabel;

  /// No description provided for @scheduleNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get scheduleNow;

  /// No description provided for @scheduleNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get scheduleNext;

  /// No description provided for @scheduleFreeNow.
  ///
  /// In en, this message translates to:
  /// **'You are free right now. Try out one of our activities!'**
  String get scheduleFreeNow;

  /// No description provided for @scheduleClashError.
  ///
  /// In en, this message translates to:
  /// **'That time overlaps another activity'**
  String get scheduleClashError;

  /// No description provided for @scheduleEndError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time'**
  String get scheduleEndError;

  /// No description provided for @scheduleSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get scheduleSaveError;

  /// No description provided for @scheduleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Schedule unavailable right now'**
  String get scheduleUnavailable;

  /// No description provided for @journalHowAreYou.
  ///
  /// In en, this message translates to:
  /// **'How do you feel today?'**
  String get journalHowAreYou;

  /// No description provided for @journalContextPrompt.
  ///
  /// In en, this message translates to:
  /// **'Where are you? (optional)'**
  String get journalContextPrompt;

  /// No description provided for @journalNotePrompt.
  ///
  /// In en, this message translates to:
  /// **'Want to say more? (optional)'**
  String get journalNotePrompt;

  /// No description provided for @journalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a little about how you feel'**
  String get journalNoteHint;

  /// No description provided for @journalSave.
  ///
  /// In en, this message translates to:
  /// **'Save how I feel'**
  String get journalSave;

  /// No description provided for @journalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Thank you for sharing.'**
  String get journalSaved;

  /// No description provided for @journalSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get journalSaveError;

  /// No description provided for @journalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this feeling?'**
  String get journalDeleteTitle;

  /// No description provided for @journalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will take it out of your journal.'**
  String get journalDeleteConfirm;

  /// No description provided for @journalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed from your journal.'**
  String get journalDeleted;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No feelings logged yet'**
  String get journalEmpty;

  /// No description provided for @journalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Journal unavailable right now'**
  String get journalUnavailable;

  /// No description provided for @journalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Feelings journal'**
  String get journalSectionTitle;

  /// No description provided for @journalToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get journalToday;

  /// No description provided for @journalYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get journalYesterday;

  /// No description provided for @journalCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get journalCommentTitle;

  /// No description provided for @journalCommentHint.
  ///
  /// In en, this message translates to:
  /// **'A short comment about this feeling (optional)'**
  String get journalCommentHint;

  /// No description provided for @emotionHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get emotionHappy;

  /// No description provided for @emotionSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get emotionSad;

  /// No description provided for @emotionScared.
  ///
  /// In en, this message translates to:
  /// **'Scared'**
  String get emotionScared;

  /// No description provided for @emotionAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get emotionAngry;

  /// No description provided for @emotionSurprised.
  ///
  /// In en, this message translates to:
  /// **'Surprised'**
  String get emotionSurprised;

  /// No description provided for @emotionOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get emotionOkay;

  /// No description provided for @journalCtxHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get journalCtxHome;

  /// No description provided for @journalCtxClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get journalCtxClass;

  /// No description provided for @journalCtxPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get journalCtxPlay;

  /// No description provided for @journalCtxOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get journalCtxOutside;

  /// No description provided for @journalCtxMeal.
  ///
  /// In en, this message translates to:
  /// **'Mealtime'**
  String get journalCtxMeal;

  /// No description provided for @journalCtxFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get journalCtxFriends;

  /// No description provided for @homeActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get homeActivities;

  /// No description provided for @previewDashboard.
  ///
  /// In en, this message translates to:
  /// **'Your students\' progress and difficulty areas will appear here.'**
  String get previewDashboard;

  /// No description provided for @previewClassroom.
  ///
  /// In en, this message translates to:
  /// **'Project an activity to the whole class from here.'**
  String get previewClassroom;

  /// No description provided for @previewReports.
  ///
  /// In en, this message translates to:
  /// **'Gentle progress reports you can share will appear here.'**
  String get previewReports;

  /// No description provided for @previewRewards.
  ///
  /// In en, this message translates to:
  /// **'Stars and badges will appear here as you play.'**
  String get previewRewards;

  /// No description provided for @previewCompanion.
  ///
  /// In en, this message translates to:
  /// **'A friendly companion will help you name feelings here.'**
  String get previewCompanion;

  /// No description provided for @previewStory.
  ///
  /// In en, this message translates to:
  /// **'Gentle stories that pause to ask how everyone feels.'**
  String get previewStory;

  /// No description provided for @previewMatch.
  ///
  /// In en, this message translates to:
  /// **'Match the faces to feelings here.'**
  String get previewMatch;

  /// No description provided for @previewQuiz.
  ///
  /// In en, this message translates to:
  /// **'A calm feelings quiz with no timer and no score.'**
  String get previewQuiz;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @mixMatchIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a way to match feelings.'**
  String get mixMatchIntro;

  /// No description provided for @mixMatchBadgeHint.
  ///
  /// In en, this message translates to:
  /// **'Complete all the questions to earn badges'**
  String get mixMatchBadgeHint;

  /// No description provided for @mixMatchAllDoneHint.
  ///
  /// In en, this message translates to:
  /// **'All done! You earned your badges'**
  String get mixMatchAllDoneHint;

  /// No description provided for @mixMatchTypeFace.
  ///
  /// In en, this message translates to:
  /// **'Faces'**
  String get mixMatchTypeFace;

  /// No description provided for @mixMatchTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Bodies'**
  String get mixMatchTypeBody;

  /// No description provided for @mixMatchTypeSituation.
  ///
  /// In en, this message translates to:
  /// **'Situations'**
  String get mixMatchTypeSituation;

  /// No description provided for @mixMatchTypeStory.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get mixMatchTypeStory;

  /// No description provided for @mixMatchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Drag it to the right feeling.'**
  String get mixMatchPrompt;

  /// No description provided for @mixMatchTryAgain.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay. Try another feeling.'**
  String get mixMatchTryAgain;

  /// No description provided for @mixMatchDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get mixMatchDone;

  /// No description provided for @mixMatchDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Great matching. You can play again any time.'**
  String get mixMatchDoneBody;

  /// No description provided for @mixMatchDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mixMatchDoneButton;

  /// No description provided for @mixMatchClassroomHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a way to play on the class screen.'**
  String get mixMatchClassroomHint;

  /// No description provided for @mixMatchListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get mixMatchListen;

  /// No description provided for @mixMatchListening.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get mixMatchListening;

  /// No description provided for @quizAskLook.
  ///
  /// In en, this message translates to:
  /// **'Who feels this way?'**
  String get quizAskLook;

  /// No description provided for @quizAskListen.
  ///
  /// In en, this message translates to:
  /// **'How does this feel?'**
  String get quizAskListen;

  /// No description provided for @quizAskStory.
  ///
  /// In en, this message translates to:
  /// **'How do they feel?'**
  String get quizAskStory;

  /// No description provided for @quizListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get quizListen;

  /// No description provided for @quizPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get quizPlaying;

  /// No description provided for @quizTryAgain.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay. Look again.'**
  String get quizTryAgain;

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// No description provided for @quizFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get quizFinish;

  /// No description provided for @quizDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get quizDone;

  /// No description provided for @quizDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Great feeling spotting. You can play again any time.'**
  String get quizDoneBody;

  /// No description provided for @quizDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get quizDoneButton;

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get quizStart;

  /// No description provided for @quizClassroomHint.
  ///
  /// In en, this message translates to:
  /// **'Play a calm feelings quiz on the class screen.'**
  String get quizClassroomHint;

  /// No description provided for @quizPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick a day to play.'**
  String get quizPickDay;

  /// No description provided for @quizToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quizToday;

  /// No description provided for @quizYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get quizYesterday;

  /// No description provided for @quizDayBefore.
  ///
  /// In en, this message translates to:
  /// **'Day before'**
  String get quizDayBefore;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ms': return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
