// Run from the package root: flutter test tool/capture_preview.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bubble_reveal_splash/bubble_reveal_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/lib/main.dart';

void main() {
  testWidgets('capture reproducible branded previews', (tester) async {
    final packages =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map;
    final flutter = (packages['packages'] as List).cast<Map>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = Uri.directory(
      Uri.parse(flutter['rootUri'] as String).toFilePath(),
    ).resolve('../../');
    for (final weight in ['regular', 'bold', 'black']) {
      final loader = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File.fromUri(
                sdk.resolve(
                  'bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
                ),
              ).readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File.fromUri(
              sdk.resolve(
                'bin/cache/artifacts/material_fonts/materialicons-regular.otf',
              ),
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundary, child: const BubbleRevealExample()),
    );
    await tester.pumpAndSettle();
    Future<void> save(String name, {String directory = 'doc'}) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(directory).createSync(recursive: true);
        await File(
          '$directory/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await save('playground');
    // Detach the studio's retained layers before capturing the standalone splash.
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = const Size(390, 680);
    final controller = AnimationController(vsync: tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: BubbleSplash(
              controller: controller,
              seed: 42,
              logo: BrandLogo(brand: palettes.first),
              backgroundColor: palettes.first.background,
              style: BubbleStyle(colors: palettes.first.colors),
              logoAnimation: const BubbleLogoAnimation(
                startScale: 0,
                endScale: 1,
                curve: Curves.linear,
                startOpacity: 1,
              ),
            ),
          ),
        ),
      ),
    );
    for (final entry in {'curtain': 0.0, 'reveal': 0.5, 'logo': 1.0}.entries) {
      controller.value = entry.value;
      await tester.pump();
      await save(entry.key);
    }
    if (const bool.fromEnvironment('CAPTURE_ANIMATION')) {
      // Sample the real Flutter widget at 30 fps over its three-second reveal.
      for (var frame = 0; frame <= 90; frame++) {
        controller.value = frame / 90;
        await tester.pump();
        await save(
          'frame_${frame.toString().padLeft(3, '0')}',
          directory: 'build/preview_frames',
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
