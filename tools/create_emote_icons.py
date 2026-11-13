"""Draw the additional World Photo emotes in the original Portrait Stage style."""
import argparse
import hashlib
import json
import struct
import sys

from create_pose_swatches import ROOT, render

# The stage illustrator takes neck, hips, head, then two arms and two legs.
EMOTES = {
    "bow": ((71,27),(57,35),(77,24),((63,31),(60,32)),((69,36),(65,39)),((58,46),(54,55)),((64,46),(67,55))),
    "cheer": ((63,18),(63,35),(63,12),((52,13),(48,6)),((75,14),(80,6)),((58,44),(52,54)),((68,45),(74,54))),
    "dance": ((59,19),(66,34),(58,12),((49,13),(52,6)),((71,25),(80,22)),((55,38),(49,33)),((68,46),(70,55))),
    "flex": ((63,19),(63,35),(63,12),((50,22),(50,12)),((77,21),(77,11)),((59,45),(55,55)),((68,44),(71,55))),
    "laugh": ((58,21),(64,36),(55,14),((53,30),(61,34)),((69,28),(62,32)),((57,45),(55,55)),((71,44),(72,54))),
    "point": ((63,20),(62,35),(64,13),((54,28),(55,37)),((74,20),(85,17)),((56,45),(55,55)),((68,45),(71,55))),
    "read": ((61,20),(61,36),(64,13),((61,31),(69,27)),((70,32),(77,26)),((56,46),(55,55)),((65,46),(67,55))),
    "salute": ((62,19),(63,36),(62,12),((54,29),(54,37)),((75,19),(66,10)),((59,46),(60,55)),((66,46),(67,55))),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library-path")
    args = parser.parse_args()
    if args.library_path:
        sys.path.insert(0, args.library_path)
    from PIL import Image, ImageDraw

    manifest = ROOT / "assets/manifest.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    for name, pose in EMOTES.items():
        image = render(pose)
        if name == "read":
            pen = ImageDraw.Draw(image)
            pen.polygon([(65,21),(70,23),(70,29),(65,26)], fill="#f7db99")
            pen.polygon([(70,23),(77,20),(77,25),(70,29)], fill="#d2b273")
        image = image.crop((40,0,88,64)).resize((16,32), Image.Resampling.LANCZOS)
        header = struct.pack("<BBBHHBHHHHBB", 0,0,2,0,0,0,0,0,*image.size,32,40)
        encoded = header + image.tobytes("raw","BGRA")
        key = f"Media/emote-{name}.tga"
        (ROOT / "addon/LumenShift" / key).write_bytes(encoded)
        data["files"][key] = hashlib.sha256(encoded).hexdigest()
    recipe = "tools/create_emote_icons.py"
    if recipe not in data["source_recipe"]:
        data["source_recipe"] += "; " + recipe
    manifest.write_text(json.dumps(data, indent=2)+"\n", encoding="utf-8")


if __name__ == "__main__":
    main()
