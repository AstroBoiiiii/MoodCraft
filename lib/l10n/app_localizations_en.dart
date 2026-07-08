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
  String get companionMobileOnly => 'The companion is available on the mobile app.';

  @override
  String get arStarting => 'Getting the camera ready.';

  @override
  String get arCameraNeeded => 'MoodCraft needs the camera to show AR. Please allow camera access.';

  @override
  String get arAllowCamera => 'Allow camera';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInWelcome => 'Welcome back. Sign in to continue.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get nameLabel => 'Your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

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
  String get classLabel => 'Class';

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
  String get tabOverview => 'Overview';

  @override
  String get tabSchedule => 'Schedule';

  @override
  String get tabJournal => 'Journal';

  @override
  String get progressReport => 'Progress report';

  @override
  String get progressReportSoon => 'A progress report for this student is coming soon.';

  @override
  String get selectStudentHint => 'Select a student to see their details';

  @override
  String get homeTodayHeading => 'Today';

  @override
  String get msgNoConversations => 'No conversations yet';

  @override
  String get msgNoLinkedTeacher => 'No teacher linked yet';

  @override
  String get msgNewMessage => 'New message';

  @override
  String get msgStartConversation => 'Start a conversation';

  @override
  String get msgNoParentsToMessage => 'No parents linked to your students yet';

  @override
  String get msgTypeHere => 'Type a message…';

  @override
  String get msgSend => 'Send';

  @override
  String get msgYou => 'You';

  @override
  String get msgDeleteMessage => 'Delete message';

  @override
  String get msgDeleteConfirm => 'Delete this message? This can\'t be undone.';

  @override
  String get msgDeleted => 'Message deleted';

  @override
  String msgAboutChild(String childName) {
    return 'About $childName';
  }

  @override
  String msgConversationTitle(String parentName, String studentName) {
    return '$parentName · $studentName';
  }

  @override
  String get navTasks => 'Tasks';

  @override
  String get taskNewTitle => 'New task';

  @override
  String get taskName => 'Task name';

  @override
  String get taskNameHint => 'e.g. This week\'s practice';

  @override
  String get taskUntitled => 'Homework';

  @override
  String get taskNoteLabel => 'Note (optional)';

  @override
  String get taskNoteHint => 'Anything you want to tell them';

  @override
  String get taskAudienceQuestion => 'Who is this for?';

  @override
  String get taskAudienceClass => 'Whole class';

  @override
  String get taskAudienceStudents => 'Chosen students';

  @override
  String get taskActivitiesHeading => 'Activities to do';

  @override
  String get taskStudentsHeading => 'Choose students';

  @override
  String get taskHandOut => 'Hand out task';

  @override
  String get taskAnnouncement => 'Announcement';

  @override
  String get taskPersonal => 'Personal';

  @override
  String get taskForClass => 'Whole class';

  @override
  String taskForStudents(int count) {
    return '$count students';
  }

  @override
  String taskDoneOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String taskStudentsFinished(int done, int total) {
    return '$done/$total finished it';
  }

  @override
  String get taskEmptyTeacher => 'No tasks yet. Hand one out with the button below.';

  @override
  String get taskEmptyParent => 'No tasks from the teacher yet.';

  @override
  String get homeworkHeading => 'Homework';

  @override
  String get taskProgressHeading => 'Who\'s done it';

  @override
  String get taskDelete => 'Delete task';

  @override
  String get taskDeleteConfirm => 'Delete this task for everyone? This can\'t be undone.';

  @override
  String get taskCreated => 'Task handed out';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get taskNeedActivity => 'Pick at least one activity';

  @override
  String get taskNeedStudent => 'Pick at least one student';

  @override
  String get taskNoStudentsInClass => 'No students in your class yet';

  @override
  String get todoHeading => 'Things to do';

  @override
  String get todoAllDone => 'All done. Great work!';

  @override
  String get messageParent => 'Message';

  @override
  String get ageLabel => 'Age';

  @override
  String get errAge => 'Please enter a valid age (3 to 18)';

  @override
  String ageYearsOld(int age) {
    return '$age years old';
  }

  @override
  String get studentDelete => 'Delete student';

  @override
  String studentDeleteConfirm(String name) {
    return 'Remove $name from your class? This can\'t be undone.';
  }

  @override
  String get studentDeleted => 'Student removed';

  @override
  String get parentRemove => 'Remove parent';

  @override
  String parentRemoveConfirm(String name) {
    return 'Remove $name as a parent of this student?';
  }

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRemove => 'Remove';

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
  String get scheduleFreeNow => 'You are free right now. Try out one of our activities!';

  @override
  String get scheduleClashError => 'That time overlaps another activity';

  @override
  String get scheduleEndError => 'End time must be after the start time';

  @override
  String get scheduleSaveError => 'Couldn\'t save. Please try again.';

  @override
  String get scheduleUnavailable => 'Schedule unavailable right now';

  @override
  String get journalHowAreYou => 'How do you feel today?';

  @override
  String get journalContextPrompt => 'Where are you? (optional)';

  @override
  String get journalNotePrompt => 'Want to say more? (optional)';

  @override
  String get journalNoteHint => 'Write a little about how you feel';

  @override
  String get journalSave => 'Save how I feel';

  @override
  String get journalSaved => 'Saved. Thank you for sharing.';

  @override
  String get journalSaveError => 'Couldn\'t save. Please try again.';

  @override
  String get journalDeleteTitle => 'Remove this feeling?';

  @override
  String get journalDeleteConfirm => 'This will take it out of your journal.';

  @override
  String get journalDeleted => 'Removed from your journal.';

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
  String get journalCommentTitle => 'Add a comment';

  @override
  String get journalCommentHint => 'A short comment about this feeling (optional)';

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

  @override
  String get homeActivities => 'Activities';

  @override
  String get previewDashboard => 'Your students\' progress and difficulty areas will appear here.';

  @override
  String get previewClassroom => 'Project an activity to the whole class from here.';

  @override
  String get previewReports => 'Gentle progress reports you can share will appear here.';

  @override
  String get previewRewards => 'Stars and badges will appear here as you play.';

  @override
  String rewardStarsEarned(int count) {
    return 'You earned $count stars';
  }

  @override
  String get rewardNewBadge => 'New badge!';

  @override
  String get rewardStarTotal => 'Stars so far';

  @override
  String get rewardBadgesTitle => 'Your badges';

  @override
  String rewardBadgesCount(int earned, int total) {
    return '$earned of $total badges';
  }

  @override
  String get rewardBadgeAllStories => 'All Stories';

  @override
  String get rewardBadgeAllMatched => 'All Matched';

  @override
  String get rewardBadgeAllQuizzes => 'All Quizzes';

  @override
  String get rewardBadgeAllFeelings => 'All Feelings';

  @override
  String get rewardProgressTitle => 'Keep going';

  @override
  String rewardProgressCount(int done, int total) {
    return '$done of $total';
  }

  @override
  String get rewardActivityDone => 'All done!';

  @override
  String get rewardTopBadgeTitle => 'The Grand Badge';

  @override
  String get rewardGrandBadgeHint => 'Unlock all four badges to earn this mythical badge';

  @override
  String get rewardAllBadges => 'You got them all!';

  @override
  String rewardLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String rewardStarsToNext(int count) {
    return '$count more stars to level up';
  }

  @override
  String get rewardTopLevel => 'Top level reached!';

  @override
  String get rewardNewTitle => 'New title!';

  @override
  String get rewardTitle1 => 'Sprout';

  @override
  String get rewardTitle2 => 'Buddy';

  @override
  String get rewardTitle3 => 'Explorer';

  @override
  String get rewardTitle4 => 'Helper';

  @override
  String get rewardTitle5 => 'Guide';

  @override
  String get rewardTitle6 => 'Hero';

  @override
  String get rewardTitle7 => 'Champion';

  @override
  String get rewardTitle8 => 'Legend';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressStarsCaption => 'Stars';

  @override
  String get progressBadgesCaption => 'Badges';

  @override
  String get progressFeelingsTitle => 'Feelings practiced';

  @override
  String get progressRecentTitle => 'Recent activity';

  @override
  String get progressNoActivity => 'No activities yet.';

  @override
  String get previewMatch => 'Match the faces to feelings here.';

  @override
  String get companionGreeting => 'Hello! I am Luna. We can learn about feelings together.';

  @override
  String get companionPickFeeling => 'Which feeling shall we learn?';

  @override
  String get companionNext => 'Next';

  @override
  String get companionLessonDone => 'Well done! Now you know all about this feeling. Thank you for telling me.';

  @override
  String get companionAwaitingAnswerHint => 'Tell me in the box below, or tap the microphone.';

  @override
  String get companionThinking => 'Let me think.';

  @override
  String get companionRestLine => 'My chat is having a little rest. Let\'s learn a feeling together instead.';

  @override
  String get companionInputHint => 'Ask me about a feeling';

  @override
  String get companionSend => 'Send';

  @override
  String get companionHearAgain => 'Hear it again';

  @override
  String get companionTalk => 'Talk to me';

  @override
  String get companionListening => 'I am listening';

  @override
  String get companionPlayRound => 'Guess my feeling';

  @override
  String get companionRoundAsk => 'Look at me. How am I feeling?';

  @override
  String get companionRoundPick => 'Tap the feeling you see, or tell me';

  @override
  String get companionStopRound => 'Stop playing';

  @override
  String get previewQuiz => 'A calm feelings quiz with no timer and no score.';

  @override
  String get accountSection => 'Account';

  @override
  String get detailsSection => 'Details';

  @override
  String get mixMatchIntro => 'Pick a way to match feelings.';

  @override
  String get mixMatchBadgeHint => 'Complete all the questions to earn badges';

  @override
  String get mixMatchAllDoneHint => 'All done! You earned your badges';

  @override
  String get mixMatchTypeFace => 'Faces';

  @override
  String get mixMatchTypeBody => 'Bodies';

  @override
  String get mixMatchTypeSituation => 'Situations';

  @override
  String get mixMatchTypeStory => 'Stories';

  @override
  String get mixMatchPrompt => 'Drag it to the right feeling.';

  @override
  String get mixMatchTryAgain => 'That\'s okay. Try another feeling.';

  @override
  String get mixMatchDone => 'All done!';

  @override
  String get mixMatchDoneBody => 'Great matching. You can play again any time.';

  @override
  String get mixMatchDoneButton => 'Done';

  @override
  String get mixMatchClassroomHint => 'Pick a way to play on the class screen.';

  @override
  String get mixMatchListen => 'Listen';

  @override
  String get mixMatchListening => 'Playing';

  @override
  String get quizAskLook => 'Who feels this way?';

  @override
  String get quizAskListen => 'How does this feel?';

  @override
  String get quizAskStory => 'How do they feel?';

  @override
  String get quizListen => 'Listen';

  @override
  String get quizPlaying => 'Playing';

  @override
  String get quizTryAgain => 'That\'s okay. Look again.';

  @override
  String get quizNext => 'Next';

  @override
  String get quizFinish => 'Finish';

  @override
  String get quizDone => 'All done!';

  @override
  String get quizDoneBody => 'Great feeling spotting. You can play again any time.';

  @override
  String get quizDoneButton => 'Done';

  @override
  String get quizStart => 'Start quiz';

  @override
  String get quizClassroomHint => 'Play a calm feelings quiz on the class screen.';

  @override
  String get quizPickDay => 'Pick a day to play.';

  @override
  String get quizToday => 'Today';

  @override
  String get quizYesterday => 'Yesterday';

  @override
  String get quizDayBefore => 'Day before';

  @override
  String get storyIntro => 'Pick a story to watch.';

  @override
  String storyEpisode(int n) {
    return 'Episode $n';
  }

  @override
  String get storyTryAgain => 'That\'s okay. Have another look.';

  @override
  String get storyContinue => 'Continue';

  @override
  String get storyDone => 'The end!';

  @override
  String get storyDoneBody => 'Great watching. The next episode is ready when you are.';

  @override
  String get storyDoneButton => 'Done';

  @override
  String get storyNextEpisode => 'Next Episode';

  @override
  String get feedbackNarration => 'Speak feedback after answers';

  @override
  String get quizMuteVoice => 'Turn off the voice';

  @override
  String get quizUnmuteVoice => 'Turn on the voice';

  @override
  String get storyVideoUnavailable => 'This story is getting ready. Please try another one.';

  @override
  String get storyClassroomHint => 'Play a story episode on the class screen.';

  @override
  String get weeklyContentThisWeek => 'This week\'s content';

  @override
  String get weeklyContentPastWeeks => 'Past weeks';

  @override
  String get weeklyContentNoneYetTitle => 'No past weeks yet';

  @override
  String get weeklyContentNoneYetBody => 'This is the first week. New content arrives every week, so check back soon!';

  @override
  String weeklyContentWeekLabel(int n) {
    return 'Week $n';
  }
}
