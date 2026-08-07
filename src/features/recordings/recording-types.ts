export type RecordingLabel = 'snoring' | 'sleep-talking';

export type SoundEventKind = 'snoring' | 'speech';

export interface SoundEvent {
  id: string;
  kind: SoundEventKind;
  startSeconds: number;
  endSeconds: number;
  confidence: number;
}

export interface RecordingDraft {
  uri: string;
  startedAt: string;
  durationSeconds: number;
  soundEvents: SoundEvent[];
}

export interface StoredRecording extends RecordingDraft {
  id: string;
  label: RecordingLabel | null;
}
