import AsyncStorage from '@react-native-async-storage/async-storage';
import { File } from 'expo-file-system';

import { parseStoredRecordings } from './recording-utils';
import type { StoredRecording } from './recording-types';

const RECORDINGS_STORAGE_KEY = '@snorer/recordings/v1';

export async function loadRecordings(): Promise<StoredRecording[]> {
  const raw = await AsyncStorage.getItem(RECORDINGS_STORAGE_KEY);
  return parseStoredRecordings(raw);
}

export async function saveRecordings(recordings: StoredRecording[]): Promise<void> {
  await AsyncStorage.setItem(RECORDINGS_STORAGE_KEY, JSON.stringify(recordings));
}

export function removeRecordingFile(uri: string): void {
  const file = new File(uri);
  if (file.exists) {
    file.delete();
  }
}
