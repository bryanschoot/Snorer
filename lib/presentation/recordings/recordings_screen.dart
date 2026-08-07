import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/audio_playback_service.dart';
import '../../data/services/audio_recording_service.dart';
import '../../domain/models/recording.dart';
import '../../domain/services/recording_utils.dart';
import 'recordings_view_model.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key, required this.viewModel});

  final RecordingsViewModel viewModel;

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
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 720
                    ? 32.0
                    : 20.0;
                return ListView(
                  key: const Key('recordings_scroll_view'),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    44,
                  ),
                  children: [
                    const _AppHeader(),
                    if (viewModel.recorderState.permissionGranted == false) ...[
                      const SizedBox(height: 16),
                      const _PermissionBanner(),
                    ],
                    const SizedBox(height: 16),
                    _RecorderCard(
                      state: viewModel.recorderState,
                      onStart: viewModel.startRecording,
                      onStop: viewModel.stopRecording,
                    ),
                    const SizedBox(height: 16),
                    const _ScopeCard(),
                    const SizedBox(height: 26),
                    _SectionHeader(count: viewModel.recordings.length),
                    const SizedBox(height: 12),
                    if (!viewModel.isHydrated)
                      const _LoadingCard()
                    else if (viewModel.selectedRecording == null)
                      const _EmptyRecordingState()
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
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('delete_all_recordings'),
                          onPressed: () =>
                              _confirmDeleteAll(context, viewModel),
                          style: TextButton.styleFrom(
                            foregroundColor: SnorerColors.danger,
                          ),
                          child: const Text('Alle lokale opnames verwijderen'),
                        ),
                      ),
                    ],
                    if (viewModel.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorCard(message: viewModel.error!),
                    ],
                    const SizedBox(height: 24),
                    const _AppFooter(),
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opname verwijderen?'),
        content: const Text(
          'Het lokale audiobestand en de vermelding worden van dit apparaat verwijderd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SnorerColors.dangerDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle opnames verwijderen?'),
        content: const Text(
          'Alle lokale audiobestanden en labels worden permanent van dit apparaat verwijderd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SnorerColors.dangerDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Alles verwijderen'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await viewModel.deleteAllRecordings();
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow('SNORER · ANDROID EERST'),
              SizedBox(height: 8),
              Text(
                'Luister naar je nacht.',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Neem slaapgeluiden op en luister ze lokaal terug. Geen upload, geen cloudanalyse.',
                style: TextStyle(
                  color: SnorerColors.muted,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: SnorerColors.border),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(),
                SizedBox(width: 6),
                Text(
                  'Lokaal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: active ? SnorerColors.primary : SnorerColors.waveInactive,
      shape: BoxShape.circle,
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: SnorerColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.25,
    ),
  );
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('permission_banner'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: SnorerColors.warningBackground,
      border: Border.all(color: SnorerColors.warningBorder),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Microfoontoegang staat nog uit',
          style: TextStyle(
            color: SnorerColors.warning,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Snorer kan pas opnemen nadat Android de microfoontoestemming geeft. Er wordt niets naar een server gestuurd.',
          style: TextStyle(
            color: SnorerColors.warningText,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
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
    final isRecording = state.isRecording;
    final isBusy = state.isBusy;
    final detectionHint = switch (state.soundDetectionStatus) {
      SoundDetectionStatus.ready =>
        'Snurken en praten worden lokaal gemarkeerd.',
      SoundDetectionStatus.loading => 'Geluidsmodel wordt klaargemaakt…',
      SoundDetectionStatus.unavailable =>
        'Opname werkt, maar geluidslabels zijn niet beschikbaar.',
      SoundDetectionStatus.idle =>
        'Geluidslabels worden alleen op dit apparaat verwerkt.',
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow('NIEUWE SLAAPSESSIE'),
                      SizedBox(height: 6),
                      Text(
                        'Opname voor vannacht',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isRecording
                        ? const Color(0xFF3A2938)
                        : SnorerColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusDot(active: isRecording),
                        const SizedBox(width: 6),
                        Text(
                          isRecording ? 'Actief' : 'Inactief',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
                  style: const TextStyle(
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
                        ? 'geluid wordt lokaal opgeslagen'
                        : 'start wanneer je gaat slapen',
                    style: const TextStyle(
                      color: SnorerColors.muted,
                      fontSize: 12,
                    ),
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
                        backgroundColor: SnorerColors.dangerDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(
                        state.status == AudioRecordingStatus.stopping
                            ? 'Opname afronden…'
                            : 'Opname stoppen',
                      ),
                    )
                  : FilledButton.icon(
                      key: const Key('start_recording'),
                      onPressed: isBusy ? null : () => unawaited(onStart()),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.fiber_manual_record_rounded),
                      label: Text(
                        state.status == AudioRecordingStatus.starting
                            ? 'Microfoon klaarmaken…'
                            : 'Slaapopname starten',
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: SnorerColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Android houdt de opname actief met een zichtbare systeemmelding, ook als je scherm vergrendelt.',
                    style: TextStyle(
                      color: SnorerColors.muted,
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
              style: const TextStyle(
                color: SnorerColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: SnorerColors.surfaceSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: SnorerColors.primaryDark,
          child: Icon(Icons.check, size: 16, color: SnorerColors.text),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privé op je apparaat',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'PCM-fragmenten worden lokaal geanalyseerd met YAMNet. Audio, labels en detectie-events verlaten je telefoon niet.',
                style: TextStyle(
                  color: SnorerColors.muted,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow('OCHTENDOVERZICHT'),
            SizedBox(height: 6),
            Text(
              'Lokale opnames',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      if (count > 0)
        Text(
          '$count ${count == 1 ? 'sessie' : 'sessies'}',
          style: const TextStyle(color: SnorerColors.muted, fontSize: 13),
        ),
    ],
  );
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: SnorerColors.border),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: SnorerColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nog geen nacht vastgelegd',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Je eerste opname verschijnt hier zodra je de sessie stopt. Alles blijft op dit apparaat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SnorerColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
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
    final timelineDuration = <double>[
      recording.durationSeconds,
      playback.durationSeconds,
      1.0,
    ].reduce((a, b) => a > b ? a : b);
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
                      builder: (context, constraints) => GestureDetector(
                        key: const Key('recording_waveform'),
                        onTapUp: (details) {
                          final fraction =
                              (details.localPosition.dx / constraints.maxWidth)
                                  .clamp(0, 1)
                                  .toDouble();
                          unawaited(onSeek(fraction * timelineDuration));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        ) ??
                                        (index / _waveform.length <=
                                                playback.progress
                                            ? SnorerColors.primary
                                            : SnorerColors.waveInactive),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  key: const Key('toggle_playback'),
                  onPressed: () => unawaited(onTogglePlayback()),
                  tooltip: playback.isPlaying
                      ? 'Pauzeer opname'
                      : 'Speel opname af',
                  icon: Icon(
                    playback.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
            Slider(
              value: playback.progress,
              onChanged: playback.durationSeconds > 0
                  ? (value) => unawaited(onSeek(value * timelineDuration))
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatClock(playback.currentSeconds),
                  style: const TextStyle(
                    color: SnorerColors.muted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatClock(
                    playback.durationSeconds > 0
                        ? playback.durationSeconds
                        : recording.durationSeconds,
                  ),
                  style: const TextStyle(
                    color: SnorerColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(recording.startedAt),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              '${labelText(recording.label)} · ${formatDuration(recording.durationSeconds)}',
              style: const TextStyle(color: SnorerColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (recording.soundEvents.isEmpty)
              const Text(
                'Geen duidelijke snurk- of praatmomenten herkend.',
                style: TextStyle(color: SnorerColors.muted, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EventChip(
                    color: SnorerColors.danger,
                    text: eventCountText(SoundEventKind.snoring, snoringCount),
                  ),
                  _EventChip(
                    color: SnorerColors.warning,
                    text: eventCountText(SoundEventKind.speech, speechCount),
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
  ) {
    final start = index / _waveform.length * timelineDuration;
    final end = (index + 1) / _waveform.length * timelineDuration;
    for (final event in recording.soundEvents) {
      if (event.startSeconds < end && event.endSeconds > start) {
        return event.kind == SoundEventKind.snoring
            ? SnorerColors.danger
            : SnorerColors.warning;
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
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      color: SnorerColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? SnorerColors.primaryDark : SnorerColors.border,
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
                      color: selected
                          ? SnorerColors.primary
                          : SnorerColors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Center(
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: SnorerColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 0, maxWidth: 145),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(recording.startedAt),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatDuration(recording.durationSeconds),
                        style: const TextStyle(
                          color: SnorerColors.muted,
                          fontSize: 12,
                        ),
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
              tooltip: 'Verwijder opname',
              onPressed: onDelete,
              color: SnorerColors.danger,
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ],
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: active ? SnorerColors.text : SnorerColors.muted,
      backgroundColor: active ? SnorerColors.primaryDark : Colors.transparent,
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    child: Text(
      label.displayName,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SnorerColors.errorBackground,
      border: Border.all(color: SnorerColors.errorBorder),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Er ging iets mis',
          style: TextStyle(
            color: SnorerColors.danger,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: const TextStyle(
            color: SnorerColors.errorText,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        SizedBox(height: 14),
        Text(
          'Privé by default',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Audio, labels en detectie-events blijven in de documentmap van Snorer. De app gebruikt geen account, cloudsync of advertenties.',
          style: TextStyle(
            color: SnorerColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
