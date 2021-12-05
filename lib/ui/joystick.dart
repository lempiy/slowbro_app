import 'dart:typed_data';
import 'package:control_pad/control_pad.dart';
import 'package:control_pad/views/joystick_view.dart';
import 'package:flutter/material.dart';
import 'package:slowbro/api/event_types.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';


class Joystick extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;
  final void Function()? onTouchPressed;
  final IconData? toggleIcon;

  const Joystick(
      {Key? key,
      required this.provider,
      required this.pointerOptions,
      required this.toggleIcon,
      this.onTouchPressed})
      : super(key: key);

  sendJoystickUpdate(double angle, double distance) {
    final Uint8List bytes =
        Uint8List(Uint16List.bytesPerElement + Float32List.bytesPerElement * 2);
    final view = ByteData.view(bytes.buffer);
    view.setUint16(0, EVENT_TYPE_RESOLUTION_JOYSTICK_CHANGE, Endian.little);
    view.setFloat32(Uint16List.bytesPerElement, angle, Endian.little);
    view.setFloat32(Uint16List.bytesPerElement + Float32List.bytesPerElement,
        distance, Endian.little);
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
  _JoystickState createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset? cursor;
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
                  widget.sendJoystickUpdate(degrees, distance);
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
