"""Export World Light control illustrations from LumenShift's original landscape."""
import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "addon/LumenShift/Media"


def render(source, adjustment):
    from PIL import Image, ImageChops, ImageEnhance, ImageFilter

    strip = Image.new("RGB", (128, 32))
    for index in range(4):
        if adjustment == "brightness":
            tile = ImageEnhance.Brightness(source).enhance((.39, .74, 1.12, 1.54)[index])
        elif adjustment == "contrast":
            tile = ImageEnhance.Contrast(source).enhance((.25, .72, 1.16, 1.8)[index])
        elif adjustment == "sharpness":
            detail = source.crop((0, 20, 64, 52))
            tile = detail.filter(ImageFilter.GaussianBlur((2.5, 1.2, .4, 0)[index]))
            if index == 3:
                tile = tile.filter(ImageFilter.UnsharpMask(radius=1, percent=150, threshold=2))
        else:
            sky = source.crop((58, 4, 122, 36))
            highlights = sky.convert("L").point(lambda v: max(0, v - 135) * 2)
            halo = highlights.filter(ImageFilter.GaussianBlur(4))
            glow = ImageChops.screen(sky, Image.merge("RGB", (halo, halo, halo)))
            tile = Image.blend(sky, glow, index / 3)
        strip.paste(tile.resize((32, 32), Image.Resampling.LANCZOS), (32 * index, 0))
    return strip.convert("RGBA")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library-path")
    args = parser.parse_args()
    if args.library_path:
        sys.path.insert(0, args.library_path)
    from PIL import Image

    with Image.open(MEDIA / "look-neutral.tga") as image:
        source = image.convert("RGB")
    path = ROOT / "assets/manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    for adjustment in ("brightness", "contrast", "sharpness", "bloom"):
        strip = render(source, adjustment)
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, *strip.size, 32, 40)
        data = header + strip.tobytes("raw", "BGRA")
        name = f"light-{adjustment}.tga"
        (MEDIA / name).write_bytes(data)
        manifest["files"]["Media/" + name] = hashlib.sha256(data).hexdigest()
    recipe = "tools/create_light_strips.py"
    if recipe not in manifest["source_recipe"]:
        manifest["source_recipe"] += "; " + recipe
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
