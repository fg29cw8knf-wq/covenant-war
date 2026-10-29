"""Gives a rigged character the normal map its maker's model came with.

Gary's Tripo3D models come with a normal map (the fine shape painted into the
light: Player A's nostrils, the bridge of his nose, his eyelids, the folds in
his shirt), and rig_character.py leaves it out unless asked (AssetFurnace's
split faces in two). This takes it from the maker's own file (embedded) or an
image, and puts it beside the game's model as <stem>_normal.png, imported as a
normal map; Figure3D.dress_normal_map then dresses the model in
assets/shaders/character_nm.gdshader, which reads it without the mesh's
tangents (on the phone link's renderer a rigged model's tangents come out of
Godot's skinning mangled, and the normal map lit him in patches).

    python3 tools/add_normal_map.py assets/models/characters/<id>.glb <maker's.glb | normal.png> [--size 2048]

29 October (Gary: Player A's "face still look weird around the nose area",
then "take the original of that model and put the old head on it"): Player
A's, from his "New Player a.glb" of 25 October. tests/nm_check.gd compares the
shader with StandardMaterial3D on the unskinned mesh.
"""
import argparse, io, json, os, struct, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import write_tex_import  # noqa: E402


def normal_of(path):
    if not path.lower().endswith(".glb"):
        return Image.open(path).convert("RGB")
    d = open(path, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    b = d[off + 8:off + 8 + bl]
    for m in j.get("materials", []):
        if "normalTexture" in m:
            im = j["images"][j["textures"][m["normalTexture"]["index"]]["source"]]
            v = j["bufferViews"][im["bufferView"]]
            return Image.open(io.BytesIO(b[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]])).convert("RGB")
    sys.exit("%s has no normal map" % path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("source")
    ap.add_argument("--size", type=int, default=2048)
    a = ap.parse_args()
    img = normal_of(a.source)
    if img.width > a.size:
        img = img.resize((a.size, a.size), Image.LANCZOS)
    out = a.model[:-4] + "_normal.png"
    img.save(out)
    write_tex_import(out, True)
    print("%s: %dx%d" % (out, img.width, img.height))


if __name__ == "__main__":
    main()
