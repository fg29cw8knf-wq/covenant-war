extends Node
## Plays Ashford's Prologue P1 the way a player would and saves a screenshot
## at every step (every line, every answer, every lesson step): New Game in
## the attic, the mirror, Bram in the taproom, the crate to the green, the
## last lantern on the top hook, Tam's barrel and letter, Nell's bench,
## Tilly's moth, Ned and Hob, Corin, Bram's deck, the Lantern Duel (decided
## here: the duel screens have their own tests), the rematch and Tilly's
## gift, stopping as midnight begins. At every gated step it first tries
## what a player shouldn't be able to do yet (a tap beside the thing, the
## pause square before Bram mentions it, talking to Nell before Tam) and
## checks it didn't work. Ends with "ASHFORD TEST: ok" or the problems.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
##       res://tests/ashford_test.tscn -- <out_dir> [part] [options]
##
## part: all (the default: attic to midnight), opening (attic to "Find Tam"),
## green (Tam, Nell, Tilly, Ned and Hob), duel (Corin to Tilly's gift), still
## (two stills of the green), midnight (straight to Corin, then the film).
## options: alt (the second answer at every choice), coach (ask Bram to talk
## you through the duel: no rematch), lose (Corin wins the rematch; it's won
## otherwise), every=<n> (a still every n frames as well), read=<n> (frames
## each line stays up, 6 by default).

var out_dir := "user://"
var part := "all"
var alt := false
var coach := false
var rematch_won := true
var every := 0
var read := 6
var world: World
var hud: WorldHUD
var problems: Array = []
var _shots := 0
var _frame := 0
var _wait := 0
var _last_line := ""
var _uses := {}
var _mask := 0
var _done := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	for a in args.slice(1):
		var s := String(a)
		if s in ["all", "opening", "green", "duel", "still", "midnight"]:
			part = s
		elif s == "alt":
			alt = true
		elif s == "coach":
			coach = true
		elif s == "lose":
			rematch_won = false
		elif s.begins_with("every="):
			every = int(s.substr(6))
		elif s.begins_with("read="):
			read = int(s.substr(5))
		elif s.is_valid_int():
			every = int(s)
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	if part != "all" and part != "opening":
		for f in ["arrived_ashford", "ash_started"]:
			Game.set_flag(f)
		Game.set_flag("p1_stage", "done")
	if part in ["duel", "midnight"]:
		Game.set_flag("ash_tam")
		Game.set_flag("ash_nell")
	world = World.new().setup("ashford", "green")
	world.duel_handler = _duel
	add_child(world)
	hud = world.hud
	world.story_next.connect(func(what: String) -> void:
		print("story_next: ", what)
		_finish())
	await _frames(20)
	match part:
		"still":
			await _shot("still_spawn")
			_teleport(Vector3(-2.0, 0, 4.0))
			await _frames(12)
			await _shot("still_green")
			_finish()
		"midnight":
			await _corin_and_on(true)
		"opening":
			await _opening()
			_finish()
		"green":
			await _green()
			_finish()
		"duel":
			await _corin_and_on(false)
		_:
			await _opening()
			await _green()
			await _corin_and_on(false)


# ============================================================ the opening ===

