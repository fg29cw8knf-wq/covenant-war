class_name BlanketDrape
extends Node
## The attic blanket laid over whoever is lying under it (18 November, Gary's
## yes to "a soft blanket that folds over him"). It was a sheet of 26 by 16
## squares laid by rule: flat across the width of a body, high over a chest,
## lower down a pair of legs, whoever lay there and however; it read as a
## board. Now, once the sleeper is lying still, the cloth is laid over him as
## he is:
##
## - his shape under it is read off his own skin as it's drawn (every point
##   of his model that lies under the blanket, bent as his bones are), and
##   the mattress's off the mattress (its dip, its rolled edge);
## - the cloth lies CLEAR over him and hangs between whatever holds it up
##   as cloth does: little between two parts of him (his legs, an arm and
##   his side: TIGHT), and down off his sides and his boots to the mattress
##   in a curve that eases out onto it (LOOSE). (Each is the same sum: the
##   lowest a sheet can hang that's held up at every point under it and
##   bends no more sharply than that. A "closing" by a parabola, run along
##   the bed and then across it.)
## - where it lies loose it's folded: long folds that run down the bed and
##   out from him, that come and go, and small rumples (FOLD, RUMPLE); where
##   it's drawn over him, hardly at all;
## - its hem is turned back in a roll across his chest, a little askew, and
##   its sides hang over the mattress's edge;
## - each point carries how deep in a fold it lies ("shade"), for the
##   shader to darken the hollows.
##
## Twice the squares each way (NX by NZ). The blanket keeps the same things
## it kept (InnRooms._bed): "rows" (its points as laid, for BlanketThrow and
## BlanketTent) and "mesh_on" (its mesh as laid); and now "rows_free" (as it
## would lie without his left arm under it: what BlanketTent lifts the cloth
## from as that arm goes to his neck, so no empty ridge is left where the
## arm lay) and "shade".
##
##   BlanketDrape.lay(blanket, fig)     # AshfordP1.asleep, each time he's laid in it
##
## It's made once for a way of lying (kept by where his hips, hands and feet
## are): about a twentieth of a second, under the black before the attic
## comes up.

const NX := 52
const NZ := 32
## How far clear of him the cloth lies (m: a thick wool blanket, and the air
## under it), and of the mattress.
const CLEAR := 0.02
const THICK := 0.006
## How sharply the cloth bends as it hangs (1/m): between two parts of him a
## gap g apart it sags TIGHT * g * g / 4 (legs 20 cm apart: under 2 cm); off his
## side, from a height h, it reaches the mattress sqrt(h / LOOSE) out (from
## 15 cm up: 22 cm out. At 7 it came down in 15, and stood in a mound of its
## own over each hand, which the window's light picked out).
const TIGHT := 1.7
const LOOSE := 3.0
## (and down the bed, between his chest and his knees and his boots, it's
## drawn tauter than across him: a blanket pulled up to the chest. With
## this the same as TIGHT it lay into every hollow of him down its length,
## and stood in small mounds over his hands and his hips that each caught
## the window's light on its own, like patches on the wool.)
const TIGHT_ALONG := 0.8
## How steeply it comes down to the mattress at its foot end, if his boots
## are still holding it up there (m down per m).
const END_FALL := 3.0
## The folds where it lies loose: how high the long ones stand and how far
## apart they are (m), and the small rumples.
const FOLD := 0.022
const FOLD_APART := 0.2
const FOLD_OVER_HIM := 0.35
const RUMPLE := 0.005
## The hem turned back over his chest: how thick the roll is, how far down
## the cloth it reaches, and how far askew the hem lies (m).
const HEM_ROLL := 0.024
const HEM_REACH := 0.085
const HEM_ASKEW := 0.024
## The mattress under it (InnRooms._bed: its half length and half width, the
## roll at its edge, and where its middle is from the blanket's).
const BED_HALF := Vector2(1.0, 0.42)
const BED_ROLL := 0.045
const BED_X := 0.285
## How deep a hollow has to be to be as dark as it gets (m), and how dark.
const SHADE_DEEP := 0.04
const SHADE_LEAST := 0.6
## Where his breathing lifts the cloth (m: how far along it from his chest's
## middle and his belly's, and across it from his middle).
const BREATH_CHEST := 0.15
const BREATH_BELLY := 0.13
const BREATH_WIDE := 0.24
## How many times his bones are drawn before he's taken to be lying still.
const SETTLE := 3
## How far a hand, a foot or his hips can be from where they were for it to
## be the same way of lying, and the same cloth (m: well inside CLEAR).
const SAME := 0.015
## Every which point of his skin is read (his models' points are a
## centimetre apart or nearer; the cloth's are three).
const SKIN_STEP := 2

