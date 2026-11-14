// Run from the package root: dart run tool/check_readme.dart
import 'dart:io';

Future<void> main() async {
  final root = Directory.current;
  final readme = File('README.md').readAsStringSync();
  final blocks = RegExp(
    r'```dart\r?\n([\s\S]*?)```',
  ).allMatches(readme).map((match) => match.group(1)!.trim()).toList();
  final definitions = <String>[];
  final expressions = <String>[];
  for (final block in blocks) {
    final code = block
        .replaceAll(RegExp(r"^import '[^']+';\s*", multiLine: true), '')
        .trim();
    if (code.isEmpty) continue;
    if (code.contains('class ')) {
      definitions.add(
        code.replaceFirst(
          RegExp(
            r'^void main\(\) => runApp\(const MaterialApp\(home: WelcomeSplash\(\)\)\);\s*',
          ),
          '',
        ),
      );
    } else {
      expressions.add(code);
    }
  }
  if (expressions.isEmpty || definitions.length != 2) {
    throw StateError('README layout changed; review its executable examples.');
  }
  final output = File('build/readme_examples/readme_examples_test.dart');
  output.parent.createSync(recursive: true);
  final test = StringBuffer(r'''
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_curtain_splash/bubble_curtain_splash.dart';

class _ReadmeAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{})!;
    }
    if (key == 'assets/brand_logo.png') {
      return ByteData.sublistView(File('doc/logo.png').readAsBytesSync());
    }
    return rootBundle.load(key);
  }
}
''');
  test.writeln(definitions.join('\n'));
  test.writeln('void main() {');
  final widgets = [
    ...expressions,
    'const WelcomeSplash()',
    'const ControlledSplash()',
  ];
  for (var i = 0; i < widgets.length; i++) {
    test.writeln('''
  testWidgets('README example ${i + 1}', (tester) async {
    final example = ${widgets[i]};
    await tester.pumpWidget(MaterialApp(
      home: DefaultAssetBundle(bundle: _ReadmeAssets(),
        child: Scaffold(body: example)),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
''');
  }
  test.writeln('}');
  output.writeAsStringSync(test.toString());
  stdout.writeln('Checking ${widgets.length} README examples...');
  final process = await Process.start(
    'flutter',
    ['test', '--no-pub', output.path],
    workingDirectory: root.path,
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
