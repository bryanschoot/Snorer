import { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaView } from 'react-native-safe-area-context';

import { colors } from '../../theme';
import { AppFooter } from './components/app-footer';
import { AppHeader } from './components/app-header';
import { EmptyRecordingState } from './components/empty-recording-state';
import { ErrorCard } from './components/error-card';
import { PermissionBanner } from './components/permission-banner';
import { RecorderCard } from './components/recorder-card';
import { RecordingList } from './components/recording-list';
import { RecordingPlayerCard } from './components/recording-player-card';
import { ScopeCard } from './components/scope-card';
import { useRecordingLibrary } from './hooks/use-recording-library';
import { useRecordingPlayer } from './hooks/use-recording-player';
import { useSleepRecorder } from './hooks/use-sleep-recorder';
import type { RecordingDraft, RecordingLabel, StoredRecording } from './recording-types';

export function RecordingScreen() {
  const library = useRecordingLibrary();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selectedRecording = useMemo(
    () => library.recordings.find((recording) => recording.id === selectedId) ?? library.recordings[0] ?? null,
    [library.recordings, selectedId],
  );

  const handleRecordingFinished = useCallback(
    (draft: RecordingDraft) => {
      const nextRecording = library.addRecording(draft);
      setSelectedId(nextRecording.id);
    },
    [library.addRecording],
  );
  const recorder = useSleepRecorder(handleRecordingFinished);
  const player = useRecordingPlayer(selectedRecording);

  useEffect(() => {
    if (!selectedRecording && selectedId !== null) {
      setSelectedId(null);
    }
  }, [selectedId, selectedRecording]);

  const handleSelectRecording = useCallback(
    (recording: StoredRecording) => {
      if (recording.id === selectedId) {
        return;
      }

      player.pause();
      setSelectedId(recording.id);
    },
    [player.pause, selectedId],
  );

  const handleDeleteRecording = useCallback(
    (recording: StoredRecording) => {
      Alert.alert(
        'Opname verwijderen?',
        'Het lokale audiobestand en de vermelding worden van dit apparaat verwijderd.',
        [
          { text: 'Annuleren', style: 'cancel' },
          {
            text: 'Verwijderen',
            style: 'destructive',
            onPress: () => {
              if (!library.removeRecording(recording)) {
                return;
              }

              player.pause();
              if (selectedId === recording.id) {
                setSelectedId(null);
              }
            },
          },
        ],
      );
    },
    [library.removeRecording, player.pause, selectedId],
  );

  const handleDeleteAll = useCallback(() => {
    if (library.recordings.length === 0) {
      return;
    }

    Alert.alert(
      'Alle opnames verwijderen?',
      'Alle lokale audiobestanden en labels worden permanent van dit apparaat verwijderd.',
      [
        { text: 'Annuleren', style: 'cancel' },
        {
          text: 'Alles verwijderen',
          style: 'destructive',
          onPress: () => {
            if (!library.removeAllRecordings()) {
              return;
            }

            player.pause();
            setSelectedId(null);
          },
        },
      ],
    );
  }, [library.recordings.length, library.removeAllRecordings, player.pause]);

  const handleToggleLabel = useCallback(
    (id: string, label: RecordingLabel) => {
      library.toggleLabel(id, label);
    },
    [library.toggleLabel],
  );

  const handleStartRecording = useCallback(() => {
    void recorder.startRecording().then((result) => {
      if (result === 'permission-denied') {
        Alert.alert(
          'Microfoon nodig',
          'Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal op te nemen.',
        );
      }
    });
  }, [recorder.startRecording]);

  const error = recorder.error ?? player.error ?? library.error;

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      <StatusBar style="light" />
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <AppHeader />

        {recorder.permissionGranted === false ? <PermissionBanner /> : null}

        <RecorderCard
          durationSeconds={recorder.durationSeconds}
          isRecording={recorder.isRecording}
          isStarting={recorder.isStarting}
          isStopping={recorder.isStopping}
          onStart={handleStartRecording}
          onStop={() => void recorder.stopRecording()}
        />

        <ScopeCard />

        <View style={styles.sectionHeader}>
          <View>
            <Text style={styles.sectionEyebrow}>OCHTENDOVERZICHT</Text>
            <Text style={styles.sectionTitle}>Lokale opnames</Text>
          </View>
          {library.recordings.length > 0 ? (
            <Text style={styles.recordingCount}>
              {library.recordings.length} {library.recordings.length === 1 ? 'sessie' : 'sessies'}
            </Text>
          ) : null}
        </View>

        {library.isHydrated ? (
          selectedRecording ? (
            <RecordingPlayerCard
              recording={selectedRecording}
              currentTime={player.currentTime}
              duration={player.duration}
              progress={player.progress}
              isPlaying={player.isPlaying}
              onTogglePlayback={() => void player.togglePlayback()}
            />
          ) : (
            <EmptyRecordingState />
          )
        ) : null}

        {library.recordings.length > 0 ? (
          <RecordingList
            recordings={library.recordings}
            selectedId={selectedRecording?.id ?? null}
            onSelect={handleSelectRecording}
            onToggleLabel={handleToggleLabel}
            onDelete={handleDeleteRecording}
          />
        ) : null}

        {library.recordings.length > 0 ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Verwijder alle lokale opnames"
            onPress={handleDeleteAll}
            style={({ pressed }) => [styles.deleteAllButton, pressed && styles.buttonPressed]}
          >
            <Text style={styles.deleteAllText}>Alle lokale opnames verwijderen</Text>
          </Pressable>
        ) : null}

        {error ? <ErrorCard message={error} /> : null}

        <AppFooter />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    paddingHorizontal: 20,
    paddingTop: 18,
    paddingBottom: 42,
    gap: 18,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  sectionEyebrow: {
    color: colors.primary,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
  },
  sectionTitle: {
    color: colors.text,
    fontSize: 25,
    fontWeight: '800',
    marginTop: 6,
  },
  recordingCount: {
    color: colors.muted,
    fontSize: 13,
    marginBottom: 3,
  },
  deleteAllButton: {
    alignSelf: 'flex-start',
    paddingVertical: 4,
  },
  deleteAllText: {
    color: colors.danger,
    fontSize: 13,
    fontWeight: '700',
  },
  buttonPressed: {
    opacity: 0.76,
  },
});
