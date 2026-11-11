"""Draw the original LumenShift look-picker illustrations. Pillow is a build tool only."""
import argparse
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Sky, horizon, distant mountains, lit rock, near shore, deep water, sun.
PALETTES = {
    "neutral": ("60849b","e6d7a5","889a9b","c7c9ad","2b535b","487b82","fff4c7"),
    "ember": ("814d59","ffc079","ba7c66","ecaa72","573c42","985e58","ffe4a0"),
    "night": ("213356","67969e","4c6983","789796","152e46","34516e","cae5e5"),
    "portrait": ("a592a7","ffdbb7","ae96a0","e5b9aa","715d76","a9919c","fff0dc"),
    "sunflare": ("c87b54","ffe8a8","cb985d","ffcc7d","65534c","cb965c","fffbcf"),
    "bluehour": ("45426b","cd9eab","827a9e","ad9bb2","343955","635781","f9d9cc"),
}

def render(palette):
    from PIL import Image, ImageColor, ImageDraw
    sky, horizon, ridge, rock, shore, water, sun = [ImageColor.getrgb("#" + h) for h in palette]
    def mix(a, b, t):
        return tuple(round(v + (w - v) * t) for v, w in zip(a, b))
    image = Image.new("RGB", (256, 128))
    d = ImageDraw.Draw(image)
    for y in range(128):
        d.line((0,y,255,y), fill=mix(sky,horizon,min(1,y/88)))
    for radius in range(31, 7, -1):
        d.ellipse((176-radius,40-radius,176+radius,40+radius), fill=mix(mix(sky,horizon,.46),sun,(1-radius/32)**1.6))
    d.ellipse((168,32,184,48),fill=sun)
    d.polygon([(0,60),(22,55),(45,63),(77,40),(96,49),(112,34),(126,46),(144,54),(162,46),(195,62),(217,48),(255,60),(255,95),(0,95)],fill=ridge)
    d.polygon([(0,68),(21,74),(57,41),(70,51),(77,48),(110,78),(142,64),(166,73),(202,51),(219,65),(244,56),(255,65),(255,93),(0,93)],fill=mix(shore,rock,.58))
    d.polygon([(30,67),(57,41),(70,51),(77,48),(98,68),(78,56),(73,59),(62,49),(57,56),(53,54)],fill=rock)
    d.polygon([(182,69),(202,51),(219,65),(202,57),(200,62),(198,59)],fill=rock)
    for y in range(86,128):
        d.line((0,y,255,y),fill=mix(mix(water,horizon,.59),water,(y-86)/41))
    for i in range(10):
        y=88+3*i
        x=173+round(math.sin(i*2.1)*7)
        d.line((x-4-i,y,x+5+i,y), fill=mix(water,sun,.67-i*.035))
    d.polygon([(0,77),(21,79),(48,84),(79,88),(103,91),(72,94),(26,90),(0,91)],fill=shore)
    d.polygon([(256,78),(238,79),(222,82),(204,89),(181,93),(199,95),(239,92),(256,89)],fill=shore)
    d.polygon([(0,103),(27,98),(49,102),(74,116),(102,128),(0,128)],fill=mix(shore,(9,20,27),.35))
    def pine(x, y, h):
        color=mix(shore,(10,22,29),.35)
        d.line((x,y-h,x,y),fill=color,width=2)
        for part in (0,.19,.38):
            top=y-h+part*h
            d.polygon([(x,top),(x-h*(.13+part*.17),top+h*.44),(x+h*(.13+part*.17),top+h*.44)],fill=color)
    for args in ((9,91,39),(22,89,25),(46,87,13),(215,88,17),(238,86,30),(249,87,42),(12,109,27)):
        pine(*args)
    # Small hilltop observatory shares a silhouette across all six palettes.
    d.rectangle((122,67,129,78),fill=shore)
    d.polygon([(119,68),(125,58),(132,68)],fill=shore)
    d.line((125,55,125,60),fill=shore)
    d.rectangle((124,70,126,73),fill=sun)
    return image.resize((128,64),Image.Resampling.LANCZOS).convert("RGBA")

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--library-path")
    args=parser.parse_args()
    if args.library_path:
        sys.path.insert(0,args.library_path)
    manifest=ROOT/"assets/manifest.json"
    data=json.loads(manifest.read_text(encoding="utf-8"))
    for name,palette in PALETTES.items():
        image=render(palette)
        encoded=struct.pack("<BBBHHBHHHHBB",0,0,2,0,0,0,0,0,*image.size,32,40)+image.tobytes("raw","BGRA")
        key=f"Media/look-{name}.tga"
        (ROOT/"addon/LumenShift"/key).write_bytes(encoded)
        data["files"][key]=hashlib.sha256(encoded).hexdigest()
    if "tools/create_look_swatches.py" not in data["source_recipe"]:
        data["source_recipe"]+="; tools/create_look_swatches.py"
    manifest.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")

if __name__ == "__main__":
    main()
