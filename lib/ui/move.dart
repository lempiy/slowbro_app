import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:slowbro/api/event_types.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/ui/move_camera_view.dart';
import 'package:flutter/material.dart';
import 'package:slowbro/tflite/recognition.dart';
import 'package:slowbro/tflite/stats.dart';
import 'package:slowbro/api/camera_view_singleton.dart';
import 'package:slowbro/ui/painter.dart';

/// [MoveView] stacks [CameraView] with bottom sheet for stats
class MoveView extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;
  final void Function()? onTouchPressed;
  final IconData? toggleIcon;

  const MoveView({Key? key, required this.provider, required this.pointerOptions, this.onTouchPressed, this.toggleIcon}) : super(key: key);

  @override
  _MoveViewState createState() => _MoveViewState();
}

class _MoveViewState extends State<MoveView> {
  /// Results to draw bounding boxes
  List<Recognition>? results;

  Uint8List? output;

  /// Realtime stats
  Stats? stats;

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  void initState(){
    print("move view");
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  dispose(){
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: <Widget>[
          // Camera View
          CameraView(resultsCallback),
          // Bottom Sheet
          CustomPaint(
            painter: EdgePainter(results),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (_, ScrollController scrollController) => Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BORDER_RADIUS_BOTTOM_SHEET),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up,
                            size: 48, color: Colors.black54),
                        (stats != null)
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              StatsRow('Inference time:',
                                  '${stats!.inferenceTime} ms'),
                              StatsRow('Total prediction time:',
                                  '${stats!.totalElapsedTime} ms'),
                              StatsRow('Pre-processing time:',
                                  '${stats!.preProcessingTime} ms'),
                              StatsRow('Frame',
                                  '${CameraViewSingleton.inputImageSize.width} X ${CameraViewSingleton.inputImageSize.height}'),
                            ],
                          ),
                        )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      );
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition>? results) {
    if (results == null) {
      return Container();
    }
    return Container();
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results, Uint8List output, Stats stats) {
    final msg = new Uint8List(output.lengthInBytes + Uint16List.bytesPerElement);
    final view = ByteData.view(msg.buffer);
    view.setUint16(0, EVENT_TYPE_MOVE_DATA, Endian.little);
    msg.setAll(Uint16List.bytesPerElement, output);
    widget.provider.sendBinaryMessage(msg);
    setState(() {
      this.results = results;
      this.output = output;
      this.stats = stats;
    });
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  StatsRow(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
