# Baking light here (18 November)

Godot bakes `LightmapGI` only in its editor, at a press of Bake
(`LightmapGI.bake()` isn't open to scripts), and only with a graphics card.
Both can be had here: the editor runs under xvfb on software Vulkan
(lavapipe), and `autobake/` is an editor plugin that, when `BAKE_SCENE` is
set, opens that scene, selects its LightmapGI, presses "Bake Lightmaps",
answers the "Select lightmap bake file" dialog with `<scene>.lmbake`, waits,
saves the scene and quits (exit 0 when there's light data).

Proved on a practice room (`practice_room.gd` builds it): 25 s at low
quality, 42 s at medium, on two cores. With the light's bake mode Dynamic
(the light itself live, its bounced light baked) the result is right:
shadows filled with soft bounced light, a red wall tinting the wall beside
it. With Static (the light baked too) the box's own shadow was missing:
use Dynamic.

To use it, copy `autobake/` into a project's `addons/`, enable it in
`project.godot` (`[editor_plugins] enabled=PackedStringArray("res://addons/autobake/plugin.cfg")`),
and run:

```sh
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json BAKE_SCENE=res://<scene>.tscn BAKE_WAIT=1800 \
    xvfb-run -a -s "-screen 0 1600x900x24" godot --editor --path <project> --rendering-driver vulkan
```

The scene needs every baked mesh with a second UV set (a glb imported with
`meshes/light_baking=2`, a primitive with `add_uv2`, an ArrayMesh through
`lightmap_unwrap`) and `gi_mode` static, and the LightmapGIData it makes
belongs to that scene's node paths.

**Why Ashford isn't baked (18 November):** its light changes as it's played:
the sun sets live through the festival day (`AshfordDay`, a tween of
`set_daylight` over `SUNSET_SECS`), then Lantern Night, the fires, the
Sigilfall's burning and dawn (`set_time`). Baked light is frozen at one
moment: Ashford would need six or more bakes, the sunset would jump between
them, and the village is built by code as it loads, so its fixed parts would
have to be saved as a scene to bake and swapped in at the right time. Put to
Gary as a choice. Places whose light stays the same while they're seen suit
it: the inn's rooms, and the duel arenas once their 3D rings are built.
