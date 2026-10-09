extends Node
## Plays whole duels through the Duel screen with random taps, to catch errors
## in the screen's input flows (pickers, targets, dialogs). Watch the output
## for SCRIPT ERROR lines.
##   godot --headless res://tests/duel_monkey.tscn -- [duels]

var rng := RandomNumberGenerator.new()
var screen: DuelScreen
var taps := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var duels := int(args[0]) if args.size() > 0 else 3
	get_tree().root.theme = UITheme.make()
	rng.seed = 3
	var decks := DuelCards.DECKS.keys()
	for d in duels:
		var a: String = decks[d % decks.size()]
		var b: String = decks[(d + 1 + d / 4) % decks.size()]
		var patrons := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith"]
		var p0 := Lore.new_profile("You", patrons[d % 8], 5 + d % 3)
		p0["fortune"] = 2
		var p1 := Lore.new_profile("Rival", patrons[(d + 3) % 8], 4)
		screen = DuelScreen.new().configure({"decks": [a, b], "names": ["You", "Rival"], "profiles": [p0, p1],
			"ai": [false, true], "seed": 100 + d, "speed": 50.0, "field3d": OS.get_cmdline_user_args().has("--3d"),
			"law": "" if d % 3 == 0 else DuelLaws.ids()[d % DuelLaws.ids().size()]})
		add_child(screen)
		var done := [false]
		screen.finished.connect(func(_r) -> void: done[0] = true)
		var frames := 0
		while not done[0] and frames < 40000:
			await get_tree().process_frame
			frames += 1
			if frames % 3 == 0:
				_poke()
		print("duel %d (%s vs %s): turn %d, winner %d, %s, taps %d" % [d, a, b, screen.game.turn, screen.game.winner, screen.game.win_reason, taps])
		screen.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _poke() -> void:
	# pop-ups first
	for c in screen.overlay.get_children():
		if c is DuelViews.CardPicker:
			for cell in c._cells:
				if c.picked.size() < c.max_n and rng.randf() < 0.7:
					c._toggle(cell)
			while c.picked.size() < c.min_n:
				for cell in c._cells:
					if not c.picked.has(cell.item):
						c._toggle(cell)
						break
			c.done.emit(c.picked.duplicate())
			return
		if c is DuelViews.Dialog:
			c.answered.emit(rng.randf() < 0.5)
			return
		if c.has_method("_draw") and c.get_class() == "PanelContainer":
			pass
	# result screen
	if screen.mode == "over":
		for b in _buttons(screen.overlay):
			if b.text == "Back to the Lab":
				b.pressed.emit()
				return
		return
	if screen.mode == "pick_slot":
		var v = screen.views[screen.pick_side][screen.targets[rng.randi() % screen.targets.size()]]
		screen._on_slot_tapped(v)
		taps += 1
		return
	if screen.mode != "main":
		return
	taps += 1
	if screen.pending != "":
		# resolve or cancel
		if screen.targets.is_empty() or rng.randf() < 0.1:
			screen._cancel_pending()
			return
		var t = screen.targets[rng.randi() % screen.targets.size()]
		if t is String and t == DuelGame.LIFE:
			screen._on_panel_tapped(screen.panels[screen.rival])
		elif t is DuelTotem:
			screen._on_slot_tapped(screen.views[t.owner][t.slot])
		elif t is int:
			screen._on_slot_tapped(screen.views[screen.pick_side if screen.pending != "shift" else screen.me][t])
		return
	# pressed action buttons?
	var acts := screen.actions.get_children().filter(func(n): return n is DuelScreen.ActionButton and n.enabled and not n.is_queued_for_deletion())
	if not acts.is_empty() and rng.randf() < 0.8:
		acts[rng.randi() % acts.size()].pressed.emit()
		return
	var r := rng.randf()
	var p: DuelPlayer = screen.game.players[screen.me]
	if r < 0.45 and not screen.hand_views.is_empty():
		screen._on_hand_tapped(screen.hand_views[rng.randi() % screen.hand_views.size()])
	elif r < 0.8 and not p.totems().is_empty():
		var t: DuelTotem = p.totems()[rng.randi() % p.totems().size()]
		screen._on_slot_tapped(screen.views[screen.me][t.slot])
	elif r < 0.85:
		screen._on_gift()
	else:
		screen._on_end_turn()


func _buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out
