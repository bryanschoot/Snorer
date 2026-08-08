// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get headerTitle => 'Sleep, made clear.';

  @override
  String get headerDescription =>
      'Record your night and discover what happens. Everything stays on your phone.';

  @override
  String get local => 'Local';

  @override
  String get deleteAllRecordings => 'Delete all recordings';

  @override
  String get deleteRecordingTitle => 'Delete recording?';

  @override
  String get deleteRecordingContent =>
      'The local audio file and its entry will be removed from this device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAllTitle => 'Delete all recordings?';

  @override
  String get deleteAllContent =>
      'All local audio files and labels will be permanently removed from this device.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get permissionTitle => 'Microphone access is turned off';

  @override
  String get permissionBody =>
      'Allow access before starting a sleep recording. Nothing is sent to a server.';

  @override
  String get recordingEyebrow => 'SLEEP RECORDING';

  @override
  String get recordingTitle => 'Tonight\'s recording';

  @override
  String get recordingBusy => 'Recording';

  @override
  String get recordingReady => 'Ready';

  @override
  String get recordingInProgressHint => 'audio is saved locally';

  @override
  String get recordingReadyHint => 'ready when you go to sleep';

  @override
  String get finishRecording => 'Finishing recording…';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get prepareMicrophone => 'Preparing microphone…';

  @override
  String get startRecording => 'Start sleep recording';

  @override
  String get foregroundServiceNote =>
      'Android keeps the recording active with a visible system notification, even when your screen is locked.';

  @override
  String get detectionReady => 'Snoring and speech are marked locally.';

  @override
  String get detectionLoading => 'Preparing sound model…';

  @override
  String get detectionUnavailable =>
      'Recording works, but sound labels are unavailable.';

  @override
  String get detectionIdle => 'Sound labels are processed on this device only.';

  @override
  String get overviewEyebrow => 'OVERVIEW';

  @override
  String get localRecordings => 'Local recordings';

  @override
  String recordingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get emptyRecordingTitle => 'Your first night will appear here';

  @override
  String get emptyRecordingBody =>
      'Start a sleep recording before you go to bed. After stopping, the recording and local sound labels will appear here.';

  @override
  String get pauseRecording => 'Pause recording';

  @override
  String get playRecording => 'Play recording';

  @override
  String get noEvents => 'No clear snoring or speech moments were detected.';

  @override
  String get deleteRecordingTooltip => 'Delete recording';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get footerTitle => 'Your data stays yours';

  @override
  String get footerBody =>
      'Snorer works without an account, cloud sync, or ads. You decide when a recording is deleted.';

  @override
  String get settingsIntroTitle => 'Your Snorer';

  @override
  String get settingsIntroBody =>
      'Keep the app calm for the moment you use it.';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get languageHint => 'Choose the app language.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPhoneTitle => 'Everything stays on your phone';

  @override
  String get privacyPhoneBody =>
      'Recordings, labels, and sound analysis are stored locally. Snorer uses no account or cloud sync.';

  @override
  String get privacyMicrophoneTitle => 'Microphone only while recording';

  @override
  String get privacyMicrophoneBody =>
      'Android shows a notification while a sleep recording is active.';

  @override
  String get about => 'About Snorer';

  @override
  String get aboutTitle => 'Sleep, made clear and stored locally';

  @override
  String get aboutBody => 'A simple sleep recorder without ads or an account.';
  @override
  String get aboutAuthorLabel => 'Created by';

  @override
  String get aboutAuthor => 'Bryan Schoot';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutBuildLabel => 'Build';


  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeHurm => 'Hurm';

  @override
  String get themeDarkDescription => 'Calm for the night';

  @override
  String get themeLightDescription => 'Bright during the day';

  @override
  String get themeHurmDescription => 'Warm and soft';

  @override
  String get languageDutch => 'Dutch';

  @override
  String get languageEnglish => 'English';

  @override
  String get recordingLabelSnoring => 'Snoring';

  @override
  String get recordingLabelSpeech => 'Speech';

  @override
  String get recordingLabelNone => 'Not labeled yet';

  @override
  String snoringMoments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count snoring moments',
      one: '1 snoring moment',
    );
    return '$_temp0';
  }

  @override
  String speechMoments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count speech moments',
      one: '1 speech moment',
    );
    return '$_temp0';
  }
  @override
  String get detectedSounds => 'Detected sounds';

  @override
  String get allEvents => 'All';

  @override
  String get previousSoundEvent => 'Previous sound';

  @override
  String get nextSoundEvent => 'Next sound';

  @override
  String soundEventPosition(int current, int total) =>
      '$current of $total';

  @override
  String get durationHoursUnit => 'h';

  @override
  String get durationMinutesUnit => 'm';

  @override
  String get durationSecondsUnit => 's';

  @override
  String get notificationChannelName => 'Snorer recording';

  @override
  String get notificationChannelDescription =>
      'Shows when Snorer is recording during the night.';

  @override
  String get notificationTitle => 'Snorer is recording';

  @override
  String get notificationText => 'Sleep sounds are stored locally.';

  @override
  String get errorMicrophonePermission =>
      'Allow Snorer to access the microphone to record sleep sounds locally.';

  @override
  String get errorRecordingStart => 'Could not start recording';

  @override
  String get errorRecordingStop => 'Could not stop recording';

  @override
  String get errorRecordingInvalidFile =>
      'The recording did not produce a valid file.';

  @override
  String get errorPlaybackLoad => 'Could not prepare playback';

  @override
  String get errorPlayback => 'Could not play recording';

  @override
  String get errorPlaybackSeek => 'Could not seek to this moment';

  @override
  String get errorLibraryLoad => 'Could not read local recording history.';

  @override
  String get errorDeleteRecording =>
      'This recording could not be removed from the device.';

  @override
  String get errorDeleteAllRecordings =>
      'Not all local recordings could be removed.';

  @override
  String get errorPersistRecording =>
      'The recording was created, but the local index could not be updated.';

  @override
  String errorWithDetail(String message, String detail) {
    return '$message: $detail';
  }

  @override
  String get updateCheckTitle => 'Check for updates';

  @override
  String get updateCheckBody => 'Snorer checks GitHub for a newer release.';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateCheckingBody => 'Looking for a newer Snorer release.';

  @override
  String get updateUpToDate => 'Snorer is up to date';

  @override
  String get updateUpToDateBody =>
      'You are using the latest available release.';

  @override
  String get updateCheckFailed => 'Update check unavailable';

  @override
  String get updateCheckFailedBody =>
      'Try again when you have an internet connection.';

  @override
  String get updateAvailableTitle => 'New version available';

  @override
  String updateAvailableBody(String version) {
    return 'Snorer $version is available. Open GitHub to view the release.';
  }

  @override
  String get updateOpen => 'View release';

  @override
  String get updateOpenFailed => 'Could not open the GitHub release.';
  @override
  String get updateInstall => 'Install update';

  @override
  String get updateInstalling => 'Preparing update…';

  @override
  String get updateInstallingBody =>
      "The verified APK is downloading. Android's installer will open next.";

  @override
  String get updateInstallStarted => 'Android installer opened';

  @override
  String get updateInstallStartedBody =>
      "Finish the update in Android's installer.";

  @override
  String get updateInstallPermission => 'Allow installation';

  @override
  String get updateInstallPermissionBody =>
      'Android needs permission to install apps from Snorer. Allow it, then tap Install update again.';

  @override
  String get updateInstallFailed => 'Update installation failed';

  @override
  String get updateInstallFailedBody =>
      'The update could not be installed. Try again or view the release.';

  @override
  String get updateInstallRetry => 'Try installation again';
}
