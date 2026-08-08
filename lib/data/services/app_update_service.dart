import 'dart:convert';

import 'package:http/http.dart' as http;

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

    final releaseUrl = Uri.tryParse(htmlUrl);
    if (releaseUrl == null ||
        releaseUrl.scheme != 'https' ||
        releaseUrl.host != 'github.com') {
      throw const FormatException('GitHub release URL is not trusted.');
    }

    final publishedAtValue = json['published_at'];
    return AppRelease(
      tagName: tagName,
      version: AppVersion.parse(tagName),
      releaseUrl: releaseUrl,
      publishedAt: publishedAtValue is String
          ? DateTime.tryParse(publishedAtValue)
          : null,
    );
  }

  final String tagName;
  final AppVersion version;
  final Uri releaseUrl;
  final DateTime? publishedAt;
}

abstract interface class AppUpdateService {
  Future<AppRelease?> checkForUpdate(String currentVersion);

  void dispose();
}

class GitHubAppUpdateService implements AppUpdateService {
  GitHubAppUpdateService({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint =
          endpoint ??
          Uri.parse(
            'https://api.github.com/repos/bryanschoot/Snorer/releases/latest',
          );

  final http.Client _client;
  final Uri _endpoint;

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
  void dispose() => _client.close();
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
