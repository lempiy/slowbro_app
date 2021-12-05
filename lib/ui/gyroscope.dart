import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:control_pad/control_pad.dart';
import 'package:control_pad/views/joystick_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slowbro/api/event_types.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/utils/gyromath.dart';
import 'package:sensors_plus/sensors_plus.dart';



class Gyroscope extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;
  final void Function()? onTouchPressed;
  final DeviceOrientation orientation = DeviceOrientation.landscapeLeft;
  final IconData? toggleIcon;

  const Gyroscope(
      {Key? key,
        required this.provider,
        required this.pointerOptions,
        this.toggleIcon,
        this.onTouchPressed})
      : super(key: key);

  sendGyroscopeUpdate(List<double> orientation) {
    final Uint8List bytes =
    Uint8List(Uint16List.bytesPerElement + Float32List.bytesPerElement * 3);
    final view = ByteData.view(bytes.buffer);
    view.setUint16(0, EVENT_TYPE_RESOLUTION_GYROSCOPE_CHANGE, Endian.little);
    view.setFloat32(Uint16List.bytesPerElement, orientation[0], Endian.little);
    view.setFloat32(Uint16List.bytesPerElement + Float32List.bytesPerElement,
        orientation[1], Endian.little);
    view.setFloat32(Uint16List.bytesPerElement + Float32List.bytesPerElement * 2,
        orientation[2], Endian.little);
    provider.sendBinaryMessage(bytes);
  }

  sendPadUpdate(int index, int gesture) {
    final Uint8List bytes =
    Uint8List(Uint16List.bytesPerElement * 3);
    final view = ByteData.view(bytes.buffer);
    view.setUint16(0, EVENT_TYPE_RESOLUTION_PAD_BUTTON_TAP, Endian.little);
    view.setUint16(Uint16List.bytesPerElement, index, Endian.little);
    view.setUint16(Uint16List.bytesPerElement * 2, gesture, Endian.little);
    provider.sendBinaryMessage(bytes);
  }


  @override
  _GyroscopeState createState() => _GyroscopeState();
}

class _GyroscopeState extends State<Gyroscope> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  Offset? cursor;
  List<double>? magnetometerData;
  List<double>? accelerometerData;
  List<double>? rotationMatrix;
  List<double>? reMappedRotationMatrix;
  List<double>? orientationAngles;

  @override
  initState() {

    _magSub = magnetometerEvents.listen(_onMagnetChange);
    _accSub = accelerometerEvents.listen(_onAccelerometerChange);
    super.initState();
  }

  _onMagnetChange(MagnetometerEvent event) {
    setState(() {
      if (magnetometerData == null) {
        magnetometerData = List.filled(3, 0.0);
      }
      magnetometerData![0] = event.x;
      magnetometerData![1] = event.y;
      magnetometerData![2] = event.z;
    });
    _onChangeRotation();
  }

  _onAccelerometerChange(AccelerometerEvent event) {
    setState(() {
      if (accelerometerData == null) {
        accelerometerData = List.filled(3, 0.0);
      }
      accelerometerData![0] = event.x;
      accelerometerData![1] = event.y;
      accelerometerData![2] = event.z;
    });
    _onChangeRotation();
  }

  _onChangeRotation() {
    if (accelerometerData == null || magnetometerData == null) {
      return;
    }
    if (rotationMatrix == null) {
      rotationMatrix = List.filled(9, 0.0);
      reMappedRotationMatrix = List.filled(9, 0.0);
    }
    if (orientationAngles == null) {
      orientationAngles = List.filled(3, 0.0);
    }
    Gyromath.getRotationMatrix(rotationMatrix, null, accelerometerData!, magnetometerData!);
    final orientation = Platform.isIOS && widget.orientation == DeviceOrientation.landscapeLeft ? DeviceOrientation.landscapeRight : widget.orientation;
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        copyInPlace(rotationMatrix!, reMappedRotationMatrix!);
        break;
      case DeviceOrientation.landscapeLeft:
        Gyromath.remapCoordinateSystem(rotationMatrix!,
            AXIS_Y, AXIS_MINUS_X,
            reMappedRotationMatrix!);
        break;
      case DeviceOrientation.portraitDown:
        Gyromath.remapCoordinateSystem(rotationMatrix!,
            AXIS_MINUS_X, AXIS_MINUS_Y,
            reMappedRotationMatrix!);
        break;
      case DeviceOrientation.landscapeRight:
        Gyromath.remapCoordinateSystem(rotationMatrix!,
            AXIS_MINUS_Y, AXIS_X,
            reMappedRotationMatrix!);
        break;
    }
    print(reMappedRotationMatrix);
    Gyromath.getOrientation(reMappedRotationMatrix!, orientationAngles!);
    print("[Orientation] Orientation: ${widget.orientation.toString()} Azimuth: ${orientationAngles![0]} | Pitch ${orientationAngles![1]} | Roll ${orientationAngles![2]}");
    widget.sendGyroscopeUpdate(orientationAngles!);
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 3,
            child: Center(
              child: JoystickView(
                onDirectionChanged: (degrees, distance) {
                  print("${[degrees, distance]}");
                },
                interval: Duration(milliseconds: 33),
              ),
            )),
        Expanded(
            flex: 2,
            child: Center(
              child: widget.onTouchPressed != null
                  ? IconButton(
                  iconSize: 40,
                  icon: Icon(widget.toggleIcon),
                  onPressed: () => widget.onTouchPressed!())
                  : Container(),
            )),
        Expanded(flex: 3, child: Center(
          child: PadButtonsView(
            padButtonPressedCallback: (i, g) {
              widget.sendPadUpdate(i, g.index);
              print("${[i, g]}");
            },
          ),
        )),
      ],
    );
  }
}

void copyInPlace(List<double> src, List<double> dst) {
  if (src.length > dst.length) throw "length mismatch";
  for (int i = 0; i < src.length; i++) {
    dst[i] = src[i];
  }
}