import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
} from 'expo-audio';

import { getRecordingLabelText, formatDate } from '../recording-utils';
import type { StoredRecording } from '../recording-types';

const playbackAudioMode = {
  allowsRecording: false,
  playsInSilentMode: true,
  shouldPlayInBackground: true,
  interruptionMode: 'doNotMix' as const,
};

interface RecordingPlayer {
  currentTime: number;
  duration: number;
  progress: number;
  isPlaying: boolean;
  error: string | null;
  pause: () => void;
  togglePlayback: () => Promise<void>;
}

export function useRecordingPlayer(selectedRecording: StoredRecording | null): RecordingPlayer {
  const [error, setError] = useState<string | null>(null);
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
    setError(null);
  }, [selectedRecording?.id]);

  useEffect(() => {
    return () => {
      player.pause();
      player.clearLockScreenControls();
    };
  }, [player]);

  const pause = useCallback(() => {
    player.pause();
  }, [player]);

  const togglePlayback = useCallback(async () => {
    if (!selectedRecording) {
      return;
    }

    try {
      setError(null);
      if (player.playing) {
        player.pause();
        return;
      }

      await setAudioModeAsync(playbackAudioMode);
      player.setActiveForLockScreen(true, {
        title: 'Snorer-opname',
        artist: getRecordingLabelText(selectedRecording.label),
        albumTitle: 'Lokaal opgeslagen',
      });
      player.play();
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : 'Onbekende afspeelfout';
      setError(`Afspelen lukt niet: ${message}`);
    }
  }, [player, selectedRecording]);

  const duration = playerStatus.duration || selectedRecording?.durationSeconds || 0;
  const progress =
    duration > 0 ? Math.min(1, Math.max(0, playerStatus.currentTime / duration)) : 0;

  return {
    currentTime: playerStatus.currentTime,
    duration,
    progress,
    isPlaying: player.playing,
    error,
    pause,
    togglePlayback,
  };
}
