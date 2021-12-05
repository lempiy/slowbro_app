import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;
import 'package:slowbro/tflite/classifier.dart';
import 'package:slowbro/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  Isolate? _isolate;
  ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;
  int cameraRotation = 0;

  SendPort get sendPort => _sendPort!;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData? isolateData in port) {
      if (isolateData != null) {
        Classifier classifier = Classifier(
            interpreter:
                Interpreter.fromAddress(isolateData.interpreterAddress));
        imageLib.Image image =
            ImageUtils.convertCameraImage(isolateData.cameraImage);
        if (Platform.isAndroid) {
          image = imageLib.copyRotate(image, isolateData.cameraRotation);
          if (isolateData.cameraRotation == 270) imageLib.flipHorizontal(image);
        }
        Map<String, dynamic> results = classifier.predict(image)!;
        isolateData.responsePort!.send(results);
      }
    }
  }
}

class CameraImageSnapshot {
  /// CameraImageSnapshot Constructor
  CameraImageSnapshot.fromCameraImage(CameraImage image)
      : format = image.format,
        height = image.height,
        width = image.width,
        lensAperture = image.lensAperture,
        sensorExposureTime = image.sensorExposureTime,
        sensorSensitivity = image.sensorSensitivity,
        planes = image.planes.map((p) => PlaneSnapshot.fromPlane(p)).toList();
  /// Format of the image provided.
  ///
  /// Determines the number of planes needed to represent the image, and
  /// the general layout of the pixel data in each [Uint8List].
  final ImageFormat format;

  /// Height of the image in pixels.
  ///
  /// For formats where some color channels are subsampled, this is the height
  /// of the largest-resolution plane.
  final int height;

  /// Width of the image in pixels.
  ///
  /// For formats where some color channels are subsampled, this is the width
  /// of the largest-resolution plane.
  final int width;

  /// The pixels planes for this image.
  ///
  /// The number of planes is determined by the format of the image.
  final List<PlaneSnapshot> planes;

  /// The aperture settings for this image.
  ///
  /// Represented as an f-stop value.
  final double? lensAperture;

  /// The sensor exposure time for this image in nanoseconds.
  final int? sensorExposureTime;

  /// The sensor sensitivity in standard ISO arithmetic units.
  final double? sensorSensitivity;
}

class PlaneSnapshot {
  /// Bytes representing this plane.
  final Uint8List bytes;

  /// The distance between adjacent pixel samples on Android, in bytes.
  ///
  /// Will be `null` on iOS.
  final int? bytesPerPixel;

  /// The row stride for this color plane, in bytes.
  final int bytesPerRow;

  /// Height of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android
  final int? height;

  /// Width of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android.
  final int? width;
  PlaneSnapshot.fromPlane(Plane p)
      : bytes = Uint8List.fromList(p.bytes),
        bytesPerPixel = p.bytesPerPixel,
        bytesPerRow = p.bytesPerRow,
        height = p.height,
        width = p.width;
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImageSnapshot cameraImage;
  int interpreterAddress;
  int cameraRotation;
  SendPort? responsePort;

  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
    this.cameraRotation,
  );
}