static var _cache := {}
## (for the tests: how many times it's been laid and made, how long the last
## making took, and what it found)
static var laid := 0
static var made := 0
static var measure := false
static var last_ms := 0.0
static var last := {}

var blanket: MeshInstance3D
var fig: Figure3D
var _seen := 0
var _was: Array = []


## Lays the blanket over `fig` as he lies now. What was laid over him last
## time goes on at once; the cloth is laid again over him as he's drawn, a
## few frames on, if he lies differently.
static func lay(p_blanket: MeshInstance3D, p_fig: Figure3D) -> void:
	if p_blanket == null or not is_instance_valid(p_blanket) or not p_blanket.has_meta("rows"):
		return
	if p_fig == null or not is_instance_valid(p_fig) or p_fig._skel == null:
		return
	for c in p_blanket.get_children():
		if c is BlanketDrape:
			(c as BlanketDrape)._stop()
	var known = _cache.get("last:" + p_fig._model_name)
	if known != null:
		_put(p_blanket, known)
	var d := BlanketDrape.new()
	d.name = "BlanketDrape"
	d.blanket = p_blanket
	d.fig = p_fig
	p_blanket.add_child(d)
	p_fig._skel.skeleton_updated.connect(d._on_skel)


## (Bones that aren't moving aren't drawn again, and say nothing: after a
## dozen frames of that, he's lying still.)
var _frames := 0

func _process(_dt: float) -> void:
	_frames += 1
	if _frames > 12 and _seen == 0 and fig != null and is_instance_valid(fig) and fig._skel != null:
		_seen = SETTLE
		_was = _marks()
		_on_skel()


func _stop() -> void:
	if fig != null and is_instance_valid(fig) and fig._skel != null and fig._skel.skeleton_updated.is_connected(_on_skel):
		fig._skel.skeleton_updated.disconnect(_on_skel)
	queue_free()


func _exit_tree() -> void:
	if fig != null and is_instance_valid(fig) and fig._skel != null and fig._skel.skeleton_updated.is_connected(_on_skel):
		fig._skel.skeleton_updated.disconnect(_on_skel)


## Inside his bones' own pass (so every reach and bend is in them): once
## he's lying still, the cloth over him.
func _on_skel() -> void:
	if blanket == null or not is_instance_valid(blanket) or not blanket.is_inside_tree():
		return
	_seen += 1
	var now := _marks()
	var still := _was.size() == now.size() and not now.is_empty()
	if still:
		for i in now.size():
			if (now[i] as Vector3).distance_to(_was[i]) > 0.002:
				still = false
				break
	_was = now
	if _seen < SETTLE or (not still and _seen < 30):
		return
	# (what was laid over him lying this way before, if anything: every mark
	# within SAME of where it was then)
	var key := "ways:" + fig._model_name
	var ways: Array = _cache.get(key, [])
	var got = null
	for way: Array in ways:
		var marks: Array = way[0]
		if marks.size() != now.size():
			continue
		var same := true
		for i in now.size():
			if (now[i] as Vector3).distance_to(marks[i]) > SAME:
				same = false
				break
		if same:
			got = way[1]
			break
	if got == null:
		got = _make()
		if (got as Dictionary).is_empty():
			_stop()
			return
		ways.append([now, got])
		_cache[key] = ways
	_cache["last:" + fig._model_name] = got
	_put(blanket, got)
	_stop()


## Where he is, in the blanket's own frame: his hips, his chest, his hands
## and his feet.
func _marks() -> Array:
	var out: Array = []
	var sk := fig._skel
	var to_bl := blanket.global_transform.affine_inverse() * sk.global_transform
	for b in ["Hips", "Spine2", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "LeftForeArm", "RightForeArm"]:
		var i := sk.find_bone(b)
		if i >= 0:
			out.append(to_bl * sk.get_bone_global_pose(i).origin)
	return out


