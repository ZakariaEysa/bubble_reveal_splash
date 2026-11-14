import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'bubble_particle.dart';
import 'bubble_settings.dart';

/// A bubble curtain that opens while revealing any logo widget.
///
/// Give this widget bounded space (for example, a Scaffold body or SizedBox).
/// It never navigates: use [onCompleted] to choose what happens next.
///
/// Omit [controller] for automatic playback. Supply an [AnimationController]
/// for play/pause/reverse/replay/seek; the caller owns its duration and disposal.
class BubbleSplash extends StatefulWidget {
  /// Creates a bounded bubble curtain and logo reveal.
  const BubbleSplash({
    super.key,
    required this.logo,
    this.style = const BubbleStyle(),
    this.motion = const BubbleMotion(),
    this.logoAnimation = const BubbleLogoAnimation(),
    this.duration = const Duration(seconds: 3),
    this.startDelay = Duration.zero,
    this.holdDuration = const Duration(seconds: 1),
    this.autoStart = true,
    this.controller,
    this.seed,
    this.backgroundColor = const Color(0xFFF3FBF7),
    this.background,
    this.foreground,
    this.logoAlignment = Alignment.center,
    this.logoPadding = EdgeInsets.zero,
    this.logoOnTop = true,
    this.particleFactory,
    this.bubbleBuilder,
    this.logoBuilder,
    this.onCompleted,
    this.onProgress,
    this.onStatusChanged,
    this.respectReducedMotion = true,
    this.clipBehavior = Clip.hardEdge,
    this.semanticsLabel,
  });

  /// Branding to reveal. Set its natural size using the supplied widget.
  final Widget logo;

  /// Bubble count, sizing, palette, and decoration.
  final BubbleStyle style;

  /// Bubble movement, scale, fade, and random stagger settings.
  final BubbleMotion motion;

  /// Built-in logo transforms, replaced when [logoBuilder] is supplied.
  final BubbleLogoAnimation logoAnimation;

  /// Applies to the internally owned controller only.
  final Duration duration;

  /// Applies to internal automatic playback only.
  final Duration startDelay;

  /// Time between reaching progress 1 and invoking [onCompleted].
  final Duration holdDuration;

  /// Starts internal playback automatically after [startDelay].
  final bool autoStart;

  /// Optional caller-owned controller for manual playback.
  final AnimationController? controller;

  /// Use a fixed seed for reproducible bubbles and replays.
  final int? seed;

  /// Base color underneath every widget layer.
  final Color backgroundColor;

  /// Optional full-size layer behind the bubbles and logo.
  final Widget? background;

  /// Optional full-size layer above the bubbles and logo.
  final Widget? foreground;

  /// Placement of the transformed logo inside its padded bounds.
  final AlignmentGeometry logoAlignment;

  /// Insets around the logo's alignment area.
  final EdgeInsetsGeometry logoPadding;

  /// Set false to put the logo underneath the curtain.
  final bool logoOnTop;

  /// Overrides default random geometry, sizes, colors, and delays.
  final BubbleParticleFactory? particleFactory;

  /// Overrides bubble decoration while retaining motion and layout.
  final BubbleWidgetBuilder? bubbleBuilder;

  /// Overrides the built-in logo transforms with overall timeline progress.
  final BubbleLogoBuilder? logoBuilder;

  /// Fires once per reveal after [holdDuration]. Rewinding below 1 rearms it.
  /// Pending callbacks are cancelled on reverse, replay, or disposal.
  final VoidCallback? onCompleted;

  /// Reports progress on controller updates, from zero to one.
  final ValueChanged<double>? onProgress;

  /// Reports subsequent controller status changes.
  final ValueChanged<AnimationStatus>? onStatusChanged;

  /// Render the revealed state when the platform requests disabled animations.
  /// An external controller is never started, stopped, or disposed by this widget.
  final bool respectReducedMotion;

  /// Clipping applied to the splash's widget stack.
  final Clip clipBehavior;

  /// Optional semantic label for the splash.
  final String? semanticsLabel;

  @override
  State<BubbleSplash> createState() => _BubbleSplashState();
}

