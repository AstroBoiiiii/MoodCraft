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
  /// **'AR placeholder — a 3D character will act out a feeling here.'**
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
  /// **'Your class code'**
  String get yourClassCode;

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