## The laid cloth onto the blanket: its points, its mesh. Not while it's
## being thrown back or is lifted over an arm (those have its points as
## they were), nor once it's been thrown (it's in its heap).
static func _put(bl: MeshInstance3D, got: Dictionary) -> void:
	for c in bl.get_children():
		if (c is BlanketThrow or c is BlanketTent) and not c.is_queued_for_deletion():
			return
	var as_laid: bool = not bl.has_meta("mesh_on") or bl.mesh == bl.get_meta("mesh_on")
	bl.set_meta("rows", got.rows)
	bl.set_meta("rows_free", got.rows_free)
	bl.set_meta("shade", got.shade)
	bl.set_meta("breath", got.get("breath", PackedFloat32Array()))
	bl.set_meta("mesh_on", got.mesh)
	if as_laid:
		bl.mesh = got.mesh
	laid += 1


## The mattress's top under a point of the blanket (the blanket's own
## frame: x down the bed from its middle, z across, y up from the mattress's
## edge height), and down its side past its edge.
static func mattress_y(x: float, z: float) -> float:
	var xm := x + BED_X
	var e := minf(BED_HALF.x - absf(xm), BED_HALF.y - absf(z))
	var sag := InnRooms._sag(xm, z, BED_HALF.x * 2.0, BED_HALF.y * 2.0)
	if e >= BED_ROLL:
		return -sag
	if e > 0.0:
		var d := BED_ROLL - e
		return -BED_ROLL + sqrt(maxf(BED_ROLL * BED_ROLL - d * d, 0.0)) - sag * (e / BED_ROLL)
	return -BED_ROLL + e


## Every point of his skin that could be under the blanket, as it's drawn
## now, in the blanket's frame; and which of them his left arm moves (from
## the elbow's side of the shoulder down).
func _skin() -> Array:
	var sk := fig._skel
	var pts := PackedVector3Array()
	var arm := PackedByteArray()
	if fig.model == null:
		return [pts, arm]
	var to_bl := blanket.global_transform.affine_inverse() * sk.global_transform
	for n in fig.model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.skin == null or mi.mesh == null or not mi.visible or mi.name == "SealMarkSkin":
			continue
		var local := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != sk:
			if cur is Node3D:
				local = (cur as Node3D).transform * local
			cur = cur.get_parent()
		if cur == null:
			continue
		# each bind of the skin: where it takes a point of the mesh now, and
		# what it is (0 a part of him that can be under the blanket, 1 his
		# left arm, 2 his head and neck: never under it)
		var bx: Array = []
		var kind := PackedByteArray()
		for i in mi.skin.get_bind_count():
			var b := mi.skin.get_bind_bone(i)
			if b < 0:
				b = sk.find_bone(mi.skin.get_bind_name(i))
			bx.append(to_bl * sk.get_bone_global_pose(b) * mi.skin.get_bind_pose(i) * local if b >= 0 else to_bl * local)
			var bn := String(sk.get_bone_name(b)) if b >= 0 else ""
			if bn.begins_with("Head") or bn.begins_with("Neck"):
				kind.append(2)
			elif bn == "LeftArm" or bn == "LeftForeArm" or bn.begins_with("LeftHand"):
				kind.append(1)
			else:
				kind.append(0)
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bs = arr[Mesh.ARRAY_BONES]
			var ws = arr[Mesh.ARRAY_WEIGHTS]
			if vs.is_empty() or bs == null or ws == null:
				continue
			var per := int(bs.size() / vs.size())
			for vi in range(0, vs.size(), SKIN_STEP):
				var o := vi * per
				# (the bind that moves it most says what it's part of)
				var best := 0
				for k in range(1, per):
					if ws[o + k] > ws[o + best]:
						best = k
				var bb := int(bs[o + best])
				if bb < 0 or bb >= bx.size() or kind[bb] == 2:
					continue
				var v := vs[vi]
				var p := Vector3.ZERO
				var tot := 0.0
				for k in per:
					var wv := float(ws[o + k])
					if wv <= 0.0:
						continue
					var bi := int(bs[o + k])
					if bi < 0 or bi >= bx.size():
						continue
					p += (bx[bi] as Transform3D) * v * wv
					tot += wv
				if tot <= 0.0:
					continue
				pts.append(p / tot)
				arm.append(1 if kind[bb] == 1 else 0)
	return [pts, arm]


