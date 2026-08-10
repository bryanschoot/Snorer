# Snorer

Offline-first Android sleep recording with local YAMNet sound analysis.

## Development

The project uses the Flutter stable toolchain and requires Dart 3.12 or newer.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The app requests microphone and notification permissions before recording. A
recording runs through an Android microphone foreground service so it can
continue when the screen is locked. Audio is stored as a private PCM WAV file;
YAMNet inference runs locally and stores only snoring/speech events in `SharedPreferences`.

## Structure

- `lib/domain/`: immutable recording models and YAMNet event rules.
- `lib/data/`: local metadata repository, PCM/WAV recorder, foreground service,
  TFLite model adapter, and audio playback.
- `lib/presentation/`: `ChangeNotifier` view models, the recording interface,
  playback controls, and settings with persisted dark, light, Hurm, Dutch, English,
  and recording-size-unit choices.
- `test/`: model, sound-detection, recording UI, playback, language, and theme
  interaction tests.

The settings screen lets users choose a dark, light, or Hurm theme, switch between
Dutch and English, and choose whether recording sizes are shown in MB or GB. These
choices are stored locally and restored on the next launch. Each recording entry
shows the size of its local audio file. The playback waveform shows the current
audio position and accepts tap-to-seek input.

The release build falls back to Flutter's debug signing configuration when no
keystore is provided. This produces an installable APK for testing and GitHub
Releases, but it is not suitable for Google Play publication or production
updates. Configure these repository secrets when a stable application signing
identity is needed:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Pushing a `vMAJOR.MINOR.PATCH` tag starts
`.github/workflows/android-release.yml`. The tag must match the version in
`pubspec.yaml`. The workflow runs analysis and tests, builds the release APK,
verifies its signature, publishes a SHA-256 checksum, and attaches both files
to a GitHub Release.
