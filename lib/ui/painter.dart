import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:slowbro/tflite/recognition.dart';

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

final List<List<String>> edges = [
  // torso
  ["leftShoulder", "rightShoulder"],
  ["rightShoulder", "rightHip"],
  ["rightHip", "leftHip"],
  ["leftShoulder", "leftHip"],
  // left arm
  ["leftShoulder", "leftElbow"],
  ["leftElbow", "leftWrist"],
  // right arm
  ["rightShoulder", "rightElbow"],
  ["rightElbow", "rightWrist"],
  // left leg
  ["leftHip", "leftKnee"],
  ["leftKnee", "leftAnkle"],
  // right leg
  ["rightHip", "rightKnee"],
  ["rightKnee", "rightAnkle"],
];

class EdgePainter extends CustomPainter {
  final List<Recognition>? recognitions;
  final Map<String, Recognition> _hMap;

  EdgePainter(this.recognitions) :
        this._hMap = recognitions == null ? {} : recognitions.fold({}, (acc, r) {acc[r.name] = r; return acc;});

  @override
  void paint(Canvas canvas, Size size) {
    if (recognitions == null) return;
    this.recognitions!.forEach((r) {
      drawPoint(r.renderLocation, canvas, size, Colors.green, r.name);
    });
    edges.forEach((edge) {
      final f = _hMap[edge[0]];
      final t = _hMap[edge[1]];
      if (f == null || t == null) return;
      drawEdge(f.renderLocation, t.renderLocation, canvas, size, Colors.green);
    });
  }

  void drawPoint(Point<double> f, Canvas canvas, Size size, Color color, String name) {
    final p = Offset(f.x, f.y);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawCircle(p, 3.0, paint);
    TextSpan span = new TextSpan(style: new TextStyle(color: Colors.green, fontSize: 9), text: name);
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(f.x + 4, f.y + 4));
  }

  void drawEdge(Point<double> f, Point<double> t, Canvas canvas, Size size, Color color) {
    final p1 = Offset(f.x, f.y);
    final p2 = Offset(t.x, t.y);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
