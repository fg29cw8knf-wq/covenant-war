extends Node
## Readies the Shardlands for baking (18 November, Gary: "also bake the
## shardlands at the beginning of the game"): builds the Night of the White
## Sky's set as the game does (WhiteSky, at the full level: every spire),
## gives the snow, the ice spires and the crater's shards a second set of UVs
## (assets/bake/shards/s<k>.res, and which wears which: shapes.json), and
## saves the set twice for the editor to bake, its light as he walks under
## the moon (walk) and once the sky is torn open (torn):
## tools/bake/scenes/shards_<state>.tscn. Then tools/bake/bake_rooms.sh shards.
## Not shipped: WhiteSky.BAKED_LIGHT says why.
##
## Only the light's bounce is baked: the moon, the tear and the crater stay
## live (a shadow still swings round as the sky opens, the crater still
## flickers), and so does the sky's light over everything (the bake leaves
## the sky out and the game adds it as it changes). The light that's only on
## Bram (the fill) and the passing lights (the hunter's, the Sigils') have
## no bounce baked.
##   godot --headless res://tools/bake/bake_shards.tscn

const OUT := "res://tools/bake/scenes/"
const ROOM := "shards"
## How big a texel of baked light is (m): the snow is 380 m across, its
## bounce soft and wide; the spires' and the shards' sides finer.
const TEXEL := {"Ground": 0.5, "Spire": 0.2, "CraterShard": 0.06}


func _ready() -> void:
	Gfx.force_level = 2
	Game.settings["seen_white_sky"] = false
	Gfx.setup(get_tree())
	BakedLight.baking = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var m := WhiteSky.new()
	m.prep_early = false
	add_child(m)
	await get_tree().process_frame
	m.process_mode = Node.PROCESS_MODE_DISABLED
	var root: Node3D = m._set
	var dir := BakedLight.DIR + ROOM + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var shapes := {}
	var baked := {}
	var k := 0
	var tris := 0
	for c in root.get_children():
		if not (c is MeshInstance3D):
			continue
		var mi := c as MeshInstance3D
		var t := 0.0
		for key in TEXEL:
			if String(mi.name).begins_with(key):
				t = TEXEL[key]
		if t <= 0.0 or mi.mesh == null:
			continue
		var am: ArrayMesh = (mi.mesh as ArrayMesh).duplicate() if mi.mesh is ArrayMesh else null
		if am == null or am.lightmap_unwrap(Transform3D.IDENTITY, t) != OK:
			print("BAKE SHARDS: %s couldn't be laid out, left unbaked" % mi.name)
			continue
		var f := "s%d.res" % k
		k += 1
		ResourceSaver.save(am, dir + f)
		for si in am.get_surface_count():
			tris += am.surface_get_array_index_len(si) / 3 if am.surface_get_array_index_len(si) > 0 else am.surface_get_array_len(si) / 3
		shapes[String(mi.name)] = f
		mi.mesh = am
		mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		baked[mi] = true
	var jf := FileAccess.open(dir + "shapes.json", FileAccess.WRITE)
	jf.store_string(JSON.stringify(shapes, "\t", true))
	jf.close()
	print("BAKE SHARDS: %d things baked, %d triangles" % [shapes.size(), tris])
	for n in BakedLight._walk(root):
		if n is GeometryInstance3D and not baked.has(n):
			(n as GeometryInstance3D).gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		elif n is Light3D and not [m._moon, m._tear_light, m._crater_light].has(n):
			(n as Light3D).light_bake_mode = Light3D.BAKE_DISABLED
	# the crater's light as it burns while he walks to it (WhiteSky._process:
	# its flicker about 2.4, at its full, times CRATER_LIGHT)
	m._crater_light.light_energy = 2.4 * WhiteSky.CRATER_LIGHT
	m._vp.remove_child(root)
	add_child(root)
	_strip(root)
	var lm := LightmapGI.new()
	lm.name = "BakedLight"
	lm.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lm.bounces = 2
	lm.directional = false
	lm.use_denoiser = true
	lm.environment_mode = LightmapGI.ENVIRONMENT_MODE_DISABLED   # (the sky's light stays live: it changes)
	lm.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8   # (Bram lit by the snow's bounce too)
	root.add_child(lm)
	for state in BakedLight.STATES[ROOM]:
		if state == "torn":
			m.tear_now()
		# (a light at nothing, the tear's as he walks, left out of the bake: the
		# walk's bake with it in came out with black and red blots on the
		# snow, the torn sky's clean. The likely cause, not yet baked again)
		for l in [m._moon, m._tear_light, m._crater_light]:
			(l as Light3D).light_bake_mode = Light3D.BAKE_DYNAMIC if (l as Light3D).light_energy > 0.0 else Light3D.BAKE_DISABLED
		_own(root, root)
		var ps := PackedScene.new()
		var err := ps.pack(root)
		var path := OUT + "%s_%s.tscn" % [ROOM, state]
		print("BAKE SHARDS: %s packed (%s), saved %s" % [state, error_string(err), error_string(ResourceSaver.save(ps, path))])
		await get_tree().process_frame
	print("BAKE SHARDS: done")
	get_tree().quit()


## What a bake has no use for, gone from the copy it's given (the storm, the
## child's glow, the hunter, Bram: nothing baked is under them), and the
## sky, fog and haze (the bake leaves the sky out; the editor drawing the
## set in its haze at every step of the bake, on a software GPU, made a
## state's bake take half an hour. Not drawing it at all, its 3D views
## switched off, broke the bake: the night's came out with black and red
## blots).
func _strip(root: Node) -> void:
	for n in BakedLight._walk(root):
		if not is_instance_valid(n):
			continue
		if n is SubViewport or n is GPUParticles3D or n is CPUParticles3D or n is Label3D or n is SpriteBase3D \
				or n is AudioStreamPlayer3D or n is AudioStreamPlayer or n is WorldEnvironment:
			n.get_parent().remove_child(n)
			n.queue_free()


## Every node under `root` owned by it, a model's own nodes too, and no
## scripts (the editor doesn't run the game's).
func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		if c.scene_file_path != "":
			c.scene_file_path = ""
		if c.get_script() != null:
			c.set_script(null)
		_own(c, root)
