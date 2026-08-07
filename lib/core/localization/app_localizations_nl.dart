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
      'Alle lokale audiobestanden en labels worden permanent van dit apparaat verwijderd.';

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
  String get detectionReady => 'Snurken en praten worden lokaal gemarkeerd.';

  @override
  String get detectionLoading => 'Geluidsmodel wordt klaargemaakt…';

  @override
  String get detectionUnavailable =>
      'Opname werkt, maar geluidslabels zijn niet beschikbaar.';

  @override
  String get detectionIdle =>
      'Geluidslabels worden alleen op dit apparaat verwerkt.';

  @override
  String get privacyTitle => 'Privé en lokaal';

  @override
  String get privacyBody =>
      'Audio en geluidslabels blijven op je telefoon. Snorer gebruikt geen account, advertenties of cloudanalyse.';

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
      'Start een slaapopname voordat je gaat slapen. Na het stoppen vind je de opname en lokale geluidslabels hier terug.';

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
  String get privacy => 'Privacy';

  @override
  String get privacyPhoneTitle => 'Alles blijft op je telefoon';

  @override
  String get privacyPhoneBody =>
      'Opnames, labels en geluidsanalyse worden lokaal opgeslagen. Snorer gebruikt geen account of cloudsync.';

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
  String get recordingLabelSnoring => 'Snurken';

  @override
  String get recordingLabelSpeech => 'Praten';

  @override
  String get recordingLabelNone => 'Nog niet gelabeld';

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
}
