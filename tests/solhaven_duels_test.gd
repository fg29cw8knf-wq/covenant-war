extends Node
## Chapter 1's four duels on the real duel screen, the way Main plays a story
## duel (Master Script v3): Warden Hale (Hold the Gate, at half Life), Wren
## (Light Fingers), the Trial of Light (the mirrors' set board) and Ser Aldric
## (the Sunspire's Mirror). Each is played out once by the computer on both
## sides with its rule in force; then lost on purpose (their line for winning
## and Morrowen's, then Again; for the Trial, Liora's line and the board set
## again, and on the third reset her other line); then won. Checks the rules
## came into play and the barks were said, and takes screenshots.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/solhaven_duels_test.tscn -- <out_dir> [hale|wren|trial|aldric]
##   godot --headless res://tests/solhaven_duels_test.tscn -- <out_dir>     # just the checks

var out := "user://"
var layer: CanvasLayer
var fails := 0
var n := 0
var Duels: GDScript


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	var only := args[1] if args.size() > 1 else ""
	Duels = load("res://scripts/world/solhaven/duels.gd")
	Game.new_game("Rowan", "tidegrove")
	for f in ["ash_marked", "first_deck", "bram_deck"]:
		Game.set_flag(f)
	Game.area = "solhaven"
	layer = CanvasLayer.new()
	add_child(layer)
	for which in ["hale", "wren", "trial", "aldric"]:
		if only == "" or only == which:
			await _one(which)
	print("SOLHAVEN DUELS: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(0 if fails == 0 else 1)


func _spec(which: String) -> Dictionary:
	match which:
		"hale":
			return Duels.hale_spec()
		"wren":
			return Duels.wren_spec()
		"trial":
			return Duels.trial_spec("tidegrove")
	return Duels.aldric_spec()


func _one(which: String) -> void:
	print("--- ", which)
	# 1: the computer plays both sides, the rule in force
	Game.settings["debug_autoplay"] = true
	var spec := _spec(which)
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	var shot_at := [2.0, 9.0, 30.0]
	var t := 0.0
	var r := [""]
	ds.finished.connect(func(x: String) -> void: r[0] = x)
	while r[0] == "" and t < 900.0:
		await _wait(0.25)
		t += 0.25
		if ds.tutor != null and ds.tutor.blocking:
			ds.tutor._tapped.emit()
		if not shot_at.is_empty() and t >= shot_at[0]:
			shot_at.pop_front()
			await _shot("%s_auto_%d" % [which, int(t)])
		if ds.game != null and ds.game.over and r[0] == "":
			# the result: press on
			for b in ds.find_children("*", "Button", true, false):
				var bt := b as Button
				if bt.is_visible_in_tree() and bt.text in ["Continue", "Again", "Try again", "Back to the Lab"]:
					await _shot("%s_auto_result" % which)
					bt.pressed.emit()
					break
	var g: DuelGame = ds.game
	_check(g.over, "%s: the computer's duel finished (%s, turn %d, %s)" % [which, r[0], g.turn, g.win_reason])
	match which:
		"hale":
			_check(g.players[0].max_life * 2 <= DuelRules.life_for(g.players[0].attributes()) + 10, "hale: half Life (%d)" % g.players[0].max_life)
		"wren":
			_check(g.rule_state.get("light_fingers", false) or g.turn < 4, "wren: Light Fingers came into play (%s)" % g.rule_state)
			if g.rule_state.get("light_fingers", false):
				_check(ds._barked.has("rival_steals"), "wren: her line as she takes it")
		"aldric":
			if g.players[1].life * 2 <= g.players[1].max_life:
				_check(g.rule_state.get("mirror", false), "aldric: the mirror swung at half Life")
				_check(bool(spec.get("_mirror_swung", false)), "aldric: the story knows the mirror swung")
		"trial":
			_check(g.rule_state.has("trial_turns") or g.winner == 0, "trial: the mirrors counted the turns (%s)" % g.rule_state)
	if is_instance_valid(ds):
		ds.queue_free()
	Game.settings["debug_autoplay"] = false
	await _wait(0.3)
	# 2: lost (twice for the Trial's three resets), then 3: won
	spec = _spec(which)
	var losses := 3 if which == "trial" else 1
	for k in losses:
		ds = await _duel(spec)
		if k == 0:
			await _rule_moment(which, ds)
		_lose(ds)
		await _wait(2.6)
		await _shot("%s_lost_%d" % [which, k + 1])
		if which == "trial":
			var reset := ds.overlay.get_node_or_null("TrialReset")
			_check(reset != null, "trial: a mistake and the mirrors begin again (reset %d)" % (k + 1))
			var said := ""
			if reset != null:
				for l in reset.find_children("*", "Label", true, false):
					said += (l as Label).text + " "
			var want := "Some pilgrims start" if k == 2 else "Again. The mirrors don't mind."
			_check(said.contains(want), "trial: Liora's line on reset %d (%s)" % [k + 1, said.strip_edges()])
			var got := await _finish(ds, "")
			_check(got == "again", "trial: the board is set again (got %s)" % got)
		else:
			await _wait(4.0)
			await _shot("%s_morrowen" % which)
			var got := await _finish(ds, "Again")
			_check(got == "again", "%s: a loss is played again (got %s)" % [which, got])
	ds = await _duel(spec)
	ds.game._finish(0, "Their Life is empty.")
	ds.human.responded.emit({"type": "end"})
	await _wait(2.5)
	await _shot("%s_won" % which)
	var w := await _finish(ds, "Continue")
	_check(w == "won", "%s: a win carries on (got %s)" % [which, w])


## The rule's own moment, made to happen: Hale's Guardian struck and his
## Gift, Wren's steal, the mirror swinging and Dawnmane named, the blank card's
## seal; and for the Trial its set board.
func _rule_moment(which: String, ds: DuelScreen) -> void:
	var g := ds.game
	await _shot("%s_rule_banner_after" % which)
	match which:
		"hale":
			var guard: DuelTotem = null
			for c in g.players[1].hand + g.players[1].deck:
				if (c as DuelCard).is_basic_totem() and (c as DuelCard).def.get("keywords", []).has("guardian"):
					guard = DuelTotem.new(c, 1, 1, 0, g.players[1].attributes())
					break
			if guard != null:
				g.players[1].slots[1] = guard
				ds._refresh()
				ds.story_bark("rival_guardian_hit")
				await _wait(1.0)
				await _shot("hale_bark_hold")
				var pup := DuelTotem.new(DuelCard.new(9001, "brookfin", 0), 0, 0, 0, g.players[0].attributes())
				g.players[0].slots[0] = pup
				var ts := g.attack_targets(1, guard, 0)
				_check(not ts.has(DuelGame.LIFE), "hale: his Guardian up, his Totems never go for your Life")
		"wren":
			g.current = 1
			g.turn = 4
			g.players[0].hand.append(DuelCard.new(9002, "brookfin", 0))
			g.players[1].essence = 5
			g._rule_light_fingers(g.players[1])
			await _wait(2.0)
			await _shot("wren_light_fingers")
			_check(g.rule_state.get("light_fingers", false), "wren: Light Fingers takes a card")
			g.current = 0
		"aldric":
			g.current = 0
			var q: DuelPlayer = g.players[1]
			g._hit_life(1, q.life - q.max_life / 2, {"no_guard": true})
			await _wait(1.2)
			await _shot("aldric_mirror")
			await _wait(2.0)
			_check(g.rule_state.get("mirror", false), "aldric: the mirror swings at half Life")
			_check(q.hand.any(func(c): return c.id == "dawnmane"), "aldric: Dawnmane comes to his hand")
			var dm: DuelCard = null
			for c in q.hand:
				if c.id == "dawnmane":
					dm = c
			if dm != null:
				ds.fx_summon(1, dm)
				await _wait(0.9)
				await _shot("aldric_crowd_dawnmane")
				await _wait(1.6)
				await _shot("aldric_wake_bark")
				await _wait(5.0)
			var p: DuelPlayer = g.players[0]
			g._hit_life(0, p.life - p.max_life / 3 + 10, {"no_guard": true})
			await _wait(1.0)
			await _shot("aldric_blank_eye")
			await _wait(3.0)
			_check(ds._barked.has("_blank_eye"), "aldric: the seal shows on the blank card")
		"trial":
			var p0: DuelPlayer = g.players[0]
			_check(p0.hand.size() >= 2 and p0.hand.any(func(c): return c.is_summon()), "trial: the Summon is in your hand")
			_check(g.players[1].max_life == int(Duels.TRIALS.tidegrove.life), "trial: the mirrors' Life is set")
			ds.story_bark("my_summons")
			await _wait(0.8)
			await _shot("trial_oh")


func _duel(spec: Dictionary) -> DuelScreen:
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	var t := 0.0
	var banner_shot := false
	while t < 90.0 and ds.mode != "main":
		await _wait(0.2)
		t += 0.2
		if not banner_shot and t > 2.4:
			banner_shot = true
			await _shot("rule_banner_%s" % String(spec.get("title", "")).get_slice(" ", 1).to_lower())
		if ds.tutor != null and ds.tutor.blocking:
			ds.tutor._tapped.emit()
	_check(ds.mode == "main", "the duel reached the player's turn")
	return ds


func _lose(ds: DuelScreen) -> void:
	ds.game._finish(1, "Your Life is empty.")
	ds.human.responded.emit({"type": "end"})


## Presses the button with this text (or waits for the screen to finish by
## itself, text ""), and returns what the duel screen finished with.
func _finish(ds: DuelScreen, text: String) -> String:
	var got := [""]
	ds.finished.connect(func(r: String) -> void: got[0] = r)
	var t := 0.0
	while got[0] == "" and t < 60.0:
		await _wait(0.2)
		t += 0.2
		if text == "":
			continue
		for b in ds.find_children("*", "Button", true, false):
			var bt := b as Button
			if bt.is_visible_in_tree() and bt.text == text:
				bt.pressed.emit()
				break
	ds.queue_free()
	return got[0]


func _check(ok: bool, what: String) -> void:
	print("SOLHAVEN DUELS %s: %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		fails += 1


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [n, label]))
