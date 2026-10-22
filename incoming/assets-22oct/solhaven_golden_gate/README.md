# The Golden Gate of Solhaven

A grand standalone city gateway in painted fantasy style: two tall round limestone towers with fluted gold domes, a high central wall with a broad round arch, a protected wall walk and battlements, a raised gilded sunburst, and short battlemented white city walls extending from both sides. The main passage is empty and open all the way through, with no doors or ground plane.

## Model

- **31,408 triangles**, one connected watertight mesh with outward winding.
- **One 4096 × 4096 RGB colour atlas**, shared by two materials: white limestone and gold gilding.
- Approximately **24.04 m wide × 4.90 m deep × 16.24 m high**.
- Arch opening: **5.70 m wide**, vertical spring at **4.25 m**, crown at **7.10 m**.
- Central wall walk: **10.50 m above the ground**, with front and rear battlements.
- The sunburst has 24 carved rays around a convex solar disc. Narrow recessed arrow loops and stone mouldings detail the towers.
- Base and pivot at ground level, centred on the gateway. No scenery, people or text.

## Import

`golden_gate_solhaven.glb` embeds the mesh, shared PNG atlas and both materials. GLB uses Y up and faces +Z. This is the simplest single-file import.

`golden_gate_solhaven.obj` uses Z up and faces −Y. Keep its MTL and `golden_gate_solhaven_colour_4096.png` together. The OBJ contains two material groups belonging to the same gateway.

Both materials use the same colour texture as sRGB. Limestone uses metallic 0 and roughness 0.90; gilding uses metallic 0.68 and roughness 0.40. GLB preserves these values. OBJ material support varies by importer; set the gold material's metallic/roughness values manually if needed. No additional texture maps are required.

The four preview images show the actual model from the front, rear, at three-quarter angle and in detail. `mesh_validation.json` records the mesh, texture, export and passage-clearance checks.

## Rebuild

Install `requirements.txt`, then run `python build_golden_gate_solhaven.py`. This regenerates the deterministic mesh, atlas and exports. VTK with OpenGL/EGL is required only for the optional rendered previews.
