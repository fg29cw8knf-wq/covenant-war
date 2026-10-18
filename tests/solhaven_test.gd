extends Node
## Plays Chapter 1 in Solhaven from the road to the end (Master Script v3, C1
## to C7): the gate film and Hale's duel on arrival, the wagon, everyone in the
## square, Wren and the chase (tapping each glowing ledge), the Sun Court, the
## Trial of Light, the Sunspire, everyone again after the Trial, and Bram ending
## the day: Gold in the Dark. Duels are played out by the computer on both
## sides (no duel screen). Every subtitle and dialogue line is tapped on; the
## choices take the first answer, or the nth with choice=<n>. Checks the story
## flags, the cards and the items at the end, and saves screenshots.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
##       res://tests/solhaven_test.tscn -- <out_dir> keys          # a still on every line (fast: only those frames are drawn)
##   godot --headless --fixed-fps 10 res://tests/solhaven_test.tscn -- <out_dir> choice=1   # just the run and its checks
##
## from=<part> starts at a film part (thief, court, trial, spire) with the
## story flags before it set, e.g. from=spire.

var out_dir := "user://"
var world: World
var _frame := 0
var _shots := 0
var _wait := 0
var _line_frames := 0
var _choice := 0
var _keys := false
var _shooting := false
var _from := ""
var _log: Array = []
var _last_line := ""
var _chase_taps := 0
var _crier_watched := false
var _last_caption := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	_keys = "keys" in args
	for a in args:
		if String(a).begins_with("choice="):
			_choice = int(String(a).substr(7))
		elif String(a).begins_with("from="):
			_from = String(a).substr(5)
	if _keys:
		RenderingServer.render_loop_enabled = false
	Game.new_game("Rowan", "tidegrove")
	for f in ["ash_marked", "first_deck", "bram_deck", "hob_gift", "beat_hunter", "thornwood_done"]:
		Game.set_flag(f)
	_skip_to(_from)
	world = World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(10)
	await _shot("start")
	await _play()


## Sets the flags of everything before `part`, so the run can start there.
func _skip_to(part: String) -> void:
	if part == "":
		return
	Game.set_flag("arrived_solhaven")
	var order := ["gate", "wagon", "thief", "court", "trial", "spire", "vault"]
	for i in order.find(part):
		Game.set_flag("c%d_done" % (i + 1))
	Game.set_flag("gate_choice", ["all", "children", "shut"][clampi(_choice, 0, 2)])
	if order.find(part) > 0:
		Game.set_flag("beat_hale")
	if order.find(part) > 3:
		Game.set_flag("solmaris_favour", "refused")
	if order.find(part) > 4:
		Game.set_flag("trial_light_passed")
	if order.find(part) > 2:
		Game.set_flag("wren_joined", _choice == 0)
		Game.set_flag("beat_wren")
	Game.set_flag("sol_film", part)