func _opening() -> void:
	# black, the caption, the attic; the mirror waits for a look
	await _until(func() -> bool: return _picker() != null, 200.0, "the mirror")
	await _secs(1.0)
	await _shot("mirror")
	_expect(not hud._menu_btn.visible, "the pause square shows before Bram has mentioned it")
	var picker := _picker()
	var faces: Array = picker._faces
	await _click(_centre(faces[1]))
	await _secs(0.8)
	_expect(_picker() != null and not picker._done, "look B (not made yet) was taken")
	await _shot("mirror_b_coming")
	await _click(_centre(faces[0]))
	await _until(func() -> bool: return _picker() == null, 10.0, "the mirror closing")
	_expect(Game.flag("look") == "a", "look A wasn't chosen")
	# the taproom: Bram's lines, then the crate
	await _until(func() -> bool: return _objective() == "crate" and world.player.global_position.y < -20.0, 400.0, "the crate")
	await _secs(0.6)
	await _shot("crate_walk")
	_expect(not hud._menu_btn.visible, "the pause square shows before the door")
	await _press(KEY_ESCAPE)
	_expect(not hud.menu_open(), "Esc opened the pack before Bram mentioned stopping")
	var e: Dictionary = world.get_meta("village").get_meta("eve")
	await _secs(0.5)
	hud.tapped.emit(world.cam.unproject_position(e.door_in))
	await _until(func() -> bool: return hud.dialogue.visible and "need to stop" in hud.dialogue._text.text, 60.0, "the door")
	await _secs(1.2)
	await _shot("door_stop")
	_expect(hud._menu_btn.visible, "the pause square isn't there when Bram mentions stopping")
	# out of the inn, to the green
	await _until(func() -> bool: return _objective() == "crate" and not world.busy and world.player.global_position.y > -10.0, 120.0, "the street")
	await _shot("street")
	_expect(not hud._talk.visible, "the Talk button showed on the way to the green")
	var t0 := Time.get_ticks_msec()
	while _objective() == "crate" and Time.get_ticks_msec() - t0 < 240000:
		if not world.busy:
			var p := world.player.global_position
			var to := p + (Vector3.ZERO - Vector3(p.x, 0, p.z)).normalized() * 5.0
			hud.tapped.emit(world.cam.unproject_position(to))
		await _secs(1.5)
		if _frame % 4 == 0:
			await _shot("to_green")
	# the hook: walk up to it and tap it
	await _until(func() -> bool: return _objective() == "hook" and not world.busy, 120.0, "the hook")
	await _secs(0.5)
	await _shot("hook_glows")
	_expect(not hud._talk.visible, "the Talk button showed while the hook waited")
	await _until(func() -> bool: return _objective() == "tam" and not world.busy, 200.0, "Find Tam")
	await _shot("find_tam")
	for n in world.npcs:
		var id := String(n.def.id)
		_expect(bool(n.def.get("muted", false)) == not (id in ["tam", "bram"]), "%s %s while Tam waits" % [id, "is held back" if n.def.get("muted", false) else "answers"])
	# Nell won't talk yet
	var nell = world._npc_by_id("nell")
	_teleport(nell.body.global_position + Vector3(0.6, 0, 1.6))
	await _secs(0.6)
	hud.tapped.emit(world.cam.unproject_position(nell.body.global_position + Vector3(0, 1.0, 0)))
	await _secs(1.5)
	_expect(not Game.flag("ash_nell") and not hud.dialogue.visible, "Nell talked before Tam")
	await _press(KEY_E)
	await _secs(0.5)
	_expect(not hud.dialogue.visible, "E talked to someone other than Tam")
	await _shot("nell_waits")


# ============================================================= the green ===

func _green() -> void:
	# Tam: walk up to him, and the Talk button lights up
	var tam = world._npc_by_id("tam")
	_teleport(tam.body.global_position + Vector3(-0.4, 0, 1.9))
	await _until(func() -> bool: return hud.talk_showing() and world._near == tam, 20.0, "Tam's Talk button")
	await _secs(0.5)
	await _shot("talk_button")
	await _click(_centre(hud._talk))
	await _until(func() -> bool: return Game.flag("ash_tam") and not world.busy, 400.0, "Tam's scene")
	await _shot("after_tam")
	_expect(String(Game.flag("objective", "")).begins_with("Duel Corin on the green."), "the objective after Tam is \"%s\"" % Game.flag("objective", ""))
	_expect(bool(Game.flag("tam_told")) == (not alt), "Tam told: %s" % Game.flag("tam_told"))
	# Nell, on her bench
	var nell = world._npc_by_id("nell")
	var seat: Vector3 = AshfordP1.bench_seat(world, true)
	_teleport(seat + AshfordP1.bench_facing(world) * 1.4)
	await _secs(0.5)
	world._talk(nell)
	await _until(func() -> bool: return Game.flag("ash_nell") and not world.busy, 300.0, "Nell's scene")
	await _shot("after_nell")
	# Tilly runs up when the player comes near her stall
	var tb := Cine.body(world, "tilly")
	_teleport(tb.global_position + Vector3(-3.0, 0, -3.0))
	await _until(func() -> bool: return world.busy, 10.0, "Tilly running up")
	await _until(func() -> bool: return Game.flag("tilly_talked") and not world.busy, 300.0, "Tilly's scene")
	await _shot("after_tilly")
	_expect(bool(Game.flag("ash_tilly")) == (not alt), "the moth woke: %s" % Game.flag("ash_tilly"))
	for id in ["ned", "hob", "bram"]:
		var n = world._npc_by_id(id)
		_teleport(n.body.global_position + Vector3(0.0, 0, 1.6))
		await _secs(0.4)
		await world._talk(n)
		await _shot("talked_" + id)


# ============================================================ Corin onward ===

func _corin_and_on(skip_talk: bool) -> void:
	world._refresh_markers()
	var c = world._npc_by_id("corin")
	_teleport(c.body.global_position + Vector3(2.4, 0, 2.4))
	await _shot("corin_near")
	await _until(func() -> bool: return world.busy, 20.0, "Corin calling out")
	await _until(func() -> bool: return Game.flag("ash_lantern_duel"), 600.0, "the Lantern Duel and Tilly's gift")
	_expect(Game.flag("first_deck"), "no first deck")
	_expect(Game.flag("has_lantern_moth"), "no Lantern Moth")
	if not coach:
		_expect(String(Game.flag("lantern_rematch", "")) == ("won" if rematch_won else "lost"), "rematch: %s" % Game.flag("lantern_rematch", ""))
	await _secs(1.0)
	await _shot("midnight_begins")
	if not skip_talk:
		_finish()


