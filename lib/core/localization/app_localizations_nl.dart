// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get settings => 'Instellingen';

  @override
  String get headerTitle => 'Slaap inzichtelijk.';

  @override
  String get headerDescription =>
      'Neem je nacht op en ontdek wat er gebeurt. Alles blijft lokaal op je telefoon.';

  @override
  String get local => 'Lokaal';

  @override
  String get deleteAllRecordings => 'Alle opnames verwijderen';

  @override
  String get deleteRecordingTitle => 'Opname verwijderen?';

  @override
  String get deleteRecordingContent =>
      'Het lokale audiobestand en de vermelding worden van dit apparaat verwijderd.';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get deleteAllTitle => 'Alle opnames verwijderen?';

  @override
  String get deleteAllContent =>
      'Alle lokale audiobestanden en vermeldingen worden permanent van dit apparaat verwijderd.';

  @override
  String get deleteAll => 'Alles verwijderen';

  @override
  String get permissionTitle => 'Microfoontoegang staat nog uit';

  @override
  String get permissionBody =>
      'Geef toestemming voordat je een slaapopname start. Er wordt niets naar een server gestuurd.';

  @override
  String get recordingEyebrow => 'SLAAPOPNAME';

  @override
  String get recordingTitle => 'Opname voor vannacht';

  @override
  String get recordingBusy => 'Bezig';

  @override
  String get recordingReady => 'Gereed';

  @override
  String get recordingInProgressHint => 'geluid wordt lokaal opgeslagen';

  @override
  String get recordingReadyHint => 'klaar wanneer jij gaat slapen';

  @override
  String get finishRecording => 'Opname afronden…';

  @override
  String get stopRecording => 'Opname stoppen';

  @override
  String get prepareMicrophone => 'Microfoon klaarmaken…';

  @override
  String get startRecording => 'Slaapopname starten';

  @override
  String get foregroundServiceNote =>
      'Android houdt de opname actief met een zichtbare systeemmelding, ook als je scherm vergrendelt.';

  @override
  String get detectionReady => 'Snurken en praten worden lokaal gedetecteerd.';

  @override
  String get detectionLoading => 'Geluidsmodel voorbereiden…';

  @override
  String get detectionUnavailable =>
      'Opnemen werkt, maar geluidsdetectie is niet beschikbaar.';

  @override
  String get detectionIdle =>
      'Geluidsdetectie wordt alleen op dit apparaat verwerkt.';

  @override
  String get overviewEyebrow => 'OVERZICHT';

  @override
  String get localRecordings => 'Lokale opnames';

  @override
  String recordingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nachten',
      one: '1 nacht',
    );
    return '$_temp0';
  }

  @override
  String get emptyRecordingTitle => 'Je eerste nacht verschijnt hier';

  @override
  String get emptyRecordingBody =>
      'Start een opname voordat je gaat slapen. Na het stoppen verschijnen de opname en gedetecteerde geluiden hier.';

  @override
  String get pauseRecording => 'Pauzeer opname';

  @override
  String get playRecording => 'Speel opname af';

  @override
  String get noEvents => 'Geen duidelijke snurk- of praatmomenten herkend.';

  @override
  String get deleteRecordingTooltip => 'Verwijder opname';

  @override
  String get errorTitle => 'Er ging iets mis';

  @override
  String get footerTitle => 'Jouw data blijft van jou';

  @override
  String get footerBody =>
      'Snorer werkt zonder account, cloudsync of advertenties. Jij bepaalt wanneer een opname wordt verwijderd.';

  @override
  String get settingsIntroTitle => 'Jouw Snorer';

  @override
  String get settingsIntroBody =>
      'Maak de app rustig voor het moment waarop je hem gebruikt.';

  @override
  String get appearance => 'Uiterlijk';

  @override
  String get language => 'Taal';

  @override
  String get languageHint => 'Kies de taal van de app.';

  @override
  String get recordingSize => 'Grootte van opnames';

  @override
  String get recordingSizeHint =>
      'Kies de eenheid waarin de grootte van opnames wordt weergegeven.';

  @override
  String get recordingSizeMegabytes => 'Megabytes (MB)';

  @override
  String get recordingSizeGigabytes => 'Gigabytes (GB)';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPhoneTitle => 'Alles blijft op je telefoon';

  @override
  String get privacyPhoneBody =>
      'Opnames en geluidsanalyse worden lokaal opgeslagen. Snorer gebruikt geen account of cloudsync.';

  @override
  String get privacyMicrophoneTitle => 'Microfoon alleen tijdens opnemen';

  @override
  String get privacyMicrophoneBody =>
      'Android toont een melding zolang een slaapopname actief is.';

  @override
  String get about => 'Over Snorer';

  @override
  String get aboutTitle => 'Slaap inzichtelijk, lokaal opgeslagen';

  @override
  String get aboutBody =>
      'Een eenvoudige slaaprecorder zonder advertenties en zonder account.';
  @override
  String get aboutAuthorLabel => 'Gemaakt door';

  @override
  String get aboutAuthor => 'Bryan Schoot';

  @override
  String get aboutVersionLabel => 'Versie';

  @override
  String get aboutBuildLabel => 'Build';


  @override
  String get themeDark => 'Donker';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeHurm => 'Hurm';

  @override
  String get themeDarkDescription => 'Rustig voor de nacht';

  @override
  String get themeLightDescription => 'Helder overdag';

  @override
  String get themeHurmDescription => 'Warm en zacht';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get soundEventSnoring => 'Snurken';

  @override
  String get soundEventSpeech => 'Praten';

  @override
  String snoringMoments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count snurkmomenten',
      one: '1 snurkmoment',
    );
    return '$_temp0';
  }

  @override
  String speechMoments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count praatmomenten',
      one: '1 praatmoment',
    );
    return '$_temp0';
  }
  @override
  String get detectedSounds => 'Gedetecteerde geluiden';

  @override
  String get allEvents => 'Alle';

  @override
  String get previousSoundEvent => 'Vorig geluid';

  @override
  String get nextSoundEvent => 'Volgend geluid';

  @override
  String soundEventPosition(int current, int total) =>
      '$current van $total';

  @override
  String get durationHoursUnit => 'u';

  @override
  String get durationMinutesUnit => 'm';

  @override
  String get durationSecondsUnit => 's';

  @override
  String get notificationChannelName => 'Snorer-opname';

  @override
  String get notificationChannelDescription =>
      'Toont wanneer Snorer een nachtelijke opname maakt.';

  @override
  String get notificationTitle => 'Snorer neemt op';

  @override
  String get notificationText => 'Slaapgeluiden worden lokaal opgeslagen.';

  @override
  String get errorMicrophonePermission =>
      'Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal op te nemen.';

  @override
  String get errorRecordingStart => 'Opname starten lukt niet';

  @override
  String get errorRecordingStop => 'Opname stoppen lukt niet';

  @override
  String get errorRecordingInvalidFile =>
      'De opname heeft geen geldig bestand opgeleverd.';

  @override
  String get errorPlaybackLoad => 'Afspelen voorbereiden lukt niet';

  @override
  String get errorPlayback => 'Afspelen lukt niet';

  @override
  String get errorPlaybackSeek => 'Naar dit moment springen lukt niet';

  @override
  String get errorLibraryLoad =>
      'De lokale opnamegeschiedenis kon niet worden gelezen.';

  @override
  String get errorDeleteRecording =>
      'Deze opname kon niet van het apparaat worden verwijderd.';

  @override
  String get errorDeleteAllRecordings =>
      'Niet alle lokale opnames konden worden verwijderd.';

  @override
  String get errorPersistRecording =>
      'De opname is gemaakt, maar de lokale index kon niet worden bijgewerkt.';

  @override
  String errorWithDetail(String message, String detail) {
    return '$message: $detail';
  }

  @override
  String get updateCheckTitle => 'Controleren op updates';

  @override
  String get updateCheckBody =>
      'Snorer kijkt op GitHub of er een nieuwere release is.';

  @override
  String get updateChecking => 'Updates controleren…';

  @override
  String get updateCheckingBody =>
      'Snorer zoekt naar een nieuwere release.';

  @override
  String get updateUpToDate => 'Snorer is bijgewerkt';

  @override
  String get updateUpToDateBody =>
      'Je gebruikt de nieuwste beschikbare release.';

  @override
  String get updateCheckFailed => 'Updatecontrole niet beschikbaar';

  @override
  String get updateCheckFailedBody =>
      'Probeer het opnieuw met een internetverbinding.';

  @override
  String get updateAvailableTitle => 'Nieuwe versie beschikbaar';

  @override
  String updateAvailableBody(String version) {
    return 'Snorer $version is beschikbaar. Open GitHub om de release te bekijken.';
  }

  @override
  String get updateOpen => 'Release bekijken';

  @override
  String get updateOpenFailed => 'De GitHub-release kon niet worden geopend.';
  @override
  String get updateInstall => 'Update installeren';

  @override
  String get updateInstalling => 'Update voorbereiden…';

  @override
  String get updateInstallingBody =>
      'De gecontroleerde APK wordt gedownload. Daarna opent de Android-installatie.';

  @override
  String get updateInstallStarted => 'Android-installatie geopend';

  @override
  String get updateInstallStartedBody =>
      'Rond de update af in de Android-installatie.';

  @override
  String get updateInstallPermission => 'Installatie toestaan';

  @override
  String get updateInstallPermissionBody =>
      'Android heeft toestemming nodig om apps vanuit Snorer te installeren. Sta dit toe en tik daarna opnieuw op Update installeren.';

  @override
  String get updateInstallFailed => 'Update installeren mislukt';

  @override
  String get updateInstallFailedBody =>
      'De update kon niet worden geïnstalleerd. Probeer het opnieuw of bekijk de release.';

  @override
  String get updateInstallRetry => 'Opnieuw installeren';
}
