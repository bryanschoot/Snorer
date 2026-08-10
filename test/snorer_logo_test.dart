import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snorer/core/theme/app_theme.dart';
import 'package:snorer/data/services/foreground_recording_service.dart';
import 'package:snorer/presentation/widgets/snorer_logo.dart';

void main() {
  testWidgets('renders the logo with the active theme palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSnorerTheme(SnorerThemeMode.pink),
        home: const Scaffold(
          body: Center(child: SnorerLogo(key: Key('snorer_logo'), size: 96)),
        ),
      ),
    );

    expect(find.byKey(const Key('snorer_logo')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('snorer_logo'))),
      const Size(96, 96),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('snorer_logo')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  test('builds the themed notification icon metadata', () {
    const accent = Color(0xFFD44987);

    final icon = buildSnorerNotificationIcon(accent);

    expect(icon.metaDataName, 'com.bryanschoot.snorer.NOTIFICATION_ICON');
    expect(icon.backgroundColor, accent);
  });
}
