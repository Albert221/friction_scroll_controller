/// Context for friction scrolling.
///
/// It holds accelerations instead of mass, as the mass was removed on both
/// sides of the equations.
final class FrictionScrollActivityContext {
  const FrictionScrollActivityContext({
    this.normalAcceleration = 0,
    this.gravityAlongIncline = 0,
  });

  /// The acceleration of the object along the normal of the surface, i.e.
  /// orthogonal to the surface.
  final double normalAcceleration;

  /// The gravitational acceleration component along the incline of the surface.
  final double gravityAlongIncline;

  /// When we receive more than one context but cannot apply it to the object
  /// immediately (e.g. because we're still waiting for a frame), we can merge
  /// the contexts together.
  static FrictionScrollActivityContext merge(
    List<FrictionScrollActivityContext> contexts,
  ) {
    assert(contexts.isNotEmpty);

    if (contexts.length == 1) {
      return contexts.first;
    }

    return _MergedFrictionScrollActivityContext(contexts);
  }
}

final class _MergedFrictionScrollActivityContext
    implements FrictionScrollActivityContext {
  _MergedFrictionScrollActivityContext(
      List<FrictionScrollActivityContext> contexts)
      : _contexts = contexts.expand((context) {
          return context is _MergedFrictionScrollActivityContext
              ? context._contexts
              : [context];
        }).toList();

  final List<FrictionScrollActivityContext> _contexts;

  @override
  double get gravityAlongIncline =>
      _contexts.map((e) => e.gravityAlongIncline).average;

  @override
  double get normalAcceleration =>
      _contexts.map((e) => e.normalAcceleration).average;
}

extension _Average on Iterable<double> {
  double get average => isEmpty ? 0 : reduce((a, b) => a + b) / length;
}