## The cloth over him as he's drawn now: {rows, rows_free, shade, mesh}.
func _make() -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var L: float = InnRooms.BLANKET_L
	var W: float = float(blanket.get_meta("width", 0.96))
	var npx := NX + 1
	var npz := NZ + 1
	var n := npx * npz
	var hx := L / NX
	var hz := W / NZ
	# the mattress under each point, and him: the highest of his skin by it
	var bed := PackedFloat32Array()
	bed.resize(n)
	for i in npx:
		for j in npz:
			bed[i * npz + j] = mattress_y(-L * 0.5 + i * hx, -W * 0.5 + j * hz) + THICK
	var body := PackedFloat32Array()
	body.resize(n)
	body.fill(-1000.0)
	var body_free := body.duplicate()
	var sk := _skin()
	var pts: PackedVector3Array = sk[0]
	var arm: PackedByteArray = sk[1]
	var under := 0
	for vi in pts.size():
		var p := pts[vi]
		var fi := (p.x + L * 0.5) / hx
		var fj := (p.z + W * 0.5) / hz
		if fi < -1.0 or fi > NX + 1.0 or fj < -1.0 or fj > NZ + 1.0:
			continue
		under += 1
		var i0 := int(floor(fi))
		var j0 := int(floor(fj))
		for di in 2:
			var i := i0 + di
			if i < 0 or i > NX:
				continue
			for dj in 2:
				var j := j0 + dj
				if j < 0 or j > NZ:
					continue
				var k := i * npz + j
				if p.y > body[k]:
					body[k] = p.y
				if arm[vi] == 0 and p.y > body_free[k]:
					body_free[k] = p.y
	if under < 50:
		return {}
	var noise := FastNoiseLite.new()
	noise.seed = 1171
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0
	var high := _cloth(body, bed, npx, npz, hx, hz, L, W, noise)
	var high_free := _cloth(body_free, bed, npx, npz, hx, hz, L, W, noise)
	# (never higher without the arm than with it)
	for k in n:
		if high_free[k] > high[k]:
			high_free[k] = high[k]
	var rows := _points(high, npx, npz, hx, hz, L, W)
	var rows_free := _points(high_free, npx, npz, hx, hz, L, W)
	# how deep in a hollow each point lies: the cloth two squares round it,
	# against it
	var shade := _blur(high, npx, npz, 2)
	for k in n:
		shade[k] = clampf(1.0 - (1.0 - SHADE_LEAST) * (shade[k] - high[k]) / SHADE_DEEP, SHADE_LEAST, 1.0)
	# (soft-edged: a shadow in a fold, not a stain on the wool)
	shade = _blur(shade, npx, npz, 1)
	# how much his breathing lifts each point (blanket.gdshader): most over
	# his chest, some over his middle, across his body's width, none where
	# the cloth's on the mattress
	var breath := PackedFloat32Array()
	breath.resize(n)
	var sk2 := fig._skel
	var to_bl := blanket.global_transform.affine_inverse() * sk2.global_transform
	var chest := to_bl * sk2.get_bone_global_pose(maxi(sk2.find_bone("Spine2"), 0)).origin
	var hips := to_bl * sk2.get_bone_global_pose(maxi(sk2.find_bone("Hips"), 0)).origin
	var belly := chest.lerp(hips, 0.55)
	for i in npx:
		var x := -L * 0.5 + i * hx
		var along := maxf(exp(-pow((x - chest.x) / BREATH_CHEST, 2.0)), 0.6 * exp(-pow((x - belly.x) / BREATH_BELLY, 2.0)))
		for j in npz:
			var z := -W * 0.5 + j * hz
			var k := i * npz + j
			var across := smoothstep(BREATH_WIDE, BREATH_WIDE * 0.4, absf(z - chest.z))
			var over := smoothstep(0.02, 0.07, high[k] - bed[k])
			breath[k] = along * across * over
	var mesh := mesh_of(flat(rows), npx, npz, shade, breath)
	# (what the tests ask after: how near his skin the cloth comes)
	var least := INF
	var through := 0
	for vi in (pts.size() if measure else 0):
		var p := pts[vi]
		var fi := (p.x + L * 0.5) / hx
		var fj := (p.z + W * 0.5) / hz
		if fi < 0.0 or fi > NX or fj < 0.0 or fj > NZ:
			continue
		var i0 := mini(int(fi), NX - 1)
		var j0 := mini(int(fj), NZ - 1)
		var u := fi - i0
		var w := fj - j0
		var y := lerpf(lerpf(high[i0 * npz + j0], high[(i0 + 1) * npz + j0], u), lerpf(high[i0 * npz + j0 + 1], high[(i0 + 1) * npz + j0 + 1], u), w)
		least = minf(least, y - p.y)
		if y < p.y:
			through += 1
	made += 1
	last_ms = (Time.get_ticks_usec() - t0) / 1000.0
	var top := -INF
	for k in n:
		top = maxf(top, high[k])
	last = {"skin": pts.size(), "under": under, "least": least, "through": through, "top": top, "ms": last_ms}
	return {"rows": rows, "rows_free": rows_free, "shade": shade, "breath": breath, "mesh": mesh}


