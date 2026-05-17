import 'package:flutter/material.dart';

/// CampusPool Motion System — timing, curves, and physics.
class AppMotion {
  AppMotion._();

  // ── Durations ──
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const ambient = Duration(milliseconds: 2000);

  // ── Curves ──
  static const standard = Curves.easeInOut;
  static const decelerate = Curves.decelerate;
  static const overshoot = Curves.elasticOut;
  static const emphasize = Cubic(0.4, 0.0, 0.2, 1.0);
}
