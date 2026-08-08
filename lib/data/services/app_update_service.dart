import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  factory AppVersion.parse(String value) {
    final match = RegExp(
      r'^v?([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+[0-9]+)?$',
    ).firstMatch(value.trim());
    if (match == null) {
      throw FormatException('Invalid app version: $value');
    }
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(AppVersion other) {
    final majorComparison = major.compareTo(other.major);
    if (majorComparison != 0) return majorComparison;
    final minorComparison = minor.compareTo(other.minor);
    if (minorComparison != 0) return minorComparison;
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.releaseUrl,
    this.apkUrl,
    this.checksumUrl,
    this.publishedAt,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'];
    final htmlUrl = json['html_url'];
    if (tagName is! String || htmlUrl is! String) {
      throw const FormatException('GitHub release is missing required fields.');
    }
    if (json['draft'] == true || json['prerelease'] == true) {
      throw const FormatException('GitHub release is not a stable release.');
    }

    final releaseUrl = _trustedGitHubUrl(htmlUrl);
    if (releaseUrl == null) {
      throw const FormatException('GitHub release URL is not trusted.');
    }

    Uri? apkUrl;
    Uri? checksumUrl;
    String? apkName;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = asset['name'];
        final url = _trustedDownloadUrl(asset['browser_download_url']);
        if (name is String &&
            name.toLowerCase().endsWith('.apk') &&
            url != null) {
          apkName = name;
          apkUrl = url;
          break;
        }
      }
      if (apkName != null) {
        for (final asset in assets) {
          if (asset is! Map) continue;
          final name = asset['name'];
          final url = _trustedDownloadUrl(asset['browser_download_url']);
          if (name == '$apkName.sha256' && url != null) {
            checksumUrl = url;
            break;
          }
        }
      }
    }

    final publishedAtValue = json['published_at'];
    return AppRelease(
      tagName: tagName,
      version: AppVersion.parse(tagName),
      releaseUrl: releaseUrl,
      apkUrl: apkUrl,
      checksumUrl: checksumUrl,
      publishedAt: publishedAtValue is String
          ? DateTime.tryParse(publishedAtValue)
          : null,
    );
  }

  final String tagName;
  final AppVersion version;
  final Uri releaseUrl;
  final Uri? apkUrl;
  final Uri? checksumUrl;
  final DateTime? publishedAt;

  bool get canInstall => apkUrl != null && checksumUrl != null;
}

abstract interface class AppUpdateService {
  Future<AppRelease?> checkForUpdate(String currentVersion);

  Future<ApkInstallResult> install(AppRelease release);

  void dispose();
}

class GitHubAppUpdateService implements AppUpdateService {
  GitHubAppUpdateService({
    http.Client? client,
    Uri? endpoint,
    ApkInstaller? installer,
    Future<Directory> Function()? temporaryDirectoryProvider,
  }) : _client = client ?? http.Client(),
       _endpoint =
           endpoint ??
           Uri.parse(
             'https://api.github.com/repos/bryanschoot/Snorer/releases/latest',
           ),
       _installer = installer ?? const AndroidApkInstaller(),
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  final http.Client _client;
  final Uri _endpoint;
  final ApkInstaller _installer;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  String? _cachedApkPath;
  String? _cachedReleaseTag;

  @override
  Future<AppRelease?> checkForUpdate(String currentVersion) async {
    final response = await _client.get(
      _endpoint,
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'Snorer/$currentVersion',
      },
    );
    if (response.statusCode != 200) {
      throw AppUpdateException(
        'GitHub release check failed with HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GitHub release response is not an object.');
    }

    final release = AppRelease.fromJson(decoded);
    final installedVersion = AppVersion.parse(currentVersion);
    return release.version.compareTo(installedVersion) > 0 ? release : null;
  }

  @override
  Future<ApkInstallResult> install(AppRelease release) async {
    if (!release.canInstall) {
      throw const AppUpdateException(
        'This release does not provide a verified APK download.',
      );
    }

    final apkPath = await _downloadVerifiedApk(release);
    return _installer.install(apkPath);
  }

  Future<String> _downloadVerifiedApk(AppRelease release) async {
    if (_cachedReleaseTag == release.tagName &&
        _cachedApkPath != null &&
        await File(_cachedApkPath!).exists()) {
      return _cachedApkPath!;
    }

    final checksumResponse = await _client.get(release.checksumUrl!);
    if (checksumResponse.statusCode != 200) {
      throw AppUpdateException(
        'APK checksum download failed with HTTP '
        '${checksumResponse.statusCode}.',
      );
    }
    final apkName = Uri.decodeComponent(release.apkUrl!.pathSegments.last);
    final checksumMatch =
        RegExp(r'([0-9a-fA-F]{64})').firstMatch(checksumResponse.body);
    if (checksumMatch == null || !checksumResponse.body.contains(apkName)) {
      throw const AppUpdateException('APK checksum data is invalid.');
    }
    final expectedChecksum = checksumMatch.group(1)!.toLowerCase();

    final streamedResponse = await _client.send(
      http.Request('GET', release.apkUrl!),
    );
    if (streamedResponse.statusCode != 200) {
      throw AppUpdateException(
        'APK download failed with HTTP ${streamedResponse.statusCode}.',
      );
    }

    final directory = await _temporaryDirectoryProvider();
    final apkFile = File(
      '${directory.path}/snorer-update-${release.version}.apk',
    );
    if (await apkFile.exists()) await apkFile.delete();

    final digestSink = _DigestSink();
    final digestInput = sha256.startChunkedConversion(digestSink);
    final output = apkFile.openWrite();
    var outputClosed = false;
    try {
      await for (final chunk in streamedResponse.stream) {
        digestInput.add(chunk);
        output.add(chunk);
      }
      digestInput.close();
      await output.close();
      outputClosed = true;
    } catch (error) {
      if (!outputClosed) await output.close();
      if (await apkFile.exists()) await apkFile.delete();
      throw AppUpdateException('APK download failed: $error');
    }

    final actualChecksum = digestSink.digest?.toString().toLowerCase();
    if (actualChecksum != expectedChecksum) {
      if (await apkFile.exists()) await apkFile.delete();
      throw const AppUpdateException(
        'Downloaded APK checksum does not match the release.',
      );
    }

    _cachedReleaseTag = release.tagName;
    _cachedApkPath = apkFile.path;
    return apkFile.path;
  }

  @override
  void dispose() => _client.close();
}
class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest value) => digest = value;

  @override
  void close() {}
}

enum ApkInstallResult {
  started,
  permissionRequired,
}

abstract interface class ApkInstaller {
  Future<ApkInstallResult> install(String apkPath);
}

class AndroidApkInstaller implements ApkInstaller {
  const AndroidApkInstaller();

  static const MethodChannel _channel = MethodChannel(
    'com.bryanschoot.snorer/installer',
  );

  @override
  Future<ApkInstallResult> install(String apkPath) async {
    if (!Platform.isAndroid) {
      throw const AppUpdateException(
        'Direct APK installation is only available on Android.',
      );
    }
    final result = await _channel.invokeMethod<String>(
      'installApk',
      <String, Object?>{'path': apkPath},
    );
    return switch (result) {
      'started' => ApkInstallResult.started,
      'permission_required' => ApkInstallResult.permissionRequired,
      _ => throw const AppUpdateException(
        'Android could not open the package installer.',
      ),
    };
  }
}

Uri? _trustedGitHubUrl(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host != 'github.com') {
    return null;
  }
  return uri;
}

Uri? _trustedDownloadUrl(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'github.com' ||
      !uri.path.contains('/releases/download/')) {
    return null;
  }
  return uri;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