## How high the cloth lies at each point of the grid, over `body` (the
## highest of him by each point, -1000 where he isn't) on `bed`.
func _cloth(body: PackedFloat32Array, bed: PackedFloat32Array, npx: int, npz: int, hx: float, hz: float, L: float, W: float, noise: FastNoiseLite) -> PackedFloat32Array:
	var n := npx * npz
	# held up by him or by the mattress
	var held := PackedFloat32Array()
	held.resize(n)
	for k in n:
		held[k] = maxf(body[k] + CLEAR, bed[k])
	# hung between what holds it up, tightly and loosely
	var tight := _hang(held, npx, npz, TIGHT_ALONG * hx * hx, TIGHT * hz * hz)
	var loose := _hang(held, npx, npz, LOOSE * hx * hx, LOOSE * hz * hz)
	# tightly between the two sides of him (across the bed, from the first
	# of him to the last), loosely outside him and past his feet
	var inside := PackedFloat32Array()
	inside.resize(n)
	for i in npx:
		var first := -1
		var last_j := -1
		for j in npz:
			if body[i * npz + j] + CLEAR > bed[i * npz + j] + 0.03:
				if first < 0:
					first = j
				last_j = j
		if first >= 0:
			for j in range(first, last_j + 1):
				inside[i * npz + j] = 1.0
	for pass_i in 2:
		inside = _soften(inside, npx, npz, 1.0)
	var high := PackedFloat32Array()
	high.resize(n)
	for k in n:
		high[k] = lerpf(loose[k], tight[k], inside[k])
	# down to the mattress by its foot end, as far as his boots let it
	for i in npx:
		var left := L - i * hx
		if left > 0.2:
			continue
		for j in npz:
			var k := i * npz + j
			high[k] = maxf(held[k], minf(high[k], bed[k] + END_FALL * left))
	# folded where it lies loose: long folds down the bed and out from him,
	# coming and going, and small rumples
	var fold := PackedFloat32Array()
	fold.resize(n)
	for i in npx:
		var x := -L * 0.5 + i * hx
		for j in npz:
			var z := -W * 0.5 + j * hz
			var k := i * npz + j
			var slack := clampf((high[k] - (body[k] + CLEAR)) / 0.03, 0.0, 1.0)
			var warp := noise.get_noise_2d(x * 2.3, z * 2.3)
			var ph := TAU * (x * 0.5 + absf(z)) / FOLD_APART + warp * 2.6
			var ridge := pow(0.5 + 0.5 * sin(ph), 3.0)
			var here := smoothstep(-0.3, 0.3, noise.get_noise_2d(x * 1.7 + 9.0, z * 1.7 - 4.0))
			var rum := 0.5 + 0.5 * noise.get_noise_2d(x * 8.0 + 3.0, z * 8.0)
			# (none where it hangs down the mattress's side)
			var on_top := smoothstep(BED_HALF.y + 0.01, BED_HALF.y - 0.05, absf(z))
			# (a third as high where it's drawn over him; none by the hem,
			# where it's pulled flat across his chest)
			var give := (FOLD_OVER_HIM + (1.0 - FOLD_OVER_HIM) * slack) * smoothstep(0.06, 0.3, i * hx)
			fold[k] = on_top * (give * (FOLD * ridge * here + RUMPLE * rum) + (1.0 - give) * 0.0025 * rum)
	fold = _soften(fold, npx, npz, 0.6)
	for k in n:
		high[k] += fold[k]
	# and soft: every crease in it rounded, never into him
	for pass_i in 2:
		var soft := _soften(high, npx, npz, 0.5)
		for k in n:
			high[k] = maxf(soft[k], held[k])
	return high


## A sheet hung over `f`: held up at every point, bending no more sharply
## than `ax` along the bed and `az` across it (each in squares: the sag per
## square, squared). Up by the bend and down by it again (a closing by a
## parabola).
static func _hang(f: PackedFloat32Array, npx: int, npz: int, ax: float, az: float) -> PackedFloat32Array:
	var neg := PackedFloat32Array()
	neg.resize(f.size())
	for k in f.size():
		neg[k] = -f[k]
	var up := _least(neg, npx, npz, ax, az)
	for k in up.size():
		up[k] = -up[k]
	return _least(up, npx, npz, ax, az)


