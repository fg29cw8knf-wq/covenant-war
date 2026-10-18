extends "res://tests/film_test.gd"
## Plays a part of the Prologue's film (as film_test does) and watches where
## everyone goes: the player, the villagers, the riders and their hounds. Says
## whenever someone comes within reach of one of Gary's grain sacks or crates,
## the inn's fence or a dry-stone wall, and how close everyone came to each.
##   godot --headless --fixed-fps 10 res://tests/props_clear_test.tscn -- <out_dir> <part> 0 only
## part: corin, midnight, dawn, burning (see film_test.gd). Ends with
## "PROPS CLEAR: ok" or "PROPS CLEAR: <n> too close".

const BODY := 0.3    # someone's half-width, about

var _v: AshfordVillage
var _walls: Array = []   # [from, to] of each length of wall, flat
var _close := {}         # "who / what" -> [nearest, frame]
var _hits := 0


func _process(d: float) -> void:
	super(d)
	if world == null or not world.has_meta("village"):
		return
	if _v == null:
		_v = world.get_meta("village")
		for s in _v.wall_sections():
			var xf: Transform3D = s[0]
			var half := xf.basis.x * AshfordVillage.WALL_LENGTH * 0.5
			_walls.append([Vector2(xf.origin.x - half.x, xf.origin.z - half.z), Vector2(xf.origin.x + half.x, xf.origin.z + half.z)])
		_check_ground()
	for who in _bodies():
		var b: Node3D = who[1]
		var p := Vector2(b.global_position.x, b.global_position.z)
		for i in _v.props_placed.size():
			var pr: Array = _v.props_placed[i]
			_note(who[0], "prop %d at %s" % [i, (pr[0] as Vector2).round()], p.distance_to(pr[0]) - float(pr[1]))
		for run in AshfordVillage.INN_FENCE:
			_note(who[0], "fence %s" % [(run[0] as Vector2).round()], _to_segment(p, run[0], run[1]) - AshfordVillage.FENCE_POST)
		for w in _walls:
			var gap := _to_segment(p, w[0], w[1]) - AshfordVillage.WALL_HALF_DEPTH
			if gap < 2.0:
				_note(who[0], "wall at %s" % [((w[0] + w[1]) * 0.5).round()], gap)


## Everyone in the scene who's visible: [name, body].
func _bodies() -> Array:
	var out: Array = []
	if world.player != null and world.player.is_visible_in_tree():
		out.append(["player", world.player])
	for n in world.npcs:
		var b: Node3D = n.body
		if b != null and b.is_visible_in_tree():
			out.append([String(n.def.id), b])
	var ex: Dictionary = world.get_meta("extras", {}) if world.has_meta("extras") else {}
	for id in ex:
		var b: Node3D = ex[id].get("body", null)
		if b != null and is_instance_valid(b) and b.is_visible_in_tree():
			out.append([String(id), b])
	for c in world.get_children():
		if c is Node3D and c.has_meta("beast") and (c as Node3D).is_visible_in_tree():
			out.append([String(c.name), c])
	return out


