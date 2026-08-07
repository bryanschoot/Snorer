import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Badge, BadgeText } from '../../../../components/ui/badge';
import { colors } from '../../../theme';
import { formatClock, formatDate, formatDuration, getRecordingLabelText } from '../recording-utils';
import type { StoredRecording } from '../recording-types';

const waveformBars = [0.35, 0.58, 0.82, 0.46, 0.67, 0.94, 0.52, 0.73, 0.39, 0.63, 0.88, 0.5, 0.76, 0.42, 0.6];
interface RecordingPlayerCardProps {
  recording: StoredRecording;
  currentTime: number;
  duration: number;
  progress: number;
  isPlaying: boolean;
  onSeek: (seconds: number) => Promise<void>;
  onTogglePlayback: () => void;
}

export function RecordingPlayerCard({
  recording,
  currentTime,
  duration,
  progress,
  isPlaying,
  onSeek,
  onTogglePlayback,
}: RecordingPlayerCardProps) {
  const [waveformWidth, setWaveformWidth] = useState(0);
  const timelineDuration = Math.max(recording.durationSeconds, duration, 1);
  const snoringCount = recording.soundEvents.filter((event) => event.kind === 'snoring').length;
  const speechCount = recording.soundEvents.filter((event) => event.kind === 'speech').length;

  return (
    <View style={styles.card}>
      <View style={styles.topRow}>
        <Pressable
          style={styles.waveform}
          onLayout={({ nativeEvent }) => setWaveformWidth(nativeEvent.layout.width)}
          onPress={({ nativeEvent }) => {
            if (waveformWidth > 0) {
              void onSeek((nativeEvent.locationX / waveformWidth) * timelineDuration);
            }
          }}
          accessibilityRole="adjustable"
          accessibilityLabel={`Lokale opname, ${snoringCount} snurkmomenten en ${speechCount} praatmomenten`}
          accessibilityHint="Tik op de tijdlijn om naar dat moment te springen."
        >
          {waveformBars.map((height, index) => {
            const segmentStart = (index / waveformBars.length) * timelineDuration;
            const segmentEnd = ((index + 1) / waveformBars.length) * timelineDuration;
            const detectedEvent = recording.soundEvents.find(
              (event) => event.startSeconds < segmentEnd && event.endSeconds > segmentStart,
            );

            return (
              <View
                key={`wave-${index}`}
                style={[
                  styles.waveBar,
                  { height: 14 + height * 28 },
                  detectedEvent?.kind === 'snoring' && styles.waveBarSnoring,
                  detectedEvent?.kind === 'speech' && styles.waveBarSpeech,
                  !detectedEvent && index / waveformBars.length <= progress && styles.waveBarActive,
                ]}
              />
            );
          })}
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={isPlaying ? 'Pauzeer opname' : 'Speel opname af'}
          onPress={onTogglePlayback}
          style={({ pressed }) => [styles.playButton, pressed && styles.buttonPressed]}
        >
          <Text style={styles.playButtonText}>{isPlaying ? 'Ⅱ' : '▶'}</Text>
        </Pressable>
      </View>
      <View style={styles.metaRow}>
        <Text style={styles.playerTime}>{formatClock(currentTime)}</Text>
        <Text style={styles.playerTime}>{formatClock(duration)}</Text>
      </View>
      <Text style={styles.title}>{formatDate(recording.startedAt)}</Text>
      <Text style={styles.subtitle}>
        {getRecordingLabelText(recording.label)} · {formatDuration(recording.durationSeconds)}
      </Text>
      {recording.soundEvents.length > 0 ? (
        <View style={styles.eventLegend}>
          <Badge variant="destructive">
            <BadgeText>
              {snoringCount} {snoringCount === 1 ? 'snurkmoment' : 'snurkmomenten'}
            </BadgeText>
          </Badge>
          <Badge variant="secondary">
            <BadgeText>
              {speechCount} {speechCount === 1 ? 'praatmoment' : 'praatmomenten'}
            </BadgeText>
          </Badge>
        </View>
      ) : (
        <Text style={styles.noEventsText}>Geen duidelijke snurk- of praatmomenten herkend.</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surfaceRaised,
    borderRadius: 22,
    padding: 17,
    borderWidth: 1,
    borderColor: colors.border,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  waveform: {
    flex: 1,
    height: 53,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 3,
  },
  waveBar: {
    flex: 1,
    maxWidth: 7,
    borderRadius: 5,
    backgroundColor: colors.waveInactive,
  },
  waveBarActive: {
    backgroundColor: colors.primary,
  },
  waveBarSnoring: {
    backgroundColor: colors.danger,
  },
  waveBarSpeech: {
    backgroundColor: colors.warning,
  },
  playButton: {
    width: 54,
    height: 54,
    borderRadius: 54,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  playButtonText: {
    color: colors.background,
    fontSize: 21,
    fontWeight: '900',
    marginLeft: 2,
  },
  buttonPressed: {
    opacity: 0.76,
  },
  metaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 9,
  },
  playerTime: {
    color: colors.muted,
    fontSize: 11,
    fontVariant: ['tabular-nums'],
  },
  title: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '800',
    marginTop: 16,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 4,
  },
  eventLegend: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginTop: 12,
  },
  noEventsText: {
    color: colors.muted,
    fontSize: 12,
    marginTop: 12,
  },
});
