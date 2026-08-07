export type RecordingLabel = 'snoring' | 'sleep-talking';

export interface RecordingDraft {
  uri: string;
  startedAt: string;
  durationSeconds: number;
}

export interface StoredRecording extends RecordingDraft {
  id: string;
  label: RecordingLabel | null;
}
