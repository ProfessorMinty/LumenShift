"""Draw original stage pose pictograms. Pillow is used only to export the addon art."""
import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Neck, hips, head, two arms (elbow, hand), two legs (knee, foot).
POSES = {
    "stand": ((64,18),(63,35),(64,11),((54,28),(52,36)),((73,27),(75,35)),((58,45),(55,55)),((68,45),(71,55))),
    "sit": ((60,25),(58,40),(60,18),((66,32),(75,36)),((63,34),(72,38)),((75,40),(79,52)),((68,44),(73,54))),
    "kneel": ((63,20),(59,38),(63,13),((70,28),(75,32)),((65,31),(72,34)),((71,37),(74,52)),((55,50),(44,51))),
    "wave": ((63,19),(64,36),(62,11),((54,28),(53,36)),((75,22),(78,9)),((58,46),(55,55)),((69,46),(72,55))),
    "cast": ((59,21),(62,36),(58,14),((48,24),(42,16)),((69,24),(80,17)),((53,46),(46,53)),((72,44),(80,53))),
    "run": ((69,19),(60,33),(73,13),((78,27),(87,22)),((56,22),(49,31)),((73,33),(83,44)),((50,46),(38,44))),
}

def render(pose):
    from PIL import Image, ImageDraw
    image = Image.new("RGB",(256,128))
    d = ImageDraw.Draw(image)
    for y in range(128):
        t=y/127
        d.line((0,y,255,y),fill=(round(24+20*t),round(43+31*t),round(61+19*t)))
    def points(seq):
        return [(2*x,2*y) for x,y in seq]
    def limb(joints, color, width):
        d.line(points(joints),fill=color,width=width,joint="curve")
    neck,hip,head,arm1,arm2,leg1,leg2=pose
    d.ellipse((76,105,177,114),fill="#20343c")
    limb((hip,*leg1),"#8eafa9",9)
    limb((neck,*arm1),"#92b5b0",7)
    limb((hip,*leg2),"#d8ddcb",10)
    nx,ny=neck;hx,hy=hip
    d.polygon(points(((nx-6,ny),(nx+5,ny),(hx+4,hy),(hx-5,hy+1))),fill="#d6d1b6")
    d.polygon(points(((nx-6,ny+1),(nx+5,ny),(hx+4,hy-7),(hx-4,hy-3))),fill="#58c6b0")
    limb((neck,*arm2),"#f3ddb5",7)
    x,y=head;d.ellipse((2*x-8,2*y-10,2*x+8,2*y+9),fill="#f4e6c9")
    if pose==POSES["cast"]:
        d.ellipse((164,18,176,30),outline="#aaf2d7",width=2)
        d.line((167,24,173,24),fill="#f3fff1",width=2)
    return image.resize((128,64),Image.Resampling.LANCZOS).convert("RGBA")

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--library-path")
    args=parser.parse_args()
    if args.library_path:
        sys.path.insert(0,args.library_path)
    manifest=ROOT/"assets/manifest.json"
    data=json.loads(manifest.read_text(encoding="utf-8"))
    for name,pose in POSES.items():
        image=render(pose)
        encoded=struct.pack("<BBBHHBHHHHBB",0,0,2,0,0,0,0,0,*image.size,32,40)+image.tobytes("raw","BGRA")
        key=f"Media/pose-{name}.tga"
        (ROOT/"addon/LumenShift"/key).write_bytes(encoded)
        data["files"][key]=hashlib.sha256(encoded).hexdigest()
    if "tools/create_pose_swatches.py" not in data["source_recipe"]:
        data["source_recipe"]+="; tools/create_pose_swatches.py"
    manifest.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")

if __name__=="__main__":
    main()
