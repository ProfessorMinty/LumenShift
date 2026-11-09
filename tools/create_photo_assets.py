"""Original analytic photo textures. MIT recipe; creative outputs ASSET-LICENSE.md.
No reference artwork or image editing. Deterministic, uncompressed 32-bit TGA.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'addon/LumenShift/Media'

def tga(name, size, pixels):
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 40)
    path = MEDIA / name
    path.write_bytes(header + pixels)
    return 'Media/' + name, hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    manifest = ROOT / 'assets/manifest.json'
    data = json.loads(manifest.read_text(encoding='utf-8'))
    for i in range(11):
        feather = max(.01, i / 10)
        for kind, size in (('vignette', 128), ('glow', 64)):
            pixels = bytearray()
            for y in range(size):
                for x in range(size):
                    radius = math.hypot((x + .5) * 2 / size - 1, (y + .5) * 2 / size - 1)
                    t = min(1, max(0, (radius - (1 - feather)) / feather))
                    alpha = round(255 * t * t * (3 - 2 * t))
                    pixels.extend((0, 0, 0, alpha) if kind == 'vignette' else (255, 255, 255, 255 - alpha))
            data['files'].update([tga(f'photo-{kind}-{i}.tga', size, pixels)])
    rng, grain = random.Random(20261109), bytearray()
    for _ in range(128 * 128):
        c = rng.randrange(256)
        grain.extend((c, c, c, 180))
    data['files'].update([tga('photo-grain.tga', 128, grain)])
    if 'tools/create_photo_assets.py' not in data['source_recipe']:
        data['source_recipe'] += '; tools/create_photo_assets.py'
    manifest.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

if __name__ == '__main__':
    main()
