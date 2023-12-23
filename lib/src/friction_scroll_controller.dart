import 'package:flutter/widgets.dart';
import 'package:friction_scroll_controller/src/friction_scroll_position.dart';

class FrictionScrollController extends ScrollController {
  FrictionScrollController({
    required this.staticFrictionCoefficient,
    required this.kineticFrictionCoefficient,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  final double staticFrictionCoefficient;
  final double kineticFrictionCoefficient;

  @override
  FrictionScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return FrictionScrollPosition(
      staticFrictionCoefficient: staticFrictionCoefficient,
      kineticFrictionCoefficient: kineticFrictionCoefficient,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}
