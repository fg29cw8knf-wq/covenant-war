class_name DuelScreen
extends Control
## The duel, v1 rules: three Totem slots a side, Life, Essence, Fate dice and
## Wards. Draws the Circle, takes the player's taps and animates everything
## the rules engine (DuelGame) reports.
##
## configure(spec) with:
##   decks: [deck id | Array of card ids] x2     names: [String] x2
##   profiles: [Lore.new_profile(...)] x2        ai: [bool, bool] (who the computer plays)
##   difficulty: 0..1                            seed: int (-1 = random)
##   speed: 1.0, 2.0, 4.0
## Emits finished("won" | "lost" | "draw" | "again" | "quit").

signal finished(result: String)

const DESIGN := Vector2(1920, 1080)
const SLOT_SIZE := Vector2(340, 330)
const SLOT_X := [370.0, 760.0, 1150.0]
const ROW_Y := [430.0, 60.0]           # [me, rival] once `me` is known (see _row_y)
const HAND_Y := 800.0
const HAND_CARD := Vector2(176, 246)
const RIGHT_X := 1548.0
const LOG_MAX := 200
## The colour of the drifting light in each arena.
const ARENA_MOTES := {
	"solhaven": Color(1.0, 0.9, 0.6), "emberforge": Color(1.0, 0.55, 0.25), "tidegrove": Color(0.6, 1.0, 0.85),
	"ironstone": Color(1.0, 0.8, 0.45), "veilwild": Color(0.75, 0.55, 1.0),
}

var spec: Dictionary = {}
var game: DuelGame
var human: DuelHuman
var me := 0
var rival := 1
var speed := 1.0
var sfx: Sfx

var stage: Control
var fx_layer: Control
var overlay: Control
var views := [[], []]          # [side][slot] -> TotemView
var panels := []               # [side] -> PlayerPanel
var hand_views: Array = []
var detail: DetailCard
var actions: VBoxContainer
var hint: Label
var turn_label: Label
var end_btn: Button
var gift_btn: Button
var log_panel: PanelContainer
var log_text: RichTextLabel
var lab_panel: PanelContainer

var mode := "idle"             # idle, main, pick_slot, busy, over
var sel_card: DuelCard = null
var sel_totem: DuelTotem = null
var sel_move := -1
var pending := ""              # call, ascend, rite, summon, move, shift, gift
var targets: Array = []        # DuelTotem | "life" | int (slot index, on pick_side)
var pick_side := 0
var reveal_rival := false
var _log_lines: Array = []
var _result := ""


func configure(p_spec: Dictionary) -> DuelScreen:
	spec = p_spec
	return self


# ================================================================== build ===

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	speed = float(spec.get("speed", Game.settings.get("duel_speed", 1.0)))
	sfx = Sfx.new()
	add_child(sfx)
	sfx.volume_db = linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.9)))) - 8.0
	var bg := Arena.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var arena_name: String = spec.get("arena", "")
	if arena_name == "":
		var decks: Array = spec.get("decks", ["emberstorm", "tidegrove"])
		arena_name = DuelArt.arena_for_deck(decks[1] if decks.size() > 1 else "")
	bg.tex = DuelArt.arena(arena_name)
	bg.mote_col = ARENA_MOTES.get(arena_name, bg.mote_col)
	add_child(bg)
	stage = Control.new()
	stage.size = DESIGN
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	bg.stage = stage
	_build()
	fx_layer = Control.new()
	fx_layer.size = DESIGN
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = 50          # above the fanned hand (which uses z_index for its order)
	stage.add_child(fx_layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)
	resized.connect(_fit)
	_fit()
	_start.call_deferred()


func _fit() -> void:
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	stage.scale = Vector2(k, k)
	stage.position = ((size - DESIGN * k) * 0.5).floor()


## "Wren's", or "Your" for a duellist called You.
func _whose(player_name: String) -> String:
	return "Your" if player_name == "You" else "%s's" % player_name


func _row_y(side: int) -> float:
	return 430.0 if side == me else 60.0


func _build() -> void:
	# the Circle's slots
	for side in 2:
		views[side] = []
		for s in DuelRules.SLOTS:
			var v := DuelViews.TotemView.new()
			v.side = side
			v.slot = s
			v.size = SLOT_SIZE
			v.tapped.connect(_on_slot_tapped)
			stage.add_child(v)
			views[side].append(v)
	# duellist panels
	for side in 2:
		var p := DuelViews.PlayerPanel.new()
		p.size = Vector2(300, 400)
		p.tapped.connect(_on_panel_tapped)
		stage.add_child(p)
		panels.append(p)
	# hint and turn line
	hint = UITheme.label("", 30, UITheme.GOLD, "bold", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(340, 392)
	hint.size = Vector2(1180, 40)
	stage.add_child(hint)
	turn_label = UITheme.label("", 24, UITheme.TEXT_DIM, "bold", 4)
	turn_label.position = Vector2(340, 16)
	turn_label.size = Vector2(1180, 34)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(turn_label)
	# right column: detail card, actions, gift, end turn
	var top := HBoxContainer.new()
	top.position = Vector2(RIGHT_X, 14)
	top.size = Vector2(356, 72)
	top.add_theme_constant_override("separation", 12)
	stage.add_child(top)
	var log_btn := _small_button("Log")
	log_btn.pressed.connect(func() -> void: log_panel.visible = not log_panel.visible)
	top.add_child(log_btn)
	var lab_btn := _small_button("Lab")
	lab_btn.pressed.connect(func() -> void: lab_panel.visible = not lab_panel.visible)
	top.add_child(lab_btn)
	detail = DetailCard.new()
	detail.position = Vector2(RIGHT_X + 43, 96)
	detail.size = Vector2(270, 378)
	stage.add_child(detail)
	actions = VBoxContainer.new()
	actions.position = Vector2(RIGHT_X, 488)
	actions.size = Vector2(356, 366)
	actions.add_theme_constant_override("separation", 10)
	stage.add_child(actions)
	gift_btn = UITheme.button("Divine Gift", false, 356)
	gift_btn.position = Vector2(RIGHT_X, 866)
	gift_btn.size = Vector2(356, 88)
	gift_btn.add_theme_font_size_override("font_size", 26)
	gift_btn.pressed.connect(_on_gift)
	stage.add_child(gift_btn)
	end_btn = UITheme.button("End Turn", true, 356)
	end_btn.position = Vector2(RIGHT_X, 966)
	end_btn.size = Vector2(356, 96)
	end_btn.pressed.connect(_on_end_turn)
	stage.add_child(end_btn)
	_build_log()
	_build_lab()


func _small_button(t: String) -> Button:
	var b := UITheme.button(t, false, 170)
	b.custom_minimum_size = Vector2(172, 72)
	b.add_theme_font_size_override("font_size", 26)
	return b


func _build_log() -> void:
	log_panel = PanelContainer.new()
	log_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.07, 0.96), UITheme.GOLD_DIM, 18, 2, 18))
	log_panel.position = Vector2(RIGHT_X - 520, 96)
	log_panel.size = Vector2(876, 680)
	log_panel.visible = false
	stage.add_child(log_panel)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.add_theme_font_override("normal_font", CardFace.font("body"))
	log_text.add_theme_font_size_override("normal_font_size", 24)
	log_panel.add_child(log_text)


