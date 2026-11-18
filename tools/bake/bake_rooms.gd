extends Node
## Readies the inn's rooms for baking (18 November, BakedLight): builds the
## village and each room as the game does, gives every fixed thing in it a
## shape with a second set of UVs (assets/bake/<room>/s<k>.res, and which
## node wears which: shapes.json), and saves the room, one scene for each of
## its light states, for the editor to bake (tools/bake/scenes/<room>_<state>.tscn,
## not shipped). Then tools/bake/bake_rooms.sh presses Bake on each.
##   godot --headless res://tools/bake/bake_rooms.tscn -- [attic] [eve]

## How big a texel of baked light is on a wall (m): the attic's gable is a
## hundred across, soft enough for bounced light, small enough for the dark
## under the bed and round the beams.
const TEXEL := 0.06
const OUT := "res://tools/bake/scenes/"

## The attic's baked bounce, made to count: its walls and boards are dark
## wood, so the morning's light off the floor came back too faint to see
## (a bake 18 November added under 1% to the room). The window's and the
## candle's light bounce this many times stronger in the bake (an artist's
## lift, as the fill was), and the room's two stand-in lights (the fill and
## the "bounce" off the floorboards) aren't bounced at all: they're the
## live lift the bake now takes over from (InnRooms.baked_bounce).
const ATTIC_LIFT := {"window": 4.0, "candle": 3.0}


func _ready() -> void:
	var rooms: Array = Array(OS.get_cmdline_user_args())
	if rooms.is_empty():
		rooms = ["attic", "eve"]
	BakedLight.baking = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var v := AshfordVillage.new()
	add_child(v)
	for i in 20:
		await get_tree().process_frame
	for room in rooms:
		var out: Dictionary = InnRooms.attic(v) if room == "attic" else InnRooms.eve(v)
		await _ready_room(v, String(room), out)
	print("BAKE ROOMS: done")
	get_tree().quit()


func _ready_room(v: AshfordVillage, room: String, out: Dictionary) -> void:
	var root: Node3D = out.root
	var dir := BakedLight.DIR + room + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var meshes := BakedLight.bakeable(root, out)
	# one baked shape for each shape the room uses (a box size used ten
	# times is laid out once: the bake gives each of its ten its own patch)
	var shapes := {}
	var made := {}
	var k := 0
	var tris := 0
	for mi in meshes:
		var src: Mesh = mi.mesh
		if not made.has(src):
			var am := _with_uv2(src)
			if am == null:
				print("BAKE ROOMS: %s: %s couldn't be laid out, left unbaked" % [room, root.get_path_to(mi)])
				continue
			var f := "s%d.res" % k
			k += 1
			ResourceSaver.save(am, dir + f)
			made[src] = [f, am]
			for si in am.get_surface_count():
				tris += am.surface_get_array_len(si) / 3 if am.surface_get_array_index_len(si) <= 0 else am.surface_get_array_index_len(si) / 3
		shapes[String(root.get_path_to(mi))] = made[src][0]
		mi.mesh = made[src][1]
		mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	var f := FileAccess.open(dir + "shapes.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(shapes, "\t", true))
	f.close()
	print("BAKE ROOMS: %s: %d things baked, %d shapes, %d triangles" % [room, shapes.size(), k, tris])
	# everything else isn't baked and doesn't stand in the bake's way
	var baked := {}
	for mi in meshes:
		baked[mi] = true
	for n in BakedLight._walk(root):
		if n is GeometryInstance3D and not baked.has(n):
			(n as GeometryInstance3D).gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_strip(root)
	var lm := LightmapGI.new()
	lm.name = "BakedLight"
	lm.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lm.bounces = 3
	lm.directional = false
	lm.use_denoiser = true
	lm.environment_mode = LightmapGI.ENVIRONMENT_MODE_DISABLED   # (the rooms are shut in: no sky)
	lm.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8   # (people in the room lit by it too)
	root.add_child(lm)
	if room == "attic":
		var L: Dictionary = out.get("lights", {})
		for k2 in ATTIC_LIFT:
			(L[k2] as Light3D).light_indirect_energy = ATTIC_LIFT[k2]
		for k2 in ["fill", "bounce"]:
			if L.has(k2):
				(L[k2] as Light3D).light_bake_mode = Light3D.BAKE_DISABLED
	for state in BakedLight.STATES[room]:
		if room == "attic" and state == "awakening":
			InnRooms.attic_awakening(out)
		_own(root, root)
		var ps := PackedScene.new()
		var err := ps.pack(root)
		var path := OUT + "%s_%s.tscn" % [room, state]
		print("BAKE ROOMS: %s %s packed (%s), saved %s" % [room, state, error_string(err), error_string(ResourceSaver.save(ps, path))])
		await get_tree().process_frame


## A shape with a second set of UVs laid out for baked light (a primitive
## made into a mesh first).
func _with_uv2(src: Mesh) -> ArrayMesh:
	var am: ArrayMesh
	if src is PrimitiveMesh:
		am = ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, (src as PrimitiveMesh).get_mesh_arrays())
		if (src as PrimitiveMesh).material != null:
			am.surface_set_material(0, (src as PrimitiveMesh).material)
	elif src is ArrayMesh:
		am = (src as ArrayMesh).duplicate()
	else:
		return null
	if am.get_blend_shape_count() > 0:
		return null
	if am.lightmap_unwrap(Transform3D.IDENTITY, TEXEL) != OK:
		return null
	return am


## What a bake has no use for, gone from the copy it's given (the window's
## view of the village, smoke, words, sprites, sounds): nothing that's baked
## sits under them.
func _strip(root: Node) -> void:
	for n in BakedLight._walk(root):
		if not is_instance_valid(n):
			continue
		if n is SubViewport or n is GPUParticles3D or n is CPUParticles3D or n is Label3D or n is SpriteBase3D \
				or n is AudioStreamPlayer3D or n is AudioStreamPlayer:
			n.get_parent().remove_child(n)
			n.queue_free()


## Every node under `root` owned by it, a model's own nodes too (saved as
## the room's, so the scene the editor bakes has the game's own paths), and
## no scripts (the editor doesn't run the game's).
func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		if c.scene_file_path != "":
			c.scene_file_path = ""
		if c.get_script() != null:
			c.set_script(null)
		_own(c, root)