## Whether everything stands on the ground: the foot of every length of wall
## (all of them, as the Mac draws them), the fence's posts and the sacks and
## crates, as how far above the drawn ground (in the air) or below it each
## gets at worst.
func _check_ground() -> void:
	var air := -INF
	var deep := -INF
	var sunk: Array = []    # [how deep its foot goes at worst, where]
	for s in _v.wall_sections():
		var xf: Transform3D = s[0]
		var worst := -INF
		for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
			for z in [-0.28, 0.0, 0.28]:
				var p: Vector3 = xf * Vector3(x, 0.0, z)
				var g := _v.ground_y(p.x, p.z)
				air = maxf(air, p.y - g)
				worst = maxf(worst, g - p.y)
		deep = maxf(deep, worst)
		sunk.append([worst, xf.origin])
	sunk.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var over := [0, 0]
	for e in sunk:
		over[0] += 1 if float(e[0]) > 0.3 else 0
		over[1] += 1 if float(e[0]) > 0.5 else 0
	print("GROUND walls: foot up to %.3f m in the air, %.2f m deep; %d of %d lengths more than 0.3 m deep somewhere, %d more than 0.5 m; deepest at %s" % [
		air, deep, over[0], sunk.size(), over[1], [sunk[0][1].round(), sunk[1][1].round(), sunk[2][1].round()]])
	# how many lengths and batches the Mac (all) and the phones (near) draw,
	# against the drawn rock walls they replace (3 rocks every 0.36 m)
	var lengths := [0, 0]
	var batches := [{}, {}]
	for s in _v.wall_sections():
		var o: Vector3 = (s[0] as Transform3D).origin
		var key := Vector2i(floori(o.x / AshfordVillage.WALL_CHUNK), floori(o.z / AshfordVillage.WALL_CHUNK))
		for q in 2:
			if q == 0 or not bool(s[1]):
				lengths[q] += 1
				batches[q][key] = true
	var rocks := [0, 0]
	for line in AshfordVillage.FIELD_WALLS:
		for i in line.size() - 1:
			var n := int((line[i] as Vector2).distance_to(line[i + 1]) / 0.36)
			for k in n:
				rocks[0] += 3
				if (line[i] as Vector2).lerp(line[i + 1], (k + 0.5) / n).length() <= AshfordVillage.WALL_NEAR:
					rocks[1] += 3
	var rock_tris := []
	for q in [[10, 6], [7, 4]]:   # the rock's sphere on the Mac, and on phones (rock_mesh)
		var sm := SphereMesh.new()
		sm.radial_segments = q[0]
		sm.rings = q[1]
		rock_tris.append((sm.get_mesh_arrays()[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3)
	print("WALLS Mac: %d lengths in %d MultiMeshes (rocks were %d, %d triangles); phones: %d lengths in %d (rocks were %d, %d triangles)" % [
		lengths[0], batches[0].size(), rocks[0], rocks[0] * rock_tris[0], lengths[1], batches[1].size(), rocks[1], rocks[1] * rock_tris[1]])
	for what in ["Fences", "Props"]:
		air = -INF
		deep = -INF
		for mm: MultiMeshInstance3D in _v.get_node(what).find_children("*", "MultiMeshInstance3D", true, false):
			for i in mm.multimesh.instance_count:
				var xf := mm.multimesh.get_instance_transform(i)
				var p := xf.origin
				if what == "Props" and p.y > _v.ground_y(p.x, p.z) + 0.4:
					continue   # stacked on another
				for r in [Vector3.ZERO, xf.basis.x.normalized() * 0.1, xf.basis.z.normalized() * 0.1, -xf.basis.x.normalized() * 0.1, -xf.basis.z.normalized() * 0.1]:
					var q: Vector3 = p + r
					var g := _v.ground_y(q.x, q.z)
					air = maxf(air, q.y - g)
					deep = maxf(deep, g - q.y)
		print("GROUND %s: up to %.3f m in the air, %.2f m deep" % [what, air, deep])


func _to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _note(who: String, what: String, gap: float) -> void:
	var key := who + " / " + what
	var was: Array = _close.get(key, [INF, 0])
	if gap < float(was[0]):
		_close[key] = [gap, _frame]
	if gap < BODY and float(was[0]) >= BODY:
		_hits += 1
		print("TOO CLOSE: %s, %.2f m off it at frame %d" % [key, gap + 0.0, _frame])


func _shot(label: String) -> void:
	if label == "end":
		_report()
	await super(label)


func _report() -> void:
	var keys := _close.keys()
	keys.sort_custom(func(a, b): return float(_close[a][0]) < float(_close[b][0]))
	for k in keys.slice(0, 12):
		print("NEAREST %-48s %.2f m (frame %d)" % [k, float(_close[k][0]), int(_close[k][1])])
	print("PROPS CLEAR: " + ("ok" if _hits == 0 else "%d too close" % _hits))
