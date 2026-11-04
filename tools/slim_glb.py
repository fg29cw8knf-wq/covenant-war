"""Slims one of Gary's Tripo3D props (one mesh, one material, its pictures
embedded) for the game, the way tools/split_glb.py does for AssetFurnace's:
the mesh decimated to about `tris` triangles keeping its texture seams
(pymeshlab's quadric edge collapse with texture: pip install pymeshlab, and
libopengl0 for its meshing plugin), the colour picture shrunk to `size` and the
metal-rough and normal maps to half that, each written beside the model as
<stem>_atlas.png, <stem>_mr.png and <stem>_normal.png with our import
settings (tools/rig_character.write_tex_import), and the model turned if asked
(--rot x:-90: a thing Tripo made standing up in Y laid along Z, face up).
Tripo's baby bundle (4 November) came as 1.95 million triangles and an 8192
picture, 67 MB; it went in at 30,000 triangles and 2048, under 3 MB.
  python3 tools/slim_glb.py in.glb assets/models/ashford/<stem>.glb --tris 30000 --size 2048 [--rot x:-90]
"""
import argparse, io, json, struct, sys, os
import numpy as np
from PIL import Image
import pymeshlab
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import write_tex_import  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("out")
ap.add_argument("--tris", type=int, default=24000)
ap.add_argument("--size", type=int, default=2048)
ap.add_argument("--rot", default="", help="axis:degrees, e.g. x:-90 (applied to positions and normals)")
a = ap.parse_args()

b = open(a.src, "rb").read()
magic, ver, length = struct.unpack("<III", b[:12]); off = 12; chunks = []
while off < length:
    cl, ct = struct.unpack("<II", b[off:off+8]); chunks.append((ct, b[off+8:off+8+cl])); off += 8+cl
j = json.loads(chunks[0][1]); binc = chunks[1][1]
def acc(i):
    ac = j["accessors"][i]; v = j["bufferViews"][ac["bufferView"]]
    n = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4}[ac["type"]]
    dt = {5126:np.float32,5123:np.uint16,5125:np.uint32,5121:np.uint8}[ac["componentType"]]
    start = v["byteOffset"] + ac.get("byteOffset", 0)
    arr = np.frombuffer(binc, dt, count=ac["count"]*n, offset=start).reshape(ac["count"], n)
    return arr.astype(np.float32) if dt == np.float32 else arr.astype(np.uint32)
prim = j["meshes"][0]["primitives"][0]
P = acc(prim["attributes"]["POSITION"]); UV = acc(prim["attributes"]["TEXCOORD_0"]); F = acc(prim["indices"]).reshape(-1, 3)
print("in:", len(P), "verts", len(F), "tris")

# decimate with UVs as wedge texcoords (pymeshlab keeps seams)
m = pymeshlab.Mesh(vertex_matrix=P.astype(np.float64), face_matrix=F.astype(np.int32),
                   v_tex_coords_matrix=UV.astype(np.float64))
ms = pymeshlab.MeshSet(); ms.add_mesh(m, "prop")
ms.apply_filter("compute_texcoord_transfer_vertex_to_wedge")
ms.apply_filter("meshing_decimation_quadric_edge_collapse_with_texture", targetfacenum=a.tris,
                qualitythr=1.0, extratcoordw=1.0, preserveboundary=False, optimalplacement=True, preservenormal=True, planarquadric=True)
ms.apply_filter("compute_texcoord_transfer_wedge_to_vertex")
ms.apply_filter("compute_normal_per_vertex")
mm = ms.current_mesh()
P2 = mm.vertex_matrix().astype(np.float32); F2 = mm.face_matrix().astype(np.uint32)
UV2 = mm.vertex_tex_coord_matrix().astype(np.float32); N2 = mm.vertex_normal_matrix().astype(np.float32)
print("out:", len(P2), "verts", len(F2), "tris")