func _play() -> void:
	# the arrival plays by itself (C1, C2), then the square
	await _until_free(9000)
	await _shot("square")
	_check(Game.flag("c1_done") and Game.flag("c2_done"), "the gate and the wagon are done")
	_check(Game.flag("beat_hale"), "Hale beaten")
	_check(String(Game.flag("gate_choice", "")) != "", "the gate choice is remembered (%s)" % Game.flag("gate_choice", ""))
	if not Game.flag("c3_done"):
		# (Old Maren is on the temple steps, past where the crowd thickens:
		# she's heard after Wren)
		for id in ["board", "bram", "tamsin", "pip"]:
			await _talk(id)
		# north past the fountain: the crowd thickens, and Wren (C3, the chase)
		_teleport(Vector3(0, 0, -7.4))
		await _until_free(9000)
		await _shot("after_thief")
		_check(Game.flag("c3_done") and Game.flag("beat_wren"), "Wren beaten")
		_check(_chase_taps >= 5, "every ledge in the chase was tapped (%d)" % _chase_taps)
		if Game.flag("wren_joined"):
			await _talk("wren")
		await _talk("maren")
	if not Game.flag("c4_done"):
		_teleport(Vector3(0, 0, -17.2))
		await _until_free(9000)
		await _shot("after_court")
		_check(Game.flag("c4_done") and String(Game.flag("solmaris_favour", "")) != "", "the Sun Court, and Solmaris's offer answered (%s)" % Game.flag("solmaris_favour", ""))
		_teleport(Vector3(0, 0, -12.0))
		await _frames(30)
	if not Game.flag("c5_done"):
		_teleport(Vector3(0, 0, -17.2))
		await _until_free(9000)
		await _shot("after_trial")
		await _talk("liora")
	_check(Game.flag("c5_done") and Game.flag("trial_light_passed"), "the Trial of Light passed")
	if not Game.flag("c6_done"):
		_teleport(Vector3(-14.6, 0, -9.0))
		await _until_free(12000)
		await _shot("after_spire")
		_check(Game.flag("c6_done") and Game.flag("beat_aldric"), "Aldric beaten")
		_check(int(Game.v2.collection.get("sunmane_lion", 0)) == 1, "Sunmane Lion given (%d)" % int(Game.v2.collection.get("sunmane_lion", 0)))
	for id in ["pip", "maren", "tamsin", "wren", "aldric", "hale", "gate_warden"]:
		if id == "pip" and Game.flag("pip_at_work"):
			continue   # (at work for Mr Pell: his talk is the side story's errand and wager now)
		await _talk(id)
	# Bram ends the day: Gold in the Dark (C7)
	await _talk("bram")
	await _until_free(9000)
	await _shot("end_of_chapter")
	_check(Game.flag("c7_done") and Game.flag("ch1_done"), "Gold in the Dark, and the chapter's end")
	await _talk("bram")
	var items := Items.story_items()
	_check("revival_candle" in items and "ironvault_seal" in items, "the Revival Candle and the seal are in Items (%s)" % [items])
	_check(String(Game.flag("sol_film", "")) == "", "no film left part-way")
	if _crier_watched:
		_check(String(Game.flag("crier_day", "")) != "", "Tamsin's crier heard out: a cache")
	print("SOLHAVEN TEST: gate=%s favour=%s wren=%s lion=%d frames=%d lines=%d" % [Game.flag("gate_choice", ""), Game.flag("solmaris_favour", ""),
		Game.flag("wren_joined", false), int(Game.v2.collection.get("sunmane_lion", 0)), _frame, _log.size()])
	print("SOLHAVEN TEST: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)


var _fails := 0


func _check(ok: bool, what: String) -> void:
	print("SOLHAVEN %s: %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails += 1


## Waits until the player can walk again (no film, no talk).
func _until_free(max_frames: int) -> void:
	var t := 0
	await _frames(6)
	while t < max_frames:
		await _frames(1)
		t += 1
		if not world.busy and not world.cine and world.hud.pad.visible and String(Game.flag("sol_film", "")) == "" and not world.has_node("Chase"):
			# a few more frames: a trigger may start the next film at once
			await _frames(8)
			if not world.busy and not world.cine:
				return
	_check(false, "timed out waiting for the player to be free (frame %d)" % _frame)


func _talk(id: String) -> void:
	var n = world._npc_by_id(id)
	if n == null or not (n.body as Node3D).visible:
		return
	_teleport(n.body.global_position + Vector3(0.0, 0, 1.6))
	await _frames(4)
	await world._talk(n)
	await _frames(4)
	await _shot("talked_" + id)


func _teleport(p: Vector3) -> void:
	world.player.global_position = p
	world._focus = world._cam_focus_target()


func _process(_d: float) -> void:
	_frame += 1
	if world == null:
		return
	# the dialogue box
	if world.hud != null and world.hud.dialogue._waiting:
		_wait += 1
		if _wait == 2:
			_note(world.hud.dialogue._text.get_parsed_text())
			if _keys:
				_shot("say_%05d" % _frame)
		if _wait > 3:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud != null and world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(mini(_choice, world.hud.dialogue._choices.get_child_count() - 1))
	# the films' subtitles and choices
	if world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		if ov._waiting:
			_line_frames += 1
			if _line_frames == 4:
				_note(ov._who.text + ": " + ov._line.get_parsed_text())
				if _keys:
					_shot("line_%05d" % _frame)
			if _line_frames > 12:
				_line_frames = 0
				ov._next.emit()
		else:
			_line_frames = 0
		# a caption (the chapter's end), once it's up
		if ov._cap.modulate.a > 0.95 and ov._cap.text != _last_caption:
			_last_caption = ov._cap.text
			_note("CAPTION: " + ov._cap.text)
			if _keys:
				_shot("caption_%05d" % _frame)
		if ov._choices.visible and ov._choices.get_child_count() > 0:
			ov._chosen.emit(mini(_choice, ov._choices.get_child_count() - 1))
	# the chase: tap each ledge as it lights
	var ch := world.get_node_or_null("Chase")
	if ch != null and ch._lit >= 0 and not ch._tapped and _frame % 4 == 0:
		if _keys:
			_shot("chase_%05d" % _frame)
		ch.tap()
		_chase_taps += 1
	# a card shown big: tap on
	for r in get_tree().root.find_children("*", "DeckReveal", true, false):
		if (r as DeckReveal)._ready_to_close:
			if _keys and not r.has_meta("shot"):
				r.set_meta("shot", true)
				_shot("reveal_%05d" % _frame)
			(r as DeckReveal)._close()
	if world.hud != null:
		for c in world.hud.find_children("*", "", true, false):
			if c.has_signal("closed") and c.get("card_id") != null and (c as CanvasItem).is_visible_in_tree() and c.get("_ready_to_close"):
				c.emit_signal("closed")
	# Tamsin's crier: the advert (its placeholder) watched to the end
	if _frame % 10 == 0:
		for b in get_node("/root/Ads").find_children("*", "Button", true, false):
			if (b as Button).text == "Claim reward" and not (b as Button).disabled:
				if _keys:
					_shot("advert_%05d" % _frame)
				_crier_watched = true
				(b as Button).pressed.emit()
	# the deck screen ("Change my deck"): close it
	if world.hud != null and world.hud.menu_open() and _frame % 20 == 0:
		world.hud.close_menu()


func _note(line: String) -> void:
	if line == _last_line or line.strip_edges() == ":":
		return
	_last_line = line
	_log.append(line)
	print("LINE %5d  %s" % [_frame, line])


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless" or _shooting:
		return
	_shooting = true
	if _keys:
		RenderingServer.render_loop_enabled = true
		await get_tree().process_frame
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if _keys:
		RenderingServer.render_loop_enabled = false
	_shooting = false
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