func _build_lab() -> void:
	lab_panel = PanelContainer.new()
	lab_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.07, 0.97), UITheme.GOLD_DIM, 18, 2, 24))
	lab_panel.position = Vector2(RIGHT_X - 200, 96)
	lab_panel.size = Vector2(556, 600)
	lab_panel.visible = false
	stage.add_child(lab_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	lab_panel.add_child(box)
	box.add_child(UITheme.label("Duel Lab", 34, UITheme.GOLD, "display_bold"))
	box.add_child(UITheme.label("Animation speed", 24, UITheme.TEXT_DIM))
	var sp := HBoxContainer.new()
	sp.add_theme_constant_override("separation", 10)
	box.add_child(sp)
	for v in [1.0, 2.0, 4.0]:
		var b := _small_button("%dx" % int(v))
		b.custom_minimum_size = Vector2(160, 72)
		b.pressed.connect(func() -> void:
			speed = v
			Game.settings["duel_speed"] = v
			Game.save_settings())
		sp.add_child(b)
	var rv := CheckButton.new()
	rv.text = "Show the rival's hand and Wards"
	rv.add_theme_font_size_override("font_size", 24)
	rv.toggled.connect(func(on: bool) -> void:
		reveal_rival = on
		panels[rival].reveal_wards = on
		_refresh())
	box.add_child(rv)
	var again := UITheme.button("Restart this duel", false, 500)
	again.pressed.connect(func() -> void: _leave("again"))
	box.add_child(again)
	var quit := UITheme.button("Leave the duel", false, 500)
	quit.pressed.connect(func() -> void: _leave("quit"))
	box.add_child(quit)


func _leave(result: String) -> void:
	if mode == "over":
		return
	mode = "over"
	if game != null and not game.over:
		game._finish(2, "The duel was abandoned.")
	finished.emit(result)


# ================================================================== start ===

func _start() -> void:
	var ai_flags: Array = spec.get("ai", [false, true])
	me = 0
	rival = 1
	human = DuelHuman.new()
	human.screen = self
	var controllers := []
	for i in 2:
		if ai_flags[i]:
			var a := DuelHuman.Paced.new(float(spec.get("difficulty", 1.0)))
			a.screen = self
			controllers.append(a)
		else:
			controllers.append(human)
	game = DuelGame.new()
	game.setup(spec.get("decks", ["emberstorm", "tidegrove"]), spec.get("names", ["You", "Rival"]),
		controllers, spec.get("profiles", []), int(spec.get("seed", -1)))
	game.presenter = self
	game.logged.connect(_on_log)
	game.state_changed.connect(_refresh)
	for side in 2:
		for v in views[side]:
			v.mine = side == me
			v.position = Vector2(SLOT_X[v.slot], _row_y(side))
	panels[rival].position = Vector2(20, 20)
	panels[me].position = Vector2(20, 660)
	for side in 2:
		panels[side].player = game.players[side]
		panels[side].mine = side == me
	_refresh()
	await game.run()
	if mode == "over":
		return
	mode = "over"
	_refresh()
	var r := "draw"
	if game.winner == me:
		r = "won"
	elif game.winner == rival:
		r = "lost"
	var choice: String = await _show_result(r)
	finished.emit(choice if choice != "" else r)


func pause(sec: float) -> void:
	await get_tree().create_timer(maxf(0.01, sec / speed)).timeout


# ================================================================ refresh ===

func _refresh() -> void:
	if game == null:
		return
	for side in 2:
		var p: DuelPlayer = game.players[side]
		for v in views[side]:
			v.set_totem(p.slots[v.slot])
		panels[side].active = game.current == side and not game.over
	_layout_hand()
	_update_highlights()
	var cur: DuelPlayer = game.players[game.current]
	if game.turn > 0:
		var whose := "Your turn" if game.current == me and not _watching() else "%s turn" % _whose(cur.player_name)
		if cur.player_name == "You":
			whose = "Your turn"
		turn_label.text = "Turn %d  ·  %s" % [game.turn, whose]
	var my_turn := mode == "main"
	end_btn.disabled = not my_turn
	var mp: DuelPlayer = game.players[me]
	gift_btn.text = "%s%s" % [Lore.GIFTS[mp.gift()].name, "  (used)" if mp.gift_used else ""]
	gift_btn.disabled = not my_turn or game.gift_problem(me) != ""
	if my_turn and not game.can_do_anything_but_end(me) and pending == "":
		end_btn.modulate = Color(1.2, 1.1, 0.8)
	else:
		end_btn.modulate = Color.WHITE


func _watching() -> bool:
	var ai_flags: Array = spec.get("ai", [false, true])
	return ai_flags[me]


func _layout_hand() -> void:
	var p: DuelPlayer = game.players[me]
	var keep := {}
	for hv in hand_views:
		keep[hv.card] = hv
	var fresh := []
	for c in p.hand:
		var hv: DuelViews.HandCard = keep.get(c)
		if hv == null:
			hv = DuelViews.HandCard.new(c)
			hv.size = HAND_CARD
			hv.tapped.connect(_on_hand_tapped)
			stage.add_child(hv)
			hv.position = Vector2(930, 1100)
		keep.erase(c)
		fresh.append(hv)
	for c in keep:
		keep[c].queue_free()
	hand_views = fresh
	var n := hand_views.size()
	var area_w := 1160.0
	var step := minf(HAND_CARD.x + 12, (area_w - HAND_CARD.x) / maxf(1.0, n - 1))
	var total := step * (n - 1) + HAND_CARD.x
	var x0 := 340.0 + (area_w - total) * 0.5 + 10
	for i in n:
		var hv: DuelViews.HandCard = hand_views[i]
		var target := Vector2(x0 + i * step, HAND_Y)
		if hv.position.distance_to(target) > 2:
			var tw := hv.create_tween()
			tw.tween_property(hv, "position", target, 0.22 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		hv.z_index = i
		hv.attrs = p.attributes()
		hv.cost_shown = _card_cost(hv.card)
		hv.state = _hand_state(hv.card)
		if _watching():
			hv.state = "normal"


func _card_cost(c: DuelCard) -> int:
	if c.is_basic_totem():
		return game.call_cost(me, c)
	if c.is_summon():
		return game.summon_cost(me, c)
	return c.cost()


func _hand_state(c: DuelCard) -> String:
	if c == sel_card:
		return "selected"
	var p: DuelPlayer = game.players[me]
	if _card_cost(c) > p.essence:
		return "unaffordable"
	if mode != "main":
		return "normal"
	var ok := false
	match c.kind():
		"totem":
			ok = game.call_problem(me, c) == "" if c.is_basic_totem() else game.ascend_problem(me, c) == ""
		"rite":
			ok = game.rite_problem(me, c) == ""
		"ward":
			ok = game.ward_problem(me, c) == ""
		"summon":
			ok = game.summon_problem(me, c) == ""
	return "playable" if ok else "normal"


func _update_highlights() -> void:
	for side in 2:
		for v in views[side]:
			var h := ""
			if pending != "" or mode == "pick_slot":
				if v.totem != null and targets.has(v.totem):
					h = "target"
				elif v.totem == null and side == pick_side and targets.has(v.slot) and (pending == "call" or pending == "shift" or mode == "pick_slot"):
					h = "target"
				elif pending == "shift" and side == me and targets.has(v.slot) and v.totem != sel_totem:
					h = "target"
			if v.totem != null and v.totem == sel_totem:
				h = "selected"
			if h == "" and mode == "main" and side == me and v.totem != null and _has_usable_move(v.totem):
				h = "ready"
			v.highlight = h
	panels[rival].targetable = targets.has(DuelGame.LIFE)
	panels[me].targetable = false


func _has_usable_move(t: DuelTotem) -> bool:
	for i in t.moves().size():
		if game.move_problem(me, t, i) == "":
			return true
	return false


# ============================================================== main mode ===

func begin_main() -> void:
	mode = "main"
	_clear_selection()
	_set_hint("Your turn. Tap a card or one of your Totems.")
	_refresh()
	_show_actions_default()


func _clear_selection() -> void:
	sel_card = null
	sel_totem = null
	sel_move = -1
	pending = ""
	targets = []


func _respond(value) -> void:
	mode = "busy"
	_clear_selection()
	_set_hint("")
	_clear_actions()
	_refresh()
	human.responded.emit(value)


func _set_hint(t: String) -> void:
	hint.text = t


func _on_end_turn() -> void:
	if mode == "main":
		sfx.play("click")
		_respond({"type": "end"})


func _on_gift() -> void:
	if mode != "main":
		return
	var prob := game.gift_problem(me)
	if prob != "":
		_toast(prob)
		return
	var ts := game.gift_targets(me)
	var g: String = game.players[me].gift()
	_clear_selection()
	_clear_actions()
	_add_note("Your Divine Gift can be used once per duel.")
	if ts.is_empty():
		_add_action("Use %s" % Lore.GIFTS[g].name, DuelCards.gift_text(g), 0, true,
			func() -> void: _respond({"type": "gift"}))
		_show_cancel()
		_set_hint(DuelCards.gift_text(g))
		_refresh()
		return
	pending = "gift"
	targets = ts
	_set_hint("%s: choose one of your Totems." % Lore.GIFTS[g].name)
	_show_cancel()
	_refresh()


func _on_panel_tapped(panel) -> void:
	if mode == "main" and pending != "" and targets.has(DuelGame.LIFE) and panel == panels[rival]:
		_resolve(DuelGame.LIFE)


func _on_hand_tapped(hv) -> void:
	var c: DuelCard = hv.card
	detail.show_card(c.id, {"attrs": game.players[me].attributes(), "cost": _card_cost(c)})
	if mode != "main":
		return
	sfx.play("select")
	if sel_card == c:
		_clear_selection()
		_set_hint("Your turn. Tap a card or one of your Totems.")
		_show_actions_default()
		_refresh()
		return
	_clear_selection()
	sel_card = c
	var p: DuelPlayer = game.players[me]
	_clear_actions()
	match c.kind():
		"totem":
			if c.is_basic_totem():
				var prob := game.call_problem(me, c)
				if prob != "":
					_add_note(prob)
				else:
					pending = "call"
					pick_side = me
					targets = p.empty_slots()
					_set_hint("Tap an empty slot to call %s." % c.card_name())
					_show_cancel()
			else:
				var prob := game.ascend_problem(me, c)
				if prob != "":
					_add_note(prob)
				else:
					pending = "ascend"
					targets = game.ascend_targets(me, c)
					_set_hint("Tap %s to Ascend it." % DuelCards.CARDS[c.def.ascends_from].name)
					_show_cancel()
		"rite":
			var prob := game.rite_problem(me, c)
			if prob != "":
				_add_note(prob)
			elif game.rite_needs_target(c):
				pending = "rite"
				targets = game.rite_targets(me, c).filter(func(t): return game.rite_problem(me, c, t) == "")
				_set_hint("Choose a target for %s." % c.card_name())
				_show_cancel()
			else:
				_add_action("Cast %s" % c.card_name(), DuelCards.card_text(c.id), c.cost(), true,
					func() -> void: _respond({"type": "rite", "card": c}))
		"ward":
			var prob := game.ward_problem(me, c)
			if prob != "":
				_add_note(prob)
			else:
				_add_action("Set face down", DuelCards.TRIGGER_TEXT.get(c.def.trigger, "") + ".", c.cost(), true,
					func() -> void: _respond({"type": "ward", "card": c}))
		"summon":
			var prob := game.summon_problem(me, c)
			if prob != "":
				_add_note(prob)
			elif game.summon_needs_target(c):
				pending = "summon"
				targets = game.players[rival].totems()
				_set_hint("Choose the enemy Totem %s will strike." % c.card_name())
				_show_cancel()
			else:
				_add_action("Call down %s" % c.def.name.get_slice(",", 0), DuelCards.card_text(c.id), game.summon_cost(me, c), true,
					func() -> void: _respond({"type": "summon", "card": c}))
	_refresh()


func _on_slot_tapped(v) -> void:
	if v.totem != null:
		var opts := {"hp_left": v.totem.hp_left(), "attrs": v.totem.attrs}
		detail.show_card(v.totem.id(), opts)
	if mode == "pick_slot":
		if v.side == pick_side and v.totem == null and targets.has(v.slot):
			var s: int = v.slot
			mode = "busy"
			targets = []
			_set_hint("")
			_refresh()
			human.responded.emit(s)
		return
	if mode != "main":
		return
	if pending != "":
		match pending:
			"call":
				if v.side == me and v.totem == null and targets.has(v.slot):
					_respond({"type": "call", "card": sel_card, "slot": v.slot})
					return
			"shift":
				if v.side == me and v.slot != sel_totem.slot:
					_respond({"type": "shift", "totem": sel_totem, "slot": v.slot})
					return
			_:
				if v.totem != null and targets.has(v.totem):
					_resolve(v.totem)
					return
	if v.totem != null and v.side == me:
		_select_totem(v.totem)
	elif pending != "":
		_cancel_pending()


func _resolve(target) -> void:
	match pending:
		"ascend":
			_respond({"type": "ascend", "card": sel_card, "target": target})
		"rite":
			_respond({"type": "rite", "card": sel_card, "target": target})
		"summon":
			_respond({"type": "summon", "card": sel_card, "target": target})
		"move":
			_respond({"type": "attack", "attacker": sel_totem, "move": sel_move, "target": target})
		"gift":
			_respond({"type": "gift", "target": target})


func _cancel_pending() -> void:
	sfx.play("click")
	var t := sel_totem
	_clear_selection()
	if t != null:
		_select_totem(t)
		return
	_set_hint("Your turn. Tap a card or one of your Totems.")
	_show_actions_default()
	_refresh()


func _select_totem(t: DuelTotem) -> void:
	sfx.play("select")
	_clear_selection()
	sel_totem = t
	detail.show_card(t.id(), {"hp_left": t.hp_left(), "attrs": t.attrs})
	_clear_actions()
	var ready := game.ready_problem(me, t)
	if ready != "":
		_add_note(ready)
	for i in t.moves().size():
		var mv := t.move(i)
		var prob := game.move_problem(me, t, i)
		var sub := DuelCardFace.move_detail(mv)
		var dmg := int(mv.get("damage", 0))
		var title: String = mv.name
		if not mv.has("fate") and dmg > 0:
			title += "  —  %d" % (dmg + t.damage_bonus(i) + (DuelRules.wrath_bonus if game.players[me].wrath else 0))
		elif mv.has("fate"):
			title += "  —  d20"
		if ready == "" and prob != "":
			sub = prob
		var idx := i
		_add_action(title, sub, t.move_cost(i), prob == "", func() -> void: _choose_move(t, idx))
	if game.shift_problem(me, t, (t.slot + 1) % DuelRules.SLOTS) == "":
		var sc := game.shift_cost(me)
		_add_action("Shift", "Move to another slot (swaps if taken).", sc, true, func() -> void:
			_clear_selection()
			sel_totem = t
			pending = "shift"
			pick_side = me
			targets = range(DuelRules.SLOTS).filter(func(s): return s != t.slot)
			_set_hint("Tap the slot to shift %s to." % t.card_name())
			_clear_actions()
			_show_cancel()
			_refresh())
	_set_hint("%s: choose a move." % t.card_name())
	_refresh()


func _choose_move(t: DuelTotem, i: int) -> void:
	var ts := game.attack_targets(me, t, i)
	if ts.size() == 1 and ts[0] is String and ts[0] == DuelGame.NONE:
		_respond({"type": "attack", "attacker": t, "move": i, "target": DuelGame.NONE})
		return
	sfx.play("select")
	sel_totem = t
	sel_move = i
	pending = "move"
	targets = ts
	var life := ts.has(DuelGame.LIFE)
	var tk := t.move_target(i)
	if tk == "ally":
		_set_hint("Choose one of your Totems.")
	elif life:
		_set_hint("Choose a target, or tap %s's Life." % game.players[rival].player_name)
	else:
		_set_hint("Choose an enemy Totem.")
	_clear_actions()
	_show_cancel()
	_refresh()


# ============================================================ action list ===

func _clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()


func _show_actions_default() -> void:
	_clear_actions()
	var p: DuelPlayer = game.players[me]
	var any := false
	for t in p.totems():
		if _has_usable_move(t):
			any = true
	if any:
		_add_note("Glowing Totems are ready to attack. Tap one to choose a move.")
	elif game.can_do_anything_but_end(me):
		_add_note("Tap a glowing card in your hand to play it.")
	else:
		_add_note("Nothing left to do. End your turn.")


func _show_cancel() -> void:
	var b := UITheme.button("Cancel", false, 356)
	b.custom_minimum_size = Vector2(356, 80)
	b.pressed.connect(_cancel_pending)
	actions.add_child(b)


func _add_note(t: String) -> void:
	var l := UITheme.label(t, 25, UITheme.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(356, 0)
	actions.add_child(l)


func _add_action(title: String, sub: String, cost: int, enabled: bool, cb: Callable) -> void:
	var b := ActionButton.new()
	b.title = title
	b.sub = sub
	b.cost = cost
	b.enabled = enabled
	b.custom_minimum_size = Vector2(356, 108)
	b.pressed.connect(func() -> void:
		if b.enabled:
			cb.call())
	actions.add_child(b)


# =========================================================== human pickers ===

func begin_pick_cards(prompt: String, items: Array, min_n: int, max_n: int, context: Dictionary) -> void:
	mode = "busy"
	var picker := DuelViews.CardPicker.new().setup(prompt, items, min_n, max_n, context.get("wards", []))
	overlay.add_child(picker)
	var chosen: Array = await picker.done
	picker.queue_free()
	human.responded.emit(chosen)


func begin_pick_slot(prompt: String, slots: Array, context: Dictionary) -> void:
	mode = "pick_slot"
	pick_side = rival if context.get("reason", "") == "move_foe" else me
	targets = slots
	_set_hint(prompt)
	_refresh()


func begin_reroll(info: Dictionary) -> void:
	mode = "busy"
	var b: Dictionary = info.bands[info.index]
	var res := DuelCards.outcome_text(int(b.get("damage", 0)), b.get("effects", []), "foe", b.get("text", "Miss"))
	var p: DuelPlayer = game.players[me]
	var d := DuelViews.Dialog.new().setup("You rolled %d: %s.\nSpend Fortune to re-roll? (%d left)" % [int(info.total), res, p.fortune_left],
		"Re-roll", "Keep it")
	overlay.add_child(d)
	var yes: bool = await d.answered
	d.queue_free()
	human.responded.emit(yes)


func begin_scry(card: DuelCard) -> void:
	mode = "busy"
	var d := DuelViews.Dialog.new().setup("Insight shows the top card of your deck.", "Keep it on top", "Send it to the bottom", card.id)
	overlay.add_child(d)
	var yes: bool = await d.answered
	d.queue_free()
	human.responded.emit(yes)


## Shows what the computer is about to do, so its turn can be followed.
func preview_ai_action(pi: int, a: Dictionary) -> void:
	match a.get("type", ""):
		"attack":
			var t: DuelTotem = a.attacker
			var v: DuelViews.TotemView = views[pi][t.slot]
			v.highlight = "selected"
			var tg = a.get("target")
			if tg is DuelTotem:
				views[tg.owner][tg.slot].highlight = "target"
			elif tg is String and tg == DuelGame.LIFE:
				panels[1 - pi].targetable = true
			await pause(0.35)
			panels[1 - pi].targetable = false
		"call", "rite", "summon", "ascend":
			var c: DuelCard = a.card
			detail.show_card(c.id, {"cost": c.cost()})
			await pause(0.25)


# ================================================================ effects ===

func _view(t: DuelTotem) -> DuelViews.TotemView:
	return views[t.owner][t.slot]


func _center(v: Control) -> Vector2:
	return v.position + v.size * Vector2(0.5, 0.36)


func _life_center(pi: int) -> Vector2:
	var p: DuelViews.PlayerPanel = panels[pi]
	return p.position + p.life_rect().get_center()


func fx_start() -> void:
	await _banner("DUEL!", UITheme.GOLD, 0.8)


func fx_rolloff(r0: int, r1: int) -> void:
	var names: Array = spec.get("names", ["You", "Rival"])
	await _banner("%s %d  ·  %s %d" % [names[0], r0, names[1], r1], UITheme.TEXT, 1.0, 44)


func fx_turn(pi: int) -> void:
	_refresh()
	sfx.play("turn")
	var t := "YOUR TURN" if pi == me and not _watching() else ("%s turn" % _whose(game.players[pi].player_name)).to_upper()
	await _banner(t, UITheme.MINE if pi == me else UITheme.THEIRS, 0.7)


func fx_draw(pi: int, cards: Array) -> void:
	_refresh()
	if pi == me:
		sfx.play("card")
		for hv in hand_views:
			if cards.has(hv.card):
				hv.position = panels[me].position + Vector2(100, 200)
		_layout_hand()
		await pause(0.3)


func fx_call(t: DuelTotem) -> void:
	var v := _view(t)
	v.set_totem(t)
	v.pop = 0.2
	v.fade = 0.0
	v.flash = 1.0
	v.flash_color = Color(1, 1, 0.9)
	sfx.play("energy")
	_layout_hand()
	_beam(_center(v), Lore.color(t.element(), 0))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "pop", 1.0, 0.4 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "fade", 1.0, 0.25 / speed)
	tw.tween_property(v, "flash", 0.0, 0.5 / speed)
	await pause(0.45)


func fx_ascend(t: DuelTotem) -> void:
	var v := _view(t)
	v.set_totem(t)
	v.flash = 1.0
	v.flash_color = UITheme.GOLD
	sfx.play("evolve")
	_layout_hand()
	DuelViews.float_text(fx_layer, _center(v), "ASCENDED!", UITheme.GOLD, 44, 1.1 / speed)
	var tw := create_tween().set_parallel(true)
	v.pop = 1.18
	tw.tween_property(v, "pop", 1.0, 0.45 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "flash", 0.0, 0.6 / speed)
	await pause(0.6)


func fx_rite(pi: int, card: DuelCard, _target) -> void:
	sfx.play("card")
	_layout_hand()
	await _show_card_big(card.id, "RITE", DuelCardFace.RITE_COL, 0.7 if pi != me else 0.35)


func fx_ward_set(pi: int, _card: DuelCard) -> void:
	sfx.play("card")
	_layout_hand()
	DuelViews.float_text(fx_layer, panels[pi].position + Vector2(150, 330), "Ward set", Color("d9a6f0"), 34, 0.9 / speed)
	await pause(0.3)


func fx_ward_spring(_pi: int, card: DuelCard, _ctx: Dictionary) -> void:
	sfx.play("gift")
	await _show_card_big(card.id, "WARD!", DuelCardFace.WARD_COL, 0.9)


func fx_shift(_pi: int) -> void:
	sfx.play("select")
	for side in 2:
		for v in views[side]:
			v.set_totem(game.players[side].slots[v.slot])
	await pause(0.25)


func fx_attack(t: DuelTotem, i: int, target) -> void:
	var v := _view(t)
	var src := _center(v)
	var dest := src + Vector2(0, -120 if t.owner == me else 120)
	if target is DuelTotem:
		dest = _center(_view(target))
	elif target is String and target == DuelGame.LIFE:
		dest = _life_center(1 - t.owner)
	DuelViews.float_text(fx_layer, src + Vector2(0, -150), String(t.move(i).name), UITheme.GOLD, 36, 0.9 / speed)
	var d := (dest - src) * 0.3
	var tw := create_tween()
	tw.tween_property(v, "offset", d, 0.14 / speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(v, "offset", Vector2.ZERO, 0.22 / speed).set_ease(Tween.EASE_OUT)
	await pause(0.16)


func fx_roll(_pi: int, info: Dictionary) -> void:
	var dv := DuelViews.DiceView.new()
	dv.info = info
	dv.position = Vector2(340, 300)
	dv.size = Vector2(1180, 400)
	fx_layer.add_child(dv)
	var steps := int(14 / maxf(1.0, speed * 0.7))
	for k in steps:
		dv.face = randi_range(1, 20)
		dv.spin += 0.5
		sfx.play("click", 1.4 + randf() * 0.3)
		await pause(0.05)
	dv.face = int(info.roll)
	dv.spin = 0.0
	dv.landed = true
	sfx.play("coin")
	await pause(1.2)
	dv.queue_free()


func fx_totem_hit(t: DuelTotem, amount: int, info: Dictionary) -> void:
	var v := _view(t)
	if v.totem != t:
		v.set_totem(t)
	var c := _center(v)
	var absorbed := int(info.get("absorbed", 0))
	if absorbed > 0:
		DuelViews.float_text(fx_layer, c + Vector2(90, -30), "◈ -%d" % absorbed, Color("9fe8ff"), 40, 0.9 / speed)
	if amount <= 0:
		await pause(0.2)
		return
	sfx.play("hit")
	v.flash = 1.0
	v.flash_color = Color(1, 0.25, 0.2)
	var weak := t.weak_to(info.get("attacker").element()) if info.get("attacker") != null else false
	DuelViews.float_text(fx_layer, c, "-%d" % amount, Color("ff6a5a"), 64, 1.0 / speed)
	if weak:
		DuelViews.float_text(fx_layer, c + Vector2(0, 60), "Weak!", Color("ffd166"), 30, 0.9 / speed)
	var tw := create_tween()
	for k in 4:
		tw.tween_property(v, "offset", Vector2(randf_range(-14, 14), randf_range(-6, 6)), 0.04 / speed)
	tw.tween_property(v, "offset", Vector2.ZERO, 0.05 / speed)
	create_tween().tween_property(v, "flash", 0.0, 0.4 / speed)
	await pause(0.38)


func fx_life_hit(pi: int, amount: int, info: Dictionary) -> void:
	var p: DuelViews.PlayerPanel = panels[pi]
	sfx.play("hit", 0.7)
	p.flash = 1.0
	p.shake = 8.0
	var label := "-%d" % amount
	if info.get("spill", false):
		label += " spill-over"
	DuelViews.float_text(fx_layer, _life_center(pi) + Vector2(0, -10), label, Color("ff4d6a"), 56 if not info.get("spill", false) else 44, 1.1 / speed)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "flash", 0.0, 0.5 / speed)
	tw.tween_property(p, "shake", 0.0, 0.4 / speed)
	if pi == me:
		_screen_flash(Color(1, 0, 0, 0.25))
	await pause(0.45)


func fx_heal(t: DuelTotem, amount: int) -> void:
	var v := _view(t)
	sfx.play("heal")
	v.flash = 0.8
	v.flash_color = Color("7ee08a")
	create_tween().tween_property(v, "flash", 0.0, 0.5 / speed)
	DuelViews.float_text(fx_layer, _center(v), "+%d" % amount, Color("7ee08a"), 52, 1.0 / speed)
	await pause(0.3)


func fx_life_gain(pi: int, amount: int) -> void:
	sfx.play("heal")
	if amount > 0:
		DuelViews.float_text(fx_layer, _life_center(pi), "+%d" % amount, Color("7ee08a"), 52, 1.0 / speed)
	else:
		DuelViews.float_text(fx_layer, _life_center(pi), "Survived!", UITheme.GOLD, 46, 1.2 / speed)
	await pause(0.35)


func fx_status(t: DuelTotem, status: String) -> void:
	var v := _view(t)
	var col: Color = {"burn": Color("ff9a4a"), "poison": Color("9be15d"), "stun": Color("ffe066"), "sleep": Color("b9a4ff")}[status]
	DuelViews.float_text(fx_layer, _center(v) + Vector2(0, 50), DuelCards.STATUS_NAMES[status] + "!", col, 36, 0.9 / speed)
	sfx.play("select", 0.8)
	await pause(0.3)


func fx_ko(t: DuelTotem) -> void:
	var v: DuelViews.TotemView = views[t.owner][t.slot]
	v.set_totem(t)
	v.flash = 1.0
	v.flash_color = Color(1, 1, 1)
	sfx.play("ko")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "pop", 0.55, 0.45 / speed).set_ease(Tween.EASE_IN)
	tw.tween_property(v, "fade", 0.0, 0.45 / speed)
	await pause(0.5)
	v.pop = 1.0
	v.fade = 1.0
	v.flash = 0.0
	v.set_totem(game.players[t.owner].slots[t.slot])


func fx_summon(pi: int, card: DuelCard) -> void:
	_layout_hand()
	sfx.play("summon")
	var cine := SummonCine.new()
	cine.card_id = card.id
	cine.mine = pi == me
	cine.scene = DuelArt.summon_scene(card.id)
	cine.figure = DuelArt.summon(card.id)
	cine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cine)
	var tw := create_tween()
	cine.tween = tw
	tw.tween_property(cine, "t", 1.0, (3.2 if cine.has_art() else 1.9) / minf(speed, 2.0))
	await tw.finished
	cine.queue_free()


