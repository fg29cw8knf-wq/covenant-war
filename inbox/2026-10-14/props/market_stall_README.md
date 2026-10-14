# Village festival market stall

A sturdy outdoor market stall of weathered oak planks on four posts, with a
sloping red and cream canvas awning and a scalloped stitched front hem.
Two woven baskets contain twelve red apples and four golden bread loaves.
Three plain cork-stoppered glass jars contain amber honey. A small iron lantern
with clear panes and an unlit candle hangs from the front right corner post.
There is no lettering, ground plane, scenery or people.

The asset contains **8,038 triangles**, one combined mesh assembled from
**121 individually closed parts**, outward consistent winding, and one
**2048 × 2048 RGBA colour atlas**. The painted wood, canvas, wicker, produce,
iron and glass all use that atlas. Two materials share the same image: opaque
surfaces and transparent glass. The glass is kept in separate primitives for
transparency sorting; the complete stall is one scene node and one mesh.
Internal overlaps at structural joins are retained as a normal prop assembly.

| File | Purpose |
| --- | --- |
| `market_stall.glb` | Main asset with the single colour atlas embedded |
| `market_stall.obj`, `market_stall.mtl` | Mesh and material references for other importers |
| `market_stall_colour_2048.png` | Single sRGB colour atlas, including glass alpha |
| `build_market_stall.py` | Complete editable geometry, texture and export generator |
| `market_stall_preview.png`, `market_stall_front.png`, `market_stall_detail.png` | Renders of the actual model |
| `mesh_validation.json` | Counts, closed-part checks, and export round-trip validation |
| `requirements.txt` | Dependencies for rebuilding the asset |

Units are metres. Overall dimensions are approximately **3.56 m wide × 2.05 m
deep × 2.89 m high**. The counter top is approximately 1.07 m above ground.
The origin is at the centre of the four-post footprint, with the base at zero.
GLB uses Y-up with its front facing +Z. OBJ uses Z-up with its front facing -Y.
Keep the OBJ, MTL and PNG together when importing. GLB is the recommended
format for retaining transparent glass without extra setup.

The opaque material has metallic factor 0 and roughness 0.91. The clear-glass
material uses alpha blending, metallic factor 0 and roughness 0.16. Both use
only the supplied base-colour atlas; no normal, roughness or metallic maps are
required. For OBJ importers that ignore `map_d -imfchan a`, assign the atlas
alpha channel to the glass material's opacity input.

To rebuild with Python 3.12, install `requirements.txt`, then run
`python build_market_stall.py`. The generator uses a fixed random seed.
Preview rendering is optional and requires VTK 9.5 or newer with OpenGL/EGL.
Closed assembly parts can be separated by loose parts in a modelling program.

The standard ZIP contains one `market_stall` folder. Its contents have been
extracted and compared byte-for-byte with the original files.
