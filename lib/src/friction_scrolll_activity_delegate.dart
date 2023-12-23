import 'package:flutter/widgets.dart';
import 'package:friction_scroll_controller/src/friction_scroll_activity_context.dart';

abstract class FrictionScrollActivityDelegate extends ScrollActivityDelegate {
  FrictionScrollActivityDelegate({
    required this.staticFrictionCoefficient,
    required this.kineticFrictionCoefficient,
  });

  final double staticFrictionCoefficient;
  final double kineticFrictionCoefficient;

  FrictionScrollActivityContext? readAccumulatedContext();

  /// Start kinetic friction scroll activity.
  void goKineticFriction();

  /// Start static friction scroll activity.
  void goStaticFriction();
}
