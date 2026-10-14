# Blazehound — animated 3D creature

Import `blazehound.glb`. It contains the mesh, one 4096 × 4096 RGBA colour texture, emissive material settings, a custom quadruped skeleton and seven animations. Open `blazehound_preview.html` in a browser to rotate the actual model, inspect its neutral stance, play or scrub each clip and download the identical GLB. The viewer works offline.

The model is fitted to the original Blazehound card and creature paintings included in this pack. It retains Cinderpup's charcoal coat, orange-gold markings and cream muzzle and chest, with an adult body, longer legs, narrower face, long muzzle, pointed ears and open jaws. The neck and shoulders have a broad collar of emissive flames. The tail has a long trailing flame plume, and the ear tips carry smaller flames.

| Property | Delivered value |
| --- | --- |
| Animated model triangles | 23,616 |
| Solid body and teeth triangles | 22,300 |
| Continuous body triangles | 21,148 |
| Flame and ember effect triangles | 1,316 |
| Skeleton | Custom quadruped, 25 joints, including a jaw joint |
| Colour texture | One 4096 × 4096 RGBA atlas, embedded and supplied separately |
| Materials | Four surface settings sharing the same texture |
| Flame effects | 32 curved, double-sided transparent ribbons with emission |
| Axes | +Y up, +Z forward |
| Neutral ground contact | All four paws at Y = 0 |
| Approximate solid height | 1.31 metres; scale to suit the game |
| Root movement | Run plays in place; attack lunges forward and returns |

## Animation clips

| Clip | Duration | Playback |
| --- | --- | --- |
| `idle` | 4.00 s | Loop, low ready stance and flame flicker |
| `run` | 1.00 s | Loop, in place |
| `attack` | 1.10 s | Once, forward lunge and jaw bite |
| `hit` | 0.65 s | Once, recoil |
| `defeat` | 1.60 s | Once, falls onto its side |
| `victory` | 2.00 s | Loop |
| `spawn` | 1.80 s | Once, appears and grows to full size |

Body penetration is corrected against the opaque skinned geometry at animation samples. Transparent flame geometry can extend below the body or through a floor during a fall; let the game floor occlude it. The flames use skinned ribbons, rather than a particle simulation. Emission values are embedded in the GLB; bloom and light cast onto the environment depend on the game engine. The viewer's display platform and lighting are separate from the model.

## Neutral exports and source

`blazehound_neutral.glb` and the welded `blazehound_neutral.obj`/MTL contain the solid body and enamel teeth in a symmetrical supported stance. They exclude the rig, transparent flame ribbons and floating embers. The body is one continuous closed surface; the twelve enamel details are individually closed meshes. The OBJ uses independent UV corner indices while preserving welded body vertices.

The `source/` folder contains the sculpt, adult proportion fit, UV/material baker, rig/exporter, viewer template, verification scripts and renderer. The atlas uses a generated material sheet matched to both original paintings, with a small contribution from the card's coat colours. The built-in image-generation prompt is in `source/card_material_prompt.txt`; the source sheet is `source/card_material_source.png`.

Rebuild with Python 3, NumPy, SciPy and Pillow:

```sh
python3 source/sculpt_blazehound.py
python3 source/texture_blazehound.py
python3 source/build_blazehound.py
python3 source/verify_model.py
node source/verify_viewer.cjs
python3 source/render_preview.py
python3 source/package_test_pack.py
```

The native renderer also requires EGL/OpenGL. The viewer check uses Node's built-in modules. All model previews render the exported GLB geometry and its animation; they are not generated depictions of a hypothetical 3D model.

## Validation and limits

The continuous body passes checks for connected topology, open edges, non-manifold edges, non-degenerate triangles and symmetry. Each enamel component is closed. Export checks cover GLB structure, normals, UVs, weights, inverse binds, seven named clips, embedded texture bytes and the neutral export. The viewer loader, controls and animation interpolation are checked separately, and the ZIP is checked for corruption and identical archived file bytes.

This is a reference-fitted reconstruction with an approximate likeness, built using the same custom creature workflow as Cinderpup. It is not an exact scan or a Meshy reconstruction. Game-engine import, material compatibility and animation blending remain untested.
