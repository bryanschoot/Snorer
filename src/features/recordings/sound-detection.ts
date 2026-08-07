import type { SoundEvent, SoundEventKind } from './recording-types';

export const YAMNET_SAMPLE_RATE = 16_000;
export const YAMNET_WINDOW_SAMPLES = 15_600;
export const YAMNET_WINDOW_SECONDS = YAMNET_WINDOW_SAMPLES / YAMNET_SAMPLE_RATE;

const SPEECH_INDEX = 0;
const SNORING_INDEX = 38;
const MIN_CONFIDENCE = 0.32;
const MERGE_GAP_SECONDS = 1.5;

export interface SoundClassification {
  kind: SoundEventKind;
  confidence: number;
}

export function classifyYamnetScores(scores: Float32Array): SoundClassification | null {
  const speechScore = scores[SPEECH_INDEX] ?? 0;
  const snoringScore = scores[SNORING_INDEX] ?? 0;

  if (speechScore < MIN_CONFIDENCE && snoringScore < MIN_CONFIDENCE) {
    return null;
  }

  if (snoringScore >= speechScore) {
    return { kind: 'snoring', confidence: snoringScore };
  }

  return { kind: 'speech', confidence: speechScore };
}

export function appendSoundEvent(
  events: SoundEvent[],
  classification: SoundClassification,
  startSeconds: number,
): SoundEvent[] {
  const endSeconds = startSeconds + YAMNET_WINDOW_SECONDS;
  const previous = events.at(-1);

  if (
    previous &&
    previous.kind === classification.kind &&
    startSeconds <= previous.endSeconds + MERGE_GAP_SECONDS
  ) {
    return [
      ...events.slice(0, -1),
      {
        ...previous,
        endSeconds: Math.max(previous.endSeconds, endSeconds),
        confidence: Math.max(previous.confidence, classification.confidence),
      },
    ];
  }

  return [
    ...events,
    {
      id: `${classification.kind}-${Math.round(startSeconds * 1000)}`,
      kind: classification.kind,
      startSeconds,
      endSeconds,
      confidence: classification.confidence,
    },
  ];
}

export function createYamnetFrame(samples: number[]): Float32Array | null {
  if (samples.length < YAMNET_WINDOW_SAMPLES / 4) {
    return null;
  }

  const frame = new Float32Array(YAMNET_WINDOW_SAMPLES);
  const copyLength = Math.min(samples.length, YAMNET_WINDOW_SAMPLES);
  frame.set(samples.slice(0, copyLength));
  return frame;
}
