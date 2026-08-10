import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/snorer_language.dart';
import '../../core/localization/snorer_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/recording_size_unit.dart';
import '../update/update_card.dart';
import '../update/update_controller.dart';
import '../widgets/snorer_logo.dart';
import 'language_controller.dart';
import 'recording_size_controller.dart';
import 'theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeController,
    required this.languageController,
    required this.recordingSizeController,
    required this.appVersion,
    required this.appBuild,
    this.updateController,
  });

  final ThemeController themeController;
  final LanguageController languageController;
  final RecordingSizeController recordingSizeController;
  final UpdateController? updateController;
  final String appVersion;
  final String appBuild;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Container(
              key: const Key('settings_intro_card'),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SnorerLogo(size: 50),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.settingsIntroTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.settingsIntroBody,
                          style: TextStyle(color: colors.muted, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SettingsSectionTitle(
              icon: Icons.palette_outlined,
              title: strings.appearance,
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListenableBuilder(
                  listenable: themeController,
                  builder: (context, _) => RadioGroup<SnorerThemeMode>(
                    groupValue: themeController.mode,
                    onChanged: (mode) {
                      if (mode != null) {
                        unawaited(themeController.setMode(mode));
                      }
                    },
                    child: Column(
                      children: [
                        const Padding(
                          key: Key('theme_logo_preview'),
                          padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                          child: Center(child: SnorerLogo(size: 80)),
                        ),
                        for (final mode in SnorerThemeMode.values)
                          _ThemeOption(
                            mode: mode,
                            selected: themeController.mode == mode,
                            onSelected: () =>
                                unawaited(themeController.setMode(mode)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              icon: Icons.language_outlined,
              title: strings.language,
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListenableBuilder(
                  listenable: languageController,
                  builder: (context, _) => RadioGroup<SnorerLanguage>(
                    groupValue: languageController.language,
                    onChanged: (language) {
                      if (language != null) {
                        unawaited(languageController.setLanguage(language));
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              strings.languageHint,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        for (final language in SnorerLanguage.values)
                          _LanguageOption(
                            language: language,
                            selected: languageController.language == language,
                            onSelected: () => unawaited(
                              languageController.setLanguage(language),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              icon: Icons.data_usage_rounded,
              title: strings.recordingSize,
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListenableBuilder(
                  listenable: recordingSizeController,
                  builder: (context, _) => RadioGroup<RecordingSizeUnit>(
                    groupValue: recordingSizeController.unit,
                    onChanged: (unit) {
                      if (unit != null) {
                        unawaited(recordingSizeController.setUnit(unit));
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              strings.recordingSizeHint,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        for (final unit in RecordingSizeUnit.values)
                          _RecordingSizeOption(
                            unit: unit,
                            selected: recordingSizeController.unit == unit,
                            onSelected: () => unawaited(
                              recordingSizeController.setUnit(unit),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (updateController != null) ...[
              const SizedBox(height: 26),
              _SettingsSectionTitle(
                icon: Icons.system_update_alt_rounded,
                title: strings.updateCheckTitle,
                colors: colors,
              ),
              const SizedBox(height: 10),
              UpdateCard(controller: updateController!),
            ],
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              icon: Icons.shield_outlined,
              title: strings.privacy,
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: _SettingsIcon(
                      icon: Icons.lock_outline_rounded,
                      colors: colors,
                    ),
                    title: Text(strings.privacyPhoneTitle),
                    subtitle: Text(strings.privacyPhoneBody),
                  ),
                  Divider(height: 1, color: colors.border),
                  ListTile(
                    leading: _SettingsIcon(
                      icon: Icons.mic_none_rounded,
                      colors: colors,
                    ),
                    title: Text(strings.privacyMicrophoneTitle),
                    subtitle: Text(strings.privacyMicrophoneBody),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              icon: Icons.info_outline_rounded,
              title: strings.about,
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const SnorerLogo(size: 44),
                      title: Text(strings.aboutTitle),
                      subtitle: Text(strings.aboutBody),
                    ),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: 4),
                    _AboutDetailRow(
                      key: const Key('about_author'),
                      label: strings.aboutAuthorLabel,
                      value: strings.aboutAuthor,
                      colors: colors,
                    ),
                    _AboutDetailRow(
                      key: const Key('about_version'),
                      label: strings.aboutVersionLabel,
                      value: appVersion,
                      colors: colors,
                    ),
                    _AboutDetailRow(
                      key: const Key('about_build'),
                      label: strings.aboutBuildLabel,
                      value: appBuild,
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onSelected,
  });

  final SnorerThemeMode mode;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: Key('theme_option_${mode.name}'),
            onTap: onSelected,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mode.icon,
                      color: selected ? colors.onPrimary : colors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.themeLabel(mode),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.themeDescription(mode),
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected
                        ? Icon(
                            key: Key('theme_selected_${mode.name}'),
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 20,
                          )
                        : const SizedBox(width: 20, height: 20),
                  ),
                  Radio<SnorerThemeMode>(value: mode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onSelected,
  });

  final SnorerLanguage language;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: Key('language_option_${language.name}'),
            onTap: onSelected,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.translate_rounded,
                    color: selected ? colors.primary : colors.muted,
                    size: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.languageLabel(language),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected
                        ? Icon(
                            key: Key('language_selected_${language.name}'),
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 20,
                          )
                        : const SizedBox(width: 20, height: 20),
                  ),
                  Radio<SnorerLanguage>(value: language),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingSizeOption extends StatelessWidget {
  const _RecordingSizeOption({
    required this.unit,
    required this.selected,
    required this.onSelected,
  });

  final RecordingSizeUnit unit;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: Key('recording_size_option_${unit.name}'),
            onTap: onSelected,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.data_usage_rounded,
                    color: selected ? colors.primary : colors.muted,
                    size: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.recordingSizeUnitLabel(unit),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected
                        ? Icon(
                            key: Key('recording_size_selected_${unit.name}'),
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 20,
                          )
                        : const SizedBox(width: 20, height: 20),
                  ),
                  Radio<RecordingSizeUnit>(value: unit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutDetailRow extends StatelessWidget {
  const _AboutDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final SnorerThemePalette colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.icon,
    required this.title,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final SnorerThemePalette colors;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: colors.primary, size: 19),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.colors});

  final IconData icon;
  final SnorerThemePalette colors;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: colors.surfaceSoft,
    foregroundColor: colors.primary,
    child: Icon(icon, size: 20),
  );
}
