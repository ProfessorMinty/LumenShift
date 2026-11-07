"""Original LumenShift geometry and synthesis recipes. No borrowed media or dependencies.

Source tool: MIT. Creative output: ASSET-LICENSE.md. Re-run to reproduce the assets.
"""
import hashlib
import json
import math
import struct
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'addon/LumenShift/Media'
MASTERS = ROOT / 'assets'


def circle(x, y, cx, cy, radius):
    return (x - cx) ** 2 + (y - cy) ** 2 <= radius ** 2


def line(x, y, ax, ay, bx, by, width=0.035):
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return circle(x, y, ax + t * dx, ay + t * dy, width)


def ring(x, y, cx, cy, radius, width=0.03):
    d = math.hypot(x - cx, y - cy)
    return abs(d - radius) <= width


def icon(name, x, y):
    if name == 'natural':
        return ring(x, y, .5, .5, .19) or any(line(x, y, .5 + .29 * math.cos(a), .5 + .29 * math.sin(a),
            .5 + .38 * math.cos(a), .5 + .38 * math.sin(a), .025) for a in [i * math.pi / 4 for i in range(8)])
    if name == 'nightVision':
        return ring(x, y, .30, .53, .16) or ring(x, y, .70, .53, .16) or line(x, y, .46, .49, .54, .49) or line(x, y, .18, .27, .82, .27, .026) or line(x, y, .18, .27, .14, .5, .025) or line(x, y, .82, .27, .86, .5, .025)
    if name == 'cinematic':
        frame = .18 < x < .82 and .38 < y < .78 and (x < .22 or x > .78 or y < .42 or y > .74)
        top = line(x, y, .18, .30, .76, .15, .055)
        cut = any(line(x, y, a, .17, a + .10, .40, .018) for a in [.28, .46, .64])
        return frame or (top and not cut) or (.43 < x < .64 and abs(y - .57) < (.64 - x) * .65)
    if name == 'lantern':
        return ring(x, y, .5, .22, .09, .022) or line(x, y, .30, .36, .70, .36) or line(x, y, .25, .77, .75, .77) or line(x, y, .30, .36, .25, .77) or line(x, y, .70, .36, .75, .77) or circle(x, y, .5, .60, .10) or line(x, y, .50, .46, .50, .68, .025)
    if name == 'clarity':
        eye = abs((x - .5) / .38) ** 1.4 + abs((y - .5) / .23) ** 1.4
        return .84 < eye < 1.05 or ring(x, y, .5, .5, .10, .025) or line(x, y, .5, .13, .5, .22, .023) or line(x, y, .5, .78, .5, .87, .023)
    if name == 'moonlight':
        return (circle(x, y, .47, .51, .32) and not circle(x, y, .62, .39, .29)) or line(x, y, .76, .19, .76, .34, .018) or line(x, y, .69, .26, .83, .26, .018)
    if name == 'logo':
        crescent = circle(x, y, .48, .48, .36) and not circle(x, y, .61, .35, .33)
        aurora = .25 < x < .82 and abs(y - (.53 + .12 * math.sin(x * 9))) < .027
        ray = line(x, y, .70, .14, .70, .28, .018) or line(x, y, .63, .21, .77, .21, .018)
        return crescent or aurora or ray
    return False


COLORS = {'natural': (236, 231, 198), 'nightVision': (104, 238, 164), 'cinematic': (246, 200, 126),
          'lantern': (255, 170, 76), 'clarity': (174, 225, 246), 'moonlight': (153, 179, 255), 'logo': (104, 229, 206)}


def pixels(name, size):
    result = bytearray()
    color = COLORS[name]
    for y in range(size):
        for x in range(size):
            coverage = sum(icon(name, (x + (sx + .5) / 3) / size, (y + (sy + .5) / 3) / size)
                           for sx in range(3) for sy in range(3)) / 9
            result.extend((*color, round(255 * coverage)))
    return bytes(result)


def tga(path, data, size, height=None):
    height = height or size
    bgra = bytearray(len(data))
    for i in range(0, len(data), 4):
        r, g, b, a = data[i:i + 4]
        bgra[i:i + 4] = bytes((b, g, r, a))
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, height, 32, 0x28)
    path.write_bytes(header + bgra)


def png(path, data, width, height):
    def chunk(kind, contents):
        return struct.pack('>I', len(contents)) + kind + contents + struct.pack('>I', zlib.crc32(kind + contents) & 0xffffffff)
    rows = b''.join(b'\0' + data[y * width * 4:(y + 1) * width * 4] for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


def cue(path, direction, gain):
    rate, duration = 22050, .32
    samples = []
    phase = 0
    for index in range(round(rate * duration)):
        t = index / rate
        progress = t / duration
        frequency = (430 + 1100 * progress ** .7) if direction == 'on' else (1050 - 710 * progress)
        phase += 2 * math.pi * frequency / rate
        envelope = min(1, t / .012) * (1 - progress) ** 1.7
        tone = math.sin(phase) + .22 * math.sin(phase * 2) + .10 * math.sin(phase * 3)
        tick = math.sin(2 * math.pi * 2700 * t) * math.exp(-t * 130) * .15
        samples.append(round(32767 * gain * (tone * envelope + tick)))
    assert max(abs(n) for n in samples) < 32767
    with wave.open(str(path), 'wb') as stream:
        stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(rate)
        stream.writeframes(struct.pack('<' + 'h' * len(samples), *samples))


def main():
    MEDIA.mkdir(parents=True, exist_ok=True); MASTERS.mkdir(exist_ok=True)
    images = {}
    for name in COLORS:
        size = 256 if name == 'logo' else 128
        data = pixels(name, size); tga(MEDIA / (name + '.tga'), data, size)
        images[name] = (data, size)
    vignette = bytes(channel for y in range(64) for _ in range(64)
                     for channel in (0, 0, 0, round(255 * (1 - y / 63) ** 2)))
    tga(MEDIA / 'vignette.tga', vignette, 64)
    for direction in ('on', 'off'):
        for level, gain in (('soft', .13), ('normal', .25)):
            cue(MEDIA / f'night-{direction}-{level}.wav', direction, gain)
    preview = bytearray((9, 16, 24, 255) * (640 * 320))
    for index, (name, (data, size)) in enumerate(images.items()):
        for y in range(128):
            for x in range(128):
                source = ((y * size // 128) * size + x * size // 128) * 4
                r, g, b, a = data[source:source + 4]
                dest = ((index // 4 * 160 + 16 + y) * 640 + index % 4 * 160 + 16 + x) * 4
                preview[dest:dest + 4] = bytes((round(r * a / 255 + 9 * (1 - a / 255)),
                    round(g * a / 255 + 16 * (1 - a / 255)), round(b * a / 255 + 24 * (1 - a / 255)), 255))
    png(MASTERS / 'icon-review.png', bytes(preview), 640, 320)
    png(MASTERS / 'logo-400.png', pixels('logo', 400), 400, 400)
    manifest = {'creator': 'Northern Lights Labs; original project geometry and sound synthesis authored with Codex',
                'created': '2026-11-06', 'license': 'ASSET-LICENSE.md (All Rights Reserved)',
                'source_recipe': 'tools/create_assets.py', 'borrowed_media': False, 'files': {}}
    for path in sorted(MEDIA.iterdir()):
        manifest['files'][path.relative_to(MEDIA.parent).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    (MASTERS / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Created {len(manifest["files"])} original runtime assets and review sheet.')


if __name__ == '__main__':
    main()
