import 'dart:ui' as ui;
import 'package:bubble_curtain_splash/bubble_curtain_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
  ),
);

void main() {
  testWidgets('painted logo grows rather than only fading at its final size', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: host(
          BubbleSplash(
            controller: controller,
            style: const BubbleStyle(count: 90),
            logoAnimation: const BubbleLogoAnimation(startOpacity: 0.8),
            logo: const SizedBox(
              width: 200,
              height: 200,
              child: ColoredBox(color: Color(0xFFFF0000)),
            ),
          ),
        ),
      ),
    );
    for (final progress in [1.0, 0.25, 0.5, 0.75, 1.0]) {
      controller.value = progress;
      await tester.pump();
      final paintedWidth = await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var left = image.width;
        var right = -1;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final i = (y * image.width + x) * 4;
            if (data.getUint8(i) > data.getUint8(i + 1) + 10 &&
                data.getUint8(i) > data.getUint8(i + 2) + 10) {
              if (x < left) left = x;
              if (x > right) right = x;
            }
          }
        }
        image.dispose();
        return right - left + 1;
      });
      expect(
        paintedWidth,
        closeTo(200 * progress, 2),
        reason: 'The visible logo must grow at progress $progress',
      );
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('logo grows from the center in sync with the bubble curtain', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester);
    final logoKey = GlobalKey();
    final splashKey = GlobalKey();
    double? bubbleProgress;
    await tester.pumpWidget(
      host(
        BubbleSplash(
          key: splashKey,
          controller: controller,
          logo: SizedBox(key: logoKey, width: 200, height: 200),
          style: const BubbleStyle(count: 1),
          bubbleBuilder: (_, _, frame) {
            bubbleProgress = frame.progress;
            return const SizedBox();
          },
        ),
      ),
    );
    final center = tester.getCenter(find.byKey(splashKey));
    for (final progress in [0.0, 0.05, 0.25, 0.5, 0.75, 1.0]) {
      controller.value = progress;
      await tester.pump();
      final bounds = tester.getRect(find.byKey(logoKey));
      expect(bounds.width, closeTo(200 * progress, 0.001));
      expect(bounds.height, closeTo(200 * progress, 0.001));
      expect(bounds.center.dx, closeTo(center.dx, 0.001));
      expect(bounds.center.dy, closeTo(center.dy, 0.001));
      expect(bubbleProgress, progress);
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('turning off reduced motion cancels a pending early completion', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester);
    var completed = 0;
    Widget splash(bool reduced) => host(
      BubbleSplash(
        controller: controller,
        logo: const Text('Logo'),
        holdDuration: const Duration(seconds: 1),
        onCompleted: () => completed++,
      ),
      reduced: reduced,
    );
    await tester.pumpWidget(splash(true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(splash(false));
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 0);
    controller.value = 1;
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
    'automatic reveal honors start delay, duration and hold exactly once',
    (tester) async {
      var completed = 0;
      final progress = <double>[];
      await tester.pumpWidget(
        host(
          BubbleSplash(
            logo: const Text('LUMA'),
            duration: const Duration(seconds: 1),
            startDelay: const Duration(milliseconds: 200),
            holdDuration: const Duration(milliseconds: 300),
            onProgress: progress.add,
            onCompleted: () => completed++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 199));
      expect(progress, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(progress.last, 1);
      expect(completed, 0);
      await tester.pump(const Duration(milliseconds: 299));
      expect(completed, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(completed, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(completed, 1);
    },
  );

  testWidgets('disposing cancels start and completion timers', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      host(
        BubbleSplash(
          logo: const Text('Logo'),
          startDelay: const Duration(seconds: 2),
          onCompleted: () => completed++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(completed, 0);
    expect(tester.takeException(), isNull);
    final controller = AnimationController(vsync: tester, value: 1);
    await tester.pumpWidget(
      host(
        BubbleSplash(
          controller: controller,
          logo: const Text('Logo'),
          onCompleted: () => completed++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 0);
    controller.dispose();
  });

  testWidgets('external seek, reverse and replay rearm completion', (
    tester,
  ) async {
    var completed = 0;
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      host(
        BubbleSplash(
          controller: controller,
          logo: const Text('Logo'),
          holdDuration: const Duration(milliseconds: 200),
          onCompleted: () => completed++,
        ),
      ),
    );
    controller.value = 1;
    await tester.pump(const Duration(milliseconds: 100));
    controller.reverse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(completed, 0);
    controller.value = 1;
    await tester.pump(const Duration(milliseconds: 200));
    expect(completed, 1);
    controller.value = 0;
    controller.value = 1;
    await tester.pump(const Duration(milliseconds: 200));
    expect(completed, 2);
    await tester.pumpWidget(const SizedBox());
    // The splash must never dispose the caller's controller.
    controller.value = 0.5;
    expect(controller.value, 0.5);
    controller.dispose();
  });

  testWidgets(
    'reduced motion reveals immediately without changing caller controller',
    (tester) async {
      var completed = 0;
      double? logoProgress;
      final controller = AnimationController(vsync: tester);
      await tester.pumpWidget(
        host(
          BubbleSplash(
            controller: controller,
            logo: const Text('Logo'),
            holdDuration: Duration.zero,
            logoBuilder: (_, progress, logo) {
              logoProgress = progress;
              return logo;
            },
            onCompleted: () => completed++,
          ),
          reduced: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(logoProgress, 1);
      expect(controller.value, 0);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets('seeded particles are stable and constrained to local layout', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester, value: 0.5);
    final frames = <BubbleFrame>[];
    final particles = <BubbleParticle>[];
    Widget splash() => host(
      BubbleSplash(
        controller: controller,
        seed: 7,
        logo: const Text('Logo'),
        style: const BubbleStyle(
          count: 6,
          minSize: 0.2,
          maxSize: 0.2,
          relativeSize: true,
        ),
        bubbleBuilder: (_, particle, frame) {
          particles.add(particle);
          frames.add(frame);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(splash());
    final first = particles.first;
    expect(frames.first.diameter, 80);
    await tester.pumpWidget(const SizedBox());
    particles.clear();
    frames.clear();
    await tester.pumpWidget(splash());
    expect(particles.first.start, first.start);
    expect(particles.first.end, first.end);
    expect(particles.first.color, first.color);
    expect(frames.first.scale, 0.5);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
    'custom paths, shape builders and logo builders receive progress',
    (tester) async {
      final controller = AnimationController(vsync: tester, value: 0.5);
      BubbleFrame? frame;
      double? logoProgress;
      await tester.pumpWidget(
        host(
          BubbleSplash(
            controller: controller,
            logo: const Text('CUSTOM'),
            style: const BubbleStyle(count: 1),
            particleFactory: (_, _, _) => const BubbleParticle(
              diameter: 50,
              color: Colors.red,
              start: Offset.zero,
              end: Offset(1, 1),
            ),
            bubbleBuilder: (_, _, f) {
              frame = f;
              return const Text('B');
            },
            logoBuilder: (_, p, logo) {
              logoProgress = p;
              return logo;
            },
          ),
        ),
      );
      expect(frame!.center, const Offset(200, 300));
      expect(frame!.diameter, 50);
      expect(logoProgress, 0.5);
      expect(find.text('CUSTOM'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets('controller ownership can change repeatedly', (tester) async {
    final external = AnimationController(vsync: tester, value: 0.25);
    await tester.pumpWidget(
      host(const BubbleSplash(logo: Text('Logo'), autoStart: false)),
    );
    await tester.pumpWidget(
      host(BubbleSplash(logo: const Text('Logo'), controller: external)),
    );
    await tester.pumpWidget(
      host(const BubbleSplash(logo: Text('Logo'), autoStart: false)),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    external.value = 0.5;
    external.dispose();
  });

  testWidgets('zero bubbles and overshooting curves render safely', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester, value: 0.7);
    await tester.pumpWidget(
      host(
        BubbleSplash(
          controller: controller,
          logo: const Text('Logo'),
          style: const BubbleStyle(count: 0),
          logoAnimation: const BubbleLogoAnimation(curve: Curves.elasticOut),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(
        BubbleSplash(
          controller: controller,
          logo: const Text('Logo'),
          style: const BubbleStyle(count: 4, shape: BoxShape.rectangle),
          motion: const BubbleMotion(
            scaleCurve: Curves.elasticOut,
            fadeCurve: Curves.elasticOut,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('all directional curtains move toward their named edge', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester, value: 1);
    for (final direction in BubbleDirection.values.where(
      (d) => d != BubbleDirection.scattered,
    )) {
      final particles = <BubbleParticle>[];
      await tester.pumpWidget(
        host(
          BubbleSplash(
            controller: controller,
            logo: const Text('Logo'),
            seed: 42,
            style: const BubbleStyle(count: 4),
            motion: BubbleMotion(direction: direction),
            bubbleBuilder: (_, particle, _) {
              particles.add(particle);
              return const SizedBox();
            },
          ),
        ),
      );
      for (final p in particles) {
        switch (direction) {
          case BubbleDirection.left:
            expect(p.end.dx, lessThan(p.start.dx));
          case BubbleDirection.right:
            expect(p.end.dx, greaterThan(p.start.dx));
          case BubbleDirection.up:
            expect(p.end.dy, lessThan(p.start.dy));
          case BubbleDirection.down:
            expect(p.end.dy, greaterThan(p.start.dy));
          case BubbleDirection.horizontal:
            expect((p.end.dx - p.start.dx).sign, p.start.dx < 0.5 ? -1 : 1);
          case BubbleDirection.vertical:
            expect((p.end.dy - p.start.dy).sign, p.start.dy < 0.5 ? -1 : 1);
          case BubbleDirection.scattered:
            break;
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
