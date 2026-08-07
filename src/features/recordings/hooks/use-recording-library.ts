import { useCallback, useEffect, useState } from 'react';

import {
  loadRecordings,
  removeRecordingFile,
  saveRecordings,
} from '../recording-storage';
import { createRecordingId } from '../recording-utils';
import type { RecordingDraft, RecordingLabel, StoredRecording } from '../recording-types';

interface RecordingLibrary {
  recordings: StoredRecording[];
  isHydrated: boolean;
  error: string | null;
  addRecording: (draft: RecordingDraft) => StoredRecording;
  toggleLabel: (id: string, label: RecordingLabel) => void;
  removeRecording: (recording: StoredRecording) => boolean;
  removeAllRecordings: () => boolean;
}

export function useRecordingLibrary(): RecordingLibrary {
  const [recordings, setRecordings] = useState<StoredRecording[]>([]);
  const [isHydrated, setIsHydrated] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isActive = true;

    void loadRecordings()
      .then((storedRecordings) => {
        if (isActive) {
          setRecordings(storedRecordings);
        }
      })
      .catch(() => {
        if (isActive) {
          setError('De lokale opnamegeschiedenis kon niet worden gelezen.');
        }
      })
      .finally(() => {
        if (isActive) {
          setIsHydrated(true);
        }
      });

    return () => {
      isActive = false;
    };
  }, []);

  useEffect(() => {
    if (!isHydrated) {
      return;
    }

    let isActive = true;
    void saveRecordings(recordings).catch(() => {
      if (isActive) {
        setError('De opname is gemaakt, maar de lokale index kon niet worden bijgewerkt.');
      }
    });

    return () => {
      isActive = false;
    };
  }, [isHydrated, recordings]);

  const addRecording = useCallback((draft: RecordingDraft): StoredRecording => {
    const nextRecording: StoredRecording = {
      ...draft,
      id: createRecordingId(),
      label: null,
    };

    setRecordings((current) => [nextRecording, ...current]);
    setError(null);
    return nextRecording;
  }, []);

  const toggleLabel = useCallback((id: string, label: RecordingLabel) => {
    setRecordings((current) =>
      current.map((recording) =>
        recording.id === id
          ? { ...recording, label: recording.label === label ? null : label }
          : recording,
      ),
    );
  }, []);

  const removeRecording = useCallback((recording: StoredRecording): boolean => {
    try {
      removeRecordingFile(recording.uri);
      setRecordings((current) => current.filter((candidate) => candidate.id !== recording.id));
      return true;
    } catch {
      setError('Deze opname kon niet van het apparaat worden verwijderd.');
      return false;
    }
  }, []);

  const removeAllRecordings = useCallback((): boolean => {
    try {
      recordings.forEach((recording) => removeRecordingFile(recording.uri));
      setRecordings([]);
      return true;
    } catch {
      setError('Niet alle lokale opnames konden worden verwijderd.');
      return false;
    }
  }, [recordings]);

  return {
    recordings,
    isHydrated,
    error,
    addRecording,
    toggleLabel,
    removeRecording,
    removeAllRecordings,
  };
}