## For each point, the least of f(q) + ax * di * di + az * dj * dj over
## every other point q: along the lines across the bed, then along the
## lines down it (Felzenszwalb and Huttenlocher's lower envelope of
## parabolas: once along each line).
static func _least(f: PackedFloat32Array, npx: int, npz: int, ax: float, az: float) -> PackedFloat32Array:
	var out := f.duplicate()
	var most := maxi(npx, npz)
	var line := PackedFloat32Array()
	line.resize(most)
	var v := PackedInt32Array()
	v.resize(most)
	var zz := PackedFloat32Array()
	zz.resize(most + 1)
	for pass_i in 2:
		var cnt := npz if pass_i == 0 else npx        # points along a line
		var lines := npx if pass_i == 0 else npz
		var step := 1 if pass_i == 0 else npz
		var a := az if pass_i == 0 else ax
		for li in lines:
			var base := li * npz if pass_i == 0 else li
			for q in cnt:
				line[q] = out[base + q * step]
			var k := 0
			v[0] = 0
			zz[0] = -INF
			zz[1] = INF
			for q in range(1, cnt):
				var s := ((line[q] + a * q * q) - (line[v[k]] + a * v[k] * v[k])) / (2.0 * a * (q - v[k]))
				while s <= zz[k]:
					k -= 1
					s = ((line[q] + a * q * q) - (line[v[k]] + a * v[k] * v[k])) / (2.0 * a * (q - v[k]))
				k += 1
				v[k] = q
				zz[k] = s
				zz[k + 1] = INF
			k = 0
			for q in cnt:
				while zz[k + 1] < q:
					k += 1
				var d := q - v[k]
				out[base + q * step] = a * d * d + line[v[k]]
	return out


## `f` with each point drawn `by` of the way to the mean of those round it
## (one square each way).
static func _soften(f: PackedFloat32Array, npx: int, npz: int, by: float) -> PackedFloat32Array:
	var mean := _blur(f, npx, npz, 1)
	for k in f.size():
		mean[k] = lerpf(f[k], mean[k], by)
	return mean


## The mean of `f` over `r` squares each way: across the bed, then down it
## (the edge's own value stands in past the edge).
static func _blur(f: PackedFloat32Array, npx: int, npz: int, r: int) -> PackedFloat32Array:
	var mid := f.duplicate()
	var w := 1.0 / (2 * r + 1)
	for i in npx:
		var base := i * npz
		for j in npz:
			var sum := 0.0
			for d in range(-r, r + 1):
				sum += f[base + clampi(j + d, 0, npz - 1)]
			mid[base + j] = sum * w
	var out := f.duplicate()
	for i in npx:
		for j in npz:
			var sum := 0.0
			for d in range(-r, r + 1):
				sum += mid[clampi(i + d, 0, npx - 1) * npz + j]
			out[i * npz + j] = sum * w
	return out


## The cloth's points from how high it lies: its hem a little askew and
## turned back in a roll, its sides hung down over the mattress's edge.
func _points(high: PackedFloat32Array, npx: int, npz: int, hx: float, hz: float, L: float, W: float) -> Array:
	var rows: Array = []
	for i in npx:
		var x0 := -L * 0.5 + i * hx
		var row: Array = []
		for j in npz:
			var z := -W * 0.5 + j * hz
			var vv := z / (W * 0.5)
			# the hem lies further down him in places (never further up:
			# the cloth's height is known only under the blanket)
			var askew := HEM_ASKEW * (0.5 + 0.32 * sin(vv * 2.1 + 0.6) + 0.18 * sin(vv * 5.3 + 2.0))
			var x := x0 + askew * smoothstep(0.4, 0.0, i * hx)
			# the roll of the turned-back hem: its edge tucked in under and
			# down onto him, the roll behind it, and off into the cloth
			var from_hem := i * hx
			if i == 0:
				x += hx * 0.45
			var fi := clampf((x + L * 0.5) / hx, 0.0, npx - 1.001)
			var i0 := int(fi)
			var u := fi - i0
			var y := lerpf(high[i0 * npz + j], high[(i0 + 1) * npz + j], u)
			if i > 0 and from_hem < HEM_REACH + hx:
				y += HEM_ROLL * smoothstep(HEM_REACH + hx, hx * 0.6, from_hem) * smoothstep(1.0, 0.75, absf(vv))
			# over the mattress's edge and down its side
			var over := absf(z) - (BED_HALF.y + 0.004)
			if over > 0.0:
				z = signf(z) * (BED_HALF.y + 0.004 + over * 0.3)
			row.append(Vector3(x, y, z))
		rows.append(row)
	return rows