class _BubbleSplashState extends State<BubbleSplash>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<BubbleParticle> _particles;
  Timer? _startTimer;
  Timer? _completionTimer;
  bool _reduced = false;
  bool _dependenciesReady = false;
  bool _finished = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _validateTiming();
    _attachController();
    _generateParticles();
  }

  void _validateTiming() {
    if (widget.duration <= Duration.zero ||
        widget.startDelay < Duration.zero ||
        widget.holdDuration < Duration.zero) {
      throw ArgumentError(
        'duration must be positive; startDelay and '
        'holdDuration must be nonnegative.',
      );
    }
  }

  void _attachController() {
    _controller =
        widget.controller ??
        AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(_tick);
    _controller.addStatusListener(_statusChanged);
  }

  void _releaseController(bool owned) {
    _controller.removeListener(_tick);
    _controller.removeStatusListener(_statusChanged);
    if (owned) _controller.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        widget.respectReducedMotion && MediaQuery.disableAnimationsOf(context);
    if (!_dependenciesReady || reduced != _reduced) {
      _dependenciesReady = true;
      _reduced = reduced;
      _scheduleStart();
    }
  }

  void _scheduleStart() {
    _startTimer?.cancel();
    if (!_reduced &&
        (_controller.value < 1 ||
            _controller.status == AnimationStatus.reverse)) {
      _completionTimer?.cancel();
      _finished = false;
    }
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      if (_reduced) {
        if (widget.controller == null) {
          _controller.stop();
          _controller.value = 1;
        }
        _queueCompletion();
      } else if (widget.controller == null && widget.autoStart) {
        _startTimer = Timer(widget.startDelay, () {
          if (mounted) _controller.forward();
        });
      } else if (_controller.value == 1 &&
          _controller.status != AnimationStatus.reverse) {
        _queueCompletion();
      }
    });
  }

  @override
  void didUpdateWidget(BubbleSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateTiming();
    if (oldWidget.controller != widget.controller) {
      _completionTimer?.cancel();
      _finished = false;
      _releaseController(oldWidget.controller == null);
      _attachController();
      _scheduleStart();
    } else if (widget.controller == null) {
      _controller.duration = widget.duration;
      if (oldWidget.autoStart != widget.autoStart ||
          oldWidget.startDelay != widget.startDelay) {
        _scheduleStart();
      }
    }
    if (oldWidget.style != widget.style ||
        oldWidget.motion != widget.motion ||
        oldWidget.seed != widget.seed ||
        oldWidget.particleFactory != widget.particleFactory) {
      _generateParticles();
    }
    if (oldWidget.respectReducedMotion != widget.respectReducedMotion) {
      _reduced =
          widget.respectReducedMotion &&
          MediaQuery.disableAnimationsOf(context);
      _scheduleStart();
    }
    if (oldWidget.holdDuration != widget.holdDuration &&
        _completionTimer?.isActive == true) {
      _completionTimer?.cancel();
      _finished = false;
      _queueCompletion();
    }
  }

  void _tick() {
    if (!_reduced &&
        (_controller.value < 1 ||
            _controller.status == AnimationStatus.reverse)) {
      _completionTimer?.cancel();
      _finished = false;
    } else {
      _queueCompletion();
    }
    widget.onProgress?.call(_reduced ? 1 : _controller.value);
  }

  void _statusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _completionTimer?.cancel();
      _finished = false;
    }
    widget.onStatusChanged?.call(status);
  }

  void _queueCompletion() {
    if (_finished) return;
    _finished = true;
    _completionTimer = Timer(widget.holdDuration, () {
      if (mounted) widget.onCompleted?.call();
    });
  }

  void _generateParticles() {
    final style = widget.style;
    final motion = widget.motion;
    // Snapshot the list so caller mutations do not affect a running field.
    final colors = List<Color>.of(style.colors);
    if (style.count > 0 && colors.isEmpty && widget.particleFactory == null) {
      throw ArgumentError.value(
        style.colors,
        'style.colors',
        'Provide at least one bubble color or a particleFactory.',
      );
    }
    final random = math.Random(widget.seed);
    final columns = math.sqrt(style.count).ceil();
    final rows = columns == 0 ? 0 : (style.count / columns).ceil();
    _particles = List.generate(style.count, (i) {
      if (widget.particleFactory case final factory?) {
        return factory(i, style.count, random);
      }
      // Stratified starting positions create a fuller curtain than completely
      // independent random positions, while preserving the scattered movement.
      final start = Offset(
        (i % columns + 0.25 + random.nextDouble() * 0.5) / columns,
        (i ~/ columns + 0.25 + random.nextDouble() * 0.5) / rows,
      );
      final distance = motion.travelDistance;
      final end = switch (motion.direction) {
        BubbleDirection.scattered => Offset(
          random.nextDouble() * 2 - 0.5,
          random.nextDouble() * 2 - 0.5,
        ),
        BubbleDirection.left => start.translate(-distance, 0),
        BubbleDirection.right => start.translate(distance, 0),
        BubbleDirection.up => start.translate(0, -distance),
        BubbleDirection.down => start.translate(0, distance),
        BubbleDirection.horizontal => start.translate(
          start.dx < 0.5 ? -distance : distance,
          0,
        ),
        BubbleDirection.vertical => start.translate(
          0,
          start.dy < 0.5 ? -distance : distance,
        ),
      };
      return BubbleParticle(
        diameter:
            style.minSize +
            random.nextDouble() * (style.maxSize - style.minSize),
        color: colors[random.nextInt(colors.length)],
        start: start,
        end: end,
        delay: random.nextDouble() * motion.maxDelay,
      );
    }, growable: false);
  }

  double _unit(double value) => value.clamp(0.0, 1.0);

  Widget _buildLogo(double progress) {
    final animation = widget.logoAnimation;
    final t = animation.curve.transform(
      _unit((progress - animation.begin) / (animation.end - animation.begin)),
    );
    final child =
        widget.logoBuilder?.call(context, progress, widget.logo) ??
        Opacity(
          opacity: _unit(
            lerpDouble(animation.startOpacity, animation.endOpacity, t)!,
          ),
          child: Transform.translate(
            offset: Offset.lerp(animation.startOffset, animation.endOffset, t)!,
            child: Transform.scale(
              scale: math.max(
                0,
                lerpDouble(animation.startScale, animation.endScale, t)!,
              ),
              child: widget.logo,
            ),
          ),
        );
    return Positioned.fill(
      child: Padding(
        padding: widget.logoPadding,
        child: Align(alignment: widget.logoAlignment, child: child),
      ),
    );
  }

  List<Widget> _buildBubbles(double progress, Size size) {
    final motion = widget.motion;
    final style = widget.style;
    return _particles
        .map((particle) {
          final t = _unit((progress - particle.delay) / (1 - particle.delay));
          final position = Offset.lerp(
            particle.start,
            particle.end,
            motion.curve.transform(t),
          )!;
          final diameter =
              particle.diameter * (style.relativeSize ? size.shortestSide : 1);
          final scale = math.max(
            0.0,
            lerpDouble(
              motion.startScale,
              motion.endScale,
              motion.scaleCurve.transform(t),
            )!,
          );
          final fade = motion.fadeCurve.transform(
            _unit((t - motion.fadeStart) / (1 - motion.fadeStart)),
          );
          final opacity = _unit(lerpDouble(1, motion.endOpacity, fade)!);
          final center = Offset(
            position.dx * size.width,
            position.dy * size.height,
          );
          final frame = BubbleFrame(
            progress: t,
            scale: scale,
            opacity: opacity,
            center: center,
            diameter: diameter,
          );
          return Positioned(
            left: center.dx - diameter / 2,
            top: center.dy - diameter / 2,
            width: diameter,
            height: diameter,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child:
                    widget.bubbleBuilder?.call(context, particle, frame) ??
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: particle.color,
                        gradient: style.gradient,
                        shape: style.shape,
                        borderRadius: style.shape == BoxShape.rectangle
                            ? style.borderRadius
                            : null,
                        border: style.border,
                        boxShadow: style.shadows,
                      ),
                    ),
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
            throw FlutterError(
              'BubbleSplash needs bounded width and height. '
              'Place it in a Scaffold body, Expanded, or SizedBox.',
            );
          }
          final size = constraints.biggest;
          return ColoredBox(
            color: widget.backgroundColor,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _reduced ? 1.0 : _controller.value;
                final logo = _buildLogo(progress);
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: widget.clipBehavior,
                  children: [
                    if (widget.background != null) widget.background!,
                    if (!widget.logoOnTop) logo,
                    ..._buildBubbles(progress, size),
                    if (widget.logoOnTop) logo,
                    if (widget.foreground != null) widget.foreground!,
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _startTimer?.cancel();
    _completionTimer?.cancel();
    _releaseController(widget.controller == null);
    super.dispose();
  }
}
