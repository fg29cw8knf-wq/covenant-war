extends Node
## Stills of the 27 October battle additions on the duel screen: the skill
## ribbons on both plates, a skill working, Rallying Light arriving, the
## Circle's event, the damage preview while aiming, a skill's note, the
## finishing blow in slow motion, a riddle's opening banner and its preview,
## and the riddles list.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/battle_extras_shot.tscn -- <out_dir>

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	get_tree().root.theme = UITheme.make()
	await _duel()
	await _riddle()
	await _menu()
	print("BATTLE EXTRAS SHOT: done")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/extras_%s.png" % [out, name])
	print("BATTLE EXTRAS SHOT: saved ", name)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _duel() -> void:
	var tam: Dictionary = load("res://scripts/world/areas/ashford.gd").FRIENDLY.tam_friendly
	var ds := DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Tam"],
		"profiles": [Lore.new_profile("You", "pyrrhane", 4), Lore.new_profile("Tam", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 5, "speed": 1.0, "first": 0,
		"skills": ["second_wind", "loyal_hound"], "bark_on": tam.bark_on, "bark_who": "Tam"})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var g := ds.game
	for pl in g.players:
		pl.slots = [null, null, null]
	var pup := g._new_totem(DuelCard.new(9300, "cinderpup", 0), 0, 0, 0)
	var blaze := g._new_totem(DuelCard.new(9301, "blazehound", 0), 0, 1, 0)
	g.players[0].slots[0] = pup
	g.players[0].slots[1] = blaze
	g.players[1].slots[0] = g._new_totem(DuelCard.new(9302, "river_hound", 1), 1, 0, 0)
	g.players[1].slots[2] = g._new_totem(DuelCard.new(9303, "brookfin", 1), 1, 2, 0)
	g.players[1].life = 60
	g.turn = 3
	ds._refresh()
	await _wait(1.0)
	await _shot("plates")
	# Tam's skill works: the banner, and his line
	ds.fx_skill(1, "loyal_hound", "River Hound holds on with 10 HP.")
	g._skill_spent(1, "loyal_hound")
	await _wait(0.7)
	await _shot("skill")
	await _wait(3.0)
	# Rallying Light comes to the player
	var c := g._new_card(DuelGame.COMEBACK_CARD, 0)
	g.players[0].hand.append(c)
	g.players[0].life = 40
	ds.fx_comeback(0, c)
	await _wait(0.8)
	await _shot("comeback")
	await _wait(4.0)
	# the Circle joins in
	ds.fx_arena_event(0, "ashford", "The Lanterns Flare", DuelGame.ARENA_EVENTS.ashford.text)
	await _wait(0.8)
	await _shot("arena_event")
	await _wait(3.5)
	ds._refresh()
	await _wait(0.4)
	await _shot("countdown")
	# aiming Blazehound's Inferno Rush: the preview over each target
	ds._select_totem(blaze)
	await _wait(0.3)
	ds._choose_move(blaze, 1)
	await _wait(0.6)
	await _shot("preview")
	ds._cancel_pending()
	ds._clear_selection()
	ds._clear_actions()
	# a skill's note, tapped
	ds._on_skill_tapped(ds.panels[1])
	await _wait(0.5)
	await _shot("skill_note")
	await _wait(4.5)
	# the finishing blow: slow, close, dark at the edges
	g.players[1].slots[0] = null
	g.players[1].slots[2] = null
	ds._refresh()
	g.players[1].life = -10
	ds.fx_life_hit(1, 70, {"attacker": blaze})
	await _wait(1.2)
	await _shot("finishing")
	await _wait(9.0)
	print("BATTLE EXTRAS SHOT: time scale back to ", Engine.time_scale)
	ds.queue_free()
	await _wait(0.4)


func _riddle() -> void:
	var ds := DuelScreen.new().configure(DuelPuzzles.spec(1, "You"))
	add_child(ds)
	var t := 0.0
	var shot_banner := false
	while (ds.game == null or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			if not shot_banner:
				await _wait(0.6)
				await _shot("riddle_banner")
				shot_banner = true
			ds.tap_banner()
	var ox: DuelTotem = ds.game.players[0].slots[0]
	ds._select_totem(ox)
	await _wait(0.3)
	ds._choose_move(ox, 1)
	await _wait(0.6)
	await _shot("riddle_preview")
	ds.queue_free()
	await _wait(0.4)


func _menu() -> void:
	var m := PuzzleMenu.new()
	add_child(m)
	await _wait(0.8)
	await _shot("riddles_list")
	m.queue_free()
