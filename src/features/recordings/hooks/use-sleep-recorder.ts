import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import type { TfliteModel } from 'react-native-fast-tflite';
import {
  AudioManager,
  AudioRecorder,
  FileDirectory,
  FileFormat,
  FilePreset,
} from 'react-native-audio-api';

import type { RecordingDraft, SoundEvent } from '../recording-types';
import { loadSoundModel } from '../sound-model';
import {
  appendSoundEvent,
  classifyYamnetScores,
  createYamnetFrame,
  YAMNET_SAMPLE_RATE,
  YAMNET_WINDOW_SAMPLES,
} from '../sound-detection';

const recordingFileOptions = {
  format: FileFormat.M4A,
  preset: FilePreset.High,
  directory: FileDirectory.Document,
  channelCount: 1,
};

const audioCallbackOptions = {
  sampleRate: YAMNET_SAMPLE_RATE,
  bufferLength: YAMNET_SAMPLE_RATE / 10,
  channelCount: 1,
};

const recordingSessionOptions = {
  iosCategory: 'record' as const,
  iosMode: 'default' as const,
  iosOptions: [],
};

export type StartRecordingResult = 'started' | 'permission-denied' | 'failed';
export type SoundDetectionStatus = 'idle' | 'loading' | 'ready' | 'unavailable';

interface SleepRecorder {
  permissionGranted: boolean | null;
  isStarting: boolean;
  isStopping: boolean;
  isRecording: boolean;
  durationSeconds: number;
  error: string | null;
  soundDetectionStatus: SoundDetectionStatus;
  startRecording: () => Promise<StartRecordingResult>;
  stopRecording: () => Promise<void>;
}