func fx_gift(pi: int, g: String) -> void:
	sfx.play("gift")
	var p: DuelPlayer = game.players[pi]
	var god: String = "the Unsworn" if p.patron() == "" else Lore.GODS[p.patron()].name
	await _banner("%s  ·  %s" % [Lore.GIFTS[g].name.to_upper(), god], UITheme.GOLD, 1.1, 50, p.patron())
	_refresh()


func fx_message(text: String) -> void:
	_toast(text)
	await pause(0.8)


func fx_game_over(winner: int, _reason: String) -> void:
	sfx.play("win" if winner == me else "lose")
	await pause(0.6)


# --------------------------------------------------------- effect helpers ---

func _banner(text: String, col: Color, hold: float, size_px: int = 72, god: String = "") -> void:
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.65)
	band.position = Vector2(0, 340)
	band.size = Vector2(DESIGN.x, 150)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(band)
	var l := UITheme.label(text, size_px, col, "display_bold", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = band.size
	band.add_child(l)
	if DuelArt.god(god) != null:
		# the patron's face beside the words
		var tw_px := CardFace.font("display_bold").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		var face := GodFace.new()
		face.god = god
		face.position = Vector2(DESIGN.x * 0.5 - tw_px * 0.5 - 150, -20)
		face.size = Vector2(190, 190)
		l.add_child(face)
	band.modulate.a = 0.0
	l.position.x = -120
	var tw := create_tween().set_parallel(true)
	tw.tween_property(band, "modulate:a", 1.0, 0.15 / speed)
	tw.tween_property(l, "position:x", 0.0, 0.25 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await pause(hold)
	var tw2 := create_tween()
	tw2.tween_property(band, "modulate:a", 0.0, 0.2 / speed)
	tw2.tween_callback(band.queue_free)
	await pause(0.1)


func _toast(text: String) -> void:
	DuelViews.float_text(fx_layer, Vector2(930, 400), text, UITheme.TEXT, 34, 1.6)


func _show_card_big(id: String, tag: String, col: Color, hold: float) -> void:
	var cv := BigCard.new()
	cv.card_id = id
	cv.tag = tag
	cv.tag_col = col
	cv.size = Vector2(300, 420)
	cv.position = Vector2(930 - 150, 190)
	cv.pivot_offset = cv.size * 0.5
	cv.scale = Vector2(0.05, 1.0)
	fx_layer.add_child(cv)
	var tw := create_tween()
	tw.tween_property(cv, "scale", Vector2(1, 1), 0.18 / speed).set_ease(Tween.EASE_OUT)
	await pause(hold + 0.18)
	var tw2 := create_tween()
	tw2.tween_property(cv, "modulate:a", 0.0, 0.2 / speed)
	tw2.tween_callback(cv.queue_free)
	await pause(0.12)


func _beam(at: Vector2, col: Color) -> void:
	var b := Beam.new()
	b.col = col
	b.position = Vector2(at.x - 90, at.y - 330)
	b.size = Vector2(180, 460)
	fx_layer.add_child(b)
	var tw := b.create_tween()
	tw.tween_property(b, "modulate:a", 0.0, 0.6 / speed).set_delay(0.1 / speed)
	tw.tween_callback(b.queue_free)


func _screen_flash(col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)


# ===================================================================== log ===

func _on_log(text: String, who: int) -> void:
	var col := "#ece7da"
	if who == me:
		col = "#8fd0ff"
	elif who == rival:
		col = "#ffb09a"
	elif who == -2:
		col = "#f2c96b"
	_log_lines.append("[color=%s]%s[/color]" % [col, text.replace("[", "(").replace("]", ")")])
	if _log_lines.size() > LOG_MAX:
		_log_lines.pop_front()
	if log_text != null:
		log_text.text = "\n".join(_log_lines)


# ================================================================== result ===

func _show_result(r: String) -> String:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.96), UITheme.GOLD, 26, 3, 48))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	overlay.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	box.add_child(v)
	var title: String = {"won": "VICTORY", "lost": "DEFEAT", "draw": "DRAW"}[r]
	if _watching():
		title = "%s WINS" % String(game.players[game.winner].player_name).to_upper() if game.winner in [0, 1] else "DRAW"
	var tl := UITheme.label(title, 96, UITheme.GOLD if r == "won" else UITheme.TEXT, "display_bold", 12)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var why := UITheme.label(game.win_reason, 30, UITheme.TEXT_DIM)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(why)
	var p: DuelPlayer = game.players[me]
	var q: DuelPlayer = game.players[rival]
	var st := UITheme.label("%d turns  ·  your Life %d  ·  their Life %d  ·  knockouts %d – %d" % [game.turn, maxi(0, p.life), maxi(0, q.life), p.stats.kos, q.stats.kos], 26, UITheme.TEXT)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	v.add_child(hb)
	var again := UITheme.button("Duel again", true, 340)
	var back := UITheme.button("Back to the Lab", false, 340)
	hb.add_child(again)
	hb.add_child(back)
	var picked := [""]
	again.pressed.connect(func() -> void: picked[0] = "again")
	back.pressed.connect(func() -> void: picked[0] = r if r != "draw" else "draw")
	await get_tree().process_frame
	box.position = (overlay.size - box.size) * 0.5
	while picked[0] == "":
		await get_tree().process_frame
	return picked[0]


