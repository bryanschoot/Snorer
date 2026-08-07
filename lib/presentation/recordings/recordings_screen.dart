import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/snorer_error.dart';
import '../../core/localization/snorer_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/audio_playback_service.dart';
import '../../data/services/audio_recording_service.dart';
import '../../domain/models/recording.dart';
import '../../domain/services/recording_utils.dart';
import 'recordings_view_model.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({
    super.key,
    required this.viewModel,
    this.onOpenSettings,
  });

  final RecordingsViewModel viewModel;
  final VoidCallback? onOpenSettings;

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.initialize());
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final viewModel = widget.viewModel;
            final strings = SnorerLocalizations.of(context);
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 720
                    ? 32.0
                    : 20.0;
                return ListView(
                  key: const Key('recordings_scroll_view'),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    40,
                  ),
                  children: [
                    _AppHeader(onOpenSettings: widget.onOpenSettings),
                    if (viewModel.recorderState.permissionGranted == false) ...[
                      const SizedBox(height: 16),
                      _PermissionBanner(),
                    ],
                    const SizedBox(height: 18),
                    _RecorderCard(
                      state: viewModel.recorderState,
                      onStart: viewModel.startRecording,
                      onStop: viewModel.stopRecording,
                    ),
                    const SizedBox(height: 14),
                    _PrivacyCard(),
                    const SizedBox(height: 28),
                    _SectionHeader(count: viewModel.recordings.length),
                    const SizedBox(height: 12),
                    if (!viewModel.isHydrated)
                      const _LoadingCard()
                    else if (viewModel.selectedRecording == null)
                      _EmptyRecordingState()
                    else
                      _RecordingPlayerCard(
                        recording: viewModel.selectedRecording!,
                        playback: viewModel.playerState,
                        onTogglePlayback: viewModel.togglePlayback,
                        onSeek: viewModel.seekTo,
                      ),
                    if (viewModel.recordings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _RecordingList(
                        recordings: viewModel.recordings,
                        selectedId: viewModel.selectedRecording?.id,
                        onSelect: viewModel.selectRecording,
                        onToggleLabel: viewModel.toggleLabel,
                        onDelete: (id) =>
                            _confirmDelete(context, viewModel, id),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('delete_all_recordings'),
                          onPressed: () =>
                              _confirmDeleteAll(context, viewModel),
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(strings.deleteAllRecordings),
                          style: TextButton.styleFrom(
                            foregroundColor: context.snorerColors.danger,
                          ),
                        ),
                      ),
                    ],
                    if (viewModel.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorCard(error: viewModel.error!),
                    ],
                    const SizedBox(height: 24),
                    _AppFooter(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecordingsViewModel viewModel,
    String recordingId,
  ) async {
    final matches = viewModel.recordings.where(
      (candidate) => candidate.id == recordingId,
    );
    final recording = matches.isEmpty ? null : matches.first;
    if (recording == null) return;
    final strings = SnorerLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteRecordingTitle),
        content: Text(strings.deleteRecordingContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.snorerColors.dangerDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await viewModel.deleteRecording(recording.id);
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    RecordingsViewModel viewModel,
  ) async {
    final strings = SnorerLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteAllTitle),
        content: Text(strings.deleteAllContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.snorerColors.dangerDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deleteAll),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await viewModel.deleteAllRecordings();
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow('SNORER'),
              const SizedBox(height: 8),
              Text(
                strings.headerTitle,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.headerDescription,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              key: const Key('open_settings'),
              onPressed: onOpenSettings,
              tooltip: strings.settings,
              icon: const Icon(Icons.settings_outlined),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusDot(),
                  const SizedBox(width: 6),
                  Text(
                    strings.local,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.waveInactive,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.snorerColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.25,
    ),
  );
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Container(
      key: const Key('permission_banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warningBackground,
        border: Border.all(color: colors.warningBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mic_off_outlined, color: colors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.permissionTitle,
                  style: TextStyle(
                    color: colors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.permissionBody,
                  style: TextStyle(
                    color: colors.warningText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecorderCard extends StatelessWidget {
  const _RecorderCard({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final AudioRecordingState state;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    final isRecording = state.isRecording;
    final isBusy = state.isBusy;
    final detectionHint = switch (state.soundDetectionStatus) {
      SoundDetectionStatus.ready => strings.detectionReady,
      SoundDetectionStatus.loading => strings.detectionLoading,
      SoundDetectionStatus.unavailable => strings.detectionUnavailable,
      SoundDetectionStatus.idle => strings.detectionIdle,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow(strings.recordingEyebrow),
                      const SizedBox(height: 6),
                      Text(
                        strings.recordingTitle,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? colors.errorBackground
                        : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusDot(active: isRecording),
                      const SizedBox(width: 6),
                      Text(
                        isRecording
                            ? strings.recordingBusy
                            : strings.recordingReady,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatClock(state.durationSeconds),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    isRecording
                        ? strings.recordingInProgressHint
                        : strings.recordingReadyHint,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: isRecording
                  ? FilledButton.icon(
                      key: const Key('stop_recording'),
                      onPressed: state.status == AudioRecordingStatus.stopping
                          ? null
                          : () => unawaited(onStop()),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.dangerDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(
                        state.status == AudioRecordingStatus.stopping
                            ? strings.finishRecording
                            : strings.stopRecording,
                      ),
                    )
                  : FilledButton.icon(
                      key: const Key('start_recording'),
                      onPressed: isBusy ? null : () => unawaited(onStart()),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.fiber_manual_record_rounded),
                      label: Text(
                        state.status == AudioRecordingStatus.starting
                            ? strings.prepareMicrophone
                            : strings.startRecording,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.foregroundServiceNote,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detectionHint,
              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: const Icon(Icons.lock_outline_rounded, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.privacyTitle,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.privacyBody,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(strings.overviewEyebrow),
              const SizedBox(height: 6),
              Text(
                strings.localRecordings,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Text(
            strings.recordingsCount(count),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _EmptyRecordingState extends StatelessWidget {
  const _EmptyRecordingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.nightlight_outlined, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyRecordingTitle,
              style: TextStyle(
                color: colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              strings.emptyRecordingBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted, fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingPlayerCard extends StatelessWidget {
  const _RecordingPlayerCard({
    required this.recording,
    required this.playback,
    required this.onTogglePlayback,
    required this.onSeek,
  });

  final StoredRecording recording;
  final AudioPlaybackState playback;
  final Future<void> Function() onTogglePlayback;
  final Future<void> Function(double seconds) onSeek;

  static const _waveform = <double>[
    0.35,
    0.58,
    0.82,
    0.46,
    0.67,
    0.94,
    0.52,
    0.73,
    0.39,
    0.63,
    0.88,
    0.5,
    0.76,
    0.42,
    0.6,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    final timelineDuration = playback.durationSeconds > 0
        ? playback.durationSeconds
        : recording.durationSeconds > 0
        ? recording.durationSeconds
        : 1.0;
    final timelineProgress = (playback.currentSeconds / timelineDuration)
        .clamp(0, 1)
        .toDouble();
    final snoringCount = recording.soundEvents
        .where((event) => event.kind == SoundEventKind.snoring)
        .length;
    final speechCount = recording.soundEvents
        .where((event) => event.kind == SoundEventKind.speech)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 74,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final playheadLeft =
                            (constraints.maxWidth * timelineProgress - 1)
                                .clamp(0.0, constraints.maxWidth - 2)
                                .toDouble();
                        return GestureDetector(
                          key: const Key('recording_waveform'),
                          onTapUp: (details) {
                            final fraction =
                                (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0, 1)
                                    .toDouble();
                            unawaited(onSeek(fraction * timelineDuration));
                          },
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  for (
                                    var index = 0;
                                    index < _waveform.length;
                                    index += 1
                                  )
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: _WaveBar(
                                          height: 14 + _waveform[index] * 38,
                                          color:
                                              _eventColor(
                                                recording,
                                                index,
                                                timelineDuration,
                                                colors,
                                              ) ??
                                              ((index + 0.5) /
                                                          _waveform.length <=
                                                      timelineProgress
                                                  ? colors.primary
                                                  : colors.waveInactive),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Positioned(
                                key: const Key('recording_playhead'),
                                left: playheadLeft,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: colors.primaryDark,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  key: const Key('toggle_playback'),
                  onPressed: () => unawaited(onTogglePlayback()),
                  tooltip: playback.isPlaying
                      ? strings.pauseRecording
                      : strings.playRecording,
                  icon: Icon(
                    playback.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
            Slider(
              value: timelineProgress,
              onChanged: playback.durationSeconds > 0
                  ? (value) => unawaited(onSeek(value * timelineDuration))
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatClock(playback.currentSeconds),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                Text(
                  formatClock(
                    playback.durationSeconds > 0
                        ? playback.durationSeconds
                        : recording.durationSeconds,
                  ),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.formatDate(recording.startedAt),
              style: TextStyle(
                color: colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${strings.recordingLabel(recording.label)} · ${strings.formatDuration(recording.durationSeconds)}',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (recording.soundEvents.isEmpty)
              Text(
                strings.noEvents,
                style: TextStyle(color: colors.muted, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EventChip(
                    color: colors.danger,
                    text: strings.eventCount(
                      SoundEventKind.snoring,
                      snoringCount,
                    ),
                  ),
                  _EventChip(
                    color: colors.warning,
                    text: strings.eventCount(
                      SoundEventKind.speech,
                      speechCount,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color? _eventColor(
    StoredRecording recording,
    int index,
    double timelineDuration,
    SnorerThemePalette colors,
  ) {
    final start = index / _waveform.length * timelineDuration;
    final end = (index + 1) / _waveform.length * timelineDuration;
    for (final event in recording.soundEvents) {
      if (event.startSeconds < end && event.endSeconds > start) {
        return event.kind == SoundEventKind.snoring
            ? colors.danger
            : colors.warning;
      }
    }
    return null;
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _RecordingList extends StatelessWidget {
  const _RecordingList({
    required this.recordings,
    required this.selectedId,
    required this.onSelect,
    required this.onToggleLabel,
    required this.onDelete,
  });

  final List<StoredRecording> recordings;
  final String? selectedId;
  final void Function(String id) onSelect;
  final Future<void> Function(String id, RecordingLabel label) onToggleLabel;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final recording in recordings)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _RecordingListTile(
            recording: recording,
            selected: recording.id == selectedId,
            onSelect: () => onSelect(recording.id),
            onToggleLabel: (label) =>
                unawaited(onToggleLabel(recording.id, label)),
            onDelete: () => unawaited(onDelete(recording.id)),
          ),
        ),
    ],
  );
}

class _RecordingListTile extends StatelessWidget {
  const _RecordingListTile({
    required this.recording,
    required this.selected,
    required this.onSelect,
    required this.onToggleLabel,
    required this.onDelete,
  });

  final StoredRecording recording;
  final bool selected;
  final VoidCallback onSelect;
  final void Function(RecordingLabel label) onToggleLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? colors.primaryDark : colors.border,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            key: Key('select_recording_${recording.id}'),
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colors.primary : colors.border,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: colors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      maxWidth: 145,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.formatDate(recording.startedAt),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.formatDuration(recording.durationSeconds),
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 4,
            children: [
              _LabelButton(
                label: RecordingLabel.snoring,
                active: recording.label == RecordingLabel.snoring,
                onPressed: () => onToggleLabel(RecordingLabel.snoring),
              ),
              _LabelButton(
                label: RecordingLabel.sleepTalking,
                active: recording.label == RecordingLabel.sleepTalking,
                onPressed: () => onToggleLabel(RecordingLabel.sleepTalking),
              ),
              IconButton(
                key: Key('delete_recording_${recording.id}'),
                tooltip: strings.deleteRecordingTooltip,
                onPressed: onDelete,
                color: colors.danger,
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelButton extends StatelessWidget {
  const _LabelButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final RecordingLabel label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active ? colors.onPrimary : colors.muted,
        backgroundColor: active ? colors.primaryDark : Colors.transparent,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        strings.recordingLabel(label),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final SnorerError error;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorBackground,
        border: Border.all(color: colors.errorBorder),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.errorTitle,
            style: TextStyle(color: colors.danger, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            strings.errorMessage(error),
            style: TextStyle(
              color: colors.errorText,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colors.border),
          const SizedBox(height: 14),
          Text(
            strings.footerTitle,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            strings.footerBody,
            style: TextStyle(color: colors.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
