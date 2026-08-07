import type { TfliteModel } from 'react-native-fast-tflite';

import { YAMNET_WINDOW_SAMPLES } from './sound-detection';

export async function loadSoundModel(): Promise<TfliteModel | null> {
  const { loadTensorflowModel } = require('react-native-fast-tflite') as {
    loadTensorflowModel: (source: number, delegates: never[]) => Promise<TfliteModel>;
  };
  const model = await loadTensorflowModel(
    require('../../assets/yamnet_classification.tflite'),
    [],
  );
  const input = model.inputs[0];

  if (
    input?.dataType !== 'float32' ||
    input.shape[input.shape.length - 1] !== YAMNET_WINDOW_SAMPLES
  ) {
    throw new Error('Het YAMNet-model gebruikt een onverwacht audioformaat.');
  }

  return model;
}
