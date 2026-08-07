import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';
import { formatDate, formatDuration } from '../recording-utils';
import type { RecordingLabel, StoredRecording } from '../recording-types';

interface RecordingListProps {
  recordings: StoredRecording[];
  selectedId: string | null;
  onSelect: (recording: StoredRecording) => void;
  onToggleLabel: (id: string, label: RecordingLabel) => void;
  onDelete: (recording: StoredRecording) => void;
}

export function RecordingList({
  recordings,
  selectedId,
  onSelect,
  onToggleLabel,
  onDelete,
}: RecordingListProps) {
  return (
    <View style={styles.list}>
      {recordings.map((recording) => {
        const isSelected = recording.id === selectedId;
        const dateLabel = formatDate(recording.startedAt);

        return (
          <View
            key={recording.id}
            style={[styles.row, isSelected && styles.rowSelected]}
          >
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`Selecteer opname van ${dateLabel}`}
              accessibilityState={{ selected: isSelected }}
              onPress={() => onSelect(recording)}
              style={styles.select}
            >
              <View style={[styles.marker, isSelected && styles.markerSelected]}>
                <View style={styles.markerInner} />
              </View>
              <View style={styles.copy}>
                <Text style={styles.title}>{dateLabel}</Text>
                <Text style={styles.subtitle}>{formatDuration(recording.durationSeconds)}</Text>
              </View>
            </Pressable>
            <View style={styles.actions}>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`Label als snurken, ${dateLabel}`}
                accessibilityState={{ selected: recording.label === 'snoring' }}
                onPress={() => onToggleLabel(recording.id, 'snoring')}
                style={[styles.labelButton, recording.label === 'snoring' && styles.labelButtonActive]}
              >
                <Text
                  style={[
                    styles.labelButtonText,
                    recording.label === 'snoring' && styles.labelButtonTextActive,
                  ]}
                >
                  Snurken
                </Text>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`Label als praten in slaap, ${dateLabel}`}
                accessibilityState={{ selected: recording.label === 'sleep-talking' }}
                onPress={() => onToggleLabel(recording.id, 'sleep-talking')}
                style={[
                  styles.labelButton,
                  recording.label === 'sleep-talking' && styles.labelButtonActive,
                ]}
              >
                <Text
                  style={[
                    styles.labelButtonText,
                    recording.label === 'sleep-talking' && styles.labelButtonTextActive,
                  ]}
                >
                  Praten
                </Text>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`Verwijder opname van ${dateLabel}`}
                onPress={() => onDelete(recording)}
                style={styles.deleteButton}
              >
                <Text style={styles.deleteButtonText}>×</Text>
              </Pressable>
            </View>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    gap: 9,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 17,
    padding: 11,
    borderWidth: 1,
    borderColor: 'transparent',
    gap: 7,
  },
  rowSelected: {
    borderColor: colors.primaryDark,
  },
  select: {
    flex: 1,
    minHeight: 47,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  marker: {
    width: 28,
    height: 28,
    borderRadius: 28,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  markerSelected: {
    borderColor: colors.primary,
    backgroundColor: colors.primaryDark,
  },
  markerInner: {
    width: 8,
    height: 8,
    borderRadius: 8,
    backgroundColor: colors.primary,
  },
  copy: {
    flex: 1,
  },
  title: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '700',
  },
  subtitle: {
    color: colors.muted,
    fontSize: 12,
    marginTop: 3,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  labelButton: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 9,
    paddingHorizontal: 7,
    paddingVertical: 7,
  },
  labelButtonActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primaryDark,
  },
  labelButtonText: {
    color: colors.muted,
    fontSize: 10,
    fontWeight: '700',
  },
  labelButtonTextActive: {
    color: colors.text,
  },
  deleteButton: {
    width: 28,
    height: 34,
    alignItems: 'center',
    justifyContent: 'center',
  },
  deleteButtonText: {
    color: colors.muted,
    fontSize: 23,
    fontWeight: '300',
  },
});
