import 'dart:math';
import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:image/image.dart' as imageLib;
import 'package:slowbro/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'recognition.dart';
import 'stats.dart';

final List<String> bodyParts = [
  "nose",
  "leftEye",
  "rightEye",
  "leftEar",
  "rightEar",
  "leftShoulder",
  "rightShoulder",
  "leftElbow",
  "rightElbow",
  "leftWrist",
  "rightWrist",
  "leftHip",
  "rightHip",
  "leftKnee",
  "rightKnee",
  "leftAnkle",
  "rightAnkle",
];

/// Classifier
class Classifier {
  /// Instance of Interpreter
  Interpreter? _interpreter;

  static const String MODEL_FILE_NAME =
      "lite-model_movenet_singlepose_lightning_3.tflite";

  int? inputWidth;
  int? inputHeight;
  List<int>? outputShape;

  /// Result score threshold
  static const double THRESHOLD = 0.3;

  /// [ImageProcessor] used to pre-process the image
  ImageProcessor? imageProcessor;

  /// Padding the image to transform into square
  int? padSize;

  Classifier({
    Interpreter? interpreter,
  }) {
    loadModel(interpreter: interpreter);
  }

  /// Loads interpreter from asset
  void loadModel({Interpreter? interpreter}) async {
    try {
      //var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;
      final gpuDelegate = Platform.isAndroid ? GpuDelegateV2(options: GpuDelegateOptionsV2()) : GpuDelegate(
        options: GpuDelegateOptions(allowPrecisionLoss: true, waitType: TFLGpuDelegateWaitType.active),
      );
      InterpreterOptions interpreterOptions = InterpreterOptions()
        ..addDelegate(gpuDelegate);
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: interpreterOptions,
          );
      inputWidth = _interpreter!.getInputTensor(0).shape[1];
      inputHeight = _interpreter!.getInputTensor(0).shape[2];
      outputShape = _interpreter!.getOutputTensor(0).shape;
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Pre-process the image
  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    if (imageProcessor == null) {
      imageProcessor = ImageProcessorBuilder()
          .add(ResizeWithCropOrPadOp(padSize!, padSize!))
          .add(ResizeOp(inputHeight!, inputWidth!, ResizeMethod.BILINEAR))
          .build();
    }
    inputImage = imageProcessor!.process(inputImage);
    return inputImage;
  }

  /// Runs object detection on the input image
  Map<String, dynamic>? predict(imageLib.Image image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;

    if (_interpreter == null) {
      print("Interpreter not initialized");
      return null;
    }

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    TensorImage inputImage = TensorImage(TfLiteType.float32);
    inputImage.loadImage(image);

    // Pre-process TensorImage
    inputImage = getProcessedImage(inputImage);

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    TensorBuffer outputTensor =
        TensorBuffer.createFixedSize(outputShape!, TfLiteType.float32);
    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    // run inference
    _interpreter!.run(inputImage.tensorBuffer.buffer, outputTensor.buffer);
    var inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    List<Recognition> recognitions = [];

    List<double> output = outputTensor.getDoubleList();
    Uint8List data = outputTensor.getBuffer().asUint8List(0, outputTensor.getFlatSize() * outputTensor.getTypeSize());
    for (int i = 0, j = 0; i < output.length; i += 3) {
      if (output[i + 2] >= THRESHOLD) {
        Point p = imageProcessor!.inverseTransform(
            Point(output[i + 1] * inputHeight!, output[i] * inputWidth!),
            image.height,
            image.width);
        recognitions.add(Recognition(p, output[i + 2], bodyParts[j]));
      }
      j++;
    }

    var predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;

    return {
      "recognitions": recognitions,
      "output": data,
      "stats": Stats(
          totalPredictTime: predictElapsedTime,
          inferenceTime: inferenceTimeElapsed,
          preProcessingTime: preProcessElapsedTime)
    };
  }

  /// Gets the interpreter instance
  Interpreter? get interpreter => _interpreter;
}
