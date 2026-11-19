extends Node
## The hand to Tilly's card (18 November, Gary: "When player touches Tilly
## card he actually has to reach over and touch it"). The afternoon on the
## green, Tilly by the well with her card held up, the player stood `from`
## metres off her (as far as her talk leaves them: 1.1 to 1.7); the card is
## tapped, and AshfordDay.moth_for_tilly plays. Read every frame inside the
## skeleton's own pass (the pose as drawn): how far the player's right palm
## is from the card. Printed: how far off they stood, how far they stepped
## up, the nearest the palm came, and how far it was when the card woke (its
## glow starting to grow). Stills when drawn: before, the hand on it, the
## moth up.
##
##   godot --headless --fixed-fps 20 --path . res://tests/moth_touch_probe.tscn -- [<dir>] [from=1.6] [look=a|b|c|d] [old]
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 20 --path . res://tests/moth_touch_probe.tscn -- <dir> [from=1.6]
## ("old": they kneel where they stand, as before, to see the gap.)
## Ends "MOTH TOUCH: ok" (the palm within TOUCH of the card as it wakes) or the problems.

const TOUCH := 0.07

var out := ""
var from := 1.6
var world: World
var problems: Array = []
var _palm := Vector3.INF
var _near := INF
var _at_wake := INF
var _woke := false
var _glow0 := Vector3.ZERO
var _n := 0
var _drawn := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		var s := String(a)
		if s.begins_with("from="):
			from = float(s.substr(5))
		elif s.begins_with("look="):
			DollArt.test_look = s.substr(5)
		elif s != "old" and not s.begins_with("--"):
			out = s
	_drawn = DisplayServer.get_name() != "headless" and out != ""
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern", "ash_tam", "tam_letter_seen"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	Game.settings["first_steps"] = 2
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	await _frames(10)
	var tb := Cine.body(world, "tilly")
	if tb == null:
		problems.append("no Tilly on the green")
		_end()
		return
	# the player `from` off her, on the green's side of her
	var tp := tb.global_position
	var away := Vector3(-tp.x, 0.0, -tp.z).normalized()
	AshfordP1.put(world, "player", tp + away * from, tp)
	Cine.look(world, "tilly", world.player.global_position)
	await _frames(10)
	world.busy = true
	# (18 November: the body check on her as she reacts, her hands at her face)
	_bc = load("res://tests/body_check.gd").watch(world, (args[0] + "/body") if args.size() > 0 and not String(args[0]).contains("=") else "")
	await AshfordP1.tilly_up(world)
	var card: Node3D = world.get_meta("tilly_card_node")
	var pf = world.player_doll
	if pf is Figure3D and (pf as Figure3D)._skel != null:
		(pf as Figure3D)._skel.skeleton_updated.connect(func() -> void:
			_palm = (pf as Figure3D).palm_frame("right").origin)
	var start := world.player.global_position
	var card0 := card.global_position
	print("moth_touch_probe: stood %.2f m from Tilly, %.2f m from her card (on the ground)" % [
		_flat(start, tb.global_position), _flat(start, card0)])
	await _still("1_before")
	var done := [false]
	var run := func() -> void:
		if "old" in args:
			await _old(card)
		else:
			await AshfordDay.moth_for_tilly(world)
		done[0] = true
	run.call()
	# the card tapped, once the Use is armed
	await _frames(12)
	var t := 0.0
	var tapped := 0
	var cg := card.get_node_or_null("CardGlow") as Node3D
	_glow0 = cg.scale if cg != null else Vector3.ONE
	var stilled := {}
	while not done[0] and t < 40.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if tapped < 12 and int(t * 2.0) > tapped and not _woke:
			tapped += 1
			# (a tap in the first 300 ms by the clock after the card's offered
			# isn't taken: headless, the game's seconds go by in milliseconds)
			if tapped == 1:
				OS.delay_msec(350)
			if world.cam != null and not world.cam.is_position_behind(card.global_position):
				world.hud.tapped.emit(world.cam.unproject_position(card.global_position))
		if _palm != Vector3.INF and is_instance_valid(card):
			var d := _palm.distance_to(card.global_position)
			_near = minf(_near, d)
			if cg != null and not _woke and cg.scale.x > _glow0.x * 1.02:
				_woke = true
				_at_wake = d
				print("moth_touch_probe: the card wakes with the palm %.1f cm from it; they stand %.2f m from the card (stepped up %.2f m)" % [
					d * 100.0, _flat(world.player.global_position, card.global_position), _flat(start, world.player.global_position)])
				await _still("2_the_hand_on_it")
				await _still_close("2_the_hand_on_it_close", card)
		# (18 November: her gasp, and her smile as it goes round her head)
		var tf = Cine.fig(world, "tilly")
		if tf is Figure3D:
			_gasp = maxf(_gasp, (tf as Figure3D).jaw_now())
			_toes = maxf(_toes, (tf as Figure3D).tiptoe_now())
			_smile = maxf(_smile, (tf as Figure3D).smile_now())
			if (tf as Figure3D).jaw_now() > AshfordDay.TILLY_GASP * 0.9 and not stilled.has("gasp"):
				stilled["gasp"] = true
				await _still_face("3a_her_gasp", tf as Figure3D)
				await _frames(4)
				await _still_body("3a_her_gasp_body", tf as Figure3D)
			if (tf as Figure3D).smile_now() > 0.98 and (tf as Figure3D).jaw_now() < 0.02 and not stilled.has("smile"):
				stilled["smile"] = true
				await _frames(10)
				await _still_face("3b_her_smile", tf as Figure3D)
				await _still_body("3b_her_smile_body", tf as Figure3D)
		if _woke and not stilled.has("moth") and t > 0.0 and cg != null and cg.scale.x > _glow0.x * 2.2:
			stilled["moth"] = true
			await _frames(14)
			await _still("3_the_moth_up")
	print("moth_touch_probe: the nearest the palm came to the card %.1f cm; when it woke %.1f cm" % [_near * 100.0, _at_wake * 100.0])
	print("moth_touch_probe: Tilly's mouth opened to %.2f and her smile came to %.2f" % [_gasp, _smile])
	print("moth_touch_probe: Tilly up on her toes %.2f, her hands to her mouth %s; the body check on her: %d findings" % [_toes, str(AshfordDay.tilly_hands_up), _tilly_finds()])
	if _toes < 0.9 or not AshfordDay.tilly_hands_up:
		problems.append("Tilly's body didn't react (her toes %.2f, her hands up %s)" % [_toes, str(AshfordDay.tilly_hands_up)])
	if _tilly_finds() > 0:
		problems.append("the body check found Tilly through something %d times" % _tilly_finds())
	if not AshfordDay.tilly_gasped or _gasp < AshfordDay.TILLY_GASP * 0.9 or _smile < 0.98:
		problems.append("Tilly didn't gasp and smile (her mouth %.2f, her smile %.2f)" % [_gasp, _smile])
	if not _woke:
		problems.append("the card never woke")
	elif _at_wake > TOUCH:
		problems.append("the card woke with the hand %.1f cm from it" % (_at_wake * 100.0))
	_end()


