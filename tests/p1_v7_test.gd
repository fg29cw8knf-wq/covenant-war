extends Node
## Plays Prologue P1 as Master Script v7 has it (docs/script/v7_prologue.md),
## New Game to midnight, the way a player would: the walk to the washbasin,
## the mirror and the name written in the frost, Bram's hub in the taproom,
## the crate from the corner and the menu at the door, the street, the crate
## down at the Great Lantern, Corin's hub, Bram's hand and his offer, the
## deck, the Lantern Duel (decided here: the duel screens have their own
## tests), Bram's lines after it, then the afternoon (down the lane to Tam's
## mill: his letter and his friendly game; Tilly's moth by the well; Nell's
## hub and her friendly game on the bench), the sunset, and the evening
## (Tilly's thanks and her card, Nell's message and Tam's bread, Corin on the
## mill-race wall and his button, Bram by the Lantern), stopping as midnight
## begins. A still at every line. Ends with "P1 V7 TEST: ok" or the problems.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
##       res://tests/p1_v7_test.tscn -- <out_dir> [coach] [keys] [read=<n>]
##
## coach: ask Bram to talk you through the duel; keys: draw only the frames
## kept (much faster); read: frames each line stays up (6 by default);
## stop=<words>: stop (and pass) once the step whose wait is described by
## those words is reached, e.g. stop=street for the attic and the taproom
## only (25 October: a look at the opening without the half hour).

const NAME := "Rowan"

var out_dir := "user://"
var coach := false
var read := 6
var world: World
var hud: WorldHUD
var problems: Array = []
var duels: Array = []
var _shots := 0
var _frame := 0
var _wait := 0
var _last_line := ""
var _done := false
var _keys := false
var _uses := {}
var _goal := Callable()    # where the player is walking to now (returns a Vector3)
var _tap_t := 0.0
var _stop_at := ""         # stop=<words>: finish when this wait is reached


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	for a in args.slice(1):
		var s := String(a)
		if s == "coach":
			coach = true
		elif s == "keys":
			_keys = true
		elif s.begins_with("read="):
			read = int(s.substr(5))
		elif s.begins_with("stop="):
			_stop_at = s.substr(5)
	if _keys:
		RenderingServer.render_loop_enabled = false
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	world = World.new().setup("ashford", "green")
	world.duel_handler = _duel
	add_child(world)
	hud = world.hud
	world.story_next.connect(func(what: String) -> void:
		print("story_next: ", what))
	await _frames(20)
	await _run()
	_finish()


