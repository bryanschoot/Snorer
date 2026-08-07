import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/services/sound_detection.dart';

abstract interface class SoundModelService {
  bool get isReady;
  Future<void> initialize();
  Future<List<double>> classify(List<double> frame);
  void dispose();
}

class YamnetSoundModelService implements SoundModelService {
  Interpreter? _interpreter;
  Object? _initializationError;

  @override
  bool get isReady => _interpreter != null;

  @override
  Future<void> initialize() async {
    if (_interpreter != null) return;
    if (_initializationError != null) throw _initializationError!;

    try {
      final interpreter = await Interpreter.fromAsset(
        'assets/yamnet_classification.tflite',
      );
      final input = interpreter.getInputTensor(0);
      final inputShape = input.shape;
      final inputSize = inputShape.isEmpty ? 0 : inputShape.last;
      if (input.type != TensorType.float32 ||
          inputSize != yamnetWindowSamples) {
        interpreter.close();
        throw StateError(
          'Het YAMNet-model gebruikt een onverwacht audioformaat.',
        );
      }
      _interpreter = interpreter;
    } catch (error) {
      _initializationError = error;
      rethrow;
    }
  }

  @override
  Future<List<double>> classify(List<double> frame) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Het geluidsmodel is nog niet geladen.');
    }
    if (frame.length != yamnetWindowSamples) {
      throw ArgumentError.value(
        frame.length,
        'frame',
        'verwacht 15600 samples',
      );
    }

    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final input = inputShape.length == 1 ? frame : <Object>[frame];
    final output = _allocateFloatStructure(outputShape);
    interpreter.run(input, output);
    return _flattenNumbers(output);
  }

  Object _allocateFloatStructure(List<int> shape) {
    if (shape.isEmpty) return <double>[];
    Object value = List<double>.filled(shape.last, 0);
    for (var dimension = shape.length - 2; dimension >= 0; dimension -= 1) {
      value = List<Object>.generate(
        shape[dimension],
        (_) => value is List ? List<Object>.from(value as List<Object>) : value,
      );
    }
    return value;
  }

  List<double> _flattenNumbers(Object? value) {
    if (value is List) {
      return value
          .expand<double>((element) => _flattenNumbers(element))
          .toList(growable: false);
    }
    return value is num ? [value.toDouble()] : const [];
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