export function useSleepRecorder(onRecordingFinished: (draft: RecordingDraft) => void): SleepRecorder {
  const [recorder] = useState(() => new AudioRecorder());

  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);
  const [isStarting, setIsStarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [durationSeconds, setDurationSeconds] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [soundDetectionStatus, setSoundDetectionStatus] =
    useState<SoundDetectionStatus>('idle');
  const activeStartedAtRef = useRef<string | null>(null);
  const sampleBufferRef = useRef<number[]>([]);
  const processedSamplesRef = useRef(0);
  const soundEventsRef = useRef<SoundEvent[]>([]);
  const analysisQueueRef = useRef<Promise<void>>(Promise.resolve());
  const modelRef = useRef<TfliteModel | null>(null);
  const modelPromiseRef = useRef<Promise<TfliteModel | null> | null>(null);

  useEffect(() => {
    let isActive = true;

    void AudioManager.checkRecordingPermissions()
      .then((status) => {
        if (isActive) {
          setPermissionGranted(status === 'Granted');
        }
      })
      .catch(() => {
        if (isActive) {
          setPermissionGranted(false);
        }
      });

    return () => {
      isActive = false;
    };
  }, []);

  const queueSoundFrame = useCallback((frame: Float32Array, startSeconds: number) => {
    const model = modelRef.current;
    if (!model) {
      return;
    }

    const frameBuffer = frame.buffer.slice(
      frame.byteOffset,
      frame.byteOffset + frame.byteLength,
    ) as ArrayBuffer;
    analysisQueueRef.current = analysisQueueRef.current
      .then(async () => {
        const outputs = await model.run([frameBuffer]);
        const output = outputs[0];
        if (!output) {
          return;
        }

        const classification = classifyYamnetScores(new Float32Array(output));
        if (classification) {
          soundEventsRef.current = appendSoundEvent(
            soundEventsRef.current,
            classification,
            startSeconds,
          );
        }
      })
      .catch(() => {
        setSoundDetectionStatus('unavailable');
      });
  }, []);

  const handleAudioBuffer = useCallback(
    (samples: Float32Array, sampleRate: number) => {
      const normalizedSamples =
        sampleRate === YAMNET_SAMPLE_RATE
          ? samples
          : (() => {
              if (!Number.isFinite(sampleRate) || sampleRate <= 0) {
                return samples;
              }

              const ratio = YAMNET_SAMPLE_RATE / sampleRate;
              const outputLength = Math.max(1, Math.round(samples.length * ratio));
              const resampled = new Float32Array(outputLength);

              for (let index = 0; index < outputLength; index += 1) {
                const sourceIndex = index / ratio;
                const leftIndex = Math.min(Math.floor(sourceIndex), samples.length - 1);
                const rightIndex = Math.min(leftIndex + 1, samples.length - 1);
                const mix = sourceIndex - leftIndex;
                resampled[index] =
                  (samples[leftIndex] ?? 0) * (1 - mix) + (samples[rightIndex] ?? 0) * mix;
              }

              return resampled;
            })();

      sampleBufferRef.current.push(...normalizedSamples);

      while (sampleBufferRef.current.length >= YAMNET_WINDOW_SAMPLES) {
        const frameSamples = sampleBufferRef.current.splice(0, YAMNET_WINDOW_SAMPLES);
        const frame = createYamnetFrame(frameSamples);
        if (!frame) {
          break;
        }

        const startSeconds = processedSamplesRef.current / YAMNET_SAMPLE_RATE;
        processedSamplesRef.current += YAMNET_WINDOW_SAMPLES;
        queueSoundFrame(frame, startSeconds);
      }
    },
    [queueSoundFrame],
  );

  useEffect(() => {
    const callbackResult = recorder.onAudioReady(audioCallbackOptions, ({ buffer }) => {
      handleAudioBuffer(buffer.getChannelData(0), buffer.sampleRate);
    });

    if (callbackResult.status === 'error') {
      setSoundDetectionStatus('unavailable');
    }

    recorder.onError(({ message }) => {
      setError(`Audio-opnamefout: ${message}`);
    });

    return () => {
      recorder.clearOnAudioReady();
      recorder.clearOnError();
    };
  }, [handleAudioBuffer, recorder]);

  useEffect(() => {
    if (!isRecording) {
      return;
    }

    const updateDuration = () => {
      setDurationSeconds(recorder.getCurrentDuration());
    };

    updateDuration();
    const interval = setInterval(updateDuration, 500);
    return () => clearInterval(interval);
  }, [isRecording, recorder]);

  const ensureSoundModel = useCallback(async (): Promise<TfliteModel | null> => {
    if (!modelPromiseRef.current) {
      setSoundDetectionStatus('loading');
      modelPromiseRef.current = loadSoundModel();
    }

    try {
      const model = await modelPromiseRef.current;
      if (!model) {
        setSoundDetectionStatus('unavailable');
        return null;
      }

      modelRef.current = model;
      setSoundDetectionStatus('ready');
      return model;
    } catch {
      modelPromiseRef.current = null;
      modelRef.current = null;
      setSoundDetectionStatus('unavailable');
      return null;
    }
  }, []);

  const resetSoundDetection = useCallback(() => {
    sampleBufferRef.current = [];
    processedSamplesRef.current = 0;
    soundEventsRef.current = [];
    analysisQueueRef.current = Promise.resolve();
  }, []);

  const flushSoundDetection = useCallback(() => {
    const frame = createYamnetFrame(sampleBufferRef.current);
    if (frame) {
      queueSoundFrame(frame, processedSamplesRef.current / YAMNET_SAMPLE_RATE);
    }
    sampleBufferRef.current = [];
  }, [queueSoundFrame]);

  const configureRecordingAudio = useCallback(async (): Promise<boolean> => {
    const permission = await AudioManager.requestRecordingPermissions();
    const granted = permission === 'Granted';
    setPermissionGranted(granted);
    if (!granted) {
      return false;
    }

    if (Platform.OS === 'android') {
      await AudioManager.requestNotificationPermissions().catch(() => undefined);
    }

    AudioManager.setAudioSessionOptions(recordingSessionOptions);
    await AudioManager.setAudioSessionActivity(true);
    return true;
  }, []);

  const startRecording = useCallback(async (): Promise<StartRecordingResult> => {
    if (isRecording || isStarting) {
      return 'failed';
    }

    setError(null);
    setIsStarting(true);
    resetSoundDetection();

    try {
      const allowed = await configureRecordingAudio();
      if (!allowed) {
        setError('Geef Snorer toegang tot de microfoon om slaapgeluiden lokaal te analyseren.');
        return 'permission-denied';
      }

      const outputResult = recorder.enableFileOutput(recordingFileOptions);
      if (outputResult.status === 'error') {
        throw new Error(outputResult.message);
      }

      await ensureSoundModel();
      const result = await recorder.start();
      if (result.status === 'error') {
        throw new Error(result.message);
      }

      activeStartedAtRef.current = new Date().toISOString();
      setDurationSeconds(0);
      setIsRecording(true);
      return 'started';
    } catch (cause) {
      activeStartedAtRef.current = null;
      await AudioManager.setAudioSessionActivity(false).catch(() => undefined);
      const message = cause instanceof Error ? cause.message : 'Onbekende audiofout';
      setError(`Opname starten lukt niet: ${message}`);
      return 'failed';
    } finally {
      setIsStarting(false);
    }
  }, [configureRecordingAudio, ensureSoundModel, isRecording, isStarting, recorder, resetSoundDetection]);

  const stopRecording = useCallback(async () => {
    if (!isRecording || isStopping) {
      return;
    }

    setIsStopping(true);
    const startedAt = activeStartedAtRef.current;

    try {
      const result = await recorder.stop();
      if (result.status === 'error') {
        throw new Error(result.message);
      }

      flushSoundDetection();
      await analysisQueueRef.current;
      await AudioManager.setAudioSessionActivity(false).catch(() => undefined);

      const uri = result.paths[0];
      if (!uri || !startedAt) {
        throw new Error('De opname heeft geen geldig bestand opgeleverd.');
      }

      onRecordingFinished({
        uri,
        startedAt,
        durationSeconds: Math.max(1, Math.round(result.duration)),
        soundEvents: soundEventsRef.current,
      });
      activeStartedAtRef.current = null;
      setIsRecording(false);
      setDurationSeconds(result.duration);
      setError(null);
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : 'Onbekende audiofout';
      setError(`Opname stoppen lukt niet: ${message}`);
    } finally {
      setIsStopping(false);
    }
  }, [flushSoundDetection, isRecording, isStopping, onRecordingFinished, recorder]);

  return {
    permissionGranted,
    isStarting,
    isStopping,
    isRecording,
    durationSeconds,
    error,
    soundDetectionStatus,
    startRecording,
    stopRecording,
  };
}