func _run() -> void:
	var v: AshfordVillage = world.get_meta("village")
	# ---- the attic: walk to the basin, the mirror, the name in the frost
	await _until(func() -> bool: return _objective() == "basin", 240.0, "Walk to the washbasin")
	await _shot("attic_basin")
	_expect(v.daylight > 0.9, "the village isn't in daylight in the morning (%.2f)" % v.daylight)
	var a: Dictionary = InnRooms.attic(v)
	_goal = func() -> Vector3: return a.mirror_stand
	await _until(func() -> bool: return _objective() == "mirror", 90.0, "the mirror")
	_goal = Callable()
	await _until(func() -> bool: return Game.player_name == NAME, 200.0, "the name written in the frost")
	# ---- the taproom: Bram's hub, the crate from the corner, the door
	await _until(func() -> bool: return _objective() == "take_crate", 400.0, "Take the lantern crate")
	await _shot("taproom_crate")
	var e: Dictionary = InnRooms.eve(v)
	_goal = func() -> Vector3: return (e.crate as Node3D).global_position
	await _until(func() -> bool: return _objective() == "green_crate", 120.0, "carrying the crate")
	_goal = func() -> Vector3: return e.door_in
	await _until(func() -> bool: return hud.dialogue.visible and "menu" in hud.dialogue._text.text, 120.0, "the menu at the door")
	await _secs(1.0)
	await _shot("door_menu")
	_expect(hud._menu_btn.visible, "the menu button isn't there at the door")
	# ---- the street, to the green
	await _until(func() -> bool: return world.player.global_position.y > -10.0 and not world.busy, 200.0, "the street")
	# (round the south side of the well: a player walks round it, the taps
	# here go straight)
	_goal = func() -> Vector3:
		return Vector3(-6.4, 0, 8.6) if world.player.global_position.x < -7.2 else Vector3(0.9, 0, 4.2)
	await _until(func() -> bool: return Game.flag("ash_started"), 300.0, "the crate down at the Lantern")
	_goal = Callable()
	# ---- Corin, Bram's deck, the Lantern Duel
	await _until(func() -> bool: return Game.flag("corin_met"), 40.0, "Corin calling")
	await _until(func() -> bool: return Game.flag("ash_won_lantern") and not world.busy, 600.0, "the Lantern Duel and Bram's lines")
	await _shot("afternoon")
	_expect(Game.flag("first_deck"), "no first deck")
	_expect("corin_lantern" in duels, "no Lantern Duel")
	_expect(String(Game.flag("objective", "")) == AshfordDay.FESTIVAL, "the afternoon's objective is \"%s\"" % Game.flag("objective", ""))
	for n in world.npcs:
		_expect(not n.def.get("muted", false), "%s doesn't answer in the afternoon" % n.def.id)
	# ---- down the lane to Tam's mill
	await _to_mill()
	_goal = func() -> Vector3: return Cine.body(world, "tam").global_position
	await _until(func() -> bool: return Game.flag("ash_tam") and not world.busy and not AshfordDay.at_mill(world.player.global_position), 600.0, "Tam at the mill")
	_goal = Callable()
	await _shot("back_from_mill")
	_expect(Game.flag("tam_letter_seen"), "Tam's letter wasn't read")
	_expect("tam_friendly" in duels, "no friendly game with Tam")
	# ---- Tilly by the well
	await _talk_to("tilly")
	await _until(func() -> bool: return Game.flag("ash_tilly") and not world.busy, 300.0, "Tilly's moth")
	await _shot("after_tilly")
	_expect(int(Game.standing.get("tilly", 0)) > 0, "Tilly's standing didn't go up")
	# ---- Nell on her bench
	await _talk_to("nell")
	await _until(func() -> bool: return Game.flag("ash_nell") and not world.busy, 400.0, "Nell's hub")
	await _shot("after_nell")
	_expect("nell_friendly" in duels, "no friendly game with Nell")
	# ---- the sun goes down when they find Bram
	await _until(func() -> bool: return String(Game.flag("objective", "")) == AshfordDay.SUN_GOING, 30.0, "the sun going down")
	await _talk_to("bram")
	await _until(func() -> bool: return Game.flag("ash_evening") and not world.busy, 120.0, "the sunset")
	await _shot("evening")
	_expect(v.daylight < 0.05, "it isn't night after the sunset (%.2f)" % v.daylight)
	# ---- the evening: Tilly comes running with her card
	var tb := Cine.body(world, "tilly")
	_teleport(tb.global_position + Vector3(-4.2, 0, 1.5))
	await _until(func() -> bool: return Game.flag("tilly_thanks") and not world.busy, 300.0, "Tilly's thanks")
	_expect(Game.flag("has_lantern_moth"), "no Lantern Moth")
	# ---- Nell's message, and Tam's bread
	await _talk_to("nell")
	await _until(func() -> bool: return Game.flag("nell_waiting") and not world.busy, 120.0, "Nell's message")
	await _talk_to("tam")
	await _until(func() -> bool: return Game.flag("tam_dances") and not world.busy, 300.0, "Tam's bread and the dance")
	await _shot("tam_dances")
	# ---- Corin on the mill-race wall
	await _to_mill()
	_goal = func() -> Vector3: return Cine.body(world, "corin").global_position
	await _until(func() -> bool: return Game.flag("corin_pond") and not world.busy and not AshfordDay.at_mill(world.player.global_position), 600.0, "Corin at the mill")
	_goal = Callable()
	_expect(Game.flag("corin_button"), "no button from Corin")
	_expect(Items.story_items().has("corin_button"), "Corin's button isn't in Items")
	# ---- Bram by the Lantern: midnight
	await _talk_to("bram")
	await _until(func() -> bool: return Game.flag("ash_lantern_duel"), 300.0, "Bram's \"It's nearly midnight.\"")
	await _secs(3.0)
	await _shot("midnight_begins")


## Walks the player into the lane's mouth and waits until they're at the mill.
func _to_mill() -> void:
	_teleport(AshfordDay.LANE + Vector3(-2.6, 0, 2.4))
	await _secs(0.3)
	_goal = func() -> Vector3: return AshfordDay.LANE
	await _until(func() -> bool: return AshfordDay.at_mill(world.player.global_position), 40.0, "the lane to the mill")
	_goal = Callable()
	await _secs(1.5)
	await _shot("mill")


func _talk_to(id: String) -> void:
	var n = world._npc_by_id(id)
	if n == null:
		_expect(false, "nobody called " + id)
		return
	await _until(func() -> bool: return not world.busy, 30.0, "free to talk to " + id)
	var b: Vector3 = n.body.global_position
	var from := b + (Vector3(1.2, 0, 8.0) - b).normalized() * 1.6
	_teleport(from)
	await _secs(0.4)
	world._talk(n)
	await _secs(0.3)


## The duels are decided here; their specs are checked.
func _duel(spec: Dictionary) -> bool:
	var full: Dictionary = world.area.duel_spec(spec) if spec.get("v1", false) else spec
	# (World hands the handler the full spec: its rival's name says which duel)
	var rival := String((full.get("names", ["", ""]) as Array)[1])
	var id: String = {"Corin": "corin_lantern", "Tam": "tam_friendly", "Old Nell": "nell_friendly"}.get(rival, rival)
	duels.append(id)
	print("  [duel] %s: practice %s, life %s, decks %s / %s" % [id, full.get("practice", false), full.get("life", 0), full.decks[0].size(), full.decks[1].size()])
	_expect(full.get("practice", false), "%s gives experience (v7: none until Dask)" % id)
	if id == "tam_friendly":
		_expect((full.decks[1] as Array).has("river_hound"), "Tam's deck has no River Hound")
	if id == "nell_friendly":
		var wards := 0
		for c in full.decks[1]:
			if String(DuelCards.CARDS.get(String(c), {}).get("kind", "")) == "ward":
				wards += 1
		_expect(wards >= 3, "Nell's deck has %d Wards" % wards)
		_expect(full.get("bark_on", {}).has("rival_ward_springs"), "Nell doesn't explain her Ward")
	await _secs(0.5)
	return true


