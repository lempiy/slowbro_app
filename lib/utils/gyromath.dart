import 'dart:math';

const int AXIS_X = 1;
const int AXIS_Y = 2;
const int AXIS_Z = 3;
const int AXIS_MINUS_X = AXIS_X | 0x80;
const int AXIS_MINUS_Y = AXIS_Y | 0x80;
const int AXIS_MINUS_Z = AXIS_Z | 0x80;

abstract class Gyromath {
  static bool getRotationMatrix(List<double>? R, List<double>? I,
  List<double> gravity, List<double> geomagnetic) {
    double Ax = gravity[0];
    double Ay = gravity[1];
    double Az = gravity[2];
    final double normsqA = (Ax * Ax + Ay * Ay + Az * Az);
    final double g = 9.81;
    final double freeFallGravitySquared = 0.01 * g * g;
    if (normsqA < freeFallGravitySquared) {
    // gravity less than 10% of normal value
    return false;
    }
    final double Ex = geomagnetic[0];
    final double Ey = geomagnetic[1];
    final double Ez = geomagnetic[2];
    double Hx = Ey * Az - Ez * Ay;
    double Hy = Ez * Ax - Ex * Az;
    double Hz = Ex * Ay - Ey * Ax;
    final double normH = sqrt(Hx * Hx + Hy * Hy + Hz * Hz);
    if (normH < 0.1) {
      // device is close to free fall (or in space?), or close to
      // magnetic north pole. Typical values are  > 100.
      return false;
    }
    final double invH = 1.0 / normH;
    Hx *= invH;
    Hy *= invH;
    Hz *= invH;
    final double invA = 1.0 / sqrt(Ax * Ax + Ay * Ay + Az * Az);
    Ax *= invA;
    Ay *= invA;
    Az *= invA;
    final double Mx = Ay * Hz - Az * Hy;
    final double My = Az * Hx - Ax * Hz;
    final double Mz = Ax * Hy - Ay * Hx;
    if (R != null) {
      if (R.length == 9) {
        R[0] = Hx;     R[1] = Hy;     R[2] = Hz;
        R[3] = Mx;     R[4] = My;     R[5] = Mz;
        R[6] = Ax;     R[7] = Ay;     R[8] = Az;
      } else if (R.length == 16) {
        R[0]  = Hx;    R[1]  = Hy;    R[2]  = Hz;   R[3]  = 0;
        R[4]  = Mx;    R[5]  = My;    R[6]  = Mz;   R[7]  = 0;
        R[8]  = Ax;    R[9]  = Ay;    R[10] = Az;   R[11] = 0;
        R[12] = 0;     R[13] = 0;     R[14] = 0;    R[15] = 1;
      }
    }
    if (I != null) {
      // compute the inclination matrix by projecting the geomagnetic
      // vector onto the Z (gravity) and X (horizontal component
      // of geomagnetic vector) axes.
      final double invE = 1.0 / sqrt(Ex * Ex + Ey * Ey + Ez * Ez);
      final double c = (Ex * Mx + Ey * My + Ez * Mz) * invE;
      final double s = (Ex * Ax + Ey * Ay + Ez * Az) * invE;
      if (I.length == 9) {
        I[0] = 1;     I[1] = 0;     I[2] = 0;
        I[3] = 0;     I[4] = c;     I[5] = s;
        I[6] = 0;     I[7] = -s;     I[8] = c;
      } else if (I.length == 16) {
        I[0] = 1;     I[1] = 0;     I[2] = 0;
        I[4] = 0;     I[5] = c;     I[6] = s;
        I[8] = 0;     I[9] = -s;     I[10] = c;
        I[3] = I[7] = I[11] = I[12] = I[13] = I[14] = 0;
        I[15] = 1;
      }
    }
    return true;
  }

  static List<double> getOrientation(List<double> R, List<double> values) {
    if (R.length == 9) {
      values[0] = atan2(R[1], R[4]);
      values[1] = asin(-R[7]);
      values[2] = atan2(-R[6], R[8]);
    } else {
      values[0] = atan2(R[1], R[5]);
      values[1] = asin(-R[9]);
      values[2] = atan2(-R[8], R[10]);
    }
    return values;
  }
  
  static bool remapCoordinateSystem(List<double> inR, int X, int Y, List<double> outR) {
    /*
           * X and Y define a rotation matrix 'r':
           *
           *  (X==1)?((X&0x80)?-1:1):0    (X==2)?((X&0x80)?-1:1):0    (X==3)?((X&0x80)?-1:1):0
           *  (Y==1)?((Y&0x80)?-1:1):0    (Y==2)?((Y&0x80)?-1:1):0    (Y==3)?((X&0x80)?-1:1):0
           *                              r[0] ^ r[1]
           *
           * where the 3rd line is the vector product of the first 2 lines
           *
           */
    final int length = outR.length;
    if (inR.length != length) {
      return false;   // invalid parameter
    }
    if ((X & 0x7C) != 0 || (Y & 0x7C) != 0) {
      return false;   // invalid parameter
    }
    if (((X & 0x3) == 0) || ((Y & 0x3) == 0)) {
      return false;   // no axis specified
    }
    if ((X & 0x3) == (Y & 0x3)) {
      return false;   // same axis specified
    }
    // Z is "the other" axis, its sign is either +/- sign(X)*sign(Y)
    // this can be calculated by exclusive-or'ing X and Y; except for
    // the sign inversion (+/-) which is calculated below.
    int Z = X ^ Y;
    // extract the axis (remove the sign), offset in the range 0 to 2.
    final int x = (X & 0x3) - 1;
    final int y = (Y & 0x3) - 1;
    final int z = (Z & 0x3) - 1;
    // compute the sign of Z (whether it needs to be inverted)
    final int axis_y = (z + 1) % 3;
    final int axis_z = (z + 2) % 3;
    if (((x ^ axis_y) | (y ^ axis_z)) != 0) {
      Z ^= 0x80;
    }
    final bool sx = (X >= 0x80);
    final bool sy = (Y >= 0x80);
    final bool sz = (Z >= 0x80);
    // Perform R * r, in avoiding actual muls and adds.
    final int rowLength = ((length == 16) ? 4 : 3);
    for (int j = 0; j < 3; j++) {
      final int offset = j * rowLength;
      for (int i = 0; i < 3; i++) {
        if (x == i)   outR[offset + i] = sx ? -inR[offset + 0] : inR[offset + 0];
        if (y == i)   outR[offset + i] = sy ? -inR[offset + 1] : inR[offset + 1];
        if (z == i)   outR[offset + i] = sz ? -inR[offset + 2] : inR[offset + 2];
      }
    }
    if (length == 16) {
      outR[3] = outR[7] = outR[11] = outR[12] = outR[13] = outR[14] = 0;
      outR[15] = 1;
    }
    return true;
  }
}

