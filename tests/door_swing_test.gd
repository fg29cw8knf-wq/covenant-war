extends Node
## The inn's front door opening as the player leaves with the crate
## (AshfordP1._taproom's end; 8 November, Gary: "Door passes through player
## when it opens before leaving inn"): the game picked up at the taproom
## (the porridge already eaten), Bram's lines tapped through, the crate
## taken, the door tapped, the menu line at the door tapped on; then every
## frame from the door's first move until the picture is black, the leaf
## (its box, as hung on the hinge) against the player's capsule and against
## the crate in their arms, and a still every few frames. Also checked: the
## player only passes the doorway once the leaf is open.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/door_swing_test.tscn -- <out_dir> [every=3]
## Ends "DOOR SWING: ok" or the problems.

const BODY_R := 0.35      # the player's capsule (World._spawn_player)
const LEAF_T := 0.07      # the leaf's thickness (InnRooms.eve)

var out := "/tmp/door"
var every := 3
var world: World
var hud: WorldHUD
var e: Dictionary
var problems: Array = []
var _n := 0
var _wait := 0
var _hold_line := false   # (the menu line at the door: tapped on by the loop that watches the leaf)

const WALL_CAP_MS := 420000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	for s in a.slice(1):
		if String(s).begins_with("every="):
			every = int(String(s).substr(6))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 2
	Game.set_flag("p1_stage", "taproom")
	Game.set_flag("p1_ate")
	world = World.new().setup("ashford", "green")
	add_child(world)
	hud = world.hud
	await _frames(20)
	await _run()
	print("DOOR SWING: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _process(_d: float) -> void:
	# (a hard cap on the wall clock: a gate that never opens must not hold
	# the machine's one Godot for good)
	if Time.get_ticks_msec() > WALL_CAP_MS:
		print("DOOR SWING: timed out on the wall clock (%d s)" % (WALL_CAP_MS / 1000))
		get_tree().quit(2)
		return
	if world == null or hud == null:
		return
	if hud.dialogue._waiting and not _hold_line:
		_wait += 1
		if _wait > 6:
			_wait = 0
			hud.dialogue._advance.emit()
	if hud.dialogue._choices.visible:
		hud.dialogue._chosen.emit(0)


func _run() -> void:
	await _until(func() -> bool: return String(Game.flag("objective_key", "")) == "take_crate" and world.get_meta("village", null) != null and (world.get_meta("village") as Node).has_meta("eve"), 120.0, "the crate's turn")
	if not problems.is_empty():
		return
	e = world.get_meta("village").get_meta("eve")
	var root: Node3D = e.root
	var cr: Node3D = e.crate
	var corner := root.to_global(Vector3(3.55, 0, -2.85))
	await _secs(0.8)
	# their own walk to the crate's corner, then a tap on the crate
	hud.tapped.emit(world.cam.unproject_position(corner + Vector3(-0.6, 0, 0.4)))
	await _until(func() -> bool: return Vector2(world.player.global_position.x - corner.x, world.player.global_position.z - corner.z).length() < 1.15, 30.0, "the walk to the crate")
	var t := 0.0
	while not world.has_meta("p1_crate") and t < 20.0:
		await _secs(0.5)
		t += 0.5
		if not world.has_meta("p1_crate"):
			hud.tapped.emit(world.cam.unproject_position(cr.global_position))
	if not world.has_meta("p1_crate"):
		problems.append("the crate was never taken")
		return
	await _until(func() -> bool: return String(Game.flag("objective_key", "")) == "green_crate" and world.hud.pad.visible and world.player.global_position.y < -20.0, 30.0, "the walk to the door")
	await _secs(0.6)
	await _shot("crate_in_arms")
	# a tap at the door
	_hold_line = true
	hud.tapped.emit(world.cam.unproject_position(e.door_in))
	await _until(func() -> bool: return hud.dialogue.visible and "stops the game" in hud.dialogue._text.text, 60.0, "the menu line at the door")
	if not problems.is_empty():
		return
	await _secs(0.4)
	await _shot("at_door_menu")
	var door: Node3D = e.door
	var crate: Node3D = world.get_meta("p1_crate") if world.has_meta("p1_crate") else null
	var crate_box = _mesh_box(crate) if crate != null else null   # (an AABB, or null)
	print("  stand for the menu: %s (room), %.2f m from the hinge, the door's swing reaches %.2f m" % [
		root.to_local(world.player.global_position).snapped(Vector3(0.01, 0.01, 0.01)),
		Vector2(world.player.global_position.x - door.global_position.x, world.player.global_position.z - door.global_position.z).length(), _leaf_len(door)])
	# the line's tapped on here, so the leaf's first frames are seen; from
	# its first move to black
	var ov := Cine.overlay(world)
	_hold_line = false
	hud.dialogue._advance.emit()
	var f := 0
	var moved := false
	var passed_at := -1.0
	var open_at := -1.0
	var worst := 0.0
	var worst_crate := 0.0
	var worst_f := 0
	var dz_in := root.to_local(door.global_position).z   # the wall's line
	t = 0.0
	while t < 12.0:
		await get_tree().process_frame
		f += 1
		t += get_process_delta_time()
		var ang := rad_to_deg(door.rotation.y)
		if absf(ang) > 0.5 and not moved:
			moved = true
			print("  the leaf starts to move at frame %d" % f)
		if not moved:
			continue
		if ang > 99.0 and open_at < 0.0:
			open_at = t
		var p := world.player.global_position
		var lp := root.to_local(p)
		if lp.z < dz_in and passed_at < 0.0:
			passed_at = t
			print("  the player passes the doorway at %.2f s (the leaf at %.0f deg)" % [t, ang])
			if ang < 95.0:
				problems.append("the player went through the doorway with the leaf at %.0f deg" % ang)
		# the leaf's box in the floor plane (it only turns about the upright)
		var d := _leaf_overlap(door, p, BODY_R)
		if d > worst:
			worst = d
			worst_f = f
		if d > 0.0:
			problems.append("frame %d (%.0f deg): the leaf %.1f cm into the player's capsule" % [f, ang, d * 100.0])
		if crate != null and is_instance_valid(crate) and crate_box != null:
			var dc := _leaf_in_box(door, crate, crate_box)
			if dc > worst_crate:
				worst_crate = dc
			if dc > 0.0:
				problems.append("frame %d (%.0f deg): the leaf %.1f cm into the crate" % [f, ang, dc * 100.0])
		if f % every == 0:
			await _shot("f%03d_%03ddeg" % [f, roundi(ang)])
		if ov._black.modulate.a > 0.98 and open_at > 0.0 and t > open_at + 0.5:
			break
		if String(Game.flag("p1_stage", "")) == "street":
			break
	print("  leaf against the capsule: worst %.1f cm (frame %d); against the crate: worst %.1f cm; open at %.2f s, through the doorway at %.2f s" % [worst * 100.0, worst_f, worst_crate * 100.0, open_at, passed_at])
	if not moved:
		problems.append("the door never opened")
	if passed_at < 0.0:
		problems.append("the player never went out")


## How far along the leaf (from the hinge) its box reaches: its first mesh.
func _leaf_len(door: Node3D) -> float:
	for c in door.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			return ((c as MeshInstance3D).mesh as BoxMesh).size.x
	return 1.15


## How deep the leaf's box comes into a round body of radius `r` at `p` (m),
## in the floor plane: 0 if clear.
func _leaf_overlap(door: Node3D, p: Vector3, r: float) -> float:
	var len := _leaf_len(door)
	var o := door.global_position
	var along := -door.global_transform.basis.x.normalized()   # (the leaf hangs to the hinge's -x)
	var a := Vector2(o.x, o.z)
	var b := a + Vector2(along.x, along.z) * len
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var u := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var dist := q.distance_to(a + ab * u) - LEAF_T * 0.5
	return maxf(0.0, r - dist)


## The crate's own box (its meshes' bounds, in its frame).
func _mesh_box(n: Node3D) -> Variant:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var ab := mi.get_aabb()
		var xf := n.global_transform.affine_inverse() * mi.global_transform
		for i in 8:
			var c := xf * ab.get_endpoint(i)
			if first:
				box = AABB(c, Vector3.ZERO)
				first = false
			else:
				box = box.expand(c)
	return null if first else box


## How far the leaf's box reaches into `box` (in `n`'s frame): sampled along
## the leaf's length and height, each point's depth inside the box grown by
## the leaf's half thickness; 0 if clear.
func _leaf_in_box(door: Node3D, n: Node3D, box: AABB) -> float:
	var len := _leaf_len(door)
	var inv := n.global_transform.affine_inverse()
	var g := box.grow(LEAF_T * 0.5)
	var worst := 0.0
	var steps := int(len / 0.02)
	for i in steps + 1:
		var s := len * float(i) / float(steps)
		for y in [0.3, 0.6, 0.9, 1.2, 1.5]:
			var wp := door.to_global(Vector3(-s, y, 0.0))
			var lp := inv * wp
			if g.has_point(lp):
				var e2 := g.end - lp
				var s2 := lp - g.position
				var depth := minf(minf(minf(e2.x, e2.y), e2.z), minf(minf(s2.x, s2.y), s2.z))
				worst = maxf(worst, depth)
	return worst


func _shot(label: String) -> void:
	_n += 1
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))


func _until(cond: Callable, secs: float, what: String) -> void:
	var t := 0.0
	var said := 0.0
	while not cond.call() and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t - said > 4.0:
			said = t
			var lp := (e.root as Node3D).to_local(world.player.global_position) if not e.is_empty() else world.player.global_position
			print("  ... waiting for %s: %.0f s, stage %s, objective '%s', busy %s, line '%s', player %s" % [what, t, Game.flag("p1_stage", ""), Game.flag("objective_key", ""), world.busy, hud.dialogue._text.text.left(30), lp.snapped(Vector3(0.01, 0.01, 0.01))])
	if not cond.call():
		problems.append("timed out waiting for %s (%.0f s)" % [what, secs])


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
