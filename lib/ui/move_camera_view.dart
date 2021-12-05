import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:slowbro/tflite/classifier.dart';
import 'package:slowbro/tflite/recognition.dart';
import 'package:slowbro/tflite/stats.dart';
import 'package:slowbro/api/camera_view_singleton.dart';
import 'package:slowbro/utils/isolate_utils.dart';
import 'package:wakelock/wakelock.dart';

/// [CameraView] sends each frame for inference
class CameraView extends StatefulWidget {
  /// Callback to pass results after inference to [FitnessView]
  final Function(List<Recognition> recognitions, Uint8List output, Stats stats) resultsCallback;

  /// Constructor
  const CameraView(this.resultsCallback);
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  /// List of available cameras
  List<CameraDescription>? cameras;

  /// Controller
  CameraController? cameraController;
  CameraDescription? camera;

  /// true when inference is ongoing
  bool predicting = false;
  bool disposed = false;

  /// Instance of [Classifier]
  Classifier? classifier;

  /// Instance of [IsolateUtils]
  IsolateUtils? isolateUtils;

  CameraLensDirection direction = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    try {
      WidgetsBinding.instance!.addObserver(this);

      // Spawn a new isolate
      isolateUtils = IsolateUtils();
      await isolateUtils!.start();

      // Camera initialization
      final cameraAngle = await initializeCamera(CameraLensDirection.back);

      // Create an instance of classifier to load model and labels
      classifier = Classifier();

      // Initially predicting = false
      predicting = false;
    } catch(e) {
      print(e);
      throw e;
    }
  }

  void switchCamera() async {
    CameraController? oldController = cameraController;
    disposed = true;
    await oldController?.dispose();
    direction = direction == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
    final cameraAngle = await initializeCamera(direction);
    setState(() {});
  }

  /// Initializes the camera by setting [cameraController]
  Future<void> initializeCamera(CameraLensDirection direction) async {
    cameras = await availableCameras();
    //camera = cameras![0];
    cameras!.forEach((element) {print("${element.name} ${element.lensDirection} ${element.sensorOrientation}");});

    camera = cameras!.firstWhere((c) => c.lensDirection == direction, orElse: () => cameras![0]);
    print("init");
    cameraController =
        CameraController(camera!, ResolutionPreset.low, enableAudio: false);
    return await cameraController!.initialize().then((_) async {
      // Stream of image passed to [onLatestImageAvailable] callback
      final min = await cameraController!.getMinZoomLevel();
      print("Setting zoom level $min");

      await cameraController!.setZoomLevel(min);
      await cameraController!.startImageStream(onLatestImageAvailable);
      await cameraController!.setFocusMode(FocusMode.auto);
      await cameraController!.setExposureMode(ExposureMode.auto);

      /// previewSize is size of each image frame captured by controller
      ///
      /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
      Size previewSize = cameraController!.value.previewSize!;

      /// previewSize is size of raw input image to the model
      CameraViewSingleton.inputImageSize = previewSize;

      // the display width of image on screen is
      // same as screenWidth while maintaining the aspectRatio
      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio = screenSize.width / previewSize.height;
      Wakelock.enable();
      disposed = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container();
    }
    return Stack(
      children: [
        !disposed ? CameraPreview(cameraController!) : Container(),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              color: Colors.white,
              icon: Icon(Icons.change_circle, size: 30),
              onPressed: switchCamera,
            ),
          ),
        )
      ],
    );
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    if (classifier?.interpreter != null) {
      // If previous inference has not completed then return
      if (predicting) {
        return;
      }

      setState(() {
        predicting = true;
      });
      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;
      // Data to be passed to inference isolate
      var isolateData = IsolateData(
          CameraImageSnapshot.fromCameraImage(cameraImage),
          classifier!.interpreter!.address, camera!.sensorOrientation);

      // We could have simply used the compute method as well however
      // it would be as in-efficient as we need to continuously passing data
      // to another isolate.

      /// perform inference in separate isolate
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to FitnessView
      widget.resultsCallback(inferenceResults["recognitions"], inferenceResults["output"], (inferenceResults["stats"] as Stats)..totalElapsedTime = uiThreadInferenceElapsedTime);

      // set predicting to false to allow new frames
      setState(() {
        predicting = false;
      });
    }
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils!.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        if (cameraController!.value.isStreamingImages) {
          await cameraController!.stopImageStream();
        }
        break;
      case AppLifecycleState.resumed:
        if (!cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    print("dispose camera");
    WidgetsBinding.instance!.removeObserver(this);
    cameraController!.dispose();
    super.dispose();
    Wakelock.disable();
  }
}
