import 'package:flutter/material.dart';

/// Direction in which the curtain opens.
enum BubbleDirection { scattered, left, right, up, down, horizontal, vertical }

/// Appearance of the bubble curtain.
@immutable
class BubbleStyle {
  /// Creates a curtain appearance. Sizes must be positive, and max >= min.
  const BubbleStyle({
    this.count = 90,
    this.colors = const [
      Color(0xFF007F7A),
      Color(0xFF13B8A6),
      Color(0xFF73DCC6),
      Color(0xFFB9F3DF),
    ],
    this.minSize = 180,
    this.maxSize = 300,
    this.relativeSize = false,
    this.shadows = const [
      BoxShadow(color: Color(0x33003836), blurRadius: 10, spreadRadius: 2),
    ],
    this.shape = BoxShape.circle,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.border,
    this.gradient,
  }) : assert(count >= 0),
       assert(minSize > 0),
       assert(maxSize >= minSize);

  /// Number of bubbles. Zero keeps only the logo animation.
  final int count;

  /// Palette sampled by the default particle generator.
  final List<Color> colors;

  /// Smallest generated diameter, in pixels or shortest-side fractions.
  final double minSize;

  /// Largest generated diameter, in pixels or shortest-side fractions.
  final double maxSize;

  /// Interpret sizes as multiples of the shortest local layout dimension.
  final bool relativeSize;

  /// Shadows on each bubble. An empty list disables them.
  final List<BoxShadow> shadows;

  /// Circle or rectangle. Use a builder for other shapes.
  final BoxShape shape;

  /// Corner radii when [shape] is [BoxShape.rectangle].
  final BorderRadius borderRadius;

  /// Optional border painted around each bubble.
  final BoxBorder? border;

  /// If provided, takes visual precedence over each particle's solid color.
  final Gradient? gradient;
}

/// Motion and fading of the bubbles. All fractions refer to the reveal timeline.
@immutable
class BubbleMotion {
  /// Creates bubble movement, scale, stagger, and fade settings.
  const BubbleMotion({
    this.direction = BubbleDirection.scattered,
    this.curve = Curves.linear,
    this.scaleCurve = Curves.linear,
    this.fadeCurve = Curves.linear,
    this.fadeStart = 0.6,
    this.endOpacity = 0.2,
    this.startScale = 1,
    this.endScale = 0,
    this.maxDelay = 0,
    this.travelDistance = 1.2,
  }) : assert(fadeStart >= 0 && fadeStart < 1),
       assert(endOpacity >= 0 && endOpacity <= 1),
       assert(startScale >= 0),
       assert(endScale >= 0),
       assert(maxDelay >= 0 && maxDelay < 1),
       assert(travelDistance >= 0);

  /// Default travel direction; custom particle paths override this setting.
  final BubbleDirection direction;

  /// Curve used to interpolate bubble centers.
  final Curve curve;

  /// Curve used to interpolate bubble scale.
  final Curve scaleCurve;

  /// Curve used after [fadeStart] to interpolate opacity.
  final Curve fadeCurve;

  /// Fraction of each bubble's delayed timeline at which fading starts.
  final double fadeStart;

  /// Bubble opacity at the end of its timeline, from zero to one.
  final double endOpacity;

  /// Bubble scale before movement starts.
  final double startScale;

  /// Bubble scale at completion. Zero makes the bubble disappear.
  final double endScale;

  /// Maximum random start delay, as a fraction of the whole timeline.
  final double maxDelay;

  /// Directional distance in local width/height multiples; unused for scattered.
  final double travelDistance;
}

/// Default fade, scale and slide used to reveal the supplied logo widget.
@immutable
class BubbleLogoAnimation {
  /// Creates the default logo reveal. Set startOpacity to 1 for growth alone.
  const BubbleLogoAnimation({
    this.begin = 0,
    this.end = 1,
    this.curve = Curves.linear,
    this.startScale = 0,
    this.endScale = 1,
    this.startOpacity = 0,
    this.endOpacity = 1,
    this.startOffset = Offset.zero,
    this.endOffset = Offset.zero,
  }) : assert(begin >= 0 && begin < end),
       assert(end <= 1),
       assert(startScale >= 0 && endScale >= 0),
       assert(startOpacity >= 0 && startOpacity <= 1),
       assert(endOpacity >= 0 && endOpacity <= 1);

  /// Fraction of the whole timeline when the logo reveal starts.
  final double begin;

  /// Fraction when the logo reaches its final state. Must exceed [begin].
  final double end;

  /// Curve applied inside the [begin] to [end] interval.
  final Curve curve;

  /// Initial scale, about the logo's center.
  final double startScale;

  /// Final scale. One uses the logo widget's natural size.
  final double endScale;

  /// Initial opacity, from zero to one.
  final double startOpacity;

  /// Final opacity, from zero to one.
  final double endOpacity;

  /// Translation in logical pixels.
  final Offset startOffset;

  /// Final translation in logical pixels.
  final Offset endOffset;
}
