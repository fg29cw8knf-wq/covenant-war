class_name DuelLab
extends Control
## The Duel Lab: a test bench for the v1 duel rules. Pick both decks, patrons
## and attribute levels, tweak the rules' numbers, then duel the computer,
## watch it play itself, or run a batch of quick test duels for win rates.

signal closed

const DESIGN := Vector2(1920, 1080)
const PATRONS := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith"]
const LEVELS := {"Easy": 0.45, "Normal": 0.8, "Hard": 1.0}

var cfg := {
	"deck": ["emberstorm", "tidegrove"],
	"patron": ["", "solmaris"],
	"level": [4, 4],
	"difficulty": "Normal",
}
var stage: Control
var _side_boxes := [null, null]
var _info := [null, null]
var _tune_rows := {}
var _result: Label
var _screen: DuelScreen = null
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var saved = Game.settings.get("duel_lab", {})
	if saved is Dictionary:
		for k in saved:
			cfg[k] = saved[k]
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := DuelArt.arena("solhaven")
	if art != null:
		var pic := TextureRect.new()
		pic.texture = art
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)
		var dim := ColorRect.new()
		dim.color = Color(UITheme.BG, 0.86)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
	stage = Control.new()
	stage.size = DESIGN
	add_child(stage)
	resized.connect(_fit)
	_build()
	_fit()
	if "--lab-watch" in OS.get_cmdline_user_args():
		_play(true)


func _fit() -> void:
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	stage.scale = Vector2(k, k)
	stage.position = ((size - DESIGN * k) * 0.5).floor()


func _build() -> void:
	var t := UITheme.label("Duel Lab", 54, UITheme.GOLD, "display_bold", 8)
	t.position = Vector2(60, 18)
	stage.add_child(t)
	var sub := UITheme.label("Test the v1 duel rules. Pick decks, tweak the numbers, then duel the computer or watch it play itself.", 26, UITheme.TEXT_DIM)
	sub.position = Vector2(64, 88)
	stage.add_child(sub)
	for side in 2:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UITheme.sb(UITheme.PANEL, UITheme.MINE if side == 0 else UITheme.THEIRS, 20, 2, 26))
		panel.position = Vector2(60 + side * 620, 136)
		panel.size = Vector2(590, 790)
		stage.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		panel.add_child(box)
		_side_boxes[side] = box
		_fill_side(side)
	_build_tuning()
	var row := HBoxContainer.new()
	row.position = Vector2(60, 956)
	row.add_theme_constant_override("separation", 20)
	stage.add_child(row)
	var duel := UITheme.button("Duel!", true, 290)
	duel.pressed.connect(func() -> void: _play(false))
	row.add_child(duel)
	var watch := UITheme.button("Watch the computer", false, 380)
	watch.pressed.connect(func() -> void: _play(true))
	row.add_child(watch)
	var test := UITheme.button("Test 200 duels", false, 320)
	test.pressed.connect(_run_tests)
	row.add_child(test)
	var back := UITheme.button("Back", false, 190)
	back.pressed.connect(func() -> void: closed.emit())
	row.add_child(back)
	_result = UITheme.label("", 22, UITheme.TEXT)
	_result.position = Vector2(1340, 940)
	_result.size = Vector2(540, 110)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(_result)


