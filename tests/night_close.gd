extends Node
## Close-ups of two moments of the night (6 November, Gary's notes), as any
## of the four looks: "heave" (the hay cart going over on Corin, and the
## heave that lifts it off him: the player's hands on the cart, the cart
## coming up with each HEAVE, the PULL) and "wake" (the attic after the
## white light, AshfordNight.awakening: lying under the blanket, sitting up,
## the bed's edge, Bram sat beside them, his face). Each still is the game's
## own shot plus the close-ups for that part, from a camera of the test's
## own (the game's camera carries on as it was).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/night_close.tscn -- <dir> <heave|wake> [look=a] [every=10] [from=0] [to=99999] [choice=0]
## heave: a still at every second HEAVE and at the PULL (plus every=<frames> through the fall).
## wake: a still every <every> frames between from= and to= (frames); every=0:
## a still of each line as it comes up, from the from=th to the to=th, and done.

var out := "/tmp/night"
var part := "heave"
var look := "a"
var every := 10
var from := 0
var to := 99999
var choice := 0
var world: World
var cam: Camera3D
var _frame := 0
var _heaves := 0
var _busy := false
var _done := false
var _line_frames := 0
var _grip_mid := Vector3.ZERO
var _lines := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		part = args[1]
	for a in args.slice(2):
		var s := String(a)
		if s.begins_with("look="):
			look = s.substr(5)
		elif s.begins_with("every="):
			every = int(s.substr(6))
		elif s.begins_with("from="):
			from = int(s.substr(5))
		elif s.begins_with("to="):
			to = int(s.substr(3))
		elif s.begins_with("choice="):
			choice = int(s.substr(7))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Rowan", "")
	Game.settings["first_steps"] = 2
	Game.set_flag("look", look)
	for f in ["arrived_ashford", "ash_started", "ash_tam", "ash_tilly", "ash_nell", "ash_ready", "tilly_talked", "ash_evening",
			"first_deck", "has_lantern_moth", "moth_given"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	if part == "wake":
		for f in ["ash_lantern_duel", "ash_won_lantern", "ash_marked"]:
			Game.set_flag(f)
		Game.set_flag("pro_part", "awakening")
	world = World.new().setup("ashford", "green")
	world.story_next.connect(func(_w: String) -> void: _finish())
	add_child(world)
	cam = Camera3D.new()
	add_child(cam)
	for i in 20:
		await get_tree().process_frame
	print("NIGHT CLOSE: %s, look %s, model %s" % [part, look, (world.player_doll as Figure3D)._model_name if world.player_doll is Figure3D else "?"])
	if part == "heave":
		await _heave_run()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	print("NIGHT CLOSE: done in %s" % out)
	get_tree().quit()


# ---------------------------------------------------------------- heave ---

func _heave_run() -> void:
	var w := world
	var A: GDScript = w.area
	var v: AshfordVillage = w.get_meta("village")
	await Cine.begin(w)
	AshfordP1.undress(w)
	A._stage(w, A.MID)
	v.set_daylight(0.0)
	v.set_time("night")
	v.light_great_lantern()
	v.start_sigilfall()
	v.tear = 0.999
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	# the cart standing, with the people by it, for its size against them
	Cine.place(w, "corin", cc + fd * 2.0 + al * 0.4, cc)
	Cine.place(w, "tilly", cc + fd * 2.2 - al * 1.4, cc)
	Cine.place(w, "player", cc + fd * 2.4 + al * 2.6, cc)
	for i in 8:
		await get_tree().process_frame
	await _views("0_standing", cc)
	# Corin pinned, as the film leaves him (the cart over on him)
	v.set_cart_tip(1.0)
	var corin_at: Vector3 = cc + fd * A.CART_PIN
	Cine.place(w, "corin", corin_at, cc)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).pose("fall", A.CORIN_DOWN, 0.0)
	Cine.place(w, "tilly", cc + fd * (A.CART_PIN + 0.1) + al * 1.7 + Vector3(0.5, 0, 0.6), corin_at)
	Cine.place(w, "player", A.RUN_END, cc)
	for i in 8:
		await get_tree().process_frame
	await _views("1_pinned", cc)
	await A._the_heave(w)
	await _views("9_after", cc)


## Drives the heave: a press every third frame, a still at every second
## press, the pull in the gold.
func _process(_d: float) -> void:
	_frame += 1
	if world == null or _done:
		return
	# tap through lines and choices
	if world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		if ov._waiting:
			_line_frames += 1
			if _line_frames > 6 and not _busy:
				_line_frames = 0
				ov._next.emit()
		else:
			_line_frames = 0
		if ov._choices.visible and ov._choices.get_child_count() > 0 and not _busy:
			ov._chosen.emit(mini(choice, ov._choices.get_child_count() - 1))
	if world.hud != null and world.hud.dialogue._waiting and not _busy:
		world.hud.dialogue._advance.emit()
	if _busy:
		return
	for q in get_tree().root.find_children("*", "CartHeave", true, false):
		var qh := q as CartHeave
		if qh.phase == "heave" and _frame % 2 == 0:
			qh.heave()
			_heaves += 1
			if _heaves % 4 == 0:
				_snap_heave("2_heave_%02d" % _heaves)
		elif qh.phase == "pull":
			var g := qh.gold()
			if qh.marker > g.x + 0.03 and qh.marker < g.y - 0.03:
				_snap_heave("3_before_pull")
				qh.pull()
				_after_pull()
	if part == "wake" and every > 0 and _frame % every == 0 and _frame >= from and _frame <= to:
		_snap_wake("f%05d" % _frame)
	# wake: a still of every line as it comes up (from the from=th line)
	if part == "wake" and every == 0 and world.has_meta("cine_overlay"):
		var ov2: CineOverlay = world.get_meta("cine_overlay")
		if ov2._waiting and _line_frames == 3:
			_lines += 1
			if _lines >= from and _lines <= to:
				_snap_wake("l%03d" % _lines)
			elif _lines > to:
				_finish()


