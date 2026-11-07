"""Export a small, attributed set of owner-supplied UI assets. Build-time only.

Install Pillow 13.0.0 and resvg-py 0.5.0 outside the addon. Pass --library-path
if using an isolated install. Never copy the source packs into the repository.
"""
import argparse
import hashlib
import io
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'addon/LumenShift/Media'
ICONS = {
    'ui-modes': ('line', 'Visible'),
    'ui-quality': ('line', 'Landscape Setting'),
    'ui-camera': ('line', 'Camera 1'),
    'ui-effects': ('line', 'Color Palette'),
    'ui-audio': ('line', 'Volume Level High'),
    'ui-presets': ('line', 'Layers 1'),
    'ui-accessibility': ('line', 'User Circle Single'),
    'ui-diagnostics': ('line', 'Wave Signal'),
    'ui-advanced': ('line', 'Vertical Slider Square'),
    'ui-settings': ('line', 'Cog'),
    'ui-close': ('solid', 'Delete 1'),
    'ui-export': ('line', 'Download File'),
}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def tga(image, path):
    image = image.convert('RGBA')
    w, h = image.size
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    path.write_bytes(header + image.tobytes('raw', 'BGRA'))

def sector(index, fill, stroke):
    center = -90 + index * 60
    def point(radius, angle):
        r = math.radians(angle)
        return f'{128 + radius * math.cos(r):.4f},{128 + radius * math.sin(r):.4f}'
    a, b = center - 28, center + 28
    path = f'M {point(124,a)} A 124 124 0 0 1 {point(124,b)} L {point(64,b)} A 64 64 0 0 0 {point(64,a)} Z'
    return f'<path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="0.7"/>'

def svg(body, width=256, height=256):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-dir', type=Path, required=True)
    parser.add_argument('--library-path', type=Path)
    args = parser.parse_args()
    if args.library_path: sys.path.insert(0, str(args.library_path.resolve()))
    from PIL import Image, ImageOps
    import resvg_py
    source = args.source_dir.resolve()
    records = []
    def record(path, output, creator, license_name, license_url, changes):
        records.append(dict(file=output, source=path.relative_to(source).as_posix(), source_sha256=digest(path.read_bytes()),
                            creator=creator, license=license_name, license_url=license_url, changes=changes))
    for name, (style, title) in ICONS.items():
        matches = list((source / 'Core_Essential_UI_Icons' / f'core-{style}-free').rglob(title + '--*.svg'))
        assert len(matches) == 1, (title, len(matches))
        path = matches[0]
        # SVG-native color substitution; preserve the paths and embedded attribution.
        markup = path.read_text(encoding='utf-8').replace('#000000', '#ffffff').replace('currentColor', '#ffffff')
        raster = Image.open(io.BytesIO(resvg_py.svg_to_bytes(svg_string=markup, width=56, height=56)))
        out = Image.new('RGBA', (64, 64)); out.paste(raster, (4, 4))
        filename = name + '.tga'; tga(out, MEDIA / filename)
        record(path, 'Media/' + filename, 'Streamline', 'CC BY 4.0', 'https://creativecommons.org/licenses/by/4.0/',
               'Original paths recolored white, padded and rasterized to 64x64. Runtime applies silver/teal tint.')
    for name, path in {
        'panel-steel': source / 'Steel Mesh Gradient Background.png',
        'panel-midnight': source / 'Midnight Mesh Gradient.png',
        'light-sweep': source / 'lumenloops_v1/Package/Accents/png/1x/teal/6.png',
        'light-halo': source / 'lumenloops_v1/Package/Accents/png/1x/teal/8.png',
    }.items():
        with Image.open(path) as image:
            raster = ImageOps.contain(image.convert('RGBA'), (512, 512), Image.Resampling.LANCZOS)
            out = Image.new('RGBA', (512, 512)); out.paste(raster, ((512-raster.width)//2, (512-raster.height)//2))
        filename = name + '.tga'; tga(out, MEDIA / filename)
        record(path, 'Media/' + filename, 'Jon Lehman' if name.startswith('light') else 'Craftwork Studio',
               'Craftwork Commercial License', 'https://craftwork.design/license',
               'Aspect-preserving 512x512 runtime texture export. Composition, cropping and opacity are applied by the addon UI.')
    original = {
        'wheel-base': svg('<circle cx="128" cy="128" r="126" fill="#10181e" fill-opacity=".97" stroke="#526571"/>'
                          + ''.join(sector(i, '#1d2a32', '#3e525c') for i in range(6))
                          + '<circle cx="128" cy="128" r="58" fill="#10191f" stroke="#49616b" stroke-width=".7"/>'),
        'switch-track': svg('<rect x="1" y="1" width="126" height="62" rx="31" fill="white"/>', 128, 64),
        'switch-knob': svg('<circle cx="16" cy="16" r="15" fill="white"/>', 32, 32),
    }
    original.update({f'wheel-sector-{i+1}': svg(sector(i, '#17443f', '#65d9c3')) for i in range(6)})
    for name, markup in original.items():
        out = Image.open(io.BytesIO(resvg_py.svg_to_bytes(svg_string=markup)))
        tga(out, MEDIA / (name + '.tga'))
    ledger = dict(observed='2026-11-07', source_packs_not_distributed=True, third_party=records,
                  original_ui_geometry=[f'Media/{name}.tga' for name in original],
                  tools={'Pillow': Image.__version__, 'resvg-py': '0.5.0'},
                  missing_requested_pack='Fractal Haze was not present in the supplied directory.')
    (ROOT / 'assets/theme-sources.json').write_text(json.dumps(ledger, indent=2) + '\n', encoding='utf-8')
    path = ROOT / 'assets/manifest.json'
    manifest = json.loads(path.read_text(encoding='utf-8'))
    manifest['creator'] = 'Northern Lights Labs and credited third-party creators; see THIRD-PARTY-NOTICES.md'
    manifest['license'] = 'Mixed: ASSET-LICENSE.md and THIRD-PARTY-NOTICES.md; per-file sources in theme-sources.json'
    manifest['source_recipe'] = 'tools/create_assets.py; tools/export_logo.ps1; tools/export_theme.py'
    manifest['borrowed_media'] = 'assets/theme-sources.json'
    manifest['files'] = {p.relative_to(MEDIA.parent).as_posix(): digest(p.read_bytes()) for p in sorted(MEDIA.iterdir()) if p.is_file()}
    path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Exported {len(records)} third-party runtime textures and {len(original)} original UI shapes.')
    print(f'Total media: {sum(p.stat().st_size for p in MEDIA.iterdir() if p.is_file()):,} bytes. Source packs were not copied.')

if __name__ == '__main__': main()