## A grid of points as one run (row by row).
static func flat(rows: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	if rows.is_empty():
		return out
	var npz := (rows[0] as Array).size()
	out.resize(rows.size() * npz)
	var k := 0
	for row: Array in rows:
		for p: Vector3 in row:
			out[k] = p
			k += 1
	return out


static var _grids := {}

## The blanket's mesh from its points (as laid, or wherever BlanketThrow or
## BlanketTent have them this frame): `npx` rows of `npz`, row by row. Its
## triangles and its cloth's own coordinates are made once for a size of
## grid; each point's normal is from the points either side of it, so the
## cloth is shaded as one soft surface. In each point's colour: `shade` (r:
## 1 in the open .. SHADE_LEAST deep in a fold) and `breath` (g: how much his
## breathing lifts it, blanket.gdshader). With `fringe`, its two ends are
## fringed (a second surface: _fringe).
static func mesh_of(pts: PackedVector3Array, npx: int, npz: int, shade := PackedFloat32Array(), breath := PackedFloat32Array(), fringe := true) -> ArrayMesh:
	var n := npx * npz
	var key := Vector2i(npx, npz)
	if not _grids.has(key):
		var uvs := PackedVector2Array()
		uvs.resize(n)
		var idx := PackedInt32Array()
		var ia := PackedInt32Array()
		var ib := PackedInt32Array()
		var ja := PackedInt32Array()
		var jb := PackedInt32Array()
		ia.resize(n)
		ib.resize(n)
		ja.resize(n)
		jb.resize(n)
		for i in npx:
			for j in npz:
				var k := i * npz + j
				uvs[k] = Vector2(float(i) / (npx - 1), float(j) / (npz - 1))
				ia[k] = maxi(i - 1, 0) * npz + j
				ib[k] = mini(i + 1, npx - 1) * npz + j
				ja[k] = i * npz + maxi(j - 1, 0)
				jb[k] = i * npz + mini(j + 1, npz - 1)
				if i < npx - 1 and j < npz - 1:
					var a := k
					var b := k + npz
					var c := k + npz + 1
					var d := k + 1
					idx.append_array(PackedInt32Array([a, c, b, a, d, c]))
		_grids[key] = [uvs, idx, ia, ib, ja, jb]
	var g: Array = _grids[key]
	var ia: PackedInt32Array = g[2]
	var ib: PackedInt32Array = g[3]
	var ja: PackedInt32Array = g[4]
	var jb: PackedInt32Array = g[5]
	# (pointing down, as SurfaceTool.generate_normals had them for these
	# triangles: their front is the cloth's underside, and seen from above
	# (cull_disabled) the engine turns the normal round. Pointing up, it was
	# turned round to point down, and the cloth seen from above was lit as
	# if from under it: near black in the attic, but for the candle's red.)
	var nrm := PackedVector3Array()
	nrm.resize(n)
	for k in n:
		nrm[k] = (pts[ib[k]] - pts[ia[k]]).cross(pts[jb[k]] - pts[ja[k]]).normalized()
	var cols := PackedColorArray()
	cols.resize(n)
	var has_s := shade.size() == n
	var has_b := breath.size() == n
	for k in n:
		cols[k] = Color(shade[k] if has_s else 1.0, breath[k] if has_b else 0.0, 0.0, 1.0)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pts
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_TEX_UV] = g[0]
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = g[1]
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if fringe and npz > 2:
		var fa := _fringe(pts, npx, npz)
		if not fa.is_empty():
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fa)
	return m


## The fringe at the blanket's two ends (18 November, Gary's yes: "a real
## wool picture with fringed ends"): a tassel of yarn every half square
## along each end, FRINGE_M long, FRINGE_W wide, going on the way the cloth
## goes at its end and falling under its weight (the foot end's hangs over
## the mattress's end; the hem's, turned back on his chest, lies along it,
## stiffer and shorter), never into the mattress, nor past the footboard.
const FRINGE_M := 0.05
const FRINGE_HEM_M := 0.035
const FRINGE_W := 0.0075
const FRINGE_SEGS := 4
const FRINGE_FALL := 0.8
const FRINGE_HEM_FALL := 0.18
## (the footboard's inner face, in the blanket's frame: InnRooms._bed)
const FOOTBOARD_X := 0.735