## As it was until 18 November: down on one knee where they stand, a hand out.
func _old(card: Node3D) -> void:
	await AshfordP1.use(world, card, "moth", 0.0, Vector3.INF, 0.32)
	var pf = world.player_doll
	var tb := Cine.body(world, "tilly")
	var to_t := tb.global_position - world.player.global_position
	to_t.y = 0.0
	to_t = to_t.normalized()
	if pf is Figure3D:
		(pf as Figure3D).pose("lift", 0.42, 0.4)
		var touch := Node3D.new()
		world.add_child(touch)
		touch.global_position = card.global_position - to_t * 0.04
		(pf as Figure3D).reach(null, touch, 0.4)
	await Cine.wait(world, 0.5)
	var cg := card.get_node_or_null("CardGlow") as Node3D
	if cg != null:
		world.create_tween().tween_property(cg, "scale", cg.scale * 2.4, 0.4)
	await Cine.wait(world, 1.2)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _still(nm: String) -> void:
	if not _drawn:
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("moth_touch_probe: still ", nm)


var _gasp := 0.0
var _toes := 0.0
var _bc: Node = null
var _smile := 0.0

## All of her, from in front of her (18 November: her hands and her toes).
func _still_body(nm: String, tf: Figure3D) -> void:
	if not _drawn or world.cam == null:
		return
	var was := world.cam.global_transform
	var fov := world.cam.fov
	var f := tf.facing()
	var mid := tf.global_position + Vector3(0, 0.62, 0)
	world.cam.global_position = mid + Vector3.UP.cross(f) * 2.0 + f * 0.7 + Vector3(0, 0.1, 0)
	world.cam.look_at(mid, Vector3.UP)
	world.cam.fov = 36.0
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	world.cam.global_transform = was
	world.cam.fov = fov


## Her face, close, from a little to one side of the player.
func _still_face(nm: String, tf: Figure3D) -> void:
	if not _drawn or world.cam == null:
		return
	var was := world.cam.global_transform
	var fov := world.cam.fov
	var head := tf.bone_pos("Head") + Vector3(0, 0.06, 0)
	var to_p := world.player.global_position - tf.global_position
	to_p.y = 0.0
	to_p = to_p.normalized()
	# (square on to her face as her head is turned now, the player out of the way)
	var sk := tf._skel
	var hx := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head"))
	var out_of := hx.basis.z.normalized()
	world.cam.global_position = head + out_of * 0.7 + hx.basis.x.normalized() * 0.18
	world.cam.look_at(head + out_of * 0.05, Vector3.UP)
	world.cam.fov = 30.0
	var pd := world.player_doll as Node3D
	pd.visible = false
	await _still(nm)
	pd.visible = true
	world.cam.global_transform = was
	world.cam.fov = fov


## From beside the two of them, close on the card.
func _still_close(nm: String, card: Node3D) -> void:
	if not _drawn or world.cam == null:
		return
	var was := world.cam.global_transform
	var fov := world.cam.fov
	var p := world.player.global_position
	var to_c := card.global_position - p
	to_c.y = 0.0
	var side := to_c.normalized().cross(Vector3.UP)
	world.cam.global_position = card.global_position + side * 1.3 - to_c.normalized() * 0.25 + Vector3(0, 0.25, 0)
	world.cam.look_at(card.global_position - to_c.normalized() * 0.2, Vector3.UP)
	world.cam.fov = 34.0
	await _still(nm)
	world.cam.global_transform = was
	world.cam.fov = fov


func _end() -> void:
	print("MOTH TOUCH: ok" if problems.is_empty() else "MOTH TOUCH: %d problems\n  %s" % [problems.size(), "\n  ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


## What the body check found on Tilly.
func _tilly_finds() -> int:
	var n := 0
	if _bc != null and is_instance_valid(_bc):
		for r: Dictionary in _bc.reported:
			if String(r.get("who", "")) == "tilly":
				n += 1
				print("moth_touch_probe: ", r.get("worst_text", r.get("text", "")))
	return n
