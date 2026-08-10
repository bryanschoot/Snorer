import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @headerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep, made clear.'**
  String get headerTitle;

  /// No description provided for @headerDescription.
  ///
  /// In en, this message translates to:
  /// **'Record your night and discover what happens. Everything stays on your phone.'**
  String get headerDescription;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @deleteAllRecordings.
  ///
  /// In en, this message translates to:
  /// **'Delete all recordings'**
  String get deleteAllRecordings;

  /// No description provided for @deleteRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recording?'**
  String get deleteRecordingTitle;

  /// No description provided for @deleteRecordingContent.
  ///
  /// In en, this message translates to:
  /// **'The local audio file and its entry will be removed from this device.'**
  String get deleteRecordingContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all recordings?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllContent.
  ///
  /// In en, this message translates to:
  /// **'All local audio files and entries will be permanently removed from this device.'**
  String get deleteAllContent;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is turned off'**
  String get permissionTitle;

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow access before starting a sleep recording. Nothing is sent to a server.'**
  String get permissionBody;

  /// No description provided for @recordingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SLEEP RECORDING'**
  String get recordingEyebrow;

  /// No description provided for @recordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s recording'**
  String get recordingTitle;

  /// No description provided for @recordingBusy.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingBusy;

  /// No description provided for @recordingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get recordingReady;

  /// No description provided for @recordingInProgressHint.
  ///
  /// In en, this message translates to:
  /// **'audio is saved locally'**
  String get recordingInProgressHint;

  /// No description provided for @recordingReadyHint.
  ///
  /// In en, this message translates to:
  /// **'ready when you go to sleep'**
  String get recordingReadyHint;

  /// No description provided for @finishRecording.
  ///
  /// In en, this message translates to:
  /// **'Finishing recording…'**
  String get finishRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @prepareMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Preparing microphone…'**
  String get prepareMicrophone;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start sleep recording'**
  String get startRecording;

  /// No description provided for @foregroundServiceNote.
  ///
  /// In en, this message translates to:
  /// **'Android keeps the recording active with a visible system notification, even when your screen is locked.'**
  String get foregroundServiceNote;

  /// No description provided for @detectionReady.
  ///
  /// In en, this message translates to:
  /// **'Snoring and speech are detected locally.'**
  String get detectionReady;

  /// No description provided for @detectionLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing sound model…'**
  String get detectionLoading;

  /// No description provided for @detectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Recording works, but sound detection is unavailable.'**
  String get detectionUnavailable;

  /// No description provided for @detectionIdle.
  ///
  /// In en, this message translates to:
  /// **'Sound detection is processed on this device only.'**
  String get detectionIdle;

  /// No description provided for @overviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overviewEyebrow;

  /// No description provided for @localRecordings.
  ///
  /// In en, this message translates to:
  /// **'Local recordings'**
  String get localRecordings;

  /// The number of recorded nights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String recordingsCount(int count);

  /// No description provided for @emptyRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first night will appear here'**
  String get emptyRecordingTitle;

  /// No description provided for @emptyRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'Start a sleep recording before you go to bed. After stopping, the recording and detected sound events will appear here.'**
  String get emptyRecordingBody;

  /// No description provided for @pauseRecording.
  ///
  /// In en, this message translates to:
  /// **'Pause recording'**
  String get pauseRecording;

  /// No description provided for @playRecording.
  ///
  /// In en, this message translates to:
  /// **'Play recording'**
  String get playRecording;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No clear snoring or speech moments were detected.'**
  String get noEvents;

  /// No description provided for @deleteRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get deleteRecordingTooltip;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @footerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data stays yours'**
  String get footerTitle;

  /// No description provided for @footerBody.
  ///
  /// In en, this message translates to:
  /// **'Snorer works without an account, cloud sync, or ads. You decide when a recording is deleted.'**
  String get footerBody;

  /// No description provided for @settingsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Snorer'**
  String get settingsIntroTitle;

  /// No description provided for @settingsIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the app calm for the moment you use it.'**
  String get settingsIntroBody;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get languageHint;

  /// No description provided for @recordingSize.
  ///
  /// In en, this message translates to:
  /// **'Recording size'**
  String get recordingSize;

  /// No description provided for @recordingSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the unit used for recording sizes.'**
  String get recordingSizeHint;

  /// No description provided for @recordingSizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'Megabytes (MB)'**
  String get recordingSizeMegabytes;

  /// No description provided for @recordingSizeGigabytes.
  ///
  /// In en, this message translates to:
  /// **'Gigabytes (GB)'**
  String get recordingSizeGigabytes;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone'**
  String get privacyPhoneTitle;

  /// No description provided for @privacyPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Recordings and sound analysis are stored locally. Snorer uses no account or cloud sync.'**
  String get privacyPhoneBody;

  /// No description provided for @privacyMicrophoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone only while recording'**
  String get privacyMicrophoneTitle;

  /// No description provided for @privacyMicrophoneBody.
  ///
  /// In en, this message translates to:
  /// **'Android shows a notification while a sleep recording is active.'**
  String get privacyMicrophoneBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Snorer'**
  String get about;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep, made clear and stored locally'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'A simple sleep recorder without ads or an account.'**
  String get aboutBody;
  /// No description provided for @aboutAuthorLabel.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get aboutAuthorLabel;

  /// No description provided for @aboutAuthor.
  ///
  /// In en, this message translates to:
  /// **'Bryan Schoot'**
  String get aboutAuthor;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuildLabel;


  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeHurm.
  ///
  /// In en, this message translates to:
  /// **'Hurm'**
  String get themeHurm;

  /// No description provided for @themeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Calm for the night'**
  String get themeDarkDescription;

  /// No description provided for @themeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Bright during the day'**
  String get themeLightDescription;

  /// No description provided for @themeHurmDescription.
  ///
  /// In en, this message translates to:
  /// **'Warm and soft'**
  String get themeHurmDescription;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageDutch;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @soundEventSnoring.
  ///
  /// In en, this message translates to:
  /// **'Snoring'**
  String get soundEventSnoring;

  /// No description provided for @soundEventSpeech.
  ///
  /// In en, this message translates to:
  /// **'Speech'**
  String get soundEventSpeech;

  /// The number of detected snoring moments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 snoring moment} other{{count} snoring moments}}'**
  String snoringMoments(int count);

  /// The number of detected speech moments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 speech moment} other{{count} speech moments}}'**
  String speechMoments(int count);
  /// No description provided for @detectedSounds.
  ///
  /// In en, this message translates to:
  /// **'Detected sounds'**
  String get detectedSounds;

  /// No description provided for @allEvents.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEvents;

  /// No description provided for @previousSoundEvent.
  ///
  /// In en, this message translates to:
  /// **'Previous sound'**
  String get previousSoundEvent;

  /// No description provided for @nextSoundEvent.
  ///
  /// In en, this message translates to:
  /// **'Next sound'**
  String get nextSoundEvent;

  /// The current position in the filtered detected sounds.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String soundEventPosition(int current, int total);

  /// No description provided for @durationHoursUnit.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get durationHoursUnit;

  /// No description provided for @durationMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get durationMinutesUnit;

  /// No description provided for @durationSecondsUnit.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get durationSecondsUnit;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Snorer recording'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows when Snorer is recording during the night.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Snorer is recording'**
  String get notificationTitle;

  /// No description provided for @notificationText.
  ///
  /// In en, this message translates to:
  /// **'Sleep sounds are stored locally.'**
  String get notificationText;

  /// No description provided for @errorMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow Snorer to access the microphone to record sleep sounds locally.'**
  String get errorMicrophonePermission;

  /// No description provided for @errorRecordingStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording'**
  String get errorRecordingStart;

  /// No description provided for @errorRecordingStop.
  ///
  /// In en, this message translates to:
  /// **'Could not stop recording'**
  String get errorRecordingStop;

  /// No description provided for @errorRecordingInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'The recording did not produce a valid file.'**
  String get errorRecordingInvalidFile;

  /// No description provided for @errorPlaybackLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare playback'**
  String get errorPlaybackLoad;

  /// No description provided for @errorPlayback.
  ///
  /// In en, this message translates to:
  /// **'Could not play recording'**
  String get errorPlayback;

  /// No description provided for @errorPlaybackSeek.
  ///
  /// In en, this message translates to:
  /// **'Could not seek to this moment'**
  String get errorPlaybackSeek;

  /// No description provided for @errorLibraryLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not read local recording history.'**
  String get errorLibraryLoad;

  /// No description provided for @errorDeleteRecording.
  ///
  /// In en, this message translates to:
  /// **'This recording could not be removed from the device.'**
  String get errorDeleteRecording;

  /// No description provided for @errorDeleteAllRecordings.
  ///
  /// In en, this message translates to:
  /// **'Not all local recordings could be removed.'**
  String get errorDeleteAllRecordings;

  /// No description provided for @errorPersistRecording.
  ///
  /// In en, this message translates to:
  /// **'The recording was created, but the local index could not be updated.'**
  String get errorPersistRecording;

  /// An error message with technical detail.
  ///
  /// In en, this message translates to:
  /// **'{message}: {detail}'**
  String errorWithDetail(String message, String detail);

  /// No description provided for @updateCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckTitle;

  /// No description provided for @updateCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Snorer checks GitHub for a newer release.'**
  String get updateCheckBody;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateCheckingBody.
  ///
  /// In en, this message translates to:
  /// **'Looking for a newer Snorer release.'**
  String get updateCheckingBody;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Snorer is up to date'**
  String get updateUpToDate;

  /// No description provided for @updateUpToDateBody.
  ///
  /// In en, this message translates to:
  /// **'You are using the latest available release.'**
  String get updateUpToDateBody;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check unavailable'**
  String get updateCheckFailed;

  /// No description provided for @updateCheckFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Try again when you have an internet connection.'**
  String get updateCheckFailedBody;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Snorer {version} is available. Open GitHub to view the release.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateOpen.
  ///
  /// In en, this message translates to:
  /// **'View release'**
  String get updateOpen;

  /// No description provided for @updateOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the GitHub release.'**
  String get updateOpenFailed;
  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get updateInstall;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Preparing update…'**
  String get updateInstalling;

  /// No description provided for @updateInstallingBody.
  ///
  /// In en, this message translates to:
  /// **'The verified APK is downloading. Android's installer will open next.'**
  String get updateInstallingBody;

  /// No description provided for @updateInstallStarted.
  ///
  /// In en, this message translates to:
  /// **'Android installer opened'**
  String get updateInstallStarted;

  /// No description provided for @updateInstallStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Finish the update in Android's installer.'**
  String get updateInstallStartedBody;

  /// No description provided for @updateInstallPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow installation'**
  String get updateInstallPermission;

  /// No description provided for @updateInstallPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Android needs permission to install apps from Snorer. Allow it, then tap Install update again.'**
  String get updateInstallPermissionBody;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Update installation failed'**
  String get updateInstallFailed;

  /// No description provided for @updateInstallFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The update could not be installed. Try again or view the release.'**
  String get updateInstallFailedBody;

  /// No description provided for @updateInstallRetry.
  ///
  /// In en, this message translates to:
  /// **'Try installation again'**
  String get updateInstallRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