func _fill_side(side: int) -> void:
	var box: VBoxContainer = _side_boxes[side]
	for c in box.get_children():
		c.queue_free()
	box.add_child(UITheme.label("You" if side == 0 else "Rival (computer)", 36, UITheme.MINE if side == 0 else UITheme.THEIRS, "display_bold"))
	box.add_child(UITheme.label("Deck", 22, UITheme.TEXT_DIM, "bold"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for d in DuelCards.DECKS:
		var b := _toggle(DuelCards.DECKS[d].name, cfg.deck[side] == d, 264)
		b.pressed.connect(func() -> void:
			cfg.deck[side] = d
			_changed(side))
		grid.add_child(b)
	var desc := UITheme.label(DuelCards.DECKS[cfg.deck[side]].desc, 21, UITheme.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(538, 0)
	box.add_child(desc)
	box.add_child(UITheme.label("Patron god", 22, UITheme.TEXT_DIM, "bold"))
	var pg := GridContainer.new()
	pg.columns = 4
	pg.add_theme_constant_override("h_separation", 8)
	pg.add_theme_constant_override("v_separation", 8)
	box.add_child(pg)
	for g in PATRONS:
		var nm: String = "Unsworn" if g == "" else Lore.GODS[g].name
		var b := _toggle(nm, cfg.patron[side] == g, 128)
		b.add_theme_font_size_override("font_size", 20)
		b.custom_minimum_size = Vector2(128, 56)
		b.pressed.connect(func() -> void:
			cfg.patron[side] = g
			_changed(side))
		pg.add_child(b)
	var lv := HBoxContainer.new()
	lv.add_theme_constant_override("separation", 12)
	box.add_child(lv)
	lv.add_child(UITheme.label("Attribute level", 24, UITheme.TEXT_DIM, "bold"))
	var minus := _step_button("−")
	minus.pressed.connect(func() -> void:
		cfg.level[side] = maxi(1, int(cfg.level[side]) - 1)
		_changed(side))
	lv.add_child(minus)
	lv.add_child(UITheme.label(str(cfg.level[side]), 34, UITheme.TEXT, "display_bold"))
	var plus := _step_button("+")
	plus.pressed.connect(func() -> void:
		cfg.level[side] = mini(8, int(cfg.level[side]) + 1)
		_changed(side))
	lv.add_child(plus)
	if side == 1:
		var dl := HBoxContainer.new()
		dl.add_theme_constant_override("separation", 8)
		box.add_child(dl)
		dl.add_child(UITheme.label("Skill", 24, UITheme.TEXT_DIM, "bold"))
		for k in LEVELS:
			var b := _toggle(k, cfg.difficulty == k, 150)
			b.custom_minimum_size = Vector2(150, 58)
			b.pressed.connect(func() -> void:
				cfg.difficulty = k
				_changed(side))
			dl.add_child(b)
	var info := UITheme.label("", 22, UITheme.TEXT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(538, 0)
	box.add_child(info)
	_info[side] = info
	_update_info(side)


func _toggle(text: String, on: bool, w: int) -> Button:
	var b := UITheme.button(text, on, w)
	b.custom_minimum_size = Vector2(w, 62)
	b.add_theme_font_size_override("font_size", 24)
	if on:
		b.add_theme_stylebox_override("normal", UITheme.sb(Color("3a2f12"), UITheme.GOLD))
		b.add_theme_color_override("font_color", UITheme.GOLD)
	return b


func _step_button(t: String) -> Button:
	var b := UITheme.button(t, false, 72)
	b.custom_minimum_size = Vector2(72, 58)
	return b


func _changed(side: int) -> void:
	Game.settings["duel_lab"] = cfg.duplicate(true)
	Game.save_settings()
	_fill_side.call_deferred(side)


func profile(side: int) -> Dictionary:
	var p := Lore.new_profile("You" if side == 0 else "Rival", "", int(cfg.level[side]))
	var bumps: Dictionary = DuelCards.DECKS[cfg.deck[side]].get("attributes", {})
	for a in bumps:
		p.base[a] = mini(10, int(p.base[a]) + int(bumps[a]))
	Lore.set_patron(p, cfg.patron[side])
	return p


func _update_info(side: int) -> void:
	var p := profile(side)
	var a: Dictionary = p.attributes
	var parts := []
	for k in Lore.ATTRIBUTES:
		parts.append("%s %d" % [Lore.ATTRIBUTE_NAMES[k].substr(0, 3), a[k]])
	var perks := []
	for k in Lore.ATTRIBUTES:
		if DuelRules.has_perk(a, k):
			perks.append(Lore.ATTRIBUTE_NAMES[k])
	var gift: String = Lore.GIFTS[Lore.UNSWORN_GIFT if cfg.patron[side] == "" else Lore.GODS[cfg.patron[side]].gift].name
	_info[side].text = "%s\nLife %d  ·  Guard %d  ·  Gift: %s%s" % ["  ".join(parts), DuelRules.life_for(a), DuelRules.guard_for(a), gift,
		("\n7+ perks: " + ", ".join(perks)) if not perks.is_empty() else ""]


# ----------------------------------------------------------------- tuning ---

const TUNE_LABELS := {
	"life_base": ["Base Life", 10], "life_per_attribute": ["Life per attribute point", 1],
	"guard_min_hit": ["Smallest hit on Life", 5], "fatigue": ["Empty-deck Life loss", 10],
	"essence_cap": ["Essence limit", 1], "start_hand": ["Starting hand", 1],
	"second_player_bonus_cards": ["Extra cards going second", 1], "hand_limit": ["Hand limit", 1],
	"weakness_mult": ["Weakness multiplier", 0.25], "burn_damage": ["Burn damage", 5],
	"poison_damage": ["Poison damage", 5], "shift_cost": ["Shift cost", 1],
	"wrath_bonus": ["Wrath bonus", 5], "mercy_heal": ["Dawn's Mercy heal", 10],
}


func _build_tuning() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.sb(UITheme.PANEL, UITheme.GOLD_DIM, 20, 2, 18))
	panel.position = Vector2(1320, 136)
	panel.size = Vector2(540, 700)
	stage.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var tl := UITheme.label("Tune the rules", 34, UITheme.GOLD, "display_bold")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var reset := UITheme.button("Reset", false, 130)
	reset.custom_minimum_size = Vector2(130, 60)
	reset.add_theme_font_size_override("font_size", 22)
	reset.pressed.connect(func() -> void:
		DuelRules.reset()
		_refresh_tuning())
	head.add_child(reset)
	for key in DuelRules.tunables():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		v.add_child(row)
		var l := UITheme.label(TUNE_LABELS[key][0], 20, UITheme.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var m := _step_button("−")
		m.custom_minimum_size = Vector2(56, 40)
		m.add_theme_font_size_override("font_size", 22)
		m.pressed.connect(func() -> void: _nudge(key, -1))
		row.add_child(m)
		var val := UITheme.label("", 22, UITheme.GOLD, "bold")
		val.custom_minimum_size = Vector2(70, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val)
		var p := _step_button("+")
		p.custom_minimum_size = Vector2(56, 40)
		p.add_theme_font_size_override("font_size", 22)
		p.pressed.connect(func() -> void: _nudge(key, 1))
		row.add_child(p)
		_tune_rows[key] = val
	_refresh_tuning()


func _nudge(key: String, dir: int) -> void:
	var step = TUNE_LABELS[key][1]
	var v = DuelRules.get_value(key)
	if v is float:
		DuelRules.set_value(key, maxf(1.0, v + step * dir))
	else:
		DuelRules.set_value(key, maxi(0, int(v) + int(step) * dir))
	_refresh_tuning()


func _refresh_tuning() -> void:
	for key in _tune_rows:
		var v = DuelRules.get_value(key)
		_tune_rows[key].text = ("%.2f" % v) if v is float else str(v)
	for side in 2:
		if _info[side] != null:
			_update_info(side)


# ------------------------------------------------------------------- play ---

func _play(watch: bool) -> void:
	if _screen != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_screen = DuelScreen.new().configure({
		"decks": cfg.deck.duplicate(),
		"names": [Game.player_name if not watch else DuelCards.DECKS[cfg.deck[0]].name, "Rival" if not watch else DuelCards.DECKS[cfg.deck[1]].name],
		"profiles": [profile(0), profile(1)],
		"ai": [watch, true],
		"difficulty": LEVELS.get(cfg.difficulty, 0.8),
	})
	layer.add_child(_screen)
	var r: String = await _screen.finished
	layer.queue_free()
	_screen = null
	if r == "again":
		_play(watch)


func _run_tests() -> void:
	if _busy:
		return
	_busy = true
	var n := 200
	var wins := [0, 0]
	var turns := 0
	var first := 0
	for g in n:
		var game := DuelGame.new()
		game.setup(cfg.deck.duplicate(), ["A", "B"], [DuelAI.new(1.0, g * 2 + 1), DuelAI.new(LEVELS.get(cfg.difficulty, 0.8), g * 2 + 2)],
			[profile(0), profile(1)], 7000 + g)
		await game.run()
		if game.winner in [0, 1]:
			wins[game.winner] += 1
			if game.winner == game.first_player:
				first += 1
		turns += game.turn
		if g % 5 == 4:
			_result.text = "Testing… %d / %d" % [g + 1, n]
			await get_tree().process_frame
	_result.text = "%d test duels: %s wins %d%%, %s wins %d%%  ·  average %.1f turns  ·  first player wins %d%%" % [n,
		DuelCards.DECKS[cfg.deck[0]].name, 100 * wins[0] / n, DuelCards.DECKS[cfg.deck[1]].name, 100 * wins[1] / n,
		float(turns) / n, 100 * first / maxi(1, wins[0] + wins[1])]
	_busy = false
