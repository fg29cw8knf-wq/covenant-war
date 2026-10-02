extends Node
## Visual test for the v1 Duel screen.
##   xvfb-run ... godot --rendering-driver opengl3 res://tests/duel_shot.tscn -- <out_dir> <WxH> <watch|play|lab> [shots] [interval]
## watch: the computer plays both sides, screenshots every `interval` seconds.
## play:  you are player 1; the test taps a hand card and a Totem to show the menus.
## lab:   the Duel Lab set-up screen.
## summon: the Summon cinematic for each of the four Summons.
## film:  the computer plays both sides at normal speed for `shots` seconds
##        (run with --write-movie out.avi --fixed-fps 30 to record it).

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var wh: PackedStringArray = (args[1] if args.size() > 1 else "1920x1080").split("x")
	var how: String = args[2] if args.size() > 2 else "watch"
	var shots := int(args[3]) if args.size() > 3 else 4
	var interval := float(args[4]) if args.size() > 4 else 5.0
	get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	get_tree().root.theme = UITheme.make()
	var tag := "%sx%s" % [wh[0], wh[1]]
	if how == "lab":
		var lab := DuelLab.new()
		add_child(lab)
		await get_tree().create_timer(1.0).timeout
		await _shot(out + "/lab_%s.png" % tag)
		get_tree().quit()
		return
	var p0 := Lore.new_profile("You", "pyrrhane", 4)
	var p1 := Lore.new_profile("Rival", "oriel", 4)
	var screen := DuelScreen.new().configure({"decks": ["emberstorm", "veilwild"], "names": ["You", "Wren"],
		"profiles": [p0, p1], "ai": [how == "watch" or how == "film", true], "seed": int(args[5]) if args.size() > 5 else 11,
		"speed": 1.0 if how == "film" else (2.0 if how == "watch" else 4.0)})
	add_child(screen)
	screen.finished.connect(func(_r) -> void: get_tree().quit())
	if how == "play":
		# wait for our first turn, play a card, then open a Totem's moves on turn 3
		var shot_i := 0
		for step in 240:
			await get_tree().create_timer(0.5).timeout
			if screen.mode == "main":
				var p: DuelPlayer = screen.game.players[0]
				var callable := screen.hand_views.filter(func(hv): return hv.card.is_basic_totem() and screen.game.call_problem(0, hv.card) == "")
				if not callable.is_empty() and (p.totems().is_empty() or screen.game.turn <= 4):
					screen._on_hand_tapped(callable[0])
					await get_tree().create_timer(0.4).timeout
					await _shot(out + "/play_%d_%s.png" % [shot_i, tag])
					shot_i += 1
					if screen.pending == "call":
						var v = screen.views[0][screen.targets[0]]
						screen._on_slot_tapped(v)
					else:
						screen._on_end_turn()
				elif not p.totems().is_empty():
					screen._select_totem(p.totems()[0])
					await get_tree().create_timer(0.4).timeout
					await _shot(out + "/play_%d_%s.png" % [shot_i, tag])
					shot_i += 1
					# pick the first usable move and show the aiming arrows
					var acts: Array = screen.actions.get_children().filter(func(n): return n is DuelScreen.ActionButton and n.enabled)
					if not acts.is_empty():
						acts[0].pressed.emit()
						await get_tree().create_timer(0.5).timeout
						if screen.pending == "move":
							await _shot(out + "/aim_%d_%s.png" % [shot_i, tag])
							screen._cancel_pending()
					if shot_i >= shots:
						break
					screen._on_end_turn()
				else:
					screen._on_end_turn()
		get_tree().quit()
		return
	if how == "film":
		await get_tree().create_timer(float(shots)).timeout
		get_tree().quit()
		return
	if how == "summon":
		await get_tree().create_timer(1.5).timeout
		for id in ["pyraxis", "somnara", "thalassa", "grondmaw"]:
			screen.fx_summon(0, DuelCard.new(900, id, 0))
			for f in [0.3, 1.0, 2.2]:
				await get_tree().create_timer(f - (0.0 if f == 0.3 else (0.3 if f == 1.0 else 1.0))).timeout
				await _shot(out + "/summon_%s_%s_%s.png" % [id, str(f), tag])
			await get_tree().create_timer(1.6).timeout
		get_tree().quit()
		return
	for i in shots:
		await get_tree().create_timer(interval).timeout
		await _shot(out + "/watch_%d_%s.png" % [i, tag])
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
