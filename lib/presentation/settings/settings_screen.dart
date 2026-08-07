import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Text(
              'Jouw Snorer',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Maak de app rustig voor het moment waarop je hem gebruikt.',
              style: TextStyle(color: colors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            _SettingsSectionTitle(
              icon: Icons.palette_outlined,
              title: 'Uiterlijk',
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
              icon: Icons.shield_outlined,
              title: 'Privacy',
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
                    title: const Text('Alles blijft op je telefoon'),
                    subtitle: const Text(
                      'Opnames, labels en geluidsanalyse worden lokaal opgeslagen. Snorer gebruikt geen account of cloudsync.',
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  ListTile(
                    leading: _SettingsIcon(
                      icon: Icons.mic_none_rounded,
                      colors: colors,
                    ),
                    title: const Text('Microfoon alleen tijdens opnemen'),
                    subtitle: const Text(
                      'Android toont een melding zolang een slaapopname actief is.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SettingsSectionTitle(
              icon: Icons.info_outline_rounded,
              title: 'Over Snorer',
              colors: colors,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: _SettingsIcon(
                  icon: Icons.nightlight_round,
                  colors: colors,
                ),
                title: const Text('Slaap inzichtelijk, lokaal opgeslagen'),
                subtitle: const Text(
                  'Een eenvoudige slaaprecorder zonder advertenties en zonder account.',
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
    return Padding(
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
                        mode.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Radio<SnorerThemeMode>(value: mode),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    backgroundColor: colors.surfaceSoft,
    foregroundColor: colors.primary,
    child: Icon(icon, size: 20),
  );
}
