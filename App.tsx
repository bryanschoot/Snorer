import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  RecordingPresets,
  type RecordingStatus,
  requestNotificationPermissionsAsync,
  requestRecordingPermissionsAsync,
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
  useAudioRecorder,
  useAudioRecorderState,
} from 'expo-audio';
import { File } from 'expo-file-system';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

type RecordingLabel = 'snoring' | 'sleep-talking';

interface StoredRecording {
  id: string;
  uri: string;
  startedAt: string;
  durationSeconds: number;
  label: RecordingLabel | null;
}

const RECORDINGS_STORAGE_KEY = '@snorer/recordings/v1';
const recordingOptions = {
  ...RecordingPresets.HIGH_QUALITY,
  directory: 'document' as const,
};

const colors = {
  background: '#071A2D',
  surface: '#102A43',
  surfaceRaised: '#163B5C',
  surfaceSoft: '#12314C',
  border: '#285474',
  text: '#F3F8FC',
  muted: '#A8C0D4',
  primary: '#5ED0C0',
  primaryDark: '#2B9C91',
  danger: '#FF8B8B',
  dangerDark: '#9D3F55',
  warning: '#FFD166',
};

function isStoredRecording(value: unknown): value is StoredRecording {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const candidate = value as Record<string, unknown>;
  const hasValidLabel =
    candidate.label === null ||
    candidate.label === 'snoring' ||
    candidate.label === 'sleep-talking';

  return (
    typeof candidate.id === 'string' &&
    typeof candidate.uri === 'string' &&
    typeof candidate.startedAt === 'string' &&
    typeof candidate.durationSeconds === 'number' &&
    Number.isFinite(candidate.durationSeconds) &&
    candidate.durationSeconds >= 0 &&
    hasValidLabel
  );
}

function parseStoredRecordings(raw: string | null): StoredRecording[] {
  if (!raw) {
    return [];
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed.filter(isStoredRecording).map((recording) => ({
      ...recording,
      label: recording.label ?? null,
    }));
  } catch {
    return [];
  }
}

function createId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`;
}

function formatDuration(totalSeconds: number): string {
  const seconds = Math.max(0, Math.round(totalSeconds));
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainder = seconds % 60;

  if (hours > 0) {
    return `${hours}u ${minutes.toString().padStart(2, '0')}m`;
  }

  return `${minutes}m ${remainder.toString().padStart(2, '0')}s`;
}

function formatClock(totalSeconds: number): string {
  const seconds = Math.max(0, Math.floor(totalSeconds));
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${remainder
    .toString()
    .padStart(2, '0')}`;
}

