# Old village well

A round well built from three courses of fitted grey stone and a wider worn
coping rim. Two wooden posts support a small pitched roof of overlapping wooden
shingles. The wooden winch has a crank arm and grip, an eight-turn hemp rope
coil, and a suspension rope tied to the handle of an open wooden bucket.
The timber, stone, iron and rope have a muted painted finish for a fantasy
village environment.

The asset has **6,100 triangles**, one combined mesh assembled from individually
closed stone, timber, rope and bucket parts, consistent outward winding, one
material, and one **2048 × 2048 RGB colour atlas**. The opening is hollow and the
bucket hangs above it. There is no ground plane, scenery, lettering or people.

| File | Purpose |
| --- | --- |
| `village_well.glb` | Main 3D asset with the colour atlas embedded |
| `village_well.obj` and `village_well.mtl` | Editable mesh and material reference |
| `village_well_colour_2048.png` | Single colour atlas |
| `build_village_well.py` | Complete mesh, texture and export generator |
| `village_well_preview.png`, `village_well_front.png`, `village_well_detail.png` | Renders of the actual model |
| `mesh_validation.json` | Geometry counts, bounds and closed-mesh validation results |

Units are metres. The stone wall is about 1.07 m high. Its opening is about
1.16 m across. Overall dimensions including the roof and crank are approximately
2.67 m wide × 2.13 m deep × 3.19 m high. The origin is at the centre of the well
base and the bottom is at ground level.

The GLB is Y-up with the front facing +Z; the crank is on the right. The OBJ is
Z-up with the front facing -Y. Keep the OBJ, MTL and colour PNG together during
import. Both exports retain the individual closed assembly parts in one mesh,
which can be separated by loose parts in a modelling application.

The atlas is an sRGB base-colour texture. The material uses metallic factor 0
and roughness 0.94. No additional texture maps are needed.

To rebuild, use Python 3.12, install `requirements.txt`, and run
`python build_village_well.py`. Optional preview rendering uses VTK 9.5 or newer
with OpenGL/EGL support. The generator uses a fixed random seed.

The standard ZIP contains one `village_well` folder. Every file has been
extracted and compared byte-for-byte with its original.
