import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:slowbro/api/event_types.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';

class TouchPad extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;

  const TouchPad(
      {Key? key, required this.provider, required this.pointerOptions})
      : super(key: key);

  sendUpdate(Offset cursor, {isClick = false}) {
    final Uint8List bytes = Uint8List(Uint16List.bytesPerElement + Float32List.bytesPerElement * 2);
    final view = ByteData.view(bytes.buffer);
    view.setUint16(0, isClick ? EVENT_TYPE_RESOLUTION_TOUCH_TAP : EVENT_TYPE_RESOLUTION_TOUCH_MOVE, Endian.little);
    view.setFloat32(Uint16List.bytesPerElement, cursor.dx, Endian.little);
    view.setFloat32(Uint16List.bytesPerElement+Float32List.bytesPerElement, cursor.dy, Endian.little);
    provider.sendBinaryMessage(bytes);
  }

  @override
  _TouchPadState createState() => _TouchPadState();
}

class _TouchPadState extends State<TouchPad> {
  Offset? cursor;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.pointerOptions.touch?.aspectRatio ?? 1,
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              setState(() {
                cursor = Offset(
                    min(1, max(0, details.localPosition.dx / box.size.width)),
                    min(1, max(0, details.localPosition.dy / box.size.height)));
                widget.sendUpdate(cursor!);
              });
            },
            onPanStart: (details) {
              final box = context.findRenderObject() as RenderBox;
              setState(() {
                cursor = Offset(
                    min(1, max(0, details.localPosition.dx / box.size.width)),
                    min(1, max(0, details.localPosition.dy / box.size.height)));
                widget.sendUpdate(cursor!);
              });
            },
            onTapDown: (details) {

            },
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox;
              setState(() {
                cursor = Offset(
                    min(1, max(0, details.localPosition.dx / box.size.width)),
                    min(1, max(0, details.localPosition.dy / box.size.height)));

                widget.sendUpdate(cursor!, isClick: true);
              });
            },
            onTap: () {},
            onPanEnd: (details) {
              setState(() {
                // points.add(null);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: CustomPaint(
                painter: TouchPainter(touch: cursor),
              ),
            ),
          );
        }
      ),
    );
  }
}

class TouchPainter extends CustomPainter {
  final Offset? touch;
  final paint1 = Paint()
    ..color = Color(0xff63aa65)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  TouchPainter({required this.touch});

  @override
  void paint(Canvas canvas, Size size) {
    if (touch == null) return;
    canvas.drawCircle(Offset(touch!.dx * size.width, touch!.dy * size.height),
        size.height * 0.05, paint1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
