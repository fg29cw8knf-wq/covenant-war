extends Node
## Bram walked at the Shardlands' ice (18 November, Gary: "You can walk through
## the icicles at the beginning with Bram"). The memory's set is built, and
## where its ice really stands at the height of a man is drawn on a plan from
## the crystals' own meshes (every face of every cluster, cut between the snow
## and his head, to cells 8 cm square). Then he's walked at it: at each of a
## number of spires from two sides and several lines across it (dead on, and
## to either side, where the crystals leaning out of its foot are), and out of
## the crater's bowl through its shards from the bottom every way round;
## 5 cm a step, each step put through the walk's own keeping-off
## (WhiteSky._off_ice). A step whose place is in a cell of ice is a step
## through ice. "old" keeps him off as it was until 18 November (a ring round
## each spire's middle crystal only), for the before.
##
##   godot --headless --path . res://tests/ice_walk_probe.tscn [-- old] [spires=40]
## Ends "ICE WALK: ok" (no step in ice) or how many were.

const CELL := 0.08
const STEP := 0.05

var m: WhiteSky
var _ice := {}        # Vector2i -> true: ice at a man's height in this cell
var _old := false
var _spires_n := 40


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a) == "old":
			_old = true
		elif String(a).begins_with("spires="):
			_spires_n = int(String(a).substr(7))
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	m = WhiteSky.new()
	m.warm_sigils = false
	add_child(m)
	for k in 6:
		await get_tree().process_frame
	_plan()
	var walks := 0
	var steps := 0
	var bad := 0
	var worst := []
	# at the spires: from two sides, along lines across each
	var n := mini(_spires_n, m._spires.size())
	for si in n:
		var sp: Array = m._spires[int(float(si) * m._spires.size() / n)]
		var c := Vector3(float(sp[0]), 0.0, float(sp[1]))
		for ang: float in [0.0, 2.2]:
			var d := Vector3(cos(ang + si), 0.0, sin(ang + si))
			var side := d.cross(Vector3.UP)
			for off: float in [0.0, 0.5, -0.9, 1.5, -2.2]:
				var r := _walk(c - d * 6.5 + side * off, d, 13.0)
				walks += 1
				steps += int(r[0])
				bad += int(r[1])
				if int(r[1]) > 0:
					worst.append([int(r[1]), "the spire at (%.1f, %.1f), %.1f m aside" % [c.x, c.z, off]])
	# out of the bowl, every way round
	for k in 16:
		var a := TAU * k / 16.0
		var d := Vector3(cos(a), 0.0, sin(a))
		var r := _walk(WhiteSky.CRATER + d * 1.2, d, WhiteSky.CRATER_R + 3.0)
		walks += 1
		steps += int(r[0])
		bad += int(r[1])
		if int(r[1]) > 0:
			worst.append([int(r[1]), "out of the bowl towards %.0f degrees" % rad_to_deg(a)])
	worst.sort_custom(func(x: Array, y: Array) -> bool: return int(x[0]) > int(y[0]))
	print("ice_walk_probe: %s: %d crystals' ice on the plan in %d cells; %d parts of it solid to him; %d walks, %d steps, %d of them in ice (%.1f m walked through it)" % [
		"as it was (a ring round each spire's middle)" if _old else "as it is", _crystals, _ice.size(), m._ice.size(), walks, steps, bad, bad * STEP])
	for w in worst.slice(0, 6):
		print("ice_walk_probe:   %d steps in ice at %s" % [int(w[0]), String(w[1])])
	print("ICE WALK: ok" if bad == 0 else "ICE WALK: %d steps through ice" % bad)
	get_tree().quit(0 if bad == 0 or _old else 1)


var _crystals := 0

## Where the ice stands between the snow and a man's head: each crystal's
## faces cut level every 6 cm of that height, the cut walked along.
func _plan() -> void:
	var mats: Array = WhiteSky._ice_mats.values()
	for c in m._set.get_children():
		var mi := c as MeshInstance3D
		if mi == null or not (mi.mesh is ArrayMesh) or not mats.has(mi.material_override):
			continue
		_crystals += 1
		var faces := mi.mesh.get_faces()
		var xf := mi.transform
		for t in range(0, faces.size() - 2, 3):
			var p := [xf * faces[t], xf * faces[t + 1], xf * faces[t + 2]]
			var lo := minf(p[0].y, minf(p[1].y, p[2].y))
			var hi := maxf(p[0].y, maxf(p[1].y, p[2].y))
			var g := WhiteSky.height((p[0].x + p[1].x + p[2].x) / 3.0, (p[0].z + p[1].z + p[2].z) / 3.0)
			var y := maxf(lo, g + 0.06)
			while y <= minf(hi, g + 1.75):
				# where the level cuts the face: a point on each edge that crosses it
				var cut: Array = []
				for e in 3:
					var a: Vector3 = p[e]
					var b: Vector3 = p[(e + 1) % 3]
					if (a.y - y) * (b.y - y) <= 0.0 and absf(a.y - b.y) > 0.00001:
						cut.append(a.lerp(b, (y - a.y) / (b.y - a.y)))
				if cut.size() >= 2:
					var a2: Vector3 = cut[0]
					var b2: Vector3 = cut[1]
					var steps := maxi(1, int(a2.distance_to(b2) / (CELL * 0.5)))
					for s in steps + 1:
						var q := a2.lerp(b2, float(s) / steps)
						# (only where it's over the snow there: a foot under a drift isn't in his way)
						if q.y > WhiteSky.height(q.x, q.z) + 0.05:
							_ice[Vector2i(floori(q.x / CELL), floori(q.z / CELL))] = true
				y += 0.06


## A walk from `from` along `dir` for `far` metres, a step at a time, kept off
## the ice as the game keeps him: [steps, steps whose place is in ice].
func _walk(from: Vector3, dir: Vector3, far: float) -> Array:
	var at := Vector3(from.x, 0.0, from.z)
	# (not begun inside another crystal: back along the way he came until he's clear of all of it)
	var back := 0.0
	while back < 8.0 and (_in_ice(at) or _near_solid(at)):
		at -= dir * 0.25
		back += 0.25
	if _in_ice(at) or _near_solid(at):
		return [0, 0]
	far += back
	var n := 0
	var bad := 0
	var gone := 0.0
	while gone < far:
		var to := at + dir * STEP
		var was := at
		at = _off_old(to) if _old else m._off_ice(at, to)
		gone += STEP
		n += 1
		# (a step that took him somewhere, and that somewhere is ice)
		if at.distance_to(was) > 0.001 and _in_ice(at):
			bad += 1
	return [n, bad]


func _in_ice(at: Vector3) -> bool:
	return _ice.has(Vector2i(floori(at.x / CELL), floori(at.z / CELL)))


## Inside what's solid to him now (so a walk doesn't begin there)?
func _near_solid(at: Vector3) -> bool:
	for c: Array in m._ice:
		var a := Vector2(c[0], c[1])
		var ab := Vector2(c[2], c[3]) - a
		var q := Vector2(at.x, at.z)
		var near := a + ab * clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
		if q.distance_to(near) < float(c[4]):
			return true
	return false


## As it was: out of a ring round each spire's middle crystal.
func _off_old(nf: Vector3) -> Vector3:
	for sp in m._spires:
		var d := Vector2(nf.x - float(sp[0]), nf.z - float(sp[1]))
		var rr := float(sp[2])
		if d.length() < rr and d.length() > 0.001:
			var out := d.normalized() * rr
			nf.x = float(sp[0]) + out.x
			nf.z = float(sp[1]) + out.y
	return nf
