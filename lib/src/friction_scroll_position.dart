import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:friction_scroll_controller/src/friction_scroll_activity.dart';
import 'package:friction_scroll_controller/src/friction_scroll_activity_context.dart';
import 'package:friction_scroll_controller/src/friction_scrolll_activity_delegate.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FrictionScrollPosition extends ScrollPosition
    implements FrictionScrollActivityDelegate {
  FrictionScrollPosition({
    required this.staticFrictionCoefficient,
    required this.kineticFrictionCoefficient,
    required super.physics,
    required super.context,
    double? initialPixels = 0,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) {
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }
    if (activity == null) {
      goStaticFriction();
    }
    assert(activity != null);

    _accelerometerSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .map(_accelerometerEventToContext(context.axisDirection))
            .listen(_onFrictionContext);
  }

  @override
  final double staticFrictionCoefficient;

  @override
  final double kineticFrictionCoefficient;

  late final StreamSubscription<FrictionScrollActivityContext>
      _accelerometerSubscription;

  static FrictionScrollActivityContext Function(AccelerometerEvent)
      _accelerometerEventToContext(
    AxisDirection axisDirection,
  ) {
    return (event) {
      return FrictionScrollActivityContext(
        normalAcceleration: event.z,
        gravityAlongIncline: switch (axisDirection) {
          AxisDirection.left || AxisDirection.right => -event.x,
          AxisDirection.up || AxisDirection.down => -event.y,
        },
      );
    };
  }

  FrictionScrollActivityContext? _accumulatedContext;

  void _onFrictionContext(FrictionScrollActivityContext context) {
    _accumulatedContext = FrictionScrollActivityContext.merge([
      if (_accumulatedContext case final accumulatedContext?)
        accumulatedContext,
      context,
    ]);
  }

  @override
  FrictionScrollActivityContext? readAccumulatedContext() {
    final result = _accumulatedContext;
    _accumulatedContext = null;
    return result;
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is! FrictionScrollPosition) {
      goStaticFriction();
      return;
    }

    activity!.updateDelegate(this);
  }

  @override
  void goIdle() => goStaticFriction();

  @override
  void goBallistic(double velocity) {/* no-op */}

  @override
  void goStaticFriction() {
    beginActivity(
      StaticFrictionScrollActivity(
        delegate: this,
        vsync: context.vsync,
      ),
    );
  }

  @override
  void goKineticFriction() {
    beginActivity(
      KineticFrictionScrollActivity(
        delegate: this,
        vsync: context.vsync,
      ),
    );
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    // Copied from scroll_position_with_single_context.dart

    if (nearEqual(to, pixels, physics.toleranceFor(this).distance)) {
      // Skip the animation, go straight to the position as we are already close.
      jumpTo(to);
      return Future<void>.value();
    }

    final activity = DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  var _userScrollDirection = ScrollDirection.idle;

  @protected
  void updateUserScrollDirection(ScrollDirection value) {
    if (userScrollDirection == value) {
      return;
    }
    _userScrollDirection = value;
    didUpdateScrollDirection(value);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
      delta > 0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // we don't do drags
    dragCancelCallback();
    return const _Drag();
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    holdCancelCallback();
    return const _ScrollHoldController();
  }

  @override
  void jumpTo(double value) {
    goStaticFriction();
    if (pixels != value) {
      final oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
  }

  @override
  void jumpToWithoutSettling(double value) {
    // we don't do any settling in jumpTo
    jumpTo(value);
  }

  @override
  void pointerScroll(double delta) {/* no-op */}

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }
}

final class _Drag implements Drag {
  const _Drag();

  @override
  void cancel() {}

  @override
  void end(DragEndDetails details) {}

  @override
  void update(DragUpdateDetails details) {}
}

final class _ScrollHoldController implements ScrollHoldController {
  const _ScrollHoldController();

  @override
  void cancel() {}
}