## The duels themselves are decided here (DuelScreen has its own tests): the
## Lantern Duel is won; the rematch goes as asked.
func _duel(spec: Dictionary) -> bool:
	if spec.has("decks") or spec.get("v1", false):
		pass
	var full: Dictionary = world.area.duel_spec(spec) if spec.get("v1", false) else spec
	print("  [duel] %s: rule %s, barks %s, once %s, tutorial %s" % [spec.get("id", "?"), full.get("rule", []), full.get("bark_on", {}).keys(),
		full.get("once", false), "quiet" if full.get("tutorial", {}).get("quiet", false) else ("lesson" if not full.get("tutorial", {}).is_empty() else "none")])
	await _secs(0.5)
	if spec.get("rematch", false):
		_expect(full.get("once", false) and not full.has("life_floor") and not full.get("stacked", [false, false])[0], "the rematch is locked or tuned")
		return rematch_won
	_expect(full.get("story_rules", {}).get("showboat", -1) == 1, "the Lantern Duel has no Showboat")
	return true


# =============================================================== driving ===

func _process(_d: float) -> void:
	_frame += 1
	if world == null or hud == null or _done:
		return
	var dlg := hud.dialogue
	if dlg._choices.visible:
		_wait += 1
		if _wait == read:
			_shot("choice")
		if _wait > read + 2:
			_wait = 0
			dlg._chosen.emit(_answer(dlg))
	elif dlg._waiting:
		if dlg._typing:
			dlg._tap()
		_wait += 1
		if _wait == read:
			var t := dlg._text.text
			if t != _last_line:
				_last_line = t
				print("  ", (dlg._name.text + ": ") if dlg._name.text != "" else "", t.left(90))
				_shot("line")
		if _wait > read + 1:
			_wait = 0
			dlg._advance.emit()
	else:
		_wait = 0
	# things to use: a tap beside it first (nothing), then on it
	for u in world.get_children():
		if u is AshfordP1.Use and not _uses.has(u.get_instance_id()):
			_uses[u.get_instance_id()] = true
			_use(u)
	# a letter held up to read: put it down
	for c in hud._root.get_children():
		if c is LetterView and not c.has_meta("seen"):
			c.set_meta("seen", true)
			_letter(c)
	if every > 0 and _frame % every == 0:
		_shot("f")


func _use(u) -> void:
	var key := _objective()
	await _secs(0.8)
	if not is_instance_valid(u):
		return
	await _shot("use_" + key)
	if u.reach <= 0.0:
		hud.tapped.emit(Vector2(60, get_viewport().get_visible_rect().size.y - 60))
		await _secs(0.6)
		_expect(is_instance_valid(u) and not u._done, "a tap beside it did %s" % key)
	if is_instance_valid(u) and not u._done:
		hud.tapped.emit(world.cam.unproject_position(u.target.global_position))


func _letter(lv: LetterView) -> void:
	await _secs(0.4)
	await _click(Vector2(200, 200))
	_expect(is_instance_valid(lv) and not lv._done, "the letter went before it could be read")
	await _secs(1.4)
	await _shot("letter")
	await _click(Vector2(200, 200))


## The answer for a choice: the first (or the second, with alt), except that
## Bram is asked to coach only with "coach", and the rematch is always played.
func _answer(dlg: DialogueBox) -> int:
	var first := String((dlg._choices.get_child(0) as Button).text)
	if first == "Talk me through it.":
		return 0 if coach else 1
	if first == "Go on, then.":
		return 0
	return 1 if alt else 0


# ================================================================ helpers ===

func _objective() -> String:
	return String(Game.flag("objective_key", ""))


func _picker() -> MirrorPicker:
	for c in hud._root.get_children():
		if c is MirrorPicker:
			return c
	return null


func _teleport(p: Vector3) -> void:
	world.player.global_position = Vector3(p.x, world.get_meta("village").height(p.x, p.z), p.z)
	world._focus = world._cam_focus_target()
	world._move_target = null


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
		print("  PROBLEM: ", what)


func _until(cond: Callable, secs: float, what: String) -> void:
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > secs:
			_expect(false, "timed out waiting for " + what)
			return


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _centre(c: Control) -> Vector2:
	return c.get_global_transform_with_canvas() * (c.size * 0.5)


func _send(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _click(p: Vector2) -> void:
	var w := get_viewport().get_final_transform() * p
	var m := InputEventMouseMotion.new()
	m.position = w
	m.global_position = w
	_send(m)
	await _frames(1)
	for down in [true, false]:
		var b := InputEventMouseButton.new()
		b.position = w
		b.global_position = w
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = down
		b.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		_send(b)
	await _frames(2)


func _press(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		_send(e)
		await _frames(2)


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_shots += 1
	img.save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))


func _finish() -> void:
	if _done:
		return
	_done = true
	await _frames(4)
	await _shot("end")
	print("ASHFORD TEST: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)
