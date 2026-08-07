import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';
import type { SoundDetectionStatus } from '../hooks/use-sleep-recorder';
import { formatClock } from '../recording-utils';

interface RecorderCardProps {
  durationSeconds: number;
  isRecording: boolean;
  isStarting: boolean;
  isStopping: boolean;
  soundDetectionStatus: SoundDetectionStatus;
  onStart: () => void;
  onStop: () => void;
}

export function RecorderCard({
  durationSeconds,
  isRecording,
  isStarting,
  isStopping,
  soundDetectionStatus,
  onStart,
  onStop,
}: RecorderCardProps) {
  const isBusy = isStarting || isStopping;
  const detectionHint =
    soundDetectionStatus === 'ready'
      ? 'Snurken en praten worden lokaal gemarkeerd.'
      : soundDetectionStatus === 'loading'
        ? 'Geluidsmodel wordt klaargemaakt…'
        : soundDetectionStatus === 'unavailable'
          ? 'Opname werkt, maar geluidslabels zijn niet beschikbaar.'
          : 'Geluidslabels worden alleen op dit apparaat verwerkt.';

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View>
          <Text style={styles.eyebrow}>NIEUWE SLAAPSESSIE</Text>
          <Text style={styles.title}>{isRecording ? 'Opname loopt' : 'Klaar voor de nacht'}</Text>
        </View>
        <View style={[styles.statusPill, isRecording && styles.statusPillActive]}>
          <View style={[styles.statusDot, isRecording && styles.statusDotActive]} />
          <Text style={styles.statusText}>{isRecording ? 'Actief' : 'Inactief'}</Text>
        </View>
      </View>

      <View style={styles.timerRow}>
        <Text style={styles.timer}>{formatClock(durationSeconds)}</Text>
        <Text style={styles.timerHint}>
          {isRecording ? 'geluid wordt lokaal opgeslagen' : 'start wanneer je gaat slapen'}
        </Text>
      </View>

      {isRecording ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Stop de slaapopname"
          accessibilityState={{ disabled: isStopping }}
          disabled={isStopping}
          onPress={onStop}
          style={({ pressed }) => [
            styles.primaryButton,
            styles.stopButton,
            pressed && styles.buttonPressed,
            isStopping && styles.buttonDisabled,
          ]}
        >
          <View style={styles.stopIcon} />
          <Text style={[styles.primaryButtonText, styles.stopButtonText]}>
            {isStopping ? 'Opname afronden…' : 'Opname stoppen'}
          </Text>
        </Pressable>
      ) : (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Start een lokale slaapopname"
          accessibilityState={{ disabled: isBusy }}
          disabled={isBusy}
          onPress={onStart}
          style={({ pressed }) => [
            styles.primaryButton,
            pressed && styles.buttonPressed,
            isStarting && styles.buttonDisabled,
          ]}
        >
          <View style={styles.recordIcon} />
          <Text style={styles.primaryButtonText}>
            {isStarting ? 'Microfoon klaarmaken…' : 'Slaapopname starten'}
          </Text>
        </Pressable>
      )}

      <View style={styles.infoRow}>
        <Text style={styles.infoIcon}>i</Text>
        <Text style={styles.infoText}>
          Android houdt de opname actief met een zichtbare systeemmelding, ook als je scherm vergrendelt.
        </Text>
      </View>
      <Text style={styles.analysisText}>{detectionHint}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: 26,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
  },
  eyebrow: {
    color: colors.primary,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
  },
  title: {
    color: colors.text,
    fontSize: 23,
    lineHeight: 28,
    fontWeight: '800',
    marginTop: 7,
  },
  statusPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surfaceSoft,
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 6,
  },
  statusPillActive: {
    backgroundColor: '#3A2938',
  },
  statusDot: {
    width: 7,
    height: 7,
    borderRadius: 7,
    backgroundColor: colors.muted,
    marginRight: 6,
  },
  statusDotActive: {
    backgroundColor: colors.danger,
  },
  statusText: {
    color: colors.text,
    fontSize: 11,
    fontWeight: '700',
  },
  timerRow: {
    marginTop: 26,
    marginBottom: 20,
  },
  timer: {
    color: colors.text,
    fontSize: 58,
    lineHeight: 64,
    fontWeight: '300',
    letterSpacing: -2,
  },
  timerHint: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 3,
  },
  primaryButton: {
    minHeight: 56,
    borderRadius: 17,
    backgroundColor: colors.primary,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 18,
    gap: 10,
  },
  stopButton: {
    backgroundColor: colors.dangerDark,
  },
  primaryButtonText: {
    color: colors.background,
    fontSize: 16,
    fontWeight: '800',
  },
  stopButtonText: {
    color: colors.text,
  },
  recordIcon: {
    width: 12,
    height: 12,
    borderRadius: 12,
    backgroundColor: colors.background,
  },
  stopIcon: {
    width: 13,
    height: 13,
    borderRadius: 3,
    backgroundColor: colors.text,
  },
  buttonPressed: {
    opacity: 0.76,
  },
  buttonDisabled: {
    opacity: 0.55,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginTop: 17,
    gap: 8,
  },
  infoIcon: {
    width: 17,
    height: 17,
    borderRadius: 17,
    borderWidth: 1,
    borderColor: colors.muted,
    color: colors.muted,
    fontSize: 11,
    fontWeight: '800',
    textAlign: 'center',
    lineHeight: 15,
  },
  infoText: {
    flex: 1,
    color: colors.muted,
    fontSize: 12,
    lineHeight: 18,
  },
  analysisText: {
    color: colors.primary,
    fontSize: 12,
    lineHeight: 18,
    marginTop: 8,
  },
});