# =============================================================== driving ===

func _process(delta: float) -> void:
	_frame += 1
	if world == null or hud == null or _done:
		return
	var dlg := hud.dialogue
	var ov := Cine.overlay(world)
	# the name prompt: write it in the frost
	for le in ov.find_children("*", "LineEdit", true, false):
		if not le.has_meta("typed"):
			le.set_meta("typed", true)
			_type_name(le as LineEdit)
	if dlg._choices.visible:
		_wait += 1
		if _wait == read:
			_shot("choice")
		if _wait > read + 2:
			_wait = 0
			dlg._chosen.emit(_answer(dlg))
	elif ov._waiting and not ov._choices.visible:
		_wait += 1
		if _wait == read:
			var t := ov._line.text if ov._line.modulate.a > 0.5 else ov._cap.text
			if t != _last_line:
				_last_line = t
				print("  ", (ov._who.text + ": ") if ov._who.visible and ov._who.text != "" else "", t.left(90))
				_shot("line")
		if _wait > read + 1:
			_wait = 0
			ov._next.emit()
	elif dlg._waiting:
		if dlg._typing:
			dlg._tap()
		_wait += 1
		if _wait == read:
			var t := dlg._text.text
			if t != _last_line:
				_last_line = t
				print("  ", (dlg._name.text + ": ") if dlg._name.text != "" else "", t.left(100))
				_shot("line")
		if _wait > read + 1:
			_wait = 0
			dlg._advance.emit()
	else:
		_wait = 0
	# things to use: a tap on them
	for u in world.get_children():
		if u is AshfordP1.Use and not _uses.has(u.get_instance_id()):
			_uses[u.get_instance_id()] = true
			_use(u)
	for c in hud._root.get_children():
		if c is LetterView and not c.has_meta("seen"):
			c.set_meta("seen", true)
			_letter(c)
	for l in world.get_children():
		if l is CanvasLayer:
			for c in l.get_children():
				if c is DeckReveal and not c.has_meta("seen"):
					c.set_meta("seen", true)
					_reveal(c)
	# walking somewhere: a tap on the ground there now and then
	_tap_t -= delta
	if _goal.is_valid() and _tap_t <= 0.0 and not dlg.visible:
		_tap_t = 0.8
		var g: Vector3 = _goal.call()
		if not world.cam.is_position_behind(g):
			hud.tapped.emit(world.cam.unproject_position(g))


func _type_name(le: LineEdit) -> void:
	await _secs(0.6)
	await _shot("name_prompt")
	le.text = NAME
	le.text_submitted.emit(NAME)


## The first answer every time (a hub's questions in turn, its leave line
## last), except: Bram coaches only with "coach", and a friendly game is
## always played.
func _answer(dlg: DialogueBox) -> int:
	var first := String((dlg._choices.get_child(0) as Button).text)
	if first == "Talk me through it.":
		return 0 if coach else 1
	return 0


func _use(u) -> void:
	await _secs(0.8)
	if not is_instance_valid(u):
		return
	await _shot("use_" + _objective())
	if is_instance_valid(u) and not u._done:
		hud.tapped.emit(world.cam.unproject_position(u.target.global_position))


func _reveal(r: DeckReveal) -> void:
	await _secs(1.6)
	await _shot("reveal_" + r.title.to_lower().replace(" ", "_"))
	await _click(Vector2(200, 200))
	await _secs(0.4)
	await _click(Vector2(200, 200))


func _letter(lv: LetterView) -> void:
	await _secs(1.6)
	await _shot("letter")
	await _click(Vector2(200, 200))


# ================================================================ helpers ===

func _objective() -> String:
	return String(Game.flag("objective_key", ""))


func _teleport(p: Vector3) -> void:
	world.player.global_position = Vector3(p.x, world.get_meta("village").height(p.x, p.z), p.z)
	world._focus = world._cam_focus_target()
	world._move_target = null


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
		print("  PROBLEM: ", what)


func _until(cond: Callable, secs: float, what: String) -> void:
	if _stop_at != "" and _stop_at in what:
		print("stopping at: ", what)
		_finish()
		await get_tree().create_timer(1000.0).timeout
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


var _drawing := 0


func _shot(label: String) -> void:
	_shots += 1
	var n := _shots
	if DisplayServer.get_name() == "headless":
		return
	if _keys:
		_drawing += 1
		RenderingServer.render_loop_enabled = true
		await get_tree().process_frame
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if _keys:
		_drawing -= 1
		if _drawing == 0:
			RenderingServer.render_loop_enabled = false
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out_dir.path_join("%03d_%s.png" % [n, label]))


func _finish() -> void:
	if _done:
		return
	_done = true
	await _frames(4)
	await _shot("end")
	print("P1 V7 TEST: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)
