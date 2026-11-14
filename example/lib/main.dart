import 'dart:math' as math;
import 'package:bubble_reveal_splash/bubble_reveal_splash.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BubbleRevealExample());

class BubbleRevealExample extends StatelessWidget {
  const BubbleRevealExample({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bubble Reveal Studio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007F7A)),
      scaffoldBackgroundColor: const Color(0xFFF6F7F4),
    ),
    home: const Playground(),
  );
}

const palettes = [
  Brand(
    'LUMA',
    'A little light. A fresh start.',
    Color(0xFF005F59),
    Color(0xFFF0FAF5),
    [
      Color(0xFF005F59),
      Color(0xFF00A68F),
      Color(0xFF6AD6B7),
      Color(0xFFBAF1DC),
    ],
  ),
  Brand(
    'SOL',
    'Make room for bright ideas.',
    Color(0xFFAE471F),
    Color(0xFFFFF7ED),
    [
      Color(0xFFC45B2D),
      Color(0xFFF49A57),
      Color(0xFFFFC184),
      Color(0xFFFFE0BA),
    ],
  ),
  Brand(
    'NOVA',
    'Something wonderful starts here.',
    Color(0xFF3348A0),
    Color(0xFFF3F5FF),
    [
      Color(0xFF3348A0),
      Color(0xFF637BDA),
      Color(0xFFA2B4FA),
      Color(0xFFD6DFFF),
    ],
  ),
];

class Brand {
  const Brand(this.name, this.tagline, this.ink, this.background, this.colors);
  final String name, tagline;
  final Color ink, background;
  final List<Color> colors;
}

/// Original vector branding; no assets or downloaded fonts are required.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.brand});
  final Brand brand;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${brand.name} logo',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(100, 100),
          painter: _MarkPainter(brand.ink),
        ),
        const SizedBox(height: 24),
        Text(
          brand.name,
          style: TextStyle(
            color: brand.ink,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          brand.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: brand.ink.withValues(alpha: 0.65),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(math.pi / 2 * i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, -42, 28, 39),
          const Radius.circular(18),
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 5, paint);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => color != oldDelegate.color;
}

