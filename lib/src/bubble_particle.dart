import 'dart:math';
import 'package:flutter/widgets.dart';
import 'bubble_settings.dart';

/// An immutable bubble. Positions are normalized to the splash's local bounds.
///
/// (0, 0) is the top left; (1, 1) is the bottom right. Values outside
/// that range are allowed so bubbles can travel beyond the edges.
@immutable
class BubbleParticle {
  /// Creates a bubble with a positive diameter and a delay in [0, 1).
  const BubbleParticle({
    required this.diameter,
    required this.color,
    required this.start,
    required this.end,
    this.delay = 0,
  }) : assert(diameter > 0),
       assert(delay >= 0 && delay < 1);

  /// Diameter in logical pixels, or a fraction of the shortest side when
  /// [BubbleStyle.relativeSize] is enabled.
  final double diameter;

  /// Solid fill color used when no style gradient overrides it.
  final Color color;

  /// Initial normalized center, relative to the local splash bounds.
  final Offset start;

  /// Final normalized center; may lie outside the splash bounds.
  final Offset end;

  /// Fraction of the animation before this bubble starts moving.
  final double delay;
}

/// Supplies custom bubble geometry. Called only when the field is regenerated,
/// not on animation ticks. Use the supplied random for repeatable seeded fields.
typedef BubbleParticleFactory =
    BubbleParticle Function(int index, int count, Random random);

/// Current visual state, available to custom bubble and logo builders.
@immutable
class BubbleFrame {
  /// Creates the visual state passed to a custom bubble builder.
  const BubbleFrame({
    required this.progress,
    required this.scale,
    required this.opacity,
    required this.center,
    required this.diameter,
  });

  /// Progress after applying this particle's delay, from zero to one.
  final double progress;

  /// Current scale factor applied outside the custom builder.
  final double scale;

  /// Current opacity applied outside the custom builder.
  final double opacity;

  /// Current center in local logical pixels.
  final Offset center;

  /// Unscaled diameter in logical pixels, resolved from relative sizing.
  final double diameter;
}

/// Replaces a bubble's contents. Position, scale and opacity are applied outside
/// this builder; its box is [BubbleFrame.diameter] square.
typedef BubbleWidgetBuilder =
    Widget Function(
      BuildContext context,
      BubbleParticle particle,
      BubbleFrame frame,
    );

/// Replaces the built-in logo transform. [progress] is the overall timeline.
typedef BubbleLogoBuilder =
    Widget Function(BuildContext context, double progress, Widget logo);
