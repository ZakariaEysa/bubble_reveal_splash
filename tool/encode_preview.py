"""Encode the actual Flutter frames as a four-second looping GIF.

From the package root:
  flutter test tool/capture_preview.dart --dart-define=CAPTURE_ANIMATION=true
  python tool/encode_preview.py

Requires Pillow. Runtime package code does not depend on Python or Pillow.
"""
from pathlib import Path
from PIL import Image


def main():
    root = Path(__file__).resolve().parent.parent
    paths = [root / 'build' / 'preview_frames' / ('frame_%03d.png' % i)
             for i in range(91)]
    frames = []
    for path in paths:
        with Image.open(str(path)) as image:
            frames.append(image.convert('RGB'))

    # One palette across the whole animation keeps colors stable between frames.
    atlas = Image.new('RGB', (78 * 10, 136 * 10), '#F0FAF5')
    for i, frame in enumerate(frames):
        atlas.paste(frame.resize((78, 136), Image.LANCZOS),
                    ((i % 10) * 78, (i // 10) * 136))
    palette = atlas.quantize(colors=256, method=Image.MEDIANCUT)
    indexed = [frame.quantize(palette=palette, dither=Image.NONE)
               for frame in frames]
    output = root / 'doc' / 'bubbles_preview.gif'
    durations = [30, 30, 40] * 30 + [1000]
    indexed[0].save(str(output), save_all=True, append_images=indexed[1:],
                    duration=durations, loop=0, disposal=2, optimize=False)

    with Image.open(str(output)) as image:
        total_ms = 0
        for i in range(image.n_frames):
            image.seek(i)
            total_ms += image.info['duration']
        assert image.size == (390, 680)
        assert image.n_frames >= 80
        assert total_ms == 4000
        assert image.info['loop'] == 0
        print('%s | %s frames | %s ms | %s bytes' %
              (output, image.n_frames, total_ms, output.stat().st_size))


if __name__ == '__main__':
    main()
