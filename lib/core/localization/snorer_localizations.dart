import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' as date_data;
import 'package:intl/intl.dart' as intl;

import '../../domain/models/recording.dart';
import '../errors/snorer_error.dart';
import '../theme/app_theme.dart';
import 'app_localizations.dart';
import 'snorer_language.dart';

class SnorerLocalizations {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('nl'));
  }

  static const delegate = AppLocalizations.delegate;
  static const supportedLocales = AppLocalizations.supportedLocales;
}

extension SnorerAppLocalizations on AppLocalizations {
  String eventCount(SoundEventKind kind, int count) => switch (kind) {
    SoundEventKind.snoring => snoringMoments(count),
    SoundEventKind.speech => speechMoments(count),
  };

  String recordingLabel(RecordingLabel? label) => switch (label) {
    RecordingLabel.snoring => recordingLabelSnoring,
    RecordingLabel.sleepTalking => recordingLabelSpeech,
    null => recordingLabelNone,
  };

  String themeLabel(SnorerThemeMode mode) => switch (mode) {
    SnorerThemeMode.dark => themeDark,
    SnorerThemeMode.light => themeLight,
    SnorerThemeMode.pink => themeHurm,
  };

  String themeDescription(SnorerThemeMode mode) => switch (mode) {
    SnorerThemeMode.dark => themeDarkDescription,
    SnorerThemeMode.light => themeLightDescription,
    SnorerThemeMode.pink => themeHurmDescription,
  };

  String languageLabel(SnorerLanguage language) => switch (language) {
    SnorerLanguage.dutch => languageDutch,
    SnorerLanguage.english => languageEnglish,
  };

  String formatDuration(double totalSeconds) {
    final safeSeconds = totalSeconds.isFinite ? totalSeconds : 0;
    final seconds = safeSeconds.round().clamp(0, 863999).toInt();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    if (hours > 0) {
      return '$hours$durationHoursUnit '
          '${minutes.toString().padLeft(2, '0')}$durationMinutesUnit';
    }
    return '$minutes$durationMinutesUnit '
        '${remainder.toString().padLeft(2, '0')}$durationSecondsUnit';
  }

  String formatDate(DateTime value) {
    date_data.initializeDateFormatting(localeName);
    return intl.DateFormat('d MMM · HH:mm', localeName).format(value.toLocal());
  }

  String errorMessage(SnorerError error) {
    final message = switch (error.code) {
      SnorerErrorCode.microphonePermission => errorMicrophonePermission,
      SnorerErrorCode.recordingStart => errorRecordingStart,
      SnorerErrorCode.recordingStop => errorRecordingStop,
      SnorerErrorCode.recordingInvalidFile => errorRecordingInvalidFile,
      SnorerErrorCode.playbackLoad => errorPlaybackLoad,
      SnorerErrorCode.playback => errorPlayback,
      SnorerErrorCode.playbackSeek => errorPlaybackSeek,
      SnorerErrorCode.libraryLoad => errorLibraryLoad,
      SnorerErrorCode.deleteRecording => errorDeleteRecording,
      SnorerErrorCode.deleteAllRecordings => errorDeleteAllRecordings,
      SnorerErrorCode.persistRecording => errorPersistRecording,
    };
    final detail = error.detail;
    if (detail == null || detail.isEmpty) return message;
    return errorWithDetail(message, detail);
  }
}
