import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:friction_scroll_controller/src/friction_scroll_activity_context.dart';
import 'package:friction_scroll_controller/src/friction_scrolll_activity_delegate.dart';

/// Base class for friction scroll activities.
///
/// Override [onContextUpdate] to implement the actual friction scroll logic
/// based on the friction context and delta.
abstract final class FrictionScrollActivity extends ScrollActivity {
  FrictionScrollActivity({
    required FrictionScrollActivityDelegate delegate,
    required TickerProvider vsync,
  }) : super(delegate) {
    _ticker = Ticker(
      (elapsed) {
        final sinceLastTick = elapsed - _lastElapsed;
        _lastElapsed = elapsed;
        _elapsedSinceLastContext += sinceLastTick;

        final context = delegate.readAccumulatedContext();
        if (context == null) {
          return;
        }

        final sumElapsed = elapsed + _elapsedSinceLastContext;
        _elapsedSinceLastContext = Duration.zero;

        final delta =
            sumElapsed.inMicroseconds / Duration.microsecondsPerSecond;

        onContextUpdate(delta, context);
      },
      debugLabel: 'FrictionScrollActivity ticker',
    )..start();
  }

  late final Ticker _ticker;
  var _lastElapsed = Duration.zero;
  var _elapsedSinceLastContext = Duration.zero;

  @override
  FrictionScrollActivityDelegate get delegate =>
      super.delegate as FrictionScrollActivityDelegate;

  @override
  bool get shouldIgnorePointer => false;

  /// Called every frame.
  ///
  /// [delta] is the time since the last frame in seconds.
  void onContextUpdate(
    double delta,
    FrictionScrollActivityContext context,
  );

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

final class StaticFrictionScrollActivity extends FrictionScrollActivity {
  StaticFrictionScrollActivity({
    required super.delegate,
    required super.vsync,
  });

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0;

  @override
  void onContextUpdate(
    double delta,
    FrictionScrollActivityContext context,
  ) {
    final frictionAcceleration =
        delegate.staticFrictionCoefficient * context.normalAcceleration;

    if (context.gravityAlongIncline.abs() > frictionAcceleration) {
      delegate.goKineticFriction();
    }
  }
}

final class KineticFrictionScrollActivity extends FrictionScrollActivity {
  KineticFrictionScrollActivity({
    required super.delegate,
    required super.vsync,
  });

  var _velocity = 0.0;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _velocity;

  double _metersToPixels(double meters) {
    const inchesPerMeter = 39.3701;
    const logicalPixelsPerInch = 160;

    final inches = meters * inchesPerMeter;
    final pixels = inches * logicalPixelsPerInch;

    return pixels;
  }

  @override
  void onContextUpdate(
    double delta,
    FrictionScrollActivityContext context,
  ) {
    final frictionAcceleration =
        delegate.kineticFrictionCoefficient * context.normalAcceleration;

    // net force along incline
    final netAcceleration = context.gravityAlongIncline -
        frictionAcceleration * context.gravityAlongIncline.sign;

    final oldVelocity = _velocity;
    final deltaVelocity = _metersToPixels(netAcceleration * delta);
    _velocity += deltaVelocity;

    // If velocity is zero or is other sign that it was (so it fell below zero)
    // stop the movement.
    if (_velocity == 0 ||
        oldVelocity.sign != _velocity.sign && oldVelocity != 0) {
      delegate.goStaticFriction();
      return;
    }

    // x = v_0 * Δt + Δv / Δt * Δt^2 / 2
    // x = v_0 * Δt + Δv * Δt / 2
    final distance = oldVelocity * delta + deltaVelocity * delta / 2;

    delegate.applyUserOffset(distance);
  }
}
