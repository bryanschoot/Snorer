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
YAMNet inference runs locally and stores only snoring/speech events and manual
labels in `SharedPreferences`.

## Structure

- `lib/domain/`: immutable recording models and YAMNet event rules.
- `lib/data/`: local metadata repository, PCM/WAV recorder, foreground service,
  TFLite model adapter, and audio playback.
- `lib/presentation/`: `ChangeNotifier` view model and the Dutch dark recording
  interface.
- `test/`: model, sound-detection, and widget interaction tests.

The release build currently uses Flutter's debug signing configuration. CI
signing should provide a release keystore through GitHub Secrets before a
public release tag is created.

## Release

Pushing a `vMAJOR.MINOR.PATCH` tag starts
`.github/workflows/android-release.yml`. The tag must match the version in
`pubspec.yaml`. Configure these repository secrets before triggering a release:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The workflow runs analysis and tests, builds the release APK, verifies its
signature, publishes a SHA-256 checksum, and attaches both files to a GitHub
Release.