if a.rot:
    ax, deg = a.rot.split(":"); t = np.radians(float(deg)); c, s = np.cos(t), np.sin(t)
    R = {"x": np.array([[1,0,0],[0,c,-s],[0,s,c]]), "y": np.array([[c,0,s],[0,1,0],[-s,0,c]]), "z": np.array([[c,-s,0],[s,c,0],[0,0,1]])}[ax].astype(np.float32)
    P2 = P2 @ R.T; N2 = N2 @ R.T
lo, hi = P2.min(0), P2.max(0); print("bounds", np.round(lo, 3), np.round(hi, 3), "size", np.round(hi - lo, 3))

# pictures, beside the model
stem = os.path.basename(a.out)[:-4]
out_dir = os.path.dirname(os.path.abspath(a.out))
imgs = []
for im in j["images"]:
    v = j["bufferViews"][im["bufferView"]]; d = binc[v["byteOffset"]:v["byteOffset"]+v["byteLength"]]
    img = Image.open(io.BytesIO(d)); nm = im.get("name", "")
    kind = "normal" if "normal" in nm else ("mr" if "_rm" in nm or "metallic" in nm else "atlas")
    sz = a.size if kind == "atlas" else a.size // 2
    if img.width > sz: img = img.resize((sz, sz), Image.LANCZOS)
    png = "%s_%s.png" % (stem, kind)
    img.convert("RGB").save(os.path.join(out_dir, png), "PNG", optimize=True)
    write_tex_import(os.path.join(out_dir, png), normal=(kind == "normal"))
    imgs.append((kind, png)); print(" picture", png, img.size, os.path.getsize(os.path.join(out_dir, png)) // 1024, "KB")

# write GLB
out_bin = bytearray(); views = []; accessors = []
def add(data, target=None):
    while len(out_bin) % 4: out_bin.append(0)
    views.append({"buffer": 0, "byteOffset": len(out_bin), "byteLength": len(data), **({"target": target} if target else {})})
    out_bin.extend(data); return len(views) - 1
def addacc(arr, typ, ctype, target, minmax=False):
    v = add(arr.tobytes(), target)
    d = {"bufferView": v, "componentType": ctype, "count": len(arr), "type": typ}
    if minmax: d["min"] = arr.min(0).tolist(); d["max"] = arr.max(0).tolist()
    accessors.append(d); return len(accessors) - 1
ip = addacc(P2, "VEC3", 5126, 34962, True); inn = addacc(N2, "VEC3", 5126, 34962); iuv = addacc(UV2, "VEC2", 5126, 34962)
iidx = addacc(F2.reshape(-1), "SCALAR", 5125, 34963)
images = []; textures = []
for kind, png in imgs:
    images.append({"name": kind, "uri": png}); textures.append({"source": len(images) - 1, "sampler": 0})
mat = json.loads(json.dumps(j["materials"][0]))
# keep the material's texture slots, pointing at our textures in the same order as the images
oldtex = j.get("textures", [])
def remap(slot):
    if slot and "index" in slot:
        slot["index"] = oldtex[slot["index"]]["source"]
remap(mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")); remap(mat.get("pbrMetallicRoughness", {}).get("metallicRoughnessTexture")); remap(mat.get("normalTexture"))
g = {"asset": {"version": "2.0", "generator": "Tripo, slimmed by tools/slim_glb.py"},
     "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": stem, "mesh": 0}],
     "meshes": [{"name": stem, "primitives": [{"attributes": {"POSITION": ip, "NORMAL": inn, "TEXCOORD_0": iuv}, "indices": iidx, "material": 0}]}],
     "materials": [mat], "textures": textures, "images": images, "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}],
     "bufferViews": views, "accessors": accessors, "buffers": [{"byteLength": len(out_bin)}]}
while len(out_bin) % 4: out_bin.append(0)
js = json.dumps(g, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
tot = 12 + 8 + len(js) + 8 + len(out_bin)
with open(a.out, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, tot)); f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack("<II", len(out_bin), 0x004E4942)); f.write(out_bin)
print("wrote", a.out, os.path.getsize(a.out) // 1024, "KB")