func _snap_heave(tag: String) -> void:
	var v: AshfordVillage = world.get_meta("village")
	_views(tag, v.cart_centre())


func _after_pull() -> void:
	for i in 4:
		await get_tree().create_timer(0.4).timeout
		_snap_heave("4_pull_%d" % i)


## The game's shot, then the test's own: across the cart's fall (its side),
## along it from the open side, and close on the player's hands.
func _views(tag: String, cc: Vector3) -> void:
	if _busy:
		return
	_busy = true
	var v: AshfordVillage = world.get_meta("village")
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	var pfd = world.player_doll
	if pfd is Figure3D:
		var gs: Array = []
		for g in world.get_tree().root.find_children("*HeaveGrip*", "", true, false):
			gs.append((g as Node3D).global_position)
			if "marks" in OS.get_cmdline_user_args() and not (g as Node).has_node("Mark"):
				var mk := MeshInstance3D.new()
				mk.name = "Mark"
				var sm := SphereMesh.new()
				sm.radius = 0.025
				sm.height = 0.05
				mk.mesh = sm
				var mm := StandardMaterial3D.new()
				mm.albedo_color = Color(1, 0, 1)
				mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mk.material_override = mm
				mk.top_level = true
				(g as Node).add_child(mk)
			if (g as Node).has_node("Mark"):
				((g as Node).get_node("Mark") as Node3D).global_position = (g as Node3D).global_position
		if gs.size() > 0:
			_grip_mid = Vector3.ZERO
			for q in gs:
				_grip_mid += q / float(gs.size())
		print("%s: grips %s hands %s %s shoulders %s %s player %s tip %.2f" % [tag, gs, (pfd as Figure3D).bone_pos("LeftHand"), (pfd as Figure3D).bone_pos("RightHand"),
			(pfd as Figure3D).bone_pos("LeftArm"), (pfd as Figure3D).bone_pos("RightArm"), world.player.global_position, v.hay_cart_tip])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_game.png" % [out, tag])
	var shots := {
		"side": [cc + fd * 2.4 - al * 4.5 + Vector3(0, 1.0, 0), cc + fd * 2.0 + Vector3(0, 0.6, 0), 42.0],
		"open": [cc + fd * 8.0 - al * 1.5 + Vector3(0, 1.4, 0), cc + fd * 2.5 + Vector3(0, 0.9, 0), 40.0],
	}
	var pf = world.player_doll
	if pf is Figure3D:
		var h: Vector3 = _grip_mid if _grip_mid != Vector3.ZERO else ((pf as Figure3D).bone_pos("RightHand") + (pf as Figure3D).bone_pos("LeftHand")) * 0.5
		var to_c := cc - world.player.global_position
		to_c.y = 0.0
		to_c = to_c.normalized()
		shots["hands"] = [h - to_c * 1.3 + to_c.cross(Vector3.UP) * 1.1 + Vector3(0, 0.35, 0), h, 38.0]
	for k in shots:
		var s: Array = shots[k]
		cam.global_position = s[0]
		cam.look_at(s[1], Vector3.UP)
		cam.fov = s[2]
		cam.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, k])
	world.cam.make_current()
	_busy = false


# ----------------------------------------------------------------- wake ---

## The game's shot, then the bed from the side and the foot, and Bram's
## face close (in front of him, and from his left at three-quarters).
func _snap_wake(tag: String) -> void:
	if _busy:
		return
	_busy = true
	var v: AshfordVillage = world.get_meta("village")
	var a := InnRooms.attic(v)
	var bed: Vector3 = a.bed
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_game.png" % [out, tag])
	var shots := {
		"side": [bed + Vector3(0.0, 0.6, 2.6), bed + Vector3(0.0, 0.3, 0.0), 44.0],
		"foot": [bed + Vector3(2.7, 1.0, 0.4), bed + Vector3(-0.3, 0.35, 0.0), 42.0],
	}
	var bf = Cine.fig(world, "bram")
	if bf is Figure3D and (bf as Figure3D).is_visible_in_tree():
		var hd: Vector3 = (bf as Figure3D).bone_pos("Head") + Vector3(0, 0.07, 0)
		var fw: Vector3 = (bf as Figure3D).facing()
		shots["bram_face"] = [hd + fw * 0.75 + Vector3(0, 0.02, 0), hd, 30.0]
		shots["bram_34"] = [hd + fw * 0.6 + fw.cross(Vector3.UP) * -0.45 + Vector3(0, 0.05, 0), hd, 30.0]
	for k in shots:
		var s: Array = shots[k]
		cam.global_position = s[0]
		cam.look_at(s[1], Vector3.UP)
		cam.fov = s[2]
		cam.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, k])
	world.cam.make_current()
	_busy = false
