import 'dart:math';

import 'package:slowbro/api/camera_view_singleton.dart';

/// Represents the recognition output from the model
class Recognition {
  /// Confidence [0.0, 1.0]
  double _score;

  Point _point;

  String _name;

  Recognition(this._point, this._score, this._name);

  Point get point => _point;

  String get name => _name;

  double get score => _score;
  /// Returns Point corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where point is rendered on
  /// the screen
  Point<double> get renderLocation {
    // ratioX = screenWidth / imageInputWidth
    // ratioY = ratioX if image fits screenWidth with aspectRatio = constant

    double ratioX = CameraViewSingleton.ratio;
    double ratioY = ratioX;

    double transX = max(0.1, point.x * ratioX);
    double transY = max(0.1, point.y * ratioY);
    return Point(transX, transY);
  }

  @override
  String toString() {
    return "$name: (x: ${point.x} y: ${point.y}): score: $score";
  }
}