# ============================================================ inner views ===

## The backdrop: the painted arena (dimmed so the cards stay readable) or,
## without art, a dark hall with a drawn duelling Circle.
class Arena:
	extends Control
	var stage: Control
	var tex: Texture2D = null
	var mote_col := Color(1.0, 0.8, 0.45)
	var _t := 0.0

	## Where the painted Circle sits: this point of the picture (0-1)...
	const ART_ANCHOR := Vector2(0.5, 0.55)
	## ...lands on this point of the stage, with the picture at least this wide.
	const STAGE_ANCHOR := Vector2(930, 470)
	const MIN_WIDTH := 1.22

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if tex != null and stage != null:
			_draw_art()
			return
		CardFace.vgrad_rect(self, Rect2(Vector2.ZERO, size), Color("141a33"), Color("06070d"))
		if stage == null:
			return
		var k := stage.scale.x
		var o := stage.position
		var c := o + Vector2(930, 400) * k
		var rx := 640.0 * k
		var ry := 380.0 * k
		for i in 6:
			_ellipse(c, Vector2(rx, ry) * (1.0 - i * 0.05), Color(0.95, 0.8, 0.45, 0.018))
		_ring(c, Vector2(rx, ry), Color(UITheme.GOLD, 0.28 + 0.06 * sin(_t * 0.8)), 3.0 * k)
		_ring(c, Vector2(rx, ry) * 0.93, Color(UITheme.GOLD, 0.12), 2.0 * k)
		for i in 28:
			var a := TAU * i / 28.0 + _t * 0.03
			var p := c + Vector2(cos(a) * rx * 0.965, sin(a) * ry * 0.965)
			draw_circle(p, 3.5 * k, Color(UITheme.GOLD, 0.35))
		# the line between the two sides
		draw_line(o + Vector2(360, 400) * k, o + Vector2(1500, 400) * k, Color(UITheme.GOLD, 0.18), 2.0 * k)
		# lanes
		for x in [540.0, 930.0, 1320.0]:
			draw_line(o + Vector2(x, 110) * k, o + Vector2(x, 690) * k, Color(1, 1, 1, 0.022), 70.0 * k)

	func _draw_art() -> void:
		var k := stage.scale.x
		var o := stage.position
		# the screen in stage units, so the picture covers it on any shape of screen
		var tl := -o / k
		var br := (size - o) / k
		var ax := STAGE_ANCHOR
		var w := MIN_WIDTH * 1920.0
		var aspect := float(tex.get_height()) / float(tex.get_width())
		w = maxf(w, (ax.x - tl.x) / ART_ANCHOR.x)
		w = maxf(w, (br.x - ax.x) / (1.0 - ART_ANCHOR.x))
		w = maxf(w, (ax.y - tl.y) / (ART_ANCHOR.y * aspect))
		w = maxf(w, (br.y - ax.y) / ((1.0 - ART_ANCHOR.y) * aspect))
		var sz := Vector2(w, w * aspect)
		var r := Rect2(o + (ax - sz * ART_ANCHOR) * k, sz * k)
		draw_texture_rect(tex, r, false)
		# dim it so the cards and numbers stay the brightest things on screen
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 0.38))
		# darker under the hand, behind the side columns and at the very top
		var hand_top := o.y + 740.0 * k
		CardFace.vgrad_rect(self, Rect2(Vector2(0, hand_top), Vector2(size.x, size.y - hand_top)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.82))
		CardFace.vgrad_rect(self, Rect2(Vector2.ZERO, Vector2(size.x, o.y + 120.0 * k)), Color(0.01, 0.01, 0.03, 0.55), Color(0.01, 0.01, 0.03, 0.0))
		_hgrad(Rect2(Vector2.ZERO, Vector2(o.x + 360.0 * k, size.y)), Color(0.01, 0.01, 0.03, 0.62), Color(0.01, 0.01, 0.03, 0.0))
		var rx := o.x + 1500.0 * k
		_hgrad(Rect2(Vector2(rx, 0), Vector2(size.x - rx, size.y)), Color(0.01, 0.01, 0.03, 0.0), Color(0.01, 0.01, 0.03, 0.7))
		# drifting motes of light
		for i in 34:
			var sd := float(i) * 12.9898
			var fx := absf(fmod(sin(sd) * 43758.5453, 1.0))
			var rise := 14.0 + 22.0 * absf(fmod(sin(sd * 1.7) * 9631.2, 1.0))
			var y := fmod(_t * rise + float(i) * 97.0, 1080.0)
			var p := o + Vector2(360.0 + fx * 1140.0 + sin(_t * 0.7 + i) * 18.0, 1000.0 - y) * k
			var life := sin(y / 1080.0 * PI)
			draw_circle(p, (2.0 + float(i % 3)) * k, Color(mote_col, 0.35 * life))

	func _hgrad(r: Rect2, a: Color, b: Color) -> void:
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		draw_polygon(pts, PackedColorArray([a, b, b, a]))

	func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 64:
			var a := TAU * i / 64.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(pts, col)

	func _ring(c: Vector2, r: Vector2, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 97:
			var a := TAU * i / 96.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_polyline(pts, col, w, true)


## A patron's face in a gold ring.
class GodFace:
	extends Control
	var god := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var rad := minf(size.x, size.y) * 0.5 - 6
		draw_circle(c, rad + 10, Color(UITheme.GOLD, 0.15))
		DuelArt.god_medallion(self, c, rad, god, UITheme.GOLD)


## The big card in the right column.
class DetailCard:
	extends Control
	var card_id := ""
	var opts := {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func show_card(id: String, p_opts: Dictionary = {}) -> void:
		card_id = id
		opts = p_opts
		queue_redraw()

	func _draw() -> void:
		if card_id == "":
			CardFace.box(self, Rect2(Vector2.ZERO, size), 16, Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.08), 2.0)
			CardFace.text(self, CardFace.font("body"), Vector2(0, size.y * 0.5), "Tap any card to read it", 24, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			return
		var o := opts.duplicate()
		o["compact"] = false
		DuelCardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, o)


## A card flipped up in the middle of the Circle (a Rite being cast, a Ward springing).
class BigCard:
	extends Control
	var card_id := ""
	var tag := ""
	var tag_col := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		CardFace.box(self, Rect2(Vector2(-10, -10), size + Vector2(20, 20)), 22, Color(0, 0, 0, 0.5))
		DuelCardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, {"compact": false})
		var r := Rect2(Vector2(size.x * 0.5 - 90, -34), Vector2(180, 52))
		CardFace.box(self, r, 26, tag_col, Color.WHITE, 2.0)
		CardFace.text_in(self, CardFace.font("display_bold"), r, tag, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)


