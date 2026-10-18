extends Node
## Stills of Gary's dry-stone walls, the inn's fence, the grain sacks and the
## crates in Ashford: along the roads, a joint close to with someone beside
## it, the corners, the steepest stretch, the gateways, the fence with Bram
## and the player where they go through it in the film, the crates by the
## inn's door and the stall, the sacks by the cart and the mill, and
## make_crate()'s lantern crate by the player. Prints how much each view draws
## (objects, triangles, draw calls), with and without them, and how many
## copies of each model there are.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/walls_shot.tscn -- <out_dir>

var out_dir := "user://"
var world: World
var v: AshfordVillage


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(40)
	world.hud.visible = false
	v = world.get_meta("village")
	_count()
	# the steepest length of wall that's drawn here, to look at side on
	var steep: Transform3D
	var most := -1.0
	for s in v.wall_sections():
		var xf: Transform3D = s[0]
		if (v.quality == 2 or not bool(s[1])) and absf(xf.basis.x.y) > most:
			most = absf(xf.basis.x.y)
			steep = xf
	print("steepest wall: %.1f%% at %s" % [most / Vector2(steep.basis.x.x, steep.basis.x.z).length() * 100.0, steep.origin])
	var flat := Vector3(steep.basis.x.x, 0, steep.basis.x.z).normalized()
	# and the one sunk deepest into the ground somewhere along its foot
	var sunk: Transform3D
	most = -1.0
	for s in v.wall_sections():
		var xf: Transform3D = s[0]
		if v.quality < 2 and bool(s[1]):
			continue
		for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
			for z in [-0.28, 0.0, 0.28]:
				var p: Vector3 = xf * Vector3(x, 0.0, z)
				if v.ground_y(p.x, p.z) - p.y > most:
					most = v.ground_y(p.x, p.z) - p.y
					sunk = xf
	print("deepest wall: %.2f m at %s" % [most, sunk.origin])
	var sunk_side := Vector3(sunk.basis.x.x, 0, sunk.basis.x.z).normalized().cross(Vector3.UP)
	var mill := v.mill_root.global_position
	var front := v.mill_root.global_transform.basis.z
	var side := v.mill_root.global_transform.basis.x
	var wood := Vector3(-21.4, 0, 13.0)    # ashford.gd WOODPILE
	var views := [
		# along the road west, both walls; and a joint close to, someone beside it
		["road_west", _eye(-40, 17.5, 1.7), _eye(-75, 24, 1.0), 50.0],
		["wall_close", _eye(-55.5, 21.6, 1.6), _eye(-55, 24.9, 0.5), 50.0],
		["road_east", _eye(36, 11, 1.8), _eye(80, 3, 1.0), 50.0],
		# where three walls meet north of the village, and where the west
		# road's wall turns north behind the gardens
		["corner", _eye(16, -64, 2.6), _eye(10, -70, 0.3), 50.0],
		["corner_west", _eye(-31, 25.5, 2.2), _eye(-36, 21, 0.4), 50.0],
		["steep", steep.origin + flat.cross(Vector3.UP) * 6.0 + Vector3(0, 1.4, 0), steep.origin + Vector3(0, 0.5, 0), 50.0],
		["sunk", _eye(sunk.origin.x + sunk_side.x * 5.0, sunk.origin.z + sunk_side.z * 5.0, 1.6), _eye(sunk.origin.x, sunk.origin.z, 0.4), 50.0],
		["sunk_other", _eye(sunk.origin.x - sunk_side.x * 5.0, sunk.origin.z - sunk_side.z * 5.0, 1.6), _eye(sunk.origin.x, sunk.origin.z, 0.4), 50.0],
		# the gateway on the lane up to the mill, the one the rider takes, and
		# the north wall's end the hound passes
		["lane_gate", _eye(19, -36, 1.7), _eye(24, -42, 0.5), 50.0],
		["gateway", _eye(51, 7.5, 2.2), _eye(56, 13, 0.4), 50.0],
		["wall_end", _eye(39, 10.5, 1.8), _eye(46, 7, 0.4), 50.0],
		# the inn's fence from the road, and from the yard
		["fence_road", _eye(-15, 18.5, 1.8), _eye(-23, 13.5, 0.6), 50.0],
		["fence_yard", _eye(-25, 9.5, 2.0), _eye(-24, 14.5, 0.5), 50.0],
		["fence_west_end", _eye(-27.5, 16.5, 1.7), _eye(-30.5, 12.0, 0.6), 50.0],
		# crates by the inn's door, and by the blue stall with its sacks
		["inn_crates", _eye(-15.5, 11.0, 1.7), _eye(-19.8, 8.4, 0.6), 50.0],
		["inn_door", _eye(-12.5, 4.0, 2.4), _eye(-21, 6.5, 1.2), 50.0],
		["blue_stall", _eye(-2.0, -4.5, 1.8), _eye(-6.2, -9.0, 0.5), 50.0],
		["cart_sacks", _eye(3.5, 0.0, 1.8), _eye(6.5, -5.0, 0.5), 50.0],
		["mill_door", mill + front * 7.5 + side * 2.5 + Vector3(0, 1.7, 0), mill + front * 1.6 + Vector3(0, 0.7, 0), 50.0],
		# the whole village, and the New Game flight's first frames
		["wide", Vector3(0, 26, 40), Vector3(0, 0, -6), World.CAM_FOV],
		["intro", Vector3(-12.0, 8.5, 30.0), Vector3(0.0, 4.0, -2.0), World.CAM_FOV],
		["play", Vector3(1.5, 8.2, 20.0), Vector3(1.5, 1.1, 8.5), World.CAM_FOV],
	]
	for vw in views:
		Cine.shot(world, vw[1], vw[2], vw[3])
		if vw[0] == "wall_close":
			Cine.place(world, "player", Vector3(-54.6, 0, 23.7), Vector3(-54.6, 0, 26))
		elif vw[0] == "inn_crates":
			Cine.place(world, "player", Vector3(-19.0, 0, 9.5), Vector3(-10, 0, 9.5))   # where the player comes out of the inn
		elif vw[0] == "cart_sacks":
			Cine.place(world, "player", Vector3(1.5, 0, 10.5))
		await _frames(6)
		await _shot(vw[0])
	# the film's woodpile shot (ashford.gd, _burning): Bram and the player at
	# the gap in the fence, and from the gardens as they go through
	Cine.place(world, "bram", wood + Vector3(-0.6, 0, 0.5), wood)
	Cine.place(world, "player", wood + Vector3(0.4, 0, -0.1), wood + Vector3(-0.6, 0, 0.5))
	Cine.shot(world, wood + Vector3(2.5, 1.5, 3.4), wood + Vector3(0, 1.1, 0), 40.0)
	await _frames(6)
	await _shot("film_woodpile")
	Cine.shot(world, Vector3(-17.5, 4.5, 24.0), Vector3(-27.0, 0.8, 14.5), 46.0)
	await _frames(6)
	await _shot("film_gardens")
	# the player coming back past the fence's west end to the back door
	Cine.place(world, "player", Vector3(-30.0, 0, 13.5), Vector3(-30.7, 0, 9.5))
	Cine.place(world, "bram", Vector3(-30.7, 0, 12.0), Vector3(-31.5, 0, 9.0))
	Cine.shot(world, Vector3(-25.0, 2.2, 16.5), Vector3(-30.0, 0.9, 13.0), 46.0)
	await _frames(6)
	await _shot("film_back")
	# the lantern crate for carrying, by the player on the green
	var crate := v.make_crate()
	world.add_child(crate)
	crate.global_position = Vector3(2.6, v.height(2.6, 9.6), 9.6)
	crate.rotation.y = 0.3
	Cine.place(world, "player", Vector3(1.4, 0, 9.8), Vector3(2.6, 0, 9.6))
	Cine.shot(world, Vector3(2.2, 1.4, 13.2), Vector3(2.0, 0.6, 9.6), 46.0)
	await _frames(6)
	await _shot("make_crate")
	crate.queue_free()
	# what the walls, fence and props cost: the same views without them
	for n in ["FieldWalls", "Fences", "Props"]:
		if v.has_node(n):
			(v.get_node(n) as Node3D).visible = false
	for vw in views:
		if vw[0] in ["road_west", "road_east", "fence_road", "wide", "intro", "play"]:
			Cine.shot(world, vw[1], vw[2], vw[3])
			await _frames(6)
			await _shot(vw[0] + "_without")
	print("WALLS SHOT: done")
	get_tree().quit()


## A point `up` metres over the ground at (x, z).
func _eye(x: float, z: float, up: float) -> Vector3:
	return Vector3(x, v.ground_y(x, z) + up, z)


## How many copies of each of the new models there are, and in how many MultiMeshes.
func _count() -> void:
	var seen := {}
	for mm: MultiMeshInstance3D in v.find_children("*", "MultiMeshInstance3D", true, false):
		var m := mm.multimesh.mesh
		var mat := m.surface_get_material(0)
		var id := mat.resource_name if mat != null else ""
		if not ("Wall" in id or "Fence" in id or "Sack" in id or "Crate" in id):
			continue
		var tris := 0
		for s in m.get_surface_count():
			tris += (m.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var key := "%s (%d triangles)" % [id, tris]
		var e: Array = seen.get(key, [0, 0])
		seen[key] = [e[0] + 1, e[1] + mm.multimesh.instance_count]
	for k in seen:
		print("COUNT %s: %d MultiMeshes, %d copies" % [k, seen[k][0], seen[k][1]])
	print("COUNT quality %d, props placed %d" % [v.quality, v.props_placed.size()])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("VIEW %-14s objects %5d  triangles %8d  draw calls %4d" % [name,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
