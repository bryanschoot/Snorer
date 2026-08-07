import type { RecordingLabel, StoredRecording } from './recording-types';

const dateFormatter = new Intl.DateTimeFormat('nl-NL', {
  day: 'numeric',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
});

export function isStoredRecording(value: unknown): value is StoredRecording {
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

export function parseStoredRecordings(raw: string | null): StoredRecording[] {
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

export function createRecordingId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`;
}

export function formatDuration(totalSeconds: number): string {
  const safeSeconds = Number.isFinite(totalSeconds) ? totalSeconds : 0;
  const seconds = Math.max(0, Math.round(safeSeconds));
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainder = seconds % 60;

  if (hours > 0) {
    return `${hours}u ${minutes.toString().padStart(2, '0')}m`;
  }

  return `${minutes}m ${remainder.toString().padStart(2, '0')}s`;
}

export function formatClock(totalSeconds: number): string {
  const safeSeconds = Number.isFinite(totalSeconds) ? totalSeconds : 0;
  const seconds = Math.max(0, Math.floor(safeSeconds));
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;

  return `${minutes.toString().padStart(2, '0')}:${remainder.toString().padStart(2, '0')}`;
}

export function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return 'Onbekende datum';
  }

  return dateFormatter.format(date);
}

export function getRecordingLabelText(label: RecordingLabel | null): string {
  if (label === 'snoring') {
    return 'Snurken';
  }

  if (label === 'sleep-talking') {
    return 'Praten in slaap';
  }

  return 'Nog niet gelabeld';
}