static func _fringe(pts: PackedVector3Array, npx: int, npz: int) -> Array:
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var uv := PackedVector2Array()
	var cs := PackedColorArray()
	var idx := PackedInt32Array()
	for end in 2:
		var row := 0 if end == 0 else npx - 1
		var inner := 1 if end == 0 else npx - 2
		var length := FRINGE_HEM_M if end == 0 else FRINGE_M
		var fall := FRINGE_HEM_FALL if end == 0 else FRINGE_FALL
		var u := 0.0 if end == 0 else 1.0
		for t in range((npz - 1) * 2 + 1):
			var jf := t * 0.5
			var j0 := int(floor(jf))
			var j1 := mini(j0 + 1, npz - 1)
			var w := jf - j0
			var p: Vector3 = pts[row * npz + j0].lerp(pts[row * npz + j1], w)
			var q: Vector3 = pts[inner * npz + j0].lerp(pts[inner * npz + j1], w)
			var out := (p - q)
			if out.length() < 1e-5:
				continue
			out = out.normalized()
			var ja := maxi(j0 - 1, 0)
			var jb := mini(j0 + 2, npz - 1)
			var across: Vector3 = (pts[row * npz + jb] - pts[row * npz + ja]).normalized()
			# (each its own: a little longer or shorter, a little aside)
			var h := fposmod(sin(float(t) * 12.9898 + float(end) * 78.233) * 43758.5453, 1.0)
			var len_k := 0.8 + 0.4 * h
			var aside := across * (h - 0.5) * 0.12
			var at := p
			var prev := p
			var base := vs.size()
			for sgi in FRINGE_SEGS + 1:
				var k := float(sgi) / FRINGE_SEGS
				if sgi > 0:
					var d := (out + aside).lerp(Vector3.DOWN, clampf(k * 1.4, 0.0, 1.0) * fall).normalized()
					at += d * (length * len_k / FRINGE_SEGS)
					# never into the mattress, nor past the footboard
					var floor_y := mattress_y(at.x, at.z) + 0.002
					var on_bed := absf(at.x + BED_X) < BED_HALF.x and absf(at.z) < BED_HALF.y
					if on_bed and at.y < floor_y:
						at.y = floor_y
					at.x = minf(at.x, FOOTBOARD_X)
				var dir := out
				if sgi > 0 and at.distance_to(prev) > 1e-6:
					dir = (at - prev).normalized()
				prev = at
				var half := across * FRINGE_W * 0.5 * (1.0 - 0.45 * k)
				var nn := across.cross(dir).normalized()
				if nn.y > 0.0:
					nn = -nn   # (as the cloth's: the engine turns it round for the side that's seen)
				vs.append(at - half)
				vs.append(at + half)
				ns.append(nn)
				ns.append(nn)
				uv.append(Vector2(u, clampf((jf - 0.2) / (npz - 1), 0.0, 1.0)))
				uv.append(Vector2(u, clampf((jf + 0.2) / (npz - 1), 0.0, 1.0)))
				var sh := 0.92 - 0.25 * k
				cs.append(Color(sh, 0.0, 0.0, 1.0))
				cs.append(Color(sh, 0.0, 0.0, 1.0))
				if sgi > 0:
					var a := base + (sgi - 1) * 2
					idx.append_array(PackedInt32Array([a, a + 1, a + 3, a, a + 3, a + 2]))
	if vs.is_empty():
		return []
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_COLOR] = cs
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


## How much his breathing lifts each point of a grid this size (what was
## laid), or none.
static func breath_of(bl: MeshInstance3D, n: int) -> PackedFloat32Array:
	var s = bl.get_meta("breath", null) if bl != null and is_instance_valid(bl) else null
	if s is PackedFloat32Array and (s as PackedFloat32Array).size() == n:
		return s
	return PackedFloat32Array()


## The blanket's shade for a grid this size (what was laid), or none.
static func shade_of(bl: MeshInstance3D, n: int) -> PackedFloat32Array:
	var s = bl.get_meta("shade", null) if bl != null and is_instance_valid(bl) else null
	if s is PackedFloat32Array and (s as PackedFloat32Array).size() == n:
		return s
	return PackedFloat32Array()
