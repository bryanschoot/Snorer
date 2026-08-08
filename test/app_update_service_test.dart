import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snorer/data/services/app_update_service.dart';

void main() {
  test('parses and compares release versions', () {
    expect(AppVersion.parse('v0.2.5+7').compareTo(AppVersion(0, 2, 4)), 1);
    expect(AppVersion.parse('0.2.4').compareTo(AppVersion(0, 2, 4)), 0);
    expect(AppVersion.parse('v0.2.3').compareTo(AppVersion(0, 2, 4)), -1);
  });

  test('returns a newer stable GitHub release', () async {
    final client = MockClient((request) async {
      expect(request.headers['Accept'], 'application/vnd.github+json');
      expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
      expect(request.headers['User-Agent'], 'Snorer/0.2.4+6');
      return http.Response(
        jsonEncode({
          'tag_name': 'v0.2.5',
          'html_url':
              'https://github.com/bryanschoot/Snorer/releases/tag/v0.2.5',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-08-09T10:00:00Z',
        }),
        200,
      );
    });
    final service = GitHubAppUpdateService(client: client);

    final release = await service.checkForUpdate('0.2.4+6');

    expect(release?.tagName, 'v0.2.5');
    expect(release?.version, isNotNull);
    expect(release?.releaseUrl.host, 'github.com');
    service.dispose();
  });
  test('downloads and verifies the release APK before installation', () async {
    final apkBytes = <int>[1, 2, 3, 4, 5];
    final checksum = sha256.convert(apkBytes).toString();
    final endpoint = Uri.parse(
      'https://api.github.com/repos/bryanschoot/Snorer/releases/latest',
    );
    final apkUrl = Uri.parse(
      'https://github.com/bryanschoot/Snorer/releases/download/v0.2.5/snorer-v0.2.5.apk',
    );
    final checksumUrl = Uri.parse(
      'https://github.com/bryanschoot/Snorer/releases/download/v0.2.5/snorer-v0.2.5.apk.sha256',
    );
    final client = MockClient.streaming((request, _) async {
      final body = switch (request.url) {
        _ when request.url == endpoint => jsonEncode({
          'tag_name': 'v0.2.5',
          'html_url':
              'https://github.com/bryanschoot/Snorer/releases/tag/v0.2.5',
          'draft': false,
          'prerelease': false,
          'assets': [
            {
              'name': 'snorer-v0.2.5.apk',
              'browser_download_url': apkUrl.toString(),
            },
            {
              'name': 'snorer-v0.2.5.apk.sha256',
              'browser_download_url': checksumUrl.toString(),
            },
          ],
        }),
        _ when request.url == checksumUrl =>
          '$checksum  release/snorer-v0.2.5.apk',
        _ => null,
      };
      if (body != null) {
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode(body)),
          200,
          request: request,
        );
      }
      return http.StreamedResponse(
        Stream<List<int>>.value(apkBytes),
        200,
        request: request,
      );
    });
    final installer = _FakeApkInstaller();
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'snorer-update-test-',
    );
    final service = GitHubAppUpdateService(
      client: client,
      endpoint: endpoint,
      installer: installer,
      temporaryDirectoryProvider: () async => temporaryDirectory,
    );

    final release = await service.checkForUpdate('0.2.4');
    expect(release?.canInstall, isTrue);
    expect(await service.install(release!), ApkInstallResult.started);
    expect(installer.apkPath, isNotNull);
    expect(await File(installer.apkPath!).readAsBytes(), apkBytes);

    service.dispose();
    await temporaryDirectory.delete(recursive: true);
  });


  test('returns no update when GitHub has the installed version', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'tag_name': 'v0.2.4',
          'html_url':
              'https://github.com/bryanschoot/Snorer/releases/tag/v0.2.4',
          'draft': false,
          'prerelease': false,
        }),
        200,
      );
    });
    final service = GitHubAppUpdateService(client: client);

    expect(await service.checkForUpdate('0.2.4+6'), isNull);
    service.dispose();
  });

  test('rejects failed GitHub responses', () async {
    final client = MockClient((_) async => http.Response('rate limited', 403));
    final service = GitHubAppUpdateService(client: client);

    expect(
      () => service.checkForUpdate('0.2.4'),
      throwsA(isA<AppUpdateException>()),
    );
    service.dispose();
  });

  test('rejects release links outside GitHub', () {
    expect(
      () => AppRelease.fromJson({
        'tag_name': 'v0.2.5',
        'html_url': 'https://example.com/release',
        'draft': false,
        'prerelease': false,
      }),
      throwsFormatException,
    );
  });
}
class _FakeApkInstaller implements ApkInstaller {
  String? apkPath;

  @override
  Future<ApkInstallResult> install(String apkPath) async {
    this.apkPath = apkPath;
    return ApkInstallResult.started;
  }
}
