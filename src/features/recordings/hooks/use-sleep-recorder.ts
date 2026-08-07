import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import {
  getRecordingPermissionsAsync,
  RecordingPresets,
  requestNotificationPermissionsAsync,
  requestRecordingPermissionsAsync,
  setAudioModeAsync,
  type RecordingStatus,
  useAudioRecorder,
  useAudioRecorderState,
} from 'expo-audio';

import type { RecordingDraft } from '../recording-types';

const recordingOptions = {
  ...RecordingPresets.HIGH_QUALITY,
  directory: 'document' as const,
};

const recordingAudioMode = {
  allowsRecording: true,
  allowsBackgroundRecording: true,
  playsInSilentMode: true,
  shouldPlayInBackground: true,
  interruptionMode: 'doNotMix' as const,
};

export type StartRecordingResult = 'started' | 'permission-denied' | 'failed';

interface SleepRecorder {
  permissionGranted: boolean | null;
  isStarting: boolean;
  isStopping: boolean;
  isRecording: boolean;
  durationSeconds: number;
  error: string | null;
  startRecording: () => Promise<StartRecordingResult>;
  stopRecording: () => Promise<void>;
}

export function useSleepRecorder(onRecordingFinished: (draft: RecordingDraft) => void): SleepRecorder {
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);
  const [isStarting, setIsStarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const activeStartedAtRef = useRef<string | null>(null);
  const finalizingRef = useRef(false);

  useEffect(() => {
    let isActive = true;

    void getRecordingPermissionsAsync()
      .then((response) => {
        if (isActive) {
          setPermissionGranted(response.granted);
        }
      })
      .catch(() => {
        if (isActive) {
          setPermissionGranted(false);
        }
      });

    void setAudioModeAsync(recordingAudioMode).catch(() => {
      // Audio mode is configured again immediately before recording.
    });

    return () => {
      isActive = false;
    };
  }, []);

  const finalizeRecording = useCallback(
    (uri: string | null, durationOverride?: number) => {
      const startedAt = activeStartedAtRef.current;
      if (!uri || !startedAt || finalizingRef.current) {
        return;
      }

      finalizingRef.current = true;
      activeStartedAtRef.current = null;
      const startedAtMillis = new Date(startedAt).getTime();
      const elapsedSeconds = Number.isFinite(startedAtMillis)
        ? Math.max(1, Math.round((Date.now() - startedAtMillis) / 1000))
        : 1;
      const durationSeconds = Math.max(1, durationOverride ?? elapsedSeconds);

      try {
        onRecordingFinished({ uri, startedAt, durationSeconds });
        setError(null);
      } finally {
        finalizingRef.current = false;
      }
    },
    [onRecordingFinished],
  );

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

  const configureRecordingAudio = useCallback(async (): Promise<boolean> => {
    const response = await requestRecordingPermissionsAsync();
    setPermissionGranted(response.granted);
    if (!response.granted) {
      return false;
    }

    if (Platform.OS === 'android') {
      await requestNotificationPermissionsAsync().catch(() => undefined);
    }

    await setAudioModeAsync(recordingAudioMode);
    return true;
  }, []);

  const startRecording = useCallback(async (): Promise<StartRecordingResult> => {
    if (recorderState.isRecording || isStarting) {
      return 'failed';
    }

    setError(null);
    setIsStarting(true);
    try {
      const allowed = await configureRecordingAudio();
      if (!allowed) {
        setError('Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal op te nemen.');
        return 'permission-denied';
      }

      await recorder.prepareToRecordAsync();
      activeStartedAtRef.current = new Date().toISOString();
      recorder.record();
      return 'started';
    } catch (cause) {
      activeStartedAtRef.current = null;
      const message = cause instanceof Error ? cause.message : 'Onbekende audiofout';
      setError(`Opname starten lukt niet: ${message}`);
      return 'failed';
    } finally {
      setIsStarting(false);
    }
  }, [configureRecordingAudio, isStarting, recorder, recorderState.isRecording]);

  const stopRecording = useCallback(async () => {
    if (!recorderState.isRecording || isStopping) {
      return;
    }

    setIsStopping(true);
    const startedAt = activeStartedAtRef.current;
    const startedAtMillis = startedAt ? new Date(startedAt).getTime() : Number.NaN;
    const elapsedSeconds = Number.isFinite(startedAtMillis)
      ? Math.max(1, Math.round((Date.now() - startedAtMillis) / 1000))
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

  return {
    permissionGranted,
    isStarting,
    isStopping,
    isRecording: recorderState.isRecording,
    durationSeconds: recorderState.isRecording ? recorderState.durationMillis / 1000 : 0,
    error,
    startRecording,
    stopRecording,
  };
}