function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return 'Onbekende datum';
  }

  return new Intl.DateTimeFormat('nl-NL', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function labelText(label: RecordingLabel | null): string {
  if (label === 'snoring') {
    return 'Snurken';
  }

  if (label === 'sleep-talking') {
    return 'Praten in slaap';
  }

  return 'Nog niet gelabeld';
}

function AppContent() {
  const [recordings, setRecordings] = useState<StoredRecording[]>([]);
  const [isHydrated, setIsHydrated] = useState(false);
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);
  const [isStarting, setIsStarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const activeStartedAtRef = useRef<string | null>(null);
  const finalizingRef = useRef(false);

  useEffect(() => {
    let isMounted = true;

    const loadRecordings = async () => {
      try {
        const raw = await AsyncStorage.getItem(RECORDINGS_STORAGE_KEY);
        if (isMounted) {
          setRecordings(parseStoredRecordings(raw));
        }
      } catch {
        if (isMounted) {
          setError('De lokale opnamegeschiedenis kon niet worden gelezen.');
        }
      } finally {
        if (isMounted) {
          setIsHydrated(true);
        }
      }
    };

    void loadRecordings();
    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    if (!isHydrated) {
      return;
    }

    void AsyncStorage.setItem(RECORDINGS_STORAGE_KEY, JSON.stringify(recordings)).catch(() => {
      setError('De opname is gemaakt, maar de lokale index kon niet worden bijgewerkt.');
    });
  }, [isHydrated, recordings]);

  useEffect(() => {
    let isMounted = true;

    const readPermission = async () => {
      try {
        const response = await import('expo-audio').then(({ getRecordingPermissionsAsync }) =>
          getRecordingPermissionsAsync(),
        );
        if (isMounted) {
          setPermissionGranted(response.granted);
        }
      } catch {
        if (isMounted) {
          setPermissionGranted(false);
        }
      }
    };

    void readPermission();
    void setAudioModeAsync({
      allowsRecording: true,
      allowsBackgroundRecording: true,
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: 'doNotMix',
    }).catch(() => {
      // Audio mode is configured again immediately before recording or playback.
    });

    return () => {
      isMounted = false;
    };
  }, []);

  const finalizeRecording = useCallback((uri: string | null, durationOverride?: number) => {
    const startedAt = activeStartedAtRef.current;
    if (!uri || !startedAt || finalizingRef.current) {
      return;
    }

    finalizingRef.current = true;
    activeStartedAtRef.current = null;
    const elapsedSeconds = Math.max(
      1,
      Math.round((Date.now() - new Date(startedAt).getTime()) / 1000),
    );
    const durationSeconds = Math.max(1, durationOverride ?? elapsedSeconds);
    const nextRecording: StoredRecording = {
      id: createId(),
      uri,
      startedAt,
      durationSeconds,
      label: null,
    };

    setRecordings((current) => [nextRecording, ...current]);
    setSelectedId(nextRecording.id);
    setError(null);
    finalizingRef.current = false;
  }, []);

  const handleRecorderStatus = useCallback(
    (status: RecordingStatus) => {
      if (status.hasError) {
        setError(status.error ?? 'De opname werd door Android onderbroken.');
      }

      if (status.isFinished && status.url) {
        finalizeRecording(status.url);
      }
    },
    [finalizeRecording],
  );

  const recorder = useAudioRecorder(recordingOptions, handleRecorderStatus);
  const recorderState = useAudioRecorderState(recorder, 500);

  const selectedRecording = useMemo(
    () => recordings.find((recording) => recording.id === selectedId) ?? recordings[0] ?? null,
    [recordings, selectedId],
  );
  const playerSource = useMemo(
    () =>
      selectedRecording
        ? { uri: selectedRecording.uri, name: `Snorer ${formatDate(selectedRecording.startedAt)}` }
        : null,
    [selectedRecording?.id, selectedRecording?.startedAt, selectedRecording?.uri],
  );
  const player = useAudioPlayer(playerSource, { updateInterval: 250 });
  const playerStatus = useAudioPlayerStatus(player);

  useEffect(() => {
    if (!selectedRecording && selectedId !== null) {
      setSelectedId(null);
    }
  }, [selectedId, selectedRecording]);

  useEffect(() => {
    return () => {
      player.pause();
      player.clearLockScreenControls();
    };
  }, [player]);

  const configureRecordingAudio = useCallback(async (): Promise<boolean> => {
    const response = await requestRecordingPermissionsAsync();
    setPermissionGranted(response.granted);
    if (!response.granted) {
      return false;
    }

    if (Platform.OS === 'android') {
      await requestNotificationPermissionsAsync().catch(() => undefined);
    }

    await setAudioModeAsync({
      allowsRecording: true,
      allowsBackgroundRecording: true,
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: 'doNotMix',
    });
    return true;
  }, []);

  const handleStartRecording = useCallback(async () => {
    if (recorderState.isRecording || isStarting) {
      return;
    }

    setError(null);
    setIsStarting(true);
    try {
      const allowed = await configureRecordingAudio();
      if (!allowed) {
        Alert.alert(
          'Microfoon nodig',
          'Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal op te nemen.',
        );
        return;
      }

      await recorder.prepareToRecordAsync();
      activeStartedAtRef.current = new Date().toISOString();
      recorder.record();
    } catch (cause) {
      activeStartedAtRef.current = null;
      const message = cause instanceof Error ? cause.message : 'Onbekende audiofout';
      setError(`Opname starten lukt niet: ${message}`);
    } finally {
      setIsStarting(false);
    }
  }, [configureRecordingAudio, isStarting, recorder, recorderState.isRecording]);

  const handleStopRecording = useCallback(async () => {
    if (!recorderState.isRecording || isStopping) {
      return;
    }

    setIsStopping(true);
    const startedAt = activeStartedAtRef.current;
    const elapsedSeconds = startedAt
      ? Math.max(1, Math.round((Date.now() - new Date(startedAt).getTime()) / 1000))
      : undefined;

    try {
      await recorder.stop();
      finalizeRecording(recorder.uri, elapsedSeconds);
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : 'Onbekende audiofout';
      setError(`Opname stoppen lukt niet: ${message}`);
    } finally {
      setIsStopping(false);
    }
  }, [finalizeRecording, isStopping, recorder, recorderState.isRecording]);

  const handleTogglePlayback = useCallback(async () => {
    if (!selectedRecording) {
      return;
    }

    try {
      if (player.playing) {
        player.pause();
        return;
      }

      await setAudioModeAsync({
        allowsRecording: false,
        playsInSilentMode: true,
        shouldPlayInBackground: true,
        interruptionMode: 'doNotMix',
      });
      player.setActiveForLockScreen(true, {
        title: 'Snorer-opname',
        artist: labelText(selectedRecording.label),
        albumTitle: 'Lokaal opgeslagen',
      });
      player.play();
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : 'Onbekende afspeelfout';
      setError(`Afspelen lukt niet: ${message}`);
    }
  }, [player, selectedRecording]);

  const handleSelectRecording = useCallback(
    (recording: StoredRecording) => {
      if (recording.id === selectedId) {
        return;
      }
      player.pause();
      setSelectedId(recording.id);
    },
    [player, selectedId],
  );

  const handleLabelRecording = useCallback((id: string, label: RecordingLabel) => {
    setRecordings((current) =>
      current.map((recording) =>
        recording.id === id
          ? { ...recording, label: recording.label === label ? null : label }
          : recording,
      ),
    );
  }, []);

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
              try {
                const file = new File(recording.uri);
                if (file.exists) {
                  file.delete();
                }
                player.pause();
                setRecordings((current) =>
                  current.filter((candidate) => candidate.id !== recording.id),
                );
                if (selectedId === recording.id) {
                  setSelectedId(null);
                }
              } catch {
                setError('Deze opname kon niet van het apparaat worden verwijderd.');
              }
            },
          },
        ],
      );
    },
    [player, selectedId],
  );

  const handleDeleteAll = useCallback(() => {
    if (recordings.length === 0) {
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
            try {
              recordings.forEach((recording) => {
                const file = new File(recording.uri);
                if (file.exists) {
                  file.delete();
                }
              });
              player.pause();
              setRecordings([]);
              setSelectedId(null);
            } catch {
              setError('Niet alle lokale opnames konden worden verwijderd.');
            }
          },
        },
      ],
    );
  }, [player, recordings]);

  const recordingDuration = recorderState.isRecording
    ? recorderState.durationMillis / 1000
    : 0;
  const playerDuration = playerStatus.duration || selectedRecording?.durationSeconds || 0;
  const playerProgress =
    playerDuration > 0 ? Math.min(1, Math.max(0, playerStatus.currentTime / playerDuration)) : 0;

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      <StatusBar style="light" />
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.header}>
          <View>
            <Text style={styles.eyebrow}>SNORER · ANDROID EERST</Text>
            <Text style={styles.title}>Luister naar je nacht.</Text>
            <Text style={styles.subtitle}>
              Neem slaapgeluiden op en luister ze lokaal terug. Geen upload, geen automatische detectie.
            </Text>
          </View>
          <View style={styles.localBadge}>
            <View style={styles.localDot} />
            <Text style={styles.localBadgeText}>Lokaal</Text>
          </View>
        </View>

        {permissionGranted === false ? (
          <View style={styles.permissionBanner} accessibilityLiveRegion="polite">
            <Text style={styles.bannerTitle}>Microfoontoegang staat nog uit</Text>
            <Text style={styles.bannerText}>
              Snorer kan pas opnemen nadat Android de microfoon toestemming geeft. Er wordt niets naar een server gestuurd.
            </Text>
          </View>
        ) : null}

        <View style={styles.recordCard}>
          <View style={styles.cardHeader}>
            <View>
              <Text style={styles.cardEyebrow}>NIEUWE SLAAPSESSIE</Text>
              <Text style={styles.cardTitle}>
                {recorderState.isRecording ? 'Opname loopt' : 'Klaar voor de nacht'}
              </Text>
            </View>
            <View style={[styles.statusPill, recorderState.isRecording && styles.statusPillActive]}>
              <View style={[styles.statusDot, recorderState.isRecording && styles.statusDotActive]} />
              <Text style={styles.statusText}>
                {recorderState.isRecording ? 'Actief' : 'Inactief'}
              </Text>
            </View>
          </View>

          <View style={styles.timerRow}>
            <Text style={styles.timer}>{formatClock(recordingDuration)}</Text>
            <Text style={styles.timerHint}>
              {recorderState.isRecording ? 'geluid wordt lokaal opgeslagen' : 'start wanneer je gaat slapen'}
            </Text>
          </View>

          {recorderState.isRecording ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Stop de slaapopname"
              disabled={isStopping}
              onPress={() => void handleStopRecording()}
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
              disabled={isStarting}
              onPress={() => void handleStartRecording()}
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
        </View>

        <View style={styles.scopeCard}>
          <View style={styles.scopeMark}>
            <Text style={styles.scopeMarkText}>✓</Text>
          </View>
          <View style={styles.scopeCopy}>
            <Text style={styles.scopeTitle}>Jij bepaalt wat je hoort</Text>
            <Text style={styles.scopeText}>
              Snurken en praten in je slaap worden in deze MVP niet automatisch herkend. Je kunt een opname achteraf zelf labelen.
            </Text>
          </View>
        </View>

        <View style={styles.sectionHeader}>
          <View>
            <Text style={styles.sectionEyebrow}>OCHTENDOVERZICHT</Text>
            <Text style={styles.sectionTitle}>Lokale opnames</Text>
          </View>
          {recordings.length > 0 ? (
            <Text style={styles.recordingCount}>
              {recordings.length} {recordings.length === 1 ? 'sessie' : 'sessies'}
            </Text>
          ) : null}
        </View>

        {selectedRecording ? (
          <View style={styles.playerCard}>
            <View style={styles.playerTopRow}>
              <View style={styles.waveform} accessibilityLabel="Lokale opname">
                {[0.35, 0.58, 0.82, 0.46, 0.67, 0.94, 0.52, 0.73, 0.39, 0.63, 0.88, 0.5, 0.76, 0.42, 0.6].map(
                  (height, index) => (
                    <View
                      key={index}
                      style={[
                        styles.waveBar,
                        { height: 14 + height * 28 },
                        index / 15 <= playerProgress && styles.waveBarActive,
                      ]}
                    />
                  ),
                )}
              </View>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={player.playing ? 'Pauzeer opname' : 'Speel opname af'}
                onPress={() => void handleTogglePlayback()}
                style={({ pressed }) => [styles.playButton, pressed && styles.buttonPressed]}
              >
                <Text style={styles.playButtonText}>{player.playing ? 'Ⅱ' : '▶'}</Text>
              </Pressable>
            </View>
            <View style={styles.playerMetaRow}>
              <Text style={styles.playerTime}>{formatClock(playerStatus.currentTime)}</Text>
              <Text style={styles.playerTime}>{formatClock(playerDuration)}</Text>
            </View>
            <Text style={styles.playerTitle}>{formatDate(selectedRecording.startedAt)}</Text>
            <Text style={styles.playerSubtitle}>
              {labelText(selectedRecording.label)} · {formatDuration(selectedRecording.durationSeconds)}
            </Text>
          </View>
        ) : (
          <View style={styles.emptyCard}>
            <View style={styles.emptyCircle}>
              <View style={styles.emptyWave} />
            </View>
            <Text style={styles.emptyTitle}>Nog geen nacht vastgelegd</Text>
            <Text style={styles.emptyText}>
              Je eerste opname verschijnt hier zodra je de sessie stopt. Alles blijft op dit apparaat.
            </Text>
          </View>
        )}

        {recordings.length > 0 ? (
          <View style={styles.list}>
            {recordings.map((recording) => {
              const isSelected = recording.id === selectedRecording?.id;
              return (
                <View key={recording.id} style={[styles.recordingRow, isSelected && styles.recordingRowSelected]}>
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={`Selecteer opname van ${formatDate(recording.startedAt)}`}
                    onPress={() => handleSelectRecording(recording)}
                    style={styles.recordingSelect}
                  >
                    <View style={[styles.rowMarker, isSelected && styles.rowMarkerSelected]}>
                      <View style={styles.rowMarkerInner} />
                    </View>
                    <View style={styles.rowCopy}>
                      <Text style={styles.rowTitle}>{formatDate(recording.startedAt)}</Text>
                      <Text style={styles.rowSubtitle}>{formatDuration(recording.durationSeconds)}</Text>
                    </View>
                  </Pressable>
                  <View style={styles.rowActions}>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={`Label als snurken, ${formatDate(recording.startedAt)}`}
                      onPress={() => handleLabelRecording(recording.id, 'snoring')}
                      style={[styles.labelButton, recording.label === 'snoring' && styles.labelButtonActive]}
                    >
                      <Text style={[styles.labelButtonText, recording.label === 'snoring' && styles.labelButtonTextActive]}>Snurken</Text>
                    </Pressable>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={`Label als praten in slaap, ${formatDate(recording.startedAt)}`}
                      onPress={() => handleLabelRecording(recording.id, 'sleep-talking')}
                      style={[styles.labelButton, recording.label === 'sleep-talking' && styles.labelButtonActive]}
                    >
                      <Text style={[styles.labelButtonText, recording.label === 'sleep-talking' && styles.labelButtonTextActive]}>Praten</Text>
                    </Pressable>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={`Verwijder opname van ${formatDate(recording.startedAt)}`}
                      onPress={() => handleDeleteRecording(recording)}
                      style={styles.deleteButton}
                    >
                      <Text style={styles.deleteButtonText}>×</Text>
                    </Pressable>
                  </View>
                </View>
              );
            })}
          </View>
        ) : null}

        {recordings.length > 0 ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Verwijder alle lokale opnames"
            onPress={handleDeleteAll}
            style={({ pressed }) => [styles.deleteAllButton, pressed && styles.buttonPressed]}
          >
            <Text style={styles.deleteAllText}>Alle lokale opnames verwijderen</Text>
          </Pressable>
        ) : null}

        {error ? (
          <View style={styles.errorCard} accessibilityLiveRegion="polite">
            <Text style={styles.errorTitle}>Er ging iets mis</Text>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <View style={styles.footer}>
          <Text style={styles.footerTitle}>Privé by default</Text>
          <Text style={styles.footerText}>
            Audio en labels blijven in de documentmap van Snorer. De MVP gebruikt geen cloudanalyse, account of automatische detectie.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppContent />
    </SafeAreaProvider>
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 14,
  },
  eyebrow: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.4,
  },
  title: {
    color: colors.text,
    fontSize: 34,
    lineHeight: 39,
    fontWeight: '800',
    letterSpacing: -0.8,
    marginTop: 8,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginTop: 10,
    maxWidth: 330,
  },
  localBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 7,
    marginTop: 3,
  },
  localDot: {
    width: 7,
    height: 7,
    borderRadius: 7,
    backgroundColor: colors.primary,
    marginRight: 6,
  },
  localBadgeText: {
    color: colors.text,
    fontSize: 12,
    fontWeight: '700',
  },
  permissionBanner: {
    backgroundColor: '#382F2A',
    borderColor: '#765A35',
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
  },
  bannerTitle: {
    color: colors.warning,
    fontSize: 15,
    fontWeight: '800',
  },
  bannerText: {
    color: '#E8D9BD',
    fontSize: 13,
    lineHeight: 19,
    marginTop: 6,
  },
  recordCard: {
    backgroundColor: colors.surface,
    borderRadius: 26,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
  },
  cardEyebrow: {
    color: colors.primary,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
  },
  cardTitle: {
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
  scopeCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.surfaceSoft,
    borderRadius: 20,
    padding: 16,
    gap: 12,
  },
  scopeMark: {
    width: 26,
    height: 26,
    borderRadius: 26,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scopeMarkText: {
    color: colors.text,
    fontWeight: '900',
  },
  scopeCopy: {
    flex: 1,
  },
  scopeTitle: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '800',
  },
  scopeText: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    marginTop: 4,
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
  playerCard: {
    backgroundColor: colors.surfaceRaised,
    borderRadius: 22,
    padding: 17,
    borderWidth: 1,
    borderColor: colors.border,
  },
  playerTopRow: {
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
    backgroundColor: '#4D7490',
  },
  waveBarActive: {
    backgroundColor: colors.primary,
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
  playerMetaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 9,
  },
  playerTime: {
    color: colors.muted,
    fontSize: 11,
    fontVariant: ['tabular-nums'],
  },
  playerTitle: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '800',
    marginTop: 16,
  },
  playerSubtitle: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 4,
  },
  emptyCard: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 22,
    paddingHorizontal: 28,
    paddingVertical: 30,
    borderWidth: 1,
    borderColor: colors.border,
  },
  emptyCircle: {
    width: 56,
    height: 56,
    borderRadius: 56,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyWave: {
    width: 22,
    height: 17,
    borderTopWidth: 2,
    borderBottomWidth: 2,
    borderColor: colors.primary,
    transform: [{ skewX: '-18deg' }],
  },
  emptyTitle: {
    color: colors.text,
    fontSize: 17,
    fontWeight: '800',
    marginTop: 16,
  },
  emptyText: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    textAlign: 'center',
    marginTop: 7,
  },
  list: {
    gap: 9,
  },
  recordingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 17,
    padding: 11,
    borderWidth: 1,
    borderColor: 'transparent',
    gap: 7,
  },
  recordingRowSelected: {
    borderColor: colors.primaryDark,
  },
  recordingSelect: {
    flex: 1,
    minHeight: 47,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  rowMarker: {
    width: 28,
    height: 28,
    borderRadius: 28,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowMarkerSelected: {
    borderColor: colors.primary,
    backgroundColor: colors.primaryDark,
  },
  rowMarkerInner: {
    width: 8,
    height: 8,
    borderRadius: 8,
    backgroundColor: colors.primary,
  },
  rowCopy: {
    flex: 1,
  },
  rowTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '700',
  },
  rowSubtitle: {
    color: colors.muted,
    fontSize: 12,
    marginTop: 3,
  },
  rowActions: {
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
  deleteAllButton: {
    alignSelf: 'flex-start',
    paddingVertical: 4,
  },
  deleteAllText: {
    color: colors.danger,
    fontSize: 13,
    fontWeight: '700',
  },
  errorCard: {
    backgroundColor: '#3A2938',
    borderRadius: 17,
    padding: 14,
    borderWidth: 1,
    borderColor: '#744251',
  },
  errorTitle: {
    color: colors.danger,
    fontSize: 14,
    fontWeight: '800',
  },
  errorText: {
    color: '#F1D9DE',
    fontSize: 13,
    lineHeight: 19,
    marginTop: 4,
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 17,
    marginTop: 5,
  },
  footerTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '800',
  },
  footerText: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 18,
    marginTop: 5,
  },
});