class Playground extends StatefulWidget {
  const Playground({super.key});
  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  int palette = 0, count = 90, seed = 42;
  double seconds = 3, stagger = 0, bubbleSize = 0.65;
  bool behind = false, shadows = true, rounded = false;
  BubbleDirection direction = BubbleDirection.scattered;
  Brand get brand => palettes[palette];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.forward();
    });
  }

  void replay() {
    controller.duration = Duration(milliseconds: (seconds * 1000).round());
    controller.forward(from: 0);
  }

  void change(VoidCallback update) {
    setState(update);
    replay();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 40 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bubble_chart, color: brand.ink, size: 32),
                        const SizedBox(width: 10),
                        const Text(
                          'reveal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (constraints.maxWidth > 500)
                          const Text(
                            'FLUTTER / 0.1.0',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                          ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'A beautiful beginning.',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your logo. A curtain of bubbles. A moment worth watching.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF67756D),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _preview()),
                          const SizedBox(width: 30),
                          Expanded(flex: 5, child: _settings()),
                        ],
                      )
                    else ...[
                      _preview(),
                      const SizedBox(height: 24),
                      _settings(),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Built with Flutter. Zero third-party runtime dependencies.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF758078)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _preview() => Column(
    children: [
      Container(
        height: 510,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF203B32),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1600291C),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BubbleSplash(
            controller: controller,
            seed: seed,
            logo: BrandLogo(brand: brand),
            logoOnTop: !behind,
            backgroundColor: brand.background,
            style: BubbleStyle(
              count: count,
              colors: brand.colors,
              relativeSize: true,
              minSize: bubbleSize * 0.65,
              maxSize: bubbleSize,
              shape: rounded ? BoxShape.rectangle : BoxShape.circle,
              shadows: shadows
                  ? const [
                      BoxShadow(
                        color: Color(0x22003836),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            motion: BubbleMotion(direction: direction, maxDelay: stagger),
            logoAnimation: const BubbleLogoAnimation(
              startScale: 0,
              endScale: 1,
              curve: Curves.linear,
              startOpacity: 1,
            ),
            foreground: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '9:41',
                          style: TextStyle(
                            color: brand.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.signal_cellular_alt,
                          color: brand.ink,
                          size: 16,
                        ),
                        Icon(Icons.battery_full, color: brand.ink, size: 16),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'A FRESH PERSPECTIVE',
                      style: TextStyle(
                        color: brand.ink,
                        fontSize: 9,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 90,
                      height: 4,
                      decoration: BoxDecoration(
                        color: brand.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          children: [
            Slider(
              value: controller.value,
              onChanged: (v) {
                controller.stop();
                controller.value = v;
              },
              semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
            ),
            Row(
              children: [
                Text(
                  '${(controller.value * 100).round()}% revealed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF67756D),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: controller.isAnimating ? 'Pause' : 'Play',
                  onPressed: () => setState(() {
                    if (controller.isAnimating) {
                      controller.stop();
                    } else {
                      controller.forward(
                        from: controller.isCompleted ? 0 : controller.value,
                      );
                    }
                  }),
                  icon: Icon(
                    controller.isAnimating ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  tooltip: 'Reverse',
                  onPressed: () => controller.reverse(),
                  icon: const Icon(Icons.fast_rewind),
                ),
                IconButton(
                  tooltip: 'Replay',
                  onPressed: replay,
                  icon: const Icon(Icons.replay),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _settings() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE3E9E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Make it yours',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explore the animation, one detail at a time.',
          style: TextStyle(color: Color(0xFF67756D), fontSize: 12),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            palettes.length,
            (i) => ChoiceChip(
              selected: i == palette,
              label: Text(palettes[i].name),
              avatar: CircleAvatar(backgroundColor: palettes[i].ink, radius: 7),
              onSelected: (_) => change(() => palette = i),
            ),
          ),
        ),
        const SizedBox(height: 22),
        DropdownButtonFormField<BubbleDirection>(
          initialValue: direction,
          decoration: const InputDecoration(
            labelText: 'Curtain direction',
            border: OutlineInputBorder(),
          ),
          items: BubbleDirection.values
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d.name[0].toUpperCase() + d.name.substring(1)),
                ),
              )
              .toList(),
          onChanged: (v) => change(() => direction = v!),
        ),
        const SizedBox(height: 22),
        _slider(
          'Bubbles',
          '$count',
          count.toDouble(),
          10,
          150,
          14,
          (v) => change(() => count = v.round()),
        ),
        _slider(
          'Duration',
          '${seconds.toStringAsFixed(1)} s',
          seconds,
          0.5,
          6,
          11,
          (v) => change(() => seconds = v),
        ),
        _slider(
          'Bubble size',
          '${(bubbleSize * 100).round()}%',
          bubbleSize,
          0.2,
          1,
          16,
          (v) => change(() => bubbleSize = v),
        ),
        _slider(
          'Stagger',
          '${(stagger * 100).round()}%',
          stagger,
          0,
          0.7,
          7,
          (v) => change(() => stagger = v),
        ),
        const Divider(height: 24),
        _switch('Logo behind curtain', behind, (v) => change(() => behind = v)),
        _switch('Soft shadows', shadows, (v) => change(() => shadows = v)),
        _switch('Rounded squares', rounded, (v) => change(() => rounded = v)),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => change(() => seed++),
              icon: const Icon(Icons.shuffle, size: 16),
              label: const Text('Shuffle'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullScreenDemo(brand: brand),
                ),
              ),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: const Text('Full screen'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) => Column(
    children: [
      Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: brand.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      Slider(
        value: current,
        min: min,
        max: max,
        divisions: divisions,
        label: value,
        onChanged: onChanged,
      ),
    ],
  );
  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class FullScreenDemo extends StatefulWidget {
  const FullScreenDemo({super.key, required this.brand});
  final Brand brand;
  @override
  State<FullScreenDemo> createState() => _FullScreenDemoState();
}

class _FullScreenDemoState extends State<FullScreenDemo> {
  bool done = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: done
        ? ColoredBox(
            color: widget.brand.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandLogo(brand: widget.brand),
                  const SizedBox(height: 40),
                  const Text('Your next chapter starts here.'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to studio'),
                  ),
                ],
              ),
            ),
          )
        : BubbleSplash(
            logo: BrandLogo(brand: widget.brand),
            logoAnimation: const BubbleLogoAnimation(startOpacity: 1),
            seed: 42,
            backgroundColor: widget.brand.background,
            style: BubbleStyle(colors: widget.brand.colors),
            onCompleted: () => setState(() => done = true),
          ),
  );
}
