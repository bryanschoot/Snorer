import 'dart:convert';

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
