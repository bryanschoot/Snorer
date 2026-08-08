import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/snorer_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'update_controller.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({
    super.key,
    required this.controller,
    this.onlyWhenAvailable = false,
    this.showCheckButton = true,
  });

  final UpdateController controller;
  final bool onlyWhenAvailable;
  final bool showCheckButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final release = controller.availableRelease;
        if (onlyWhenAvailable && release == null) {
          return const SizedBox.shrink();
        }

        final strings = SnorerLocalizations.of(context);
        final colors = context.snorerColors;
        final status = controller.status;
        final title = switch (status) {
          UpdateCheckStatus.updateAvailable => strings.updateAvailableTitle,
          UpdateCheckStatus.checking => strings.updateChecking,
          UpdateCheckStatus.upToDate => strings.updateUpToDate,
          UpdateCheckStatus.failed => strings.updateCheckFailed,
          UpdateCheckStatus.idle => strings.updateCheckTitle,
        };
        final body = switch (status) {
          UpdateCheckStatus.updateAvailable => strings.updateAvailableBody(
            release!.version.toString(),
          ),
          UpdateCheckStatus.checking => strings.updateCheckingBody,
          UpdateCheckStatus.upToDate => strings.updateUpToDateBody,
          UpdateCheckStatus.failed => strings.updateCheckFailedBody,
          UpdateCheckStatus.idle => strings.updateCheckBody,
        };

        return Card(
          key: const Key('update_card'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.primary,
                      child: const Icon(Icons.system_update_alt_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(color: colors.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (release != null || showCheckButton) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (release != null)
                        FilledButton.icon(
                          key: const Key('open_update_release'),
                          onPressed: () => unawaited(
                            _openRelease(context, release.releaseUrl),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(strings.updateOpen),
                        ),
                      if (showCheckButton)
                        OutlinedButton.icon(
                          key: const Key('check_for_updates'),
                          onPressed: status == UpdateCheckStatus.checking
                              ? null
                              : () => unawaited(controller.checkForUpdate()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(strings.updateCheckTitle),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRelease(BuildContext context, Uri releaseUrl) async {
    final opened = await launchUrl(
      releaseUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      final strings = SnorerLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.updateOpenFailed)),
      );
    }
  }
}