## A column of light where a Totem is called.
class Beam:
	extends Control
	var col := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		for i in 5:
			var inset := w * 0.1 * i
			CardFace.vgrad_rect(self, Rect2(Vector2(inset, 0), Vector2(w - inset * 2, size.y)), Color(col, 0.0), Color(col, 0.12 + i * 0.05))


## The Summon cinematic: the heavens open and the Demigod descends.
class SummonCine:
	extends Control
	var card_id := ""
	var mine := true
	var tween: Tween = null
	var scene: Texture2D = null
	var figure: Texture2D = null
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	## A tap hurries the cinematic along.
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and tween != null and tween.is_valid():
			tween.set_speed_scale(4.0)
			accept_event()

	func has_art() -> bool:
		return scene != null and figure != null

	func _draw() -> void:
		if has_art():
			_draw_painted()
		else:
			_draw_plain()

	func _draw_painted() -> void:
		var d: Dictionary = DuelCards.CARDS[card_id]
		var col := Lore.color(d.element, 0)
		var a := clampf(t * 7.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		var k := minf(size.x / 1920.0, size.y / 1080.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.9 * a))
		# the opened heavens, drifting slowly closer
		var zoom := 1.1 - 0.1 * t
		var sr := Rect2(size * 0.5 - size * zoom * 0.5, size * zoom)
		DuelArt.cover(self, sr, scene, Vector2(0.5, 0.5), Color(1, 1, 1, a))
		# the Demigod comes down the beam and lands in the Circle
		var land := clampf((t - 0.08) / 0.42, 0.0, 1.0)
		var eo := 1.0 - pow(1.0 - land, 3.0)
		var fa := clampf((t - 0.06) * 6.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		var fh := size.y * 0.74 * (0.82 + 0.18 * eo)
		var fs := Vector2(fh * figure.get_width() / float(figure.get_height()), fh)
		var foot := Vector2(size.x * 0.5, size.y * 0.86 + (1.0 - eo) * -size.y * 0.95)
		if land >= 1.0:
			foot.y += sin(t * 9.0) * 6.0 * k
		var halo := foot - Vector2(0, fs.y * 0.5)
		for i in 7:
			draw_circle(halo, fs.y * (0.62 - i * 0.07), Color(col.lightened(0.3), 0.05 * fa))
		draw_texture_rect(figure, Rect2(foot - Vector2(fs.x * 0.5, fs.y), fs), false, Color(1, 1, 1, fa))
		# the flash as it lands
		var flash := clampf(1.0 - absf(t - 0.5) * 9.0, 0.0, 1.0)
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(col.lightened(0.6), 0.55 * flash))
		# the name
		var ta := clampf((t - 0.48) * 6.0, 0.0, 1.0) * clampf((1.0 - t) * 7.0, 0.0, 1.0)
		if ta > 0.0:
			CardFace.vgrad_rect(self, Rect2(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.28)), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.8 * ta))
			var fnt := CardFace.font("display_bold")
			var nm := String(d.name).to_upper()
			var fsz := CardFace.fit_size(fnt, nm, int(84 * k), size.x - 80)
			CardFace.text(self, CardFace.font("bold"), Vector2(0, size.y - 150 * k), "SUMMON", int(34 * k), Color(col.lightened(0.4), ta), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(6 * k))
			CardFace.text(self, fnt, Vector2(0, size.y - 60 * k), nm, fsz, Color(UITheme.GOLD, ta), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(12 * k))

	func _draw_plain() -> void:
		var a := clampf(t * 4.0, 0.0, 1.0) * clampf((1.0 - t) * 5.0, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.85 * a))
		var d: Dictionary = DuelCards.CARDS[card_id]
		var col := Lore.color(d.element, 0)
		var c := size * 0.5
		for i in 16:
			var ang := TAU * i / 16.0 + t * 0.6
			var p1 := c + Vector2(cos(ang), sin(ang)) * 60.0
			var p2 := c + Vector2(cos(ang), sin(ang)) * size.length()
			draw_line(p1, p2, Color(col, 0.08 * a), 40.0)
		var k := minf(size.x / 1920.0, size.y / 1080.0)
		var cs := Vector2(420, 588) * k * (0.8 + 0.2 * clampf(t * 2.0, 0.0, 1.0))
		var drop := (1.0 - clampf(t * 2.5, 0.0, 1.0)) * -size.y * 0.5
		var r := Rect2(c - cs * 0.5 + Vector2(0, drop), cs)
		if a > 0.01:
			draw_set_transform(Vector2.ZERO)
			modulate.a = a
			DuelCardFace.draw_card(self, r, card_id, {"compact": false})
			var fnt := CardFace.font("display_bold")
			var fs := int(64 * k)
			CardFace.text(self, fnt, Vector2(0, r.end.y + 80 * k), String(d.name).to_upper(), CardFace.fit_size(fnt, String(d.name).to_upper(), fs, size.x - 80), UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(10 * k))
			CardFace.text(self, CardFace.font("bold"), Vector2(0, r.position.y - 30 * k), "SUMMON", int(36 * k), Color(col, 0.9), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(6 * k))


## A move or card action in the right column: name, cost and small print.
class ActionButton:
	extends Control
	signal pressed
	var title := ""
	var sub := ""
	var cost := 0
	var enabled := true
	var _hover := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var bg := Color("1a2036") if enabled else Color("14182a")
		if _hover and enabled:
			bg = Color("242b48")
		CardFace.box(self, r, 14, bg, UITheme.GOLD_DIM if enabled else Color("2a2e44"), 2.0)
		var x := 18.0
		if cost > 0:
			DuelCardFace.essence_gem(self, Vector2(38, size.y * 0.5), 22, cost, not enabled)
			x = 70.0
		var fnt := CardFace.font("display_bold")
		var col := UITheme.TEXT if enabled else Color("6a6d82")
		CardFace.text(self, fnt, Vector2(x, 44), title, CardFace.fit_size(fnt, title, 28, size.x - x - 14), col)
		if sub != "":
			var body := CardFace.font("body")
			CardFace.text(self, body, Vector2(x, 82), sub, CardFace.fit_size(body, sub, 21, size.x - x - 14, 12), UITheme.TEXT_DIM if enabled else Color("5a5d72"))
