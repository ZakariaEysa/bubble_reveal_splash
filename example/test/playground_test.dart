import 'package:bubble_reveal_splash_example/main.dart';
import 'package:bubble_reveal_splash/bubble_reveal_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;

void main() {
  testWidgets('LUMA branding visibly scales from tiny to full size', (
    tester,
  ) async {
    final controller = AnimationController(vsync: tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: BubbleSplash(
              controller: controller,
              backgroundColor: palettes.first.background,
              style: const BubbleStyle(count: 0),
              logo: BrandLogo(brand: palettes.first),
            ),
          ),
        ),
      ),
    );
    int? fullWidth;
    for (final progress in [1.0, 0.25, 0.5, 0.75, 1.0]) {
      controller.value = progress;
      await tester.pump();
      final width = await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var left = image.width, right = -1;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final i = (y * image.width + x) * 4;
            if (data.getUint8(i) < 230 &&
                data.getUint8(i + 1) < 245 &&
                data.getUint8(i + 2) < 240) {
              if (x < left) left = x;
              if (x > right) right = x;
            }
          }
        }
        image.dispose();
        return right - left + 1;
      });
      fullWidth ??= width;
      expect(width, closeTo(fullWidth! * progress, 5));
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final width in [360.0, 1280.0]) {
    testWidgets('playground fits and switches brand at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const BubbleRevealExample());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'SOL'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'SOL'));
      await tester.pumpAndSettle();
      expect(find.text('Make room for bright ideas.'), findsOneWidget);
      await tester.ensureVisible(find.text('Full screen'));
      await tester.tap(find.text('Full screen'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Your next chapter starts here.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
