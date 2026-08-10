import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/snorer_error.dart';
import '../../core/localization/snorer_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/recording_size_unit.dart';
import '../../data/services/audio_recording_service.dart';
import '../../data/services/audio_playback_service.dart';
import '../../domain/models/recording.dart';
import '../../domain/services/recording_utils.dart';
import 'recordings_view_model.dart';
import '../settings/recording_size_controller.dart';
import '../update/update_controller.dart';
import '../widgets/snorer_logo.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({
    super.key,
    required this.viewModel,
    this.recordingSizeController,
    this.onOpenSettings,
    this.updateController,
  });

  final RecordingsViewModel viewModel;
  final RecordingSizeController? recordingSizeController;
  final VoidCallback? onOpenSettings;
  final UpdateController? updateController;
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
    final listenables = <Listenable>[widget.viewModel];
    if (widget.updateController != null) {
      listenables.add(widget.updateController!);
    }
    if (widget.recordingSizeController != null) {
      listenables.add(widget.recordingSizeController!);
    }
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(listenables),
          builder: (context, _) {
            final viewModel = widget.viewModel;
            final strings = SnorerLocalizations.of(context);
            final sizeUnit =
                widget.recordingSizeController?.unit ??
                RecordingSizeUnit.megabytes;
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
                    _AppHeader(
                      onOpenSettings: widget.onOpenSettings,
                      hasUpdate:
                          widget.updateController?.availableRelease != null,
                    ),
                    if (viewModel.recorderState.permissionGranted == false) ...[
                      const SizedBox(height: 16),
                      _PermissionBanner(),
                    ],
                    const SizedBox(height: 18),
                    _RecorderCard(
                      state: viewModel.recorderState,
                      durationSeconds: viewModel.displayedDurationSeconds,
                      onStart: viewModel.startRecording,
                      onStop: viewModel.stopRecording,
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(count: viewModel.recordings.length),
                    const SizedBox(height: 12),
                    if (!viewModel.isHydrated)
                      const _LoadingCard()
                    else if (viewModel.selectedRecording == null)
                      const _EmptyRecordingState()
                    else
                      _RecordingWaveformCard(
                        recording: viewModel.selectedRecording!,
                        sizeUnit: sizeUnit,
                        playback: viewModel.playerState,
                        onTogglePlayback: viewModel.togglePlayback,
                        onSeek: viewModel.seekTo,
                      ),
                    if (viewModel.recordings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _RecordingList(
                        recordings: viewModel.recordings,
                        selectedId: viewModel.selectedRecording?.id,
                        sizeUnit: sizeUnit,
                        onSelect: viewModel.selectRecording,
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
  const _AppHeader({this.onOpenSettings, this.hasUpdate = false});

  final VoidCallback? onOpenSettings;
  final bool hasUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SnorerLogo(size: 38),
              const SizedBox(width: 10),
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
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  key: const Key('open_settings'),
                  onPressed: onOpenSettings,
                  tooltip: strings.settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                if (hasUpdate)
                  Positioned(
                    key: const Key('settings_update_indicator'),
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
    required this.durationSeconds,
    required this.onStart,
    required this.onStop,
  });

  final AudioRecordingState state;
  final double durationSeconds;
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
                  formatClock(durationSeconds),
                  key: const Key('recording_timer'),
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

class _RecordingWaveformCard extends StatelessWidget {
  const _RecordingWaveformCard({
    required this.recording,
    required this.sizeUnit,
    required this.playback,
    required this.onTogglePlayback,
    required this.onSeek,
  });

  final StoredRecording recording;
  final RecordingSizeUnit sizeUnit;
  final AudioPlaybackState playback;
  final Future<void> Function() onTogglePlayback;
  final Future<void> Function(double seconds) onSeek;

  static const _placeholderWaveform = <double>[
    0.22,
    0.42,
    0.31,
    0.68,
    0.48,
    0.83,
    0.55,
    0.38,
    0.76,
    0.44,
    0.91,
    0.62,
    0.36,
    0.71,
    0.52,
    0.87,
    0.43,
    0.29,
    0.65,
    0.8,
    0.47,
    0.58,
    0.34,
    0.73,
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
    final displayedWaveform = playback.waveform.isNotEmpty
        ? playback.waveform
        : _placeholderWaveform;
    final displayedDuration = playback.durationSeconds > 0
        ? playback.durationSeconds
        : recording.durationSeconds;
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: colors.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        key: Key('recording_details_${recording.id}'),
                        '${strings.formatDuration(recording.durationSeconds)} · '
                        '${strings.formatFileSize(recording.fileSizeBytes, sizeUnit)}',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 18),
            _WaveformTimeline(
              waveform: displayedWaveform,
              progress: timelineProgress,
              durationSeconds: timelineDuration,
              events: recording.soundEvents,
              onSeek: onSeek,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatClock(playback.currentSeconds),
                  key: const Key('waveform_start_time'),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                Text(
                  formatClock(displayedDuration),
                  key: const Key('waveform_end_time'),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
            if (recording.soundEvents.isNotEmpty) ...[
              _SoundEventStepper(
                events: recording.soundEvents,
                currentSeconds: playback.currentSeconds,
                onSeek: onSeek,
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 14),
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
                    icon: Icons.nightlight_round,
                    text: strings.eventCount(
                      SoundEventKind.snoring,
                      snoringCount,
                    ),
                  ),
                  _EventChip(
                    color: colors.warning,
                    icon: Icons.record_voice_over_rounded,
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
}

class _SoundEventStepper extends StatefulWidget {
  const _SoundEventStepper({
    required this.events,
    required this.currentSeconds,
    required this.onSeek,
  });

  final List<SoundEvent> events;
  final double currentSeconds;
  final Future<void> Function(double seconds) onSeek;

  @override
  State<_SoundEventStepper> createState() => _SoundEventStepperState();
}

class _SoundEventStepperState extends State<_SoundEventStepper> {
  SoundEventKind? _filterKind;

  List<SoundEvent> get _filteredEvents {
    final events = widget.events
        .where((event) => _filterKind == null || event.kind == _filterKind)
        .toList();
    events.sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
    return events;
  }

  int _activeIndex(List<SoundEvent> events) {
    final position = widget.currentSeconds.isFinite ? widget.currentSeconds : 0;
    var activeIndex = -1;
    for (var index = 0; index < events.length; index += 1) {
      if (events[index].startSeconds > position + 0.05) break;
      activeIndex = index;
    }
    return activeIndex;
  }

  void _selectFilter(SoundEventKind? kind) {
    if (_filterKind == kind) return;
    setState(() => _filterKind = kind);
  }

  void _seekTo(List<SoundEvent> events, int index) {
    if (index < 0 || index >= events.length) return;
    unawaited(widget.onSeek(events[index].startSeconds));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    final strings = SnorerLocalizations.of(context);
    final events = _filteredEvents;
    final activeIndex = _activeIndex(events);
    final previousIndex = activeIndex - 1;
    final nextIndex = activeIndex + 1;
    final currentPosition = activeIndex >= 0 ? activeIndex + 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.detectedSounds,
          style: TextStyle(
            color: colors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('event_filter_all'),
              label: Text(strings.allEvents),
              selected: _filterKind == null,
              onSelected: (_) => _selectFilter(null),
            ),
            ChoiceChip(
              key: const Key('event_filter_snoring'),
              label: Text(strings.soundEventSnoring),
              selected: _filterKind == SoundEventKind.snoring,
              onSelected: (_) => _selectFilter(SoundEventKind.snoring),
            ),
            ChoiceChip(
              key: const Key('event_filter_speech'),
              label: Text(strings.soundEventSpeech),
              selected: _filterKind == SoundEventKind.speech,
              onSelected: (_) => _selectFilter(SoundEventKind.speech),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              key: const Key('previous_sound_event'),
              tooltip: strings.previousSoundEvent,
              onPressed: previousIndex >= 0
                  ? () => _seekTo(events, previousIndex)
                  : null,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            Expanded(
              child: Text(
                strings.soundEventPosition(currentPosition, events.length),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ),
            IconButton(
              key: const Key('next_sound_event'),
              tooltip: strings.nextSoundEvent,
              onPressed: nextIndex < events.length
                  ? () => _seekTo(events, nextIndex)
                  : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformTimeline extends StatefulWidget {
  const _WaveformTimeline({
    required this.waveform,
    required this.progress,
    required this.durationSeconds,
    required this.events,
    required this.onSeek,
  });

  final List<double> waveform;
  final double progress;
  final double durationSeconds;
  final List<SoundEvent> events;
  final Future<void> Function(double seconds) onSeek;

  @override
  State<_WaveformTimeline> createState() => _WaveformTimelineState();
}

class _WaveformTimelineState extends State<_WaveformTimeline> {
  Timer? _seekTimer;
  Timer? _clearDragTimer;
  double? _dragProgress;

  double get _visibleProgress =>
      (_dragProgress ?? widget.progress).clamp(0, 1).toDouble();

  @override
  void dispose() {
    _seekTimer?.cancel();
    _clearDragTimer?.cancel();
    super.dispose();
  }

  double _progressFor(double dx, double width) {
    if (width <= 0) return 0;
    return (dx / width).clamp(0, 1).toDouble();
  }

  void _setDragProgress(double progress, {required bool immediate}) {
    _clearDragTimer?.cancel();
    if (mounted) setState(() => _dragProgress = progress);
    _seekTimer?.cancel();
    if (immediate) {
      unawaited(widget.onSeek(progress * widget.durationSeconds));
      return;
    }
    _seekTimer = Timer(const Duration(milliseconds: 40), () {
      unawaited(widget.onSeek(progress * widget.durationSeconds));
    });
  }

  void _handleTap(double dx, double width) {
    final progress = _progressFor(dx, width);
    _setDragProgress(progress, immediate: true);
    _clearDragTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _dragProgress = null);
    });
  }

  void _finishDrag() {
    final progress = _dragProgress;
    if (progress != null) {
      _seekTimer?.cancel();
      unawaited(widget.onSeek(progress * widget.durationSeconds));
    }
    if (mounted) setState(() => _dragProgress = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.snorerColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final progress = _visibleProgress;
        final playheadLeft = (width * progress - 1)
            .clamp(0.0, width > 2 ? width - 2 : 0.0)
            .toDouble();
        return GestureDetector(
          key: const Key('recording_waveform'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition.dx, width),
          onHorizontalDragStart: (details) {
            _setDragProgress(
              _progressFor(details.localPosition.dx, width),
              immediate: true,
            );
          },
          onHorizontalDragUpdate: (details) {
            _setDragProgress(
              _progressFor(details.localPosition.dx, width),
              immediate: false,
            );
          },
          onHorizontalDragEnd: (_) => _finishDrag(),
          onHorizontalDragCancel: _finishDrag,
          child: SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _WaveformPainter(
                    waveform: widget.waveform,
                    progress: progress,
                    durationSeconds: widget.durationSeconds,
                    events: widget.events,
                    colors: colors,
                  ),
                ),
                Positioned(
                  key: const Key('recording_playhead'),
                  left: playheadLeft,
                  top: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: colors.primaryDark,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primaryDark.withValues(alpha: 0.35),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.durationSeconds,
    required this.events,
    required this.colors,
  });

  final List<double> waveform;
  final double progress;
  final double durationSeconds;
  final List<SoundEvent> events;
  final SnorerThemePalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(track, Paint()..color = colors.surfaceSoft);
    if (waveform.isEmpty || size.width <= 0) return;

    final slotWidth = size.width / waveform.length;
    for (var index = 0; index < waveform.length; index += 1) {
      final amplitude = waveform[index].clamp(0.08, 1.0).toDouble();
      final height = 10 + amplitude * (size.height - 28);
      final left = index * slotWidth + slotWidth * 0.2;
      final barWidth = (slotWidth * 0.6).clamp(2.0, 8.0).toDouble();
      final start = index / waveform.length * durationSeconds;
      final end = (index + 1) / waveform.length * durationSeconds;
      final eventColor = _eventColor(start, end);
      final played = (index + 0.5) / waveform.length <= progress;
      final color =
          eventColor ??
          (played ? colors.primary : colors.waveInactive).withValues(
            alpha: played ? 1 : 0.72,
          );
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }

    for (final event in events) {
      final markerProgress = (event.startSeconds / durationSeconds)
          .clamp(0, 1)
          .toDouble();
      final markerColor = event.kind == SoundEventKind.snoring
          ? colors.danger
          : colors.warning;
      canvas.drawCircle(
        Offset(markerProgress * size.width, size.height - 6),
        3,
        Paint()..color = markerColor,
      );
    }
  }

  Color? _eventColor(double start, double end) {
    for (final event in events) {
      if (event.startSeconds < end && event.endSeconds > start) {
        return event.kind == SoundEventKind.snoring
            ? colors.danger
            : colors.warning;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecordingList extends StatelessWidget {
  const _RecordingList({
    required this.recordings,
    required this.selectedId,
    required this.sizeUnit,
    required this.onSelect,
    required this.onDelete,
  });

  final List<StoredRecording> recordings;
  final String? selectedId;
  final RecordingSizeUnit sizeUnit;
  final void Function(String id) onSelect;
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
            sizeUnit: sizeUnit,
            onSelect: () => onSelect(recording.id),
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
    required this.sizeUnit,
    required this.onSelect,
    required this.onDelete,
  });

  final StoredRecording recording;
  final bool selected;
  final RecordingSizeUnit sizeUnit;
  final VoidCallback onSelect;
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
          Material(
            type: MaterialType.transparency,
            child: InkWell(
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
                            '${strings.formatDuration(recording.durationSeconds)} · '
                            '${strings.formatFileSize(recording.fileSizeBytes, sizeUnit)}',
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 4,
            children: [
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
