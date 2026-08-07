enum SnorerErrorCode {
  microphonePermission,
  recordingStart,
  recordingStop,
  recordingInvalidFile,
  playbackLoad,
  playback,
  playbackSeek,
  libraryLoad,
  deleteRecording,
  deleteAllRecordings,
  persistRecording,
}

class SnorerError {
  const SnorerError(this.code, {this.detail});

  final SnorerErrorCode code;
  final String? detail;
}
