class_name BattleScreen
extends Control
## The duel screen. Touch-first: tap a card to select it (its big picture and
## what you can do with it appear on the right), tap a glowing spot to play
## it there, press and hold any card to read it full-size.
##
## Layout is authored on a 1920 x 1080 stage that scales to fit the screen;
## the table background fills any extra space (phones, iPads).

signal finished(won: bool)

const DESIGN := Vector2(1920, 1080)
const FIELD_CX := 945.0
const ACTIVE := Vector2(172, 241)
const BENCH := Vector2(118, 165)
const HAND := Vector2(120, 168)
const BENCH_GAP := 138.0
const Y_OPP_BENCH := 14.0
const Y_OPP_ACTIVE := 186.0
const Y_MY_ACTIVE := 490.0
const Y_MY_BENCH := 744.0
const Y_HAND := 910.0
const PANEL_X := 1600.0
const PROMPT_Y := 458.0

var spec: Dictionary = {}
var game: BattleGame
var human: HumanController
var ai: PacedAI
var me := 0
var rival := 1
var speed := 1.0
var sfx: Sfx

var stage: Control
var field: Control
var fx_layer: Control
var overlay: Control
var slots := [[], []]
var hand_views: Array = []
var info := []
var preview: PreviewCard
var actions: VBoxContainer
var prompt_panel: PanelContainer
var prompt_label: Label
var toast_label: Label

var mode := "idle"          # idle, setup, main, target, pick_creature, pick_cards, over
var selected: Card = null
var focus: Creature = null
var targets: Array = []     # creatures (or TotemSlots for empty bench spots)
var target_kind := ""
var pick_cancellable := false
var setup_active: Card = null
var setup_bench: Array = []
var end_confirm := false
var _result_won := false
var _ex := 0.0   # extra design-space width on each side (wide phones)
var _ey := 0.0   # extra design-space height above and below (iPads)
var _tip := 0
var _tip_turn := -1
const TIPS := [
	"Your turn! Tap an Energy card, then tap your Active Totem to power it up. One Energy per turn.",
	"Tap a base Totem in your hand to put it on your Bench. Tap an attack on the right to strike.",
	"Knock out your rival's Totems to take Prize cards. Take all four to win!",
	"Hitting a weakness deals half as much again. Check the WEAK line on a card.",
]
var _menu_btn: Control
var _title_lbl: Label


func configure(p_spec: Dictionary) -> BattleScreen:
	spec = p_spec
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	mouse_filter = Control.MOUSE_FILTER_STOP
	sfx = Sfx.new()
	add_child(sfx)
	sfx.volume_db = linear_to_db(maxf(0.001, float(Game.settings.get("sfx", 0.9)))) - 8.0

	stage = Control.new()
	stage.size = DESIGN
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	field = Control.new()
	field.size = DESIGN
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(field)
	_build()
	fx_layer = Control.new()
	fx_layer.size = DESIGN
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(fx_layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	resized.connect(_fit)
	_fit()
	_start.call_deferred()


func _fit() -> void:
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	stage.scale = Vector2(k, k)
	stage.position = ((size - DESIGN * k) * 0.5).floor()
	# Spread the layout into any spare room: panels to the edges, the two
	# sides of the table apart.
	_ex = maxf(0.0, (size.x / k - DESIGN.x) * 0.5)
	_ey = maxf(0.0, (size.y / k - DESIGN.y) * 0.5)
	for pi in 2:
		for s in slots[pi]:
			var base: Vector2 = s.get_meta("base")
			var dy := 0.0
			if pi == me:
				dy = _ey * (0.45 if s.is_active else 0.75)
			else:
				dy = -_ey * (0.45 if s.is_active else 0.85)
			s.position = base + Vector2(0, dy)
			s.set_meta("home", s.position)
	if info.size() == 2:
		info[rival].position = Vector2(18 - _ex, 16 - _ey)
		info[me].position = Vector2(18 - _ex, 640 + _ey)
	if preview != null:
		preview.position = Vector2(PANEL_X + 8 + _ex, 98 - _ey)
		_menu_btn.position = Vector2(PANEL_X + 214 + _ex, 12 - _ey)
		_title_lbl.position = Vector2(PANEL_X + 10 + _ex, 20 - _ey)
		actions.position = Vector2(PANEL_X + 8 + _ex, 516 + _ey)
	if game != null:
		_layout_hand()
	queue_redraw()


func pause(sec: float) -> void:
	await get_tree().create_timer(sec / speed).timeout


# ================================================================== build ===

func _build() -> void:
	for pi in 2:
		var mine := pi == me
		var a := BattleWidgets.TotemSlot.new()
		a.owner_index = pi
		a.is_active = true
		a.size = ACTIVE
		a.position = Vector2(FIELD_CX - ACTIVE.x * 0.5, Y_MY_ACTIVE if mine else Y_OPP_ACTIVE)
		a.set_meta("home", a.position)
		a.set_meta("base", a.position)
		_hook_slot(a)
		field.add_child(a)
		slots[pi].append(a)
		for i in BattleGame.BENCH_MAX:
			var b := BattleWidgets.TotemSlot.new()
			b.owner_index = pi
			b.bench_index = i
			b.size = BENCH
			b.position = Vector2(FIELD_CX + (i - 2) * BENCH_GAP - BENCH.x * 0.5, Y_MY_BENCH if mine else Y_OPP_BENCH)
			b.set_meta("home", b.position)
			b.set_meta("base", b.position)
			_hook_slot(b)
			field.add_child(b)
			slots[pi].append(b)

	for pi in 2:
		var p := BattleWidgets.InfoPanel.new()
		p.pi = pi
		p.mine = pi == me
		p.size = Vector2(272, 424)
		p.position = Vector2(18, 640 if pi == me else 16)
		p.discard_tapped.connect(_view_discard)
		stage.add_child(p)
		info.append(p)

	preview = PreviewCard.new()
	preview.position = Vector2(PANEL_X + 8, 98)
	preview.size = Vector2(288, 403)
	preview.held.connect(func() -> void:
		if preview.card_id != "":
			_zoom(preview.card_id, preview.attuned))
	stage.add_child(preview)

	var menu := WorldHUD.IconButton.new()
	_menu_btn = menu
	menu.glyph = "menu"
	menu.position = Vector2(PANEL_X + 214, 12)
	menu.size = Vector2(82, 76)
	menu.pressed.connect(_open_menu)
	stage.add_child(menu)
	var title := UITheme.label(spec.get("title", "Duel"), 26, UITheme.GOLD, "display_bold")
	_title_lbl = title
	title.position = Vector2(PANEL_X + 10, 20)
	title.size = Vector2(200, 60)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage.add_child(title)

	actions = VBoxContainer.new()
	actions.position = Vector2(PANEL_X + 8, 516)
	actions.size = Vector2(288, 550)
	actions.add_theme_constant_override("separation", 10)
	actions.alignment = BoxContainer.ALIGNMENT_END
	stage.add_child(actions)

	prompt_panel = PanelContainer.new()
	prompt_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.92), Color(UITheme.GOLD, 0.6), 22, 2, 20))
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.visible = false
	stage.add_child(prompt_panel)
	prompt_label = UITheme.label("", 26, UITheme.TEXT, "bold")
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	toast_label = UITheme.label("", 34, UITheme.GOLD, "display_bold", 10)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.size = Vector2(1200, 60)
	toast_label.position = Vector2(FIELD_CX - 600, PROMPT_Y - 30)
	toast_label.modulate.a = 0.0
	stage.add_child(toast_label)


func _hook_slot(s: BattleWidgets.TotemSlot) -> void:
	s.tapped.connect(_on_slot_tapped)
	s.held.connect(func(sl) -> void:
		var id: String = sl.card_id()
		if id != "":
			_zoom(id, sl.creature.attuned() if sl.creature != null else null))


# ================================================================== start ===

func _start() -> void:
	human = HumanController.new()
	human.screen = self
	speed = float(spec.get("speed", 1.0))
	ai = PacedAI.new()
	ai.screen = self
	game = BattleGame.new()
	game.presenter = self
	var opp_profile: Dictionary = spec.get("profile", {})
	if opp_profile.is_empty():
		opp_profile = Game.npc_profile(spec.get("name", "Rival"), spec.get("patron", ""), spec.get("attrs", {}))
	var my_deck = spec.get("player_deck", Game.deck)
	if my_deck is Array and my_deck.is_empty():
		my_deck = "emberstorm"
	var mine = human
	if spec.get("autoplay", false) or Game.settings.get("debug_autoplay", false):
		mine = PacedAI.new()
		mine.screen = self
	game.setup([my_deck, spec.get("deck", "ironvault_hunter")], [Game.player_name, spec.get("name", "Rival")],
		[mine, ai], [Game.profile if not Game.profile.is_empty() else Lore.new_profile(Game.player_name), opp_profile],
		int(spec.get("seed", -1)))
	game.state_changed.connect(_refresh)
	info[me].player = game.players[me]
	info[me].portrait = DollArt.portrait("player")
	info[rival].player = game.players[rival]
	info[rival].portrait = DollArt.portrait(spec.get("look", "hunter"))
	_refresh()
	await pause(0.3)
	await game.run()


# ================================================================ refresh ===

func _refresh() -> void:
	if game == null:
		return
	for pi in 2:
		var p: PlayerState = game.players[pi]
		var a: BattleWidgets.TotemSlot = slots[pi][0]
		a.set_creature(p.active)
		a.ghost_id = ""
		for i in BattleGame.BENCH_MAX:
			var s: BattleWidgets.TotemSlot = slots[pi][i + 1]
			s.set_creature(p.bench[i] if i < p.bench.size() else null)
			s.ghost_id = ""
		info[pi].is_turn = game.phase == "main" and game.current == pi
		info[pi].queue_redraw()
	if mode == "setup":
		slots[me][0].ghost_id = setup_active.id if setup_active != null else ""
		for i in setup_bench.size():
			slots[me][i + 1].ghost_id = setup_bench[i].id
	_update_highlights()
	_layout_hand()
	_update_actions()


func _layout_hand() -> void:
	var hand: Array = game.players[me].hand.duplicate()
	if mode == "setup":
		hand.erase(setup_active)
		for c in setup_bench:
			hand.erase(c)
	# reuse views where possible
	while hand_views.size() < hand.size():
		var v := BattleWidgets.HandCard.new()
		v.size = HAND
		v.tapped.connect(_on_hand_tapped)
		v.held.connect(func(hv) -> void: _zoom(hv.card.id, null))
		field.add_child(v)
		hand_views.append(v)
	while hand_views.size() > hand.size():
		var v = hand_views.pop_back()
		v.queue_free()
	var n := hand.size()
	var avail := 1250.0
	var step := minf(HAND.x + 10, (avail - HAND.x) / maxf(1.0, n - 1))
	var total := step * (n - 1) + HAND.x
	var x0 := FIELD_CX - total * 0.5
	for i in n:
		var v: BattleWidgets.HandCard = hand_views[i]
		v.card = hand[i]
		v.selected = hand[i] == selected
		v.playable = _card_playable(hand[i])
		v.dim = mode in ["main", "target", "setup"] and not v.playable and not v.selected
		var target := Vector2(x0 + i * step, Y_HAND + _ey - (40.0 if v.selected else 0.0))
		v.z_index = 5 if v.selected else 0
		if v.position.distance_to(target) > 1.0:
			var tw := create_tween()
			tw.tween_property(v, "position", target, 0.12)
		v.queue_redraw()


func _card_playable(c: Card) -> bool:
	var pi := me
	if mode == "setup":
		return c.is_basic_creature() and c != setup_active and not setup_bench.has(c)
	if not (mode in ["main", "target"]) or game.current != me:
		return false
	if c.is_basic_creature():
		return game.bench_problem(pi, c) == ""
	if c.is_evolution():
		return not game.evolve_targets(pi, c).is_empty()
	if c.is_energy():
		return game.energy_problem(pi, c) == ""
	if c.is_trainer():
		return game.trainer_problem(pi, c) == ""
	if c.is_summon():
		return game.summon_problem(pi, c) == ""
	return false


func _update_highlights() -> void:
	for pi in 2:
		for s in slots[pi]:
			var h := ""
			if s.creature != null and targets.has(s.creature):
				h = "target"
			elif targets.has(s):
				h = "target"
			elif s.creature != null and s.creature == focus and mode in ["main", "target"]:
				h = "selected"
			s.highlight = h
			s.queue_redraw()


# ======================================================== action panel ===

func _clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()


func _add_action(title: String, detail: String, enabled: bool, cb: Callable, accent: bool = false,
		glyph: String = "", orbs: Array = [], value: String = "") -> BattleWidgets.ActionButton:
	var b := BattleWidgets.ActionButton.new()
	b.setup(title, detail, enabled)
	b.accent = accent
	b.glyph = glyph
	b.orbs = orbs
	b.value = value
	b.custom_minimum_size = Vector2(0, 118 if not orbs.is_empty() else 92)
	b.pressed.connect(func() -> void:
		_sfx("click")
		cb.call())
	actions.add_child(b)
	return b


func _update_actions() -> void:
	_clear_actions()
	match mode:
		"setup":
			_update_preview_card(setup_active.id if setup_active != null else "")
			_add_action("Reset", "Choose again", setup_active != null, func() -> void:
				setup_active = null
				setup_bench.clear()
				_setup_prompt()
				_refresh())
			_add_action("Ready", "Start the duel" if setup_active != null else "Tap a base Totem first", setup_active != null, _on_setup_ready, true)
		"main":
			_main_actions()
		"target":
			_target_actions()
		"pick_creature":
			if pick_cancellable:
				_add_action("Cancel", "", true, func() -> void: _respond(null))
		_:
			pass


func _main_actions() -> void:
	var p: PlayerState = game.players[me]
	if selected != null:
		_update_preview_card(selected.id)
		_hand_card_actions(selected)
		return
	var shown := focus if focus != null else p.active
	if shown != null:
		_update_preview_card(shown.top().id, shown.attuned())
	var fc := p.active
	if fc != null:
		for i in fc.attacks().size():
			var atk: Dictionary = fc.attacks()[i]
			var prob := game.attack_problem(me, i)
			var dmg := ""
			if int(atk.get("damage", 0)) > 0:
				var base := int(atk.damage) + fc.damage_bonus() + (Lore.WRATH_BONUS if p.wrath else 0)
				var o: PlayerState = game.players[rival]
				dmg = str(game.compute_damage(fc.element(), o.active, base) if o.active != null else base)
				dmg += String(atk.get("damage_suffix", ""))
			var idx := i
			_add_action(atk.name, prob if prob != "" else String(atk.get("text", "")), prob == "",
				func() -> void: _respond({"type": "attack", "index": idx}), false, "", fc.attack_cost(atk), dmg)
		var rprob := game.retreat_problem(me)
		var rc := game.retreat_cost(me)
		_add_action("Retreat", rprob if rprob != "" else ("Free" if rc == 0 else "Costs %d Energy" % rc), rprob == "", _begin_retreat, false, "retreat")
	var g := p.gift()
	if g != "" and not p.gift_used:
		var gprob := game.gift_problem(me)
		var gname: String = Lore.GIFTS[g].name
		var gel := "any" if p.patron() == "" else String(Lore.GODS[p.patron()].element)
		var b := _add_action(gname, gprob if gprob != "" else Lore.GIFTS[g].text, gprob == "", _on_gift, false, "")
		b.orbs = [gel]
		b.custom_minimum_size.y = 118
	var can_more := game.can_do_anything_but_end(me)
	_add_action("End turn?" if end_confirm else "End Turn",
		"Tap again to end without attacking" if end_confirm else ("" if not can_more else "You can still act"), true, _on_end_turn, true)


func _hand_card_actions(c: Card) -> void:
	var pi := me
	if c.is_basic_creature():
		var prob := game.bench_problem(pi, c)
		_add_action("Play to Bench", prob if prob != "" else "Or tap a glowing Bench spot", prob == "",
			func() -> void: _respond({"type": "bench", "card": c}), true)
	elif c.is_summon():
		var prob := game.summon_problem(pi, c)
		_add_action("Summon", prob if prob != "" else "Pay %d Energy from your Totems. Replaces your attack." % game.summon_cost(pi, c), prob == "",
			func() -> void: _respond({"type": "summon", "card": c}), true, "", c.def.get("cost", []))
	elif c.is_trainer() and not game.trainer_needs_target(c):
		var prob := game.trainer_problem(pi, c)
		_add_action("Use " + ("Ally" if c.is_supporter() else "Rite"), prob if prob != "" else String(c.def.get("text", "")), prob == "",
			func() -> void: _respond({"type": "trainer", "card": c}), true)
	elif c.is_trainer():
		var prob := game.trainer_problem(pi, c)
		_add_action("Choose a target", prob if prob != "" else "Tap a glowing Totem", false, func() -> void: pass)
	elif c.is_energy():
		var prob := game.energy_problem(pi, c)
		_add_action("Attach Energy", prob if prob != "" else "Tap one of your glowing Totems", false, func() -> void: pass)
	elif c.is_evolution():
		var t := game.evolve_targets(pi, c)
		var why := "Tap the glowing Totem to Awaken it"
		if t.is_empty():
			why = "Awakens from %s — none can Awaken now" % SigilDB.CARDS[c.def.awakens_from].name
		_add_action("Awaken", why, false, func() -> void: pass)
	_add_action("Cancel", "", true, _clear_selection)


func _target_actions() -> void:
	if target_kind == "retreat":
		_update_preview_card(game.players[me].active.top().id if game.players[me].active != null else "")
		_add_action("Retreat", "Tap a glowing Benched Totem to switch in", false, func() -> void: pass)
		_add_action("Cancel", "", true, _clear_selection)
	else:
		_main_actions()


func _update_preview_card(id: String, attuned = null) -> void:
	preview.card_id = id
	preview.attuned = attuned
	preview.queue_redraw()


# ================================================================== modes ===

func begin_setup() -> void:
	mode = "setup"
	setup_active = null
	setup_bench.clear()
	_setup_prompt()
	_refresh()


func _setup_prompt() -> void:
	if setup_active == null:
		_prompt("Choose your Active Totem: tap a base Totem in your hand")
	else:
		_prompt("Add more base Totems to your Bench if you like, then tap Ready")


func begin_main() -> void:
	mode = "main"
	selected = null
	targets.clear()
	focus = game.players[me].active
	end_confirm = false
	_hide_prompt()
	if spec.get("tutorial", false) and _tip < TIPS.size() and _tip_turn != game.turn:
		_tip_turn = game.turn
		_prompt(TIPS[_tip])
		_tip += 1
	_refresh()


func begin_pick_creature(text: String, options: Array, cancellable: bool) -> void:
	mode = "pick_creature"
	targets = options.duplicate()
	pick_cancellable = cancellable
	selected = null
	_prompt(text)
	_refresh()


func begin_pick_cards(text: String, cards: Array, min_n: int, max_n: int, ctx: Dictionary) -> void:
	mode = "pick_cards"
	_refresh()
	var picker := BattleWidgets.CardPicker.new()
	picker.cards = cards
	picker.min_n = min_n
	picker.max_n = max_n
	picker.title = text
	picker.units = int(ctx.get("units", 0)) if ctx.get("reason", "") == "discard_energy" else 0
	overlay.add_child(picker)
	var picked: Array = await picker.done
	picker.queue_free()
	_respond(picked)


func _respond(value) -> void:
	var was := mode
	mode = "idle"
	selected = null
	targets.clear()
	target_kind = ""
	_hide_prompt()
	_refresh()
	if was != "idle":
		human.responded.emit(value)


# ============================================================== handlers ===

func _on_hand_tapped(v) -> void:
	var c: Card = v.card
	_sfx("select")
	match mode:
		"setup":
			if not c.is_basic_creature():
				_toast("Only base Totems can start in play")
				return
			if setup_active == null:
				setup_active = c
			elif c == setup_active or setup_bench.has(c):
				return
			elif setup_bench.size() < BattleGame.BENCH_MAX:
				setup_bench.append(c)
			_setup_prompt()
			_refresh()
		"main", "target":
			if selected == c:
				_clear_selection()
				return
			_select_hand_card(c)
		_:
			_update_preview_card(c.id)


func _select_hand_card(c: Card) -> void:
	selected = c
	targets.clear()
	target_kind = ""
	mode = "main"
	var pi := me
	if c.is_basic_creature() and game.bench_problem(pi, c) == "":
		var p: PlayerState = game.players[pi]
		targets.append(slots[pi][p.bench.size() + 1])
		target_kind = "bench"
		mode = "target"
	elif c.is_energy() and game.energy_problem(pi, c) == "":
		targets = game.players[pi].in_play()
		target_kind = "energy"
		mode = "target"
	elif c.is_evolution():
		targets = game.evolve_targets(pi, c)
		target_kind = "evolve"
		mode = "target" if not targets.is_empty() else "main"
	elif c.is_trainer() and game.trainer_needs_target(c) and game.trainer_problem(pi, c) == "":
		targets = game.trainer_targets(pi, c)
		target_kind = "trainer"
		mode = "target"
	end_confirm = false
	_refresh()


func _clear_selection() -> void:
	selected = null
	targets.clear()
	target_kind = ""
	if mode == "target":
		mode = "main"
	_hide_prompt()
	_refresh()


func _begin_retreat() -> void:
	if game.retreat_problem(me) != "":
		return
	selected = null
	targets = game.players[me].bench.duplicate()
	target_kind = "retreat"
	mode = "target"
	_prompt("Choose a Benched Totem to switch in")
	_refresh()


func _on_slot_tapped(s) -> void:
	var c: Creature = s.creature
	match mode:
		"pick_creature":
			if c != null and targets.has(c):
				_respond(c)
				return
		"setup":
			pass
		"target":
			if targets.has(s) and target_kind == "bench":
				_respond({"type": "bench", "card": selected})
				return
			if c != null and targets.has(c):
				match target_kind:
					"energy":
						_respond({"type": "energy", "card": selected, "target": c})
					"evolve":
						_respond({"type": "evolve", "card": selected, "target": c})
					"trainer":
						_respond({"type": "trainer", "card": selected, "target": c})
					"retreat":
						_respond({"type": "retreat", "target": c})
				return
		"main":
			pass
	# otherwise: inspect it
	if c != null:
		_sfx("select")
		if mode == "target":
			_clear_selection()
		focus = c
		selected = null
		end_confirm = false
		if mode == "main" or mode == "target":
			_refresh()
		else:
			_update_preview_card(c.top().id, c.attuned())
			_update_highlights()


func _on_setup_ready() -> void:
	if setup_active == null:
		return
	var choice := {"active": setup_active, "bench": setup_bench.duplicate()}
	setup_active = null
	setup_bench.clear()
	_respond(choice)


func _on_gift() -> void:
	var p: PlayerState = game.players[me]
	if p.gift() == "dawns_mercy":
		var opts := game.gift_targets(me)
		if opts.size() == 1:
			_respond({"type": "gift", "target": opts[0]})
			return
		_respond({"type": "gift"})  # the engine asks which Totem to heal
		return
	_respond({"type": "gift"})


func _on_end_turn() -> void:
	if game.can_do_anything_but_end(me) and not end_confirm:
		var p: PlayerState = game.players[me]
		var can_attack := false
		if p.active != null:
			for i in p.active.attacks().size():
				if game.attack_problem(me, i) == "":
					can_attack = true
		if can_attack:
			end_confirm = true
			_update_actions()
			return
	_respond({"type": "end"})


func _gui_input(event: InputEvent) -> void:
	# a tap on the empty table cancels a selection
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "target" or (mode == "main" and selected != null):
			_clear_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_open_menu()


# ============================================================ small views ===

func _zoom(id: String, attuned) -> void:
	var z := BattleWidgets.ZoomOverlay.new()
	z.card_id = id
	z.attuned = attuned
	z.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(z)
	z.closed.connect(z.queue_free)


func _view_discard(pi: int) -> void:
	var cards: Array = game.players[pi].discard
	if cards.is_empty():
		_toast("The discard pile is empty")
		return
	var picker := BattleWidgets.CardPicker.new()
	picker.cards = cards.duplicate()
	picker.view_only = true
	picker.title = "%s discard pile" % ("Your" if pi == me else game.players[pi].player_name + "'s")
	overlay.add_child(picker)
	await picker.done
	picker.queue_free()


func _open_menu() -> void:
	if overlay.get_child_count() > 0:
		return
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -300
	box.offset_right = 300
	box.offset_top = -250
	box.offset_bottom = 250
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	dim.add_child(box)
	var head := UITheme.label("DUEL", 56, UITheme.GOLD, "display_bold")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var resume := UITheme.button("Resume", true, 520)
	resume.pressed.connect(dim.queue_free)
	box.add_child(resume)
	var spd := UITheme.button("Speed: %s" % ("Fast" if speed > 1.2 else "Normal"), false, 520)
	spd.pressed.connect(func() -> void:
		speed = 1.0 if speed > 1.2 else 1.8
		spd.text = "Speed: %s" % ("Fast" if speed > 1.2 else "Normal"))
	box.add_child(spd)
	var forfeit := UITheme.button("Forfeit duel", false, 520)
	forfeit.pressed.connect(func() -> void:
		dim.queue_free()
		mode = "over"
		finished.emit(false))
	box.add_child(forfeit)


func _prompt(text: String) -> void:
	prompt_label.text = text
	prompt_panel.visible = true
	prompt_panel.reset_size()
	var w := maxf(prompt_panel.get_combined_minimum_size().x, 400.0)
	prompt_panel.size = Vector2(w, 0)
	prompt_panel.position = Vector2(FIELD_CX - w * 0.5, PROMPT_Y - prompt_panel.get_combined_minimum_size().y * 0.5)


func _hide_prompt() -> void:
	prompt_panel.visible = false


func _toast(text: String) -> void:
	toast_label.text = text
	var tw := create_tween()
	tw.tween_property(toast_label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.4)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.3)


# ============================================================ background ===

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var k := stage.scale.x
	var o := stage.position
	CardFace.vgrad_rect(self, r, Color("0d1022"), Color("07080f"))
	var c := o + Vector2(FIELD_CX, PROMPT_Y) * k
	for i in 12:
		draw_circle(c, (700 - i * 50) * k, Color(0.35, 0.3, 0.6, 0.018))
	# side tints: each duellist's god colour
	if game != null:
		for pi in 2:
			var god: String = game.players[pi].patron()
			var col := Lore.color(Lore.GODS[god].element, 1) if god != "" else Color("6b7c93")
			var cy := o.y + (DESIGN.y if pi == me else 0.0) * k
			for i in 8:
				draw_circle(Vector2(c.x, cy), (620 - i * 60) * k, Color(col, 0.022))
	# the duelling circle
	draw_arc(c, 430 * k, 0, TAU, 128, Color(UITheme.GOLD, 0.14), 3.0 * k, true)
	draw_arc(c, 405 * k, 0, TAU, 128, Color(UITheme.GOLD, 0.07), 1.5 * k, true)
	draw_arc(c, 170 * k, 0, TAU, 96, Color(UITheme.GOLD, 0.09), 2.0 * k, true)
	for i in 24:
		var a := TAU * i / 24.0
		draw_line(c + Vector2(cos(a), sin(a)) * 405 * k, c + Vector2(cos(a), sin(a)) * 430 * k, Color(UITheme.GOLD, 0.12), 2.0 * k)
	draw_line(o + Vector2(330, PROMPT_Y) * k, o + Vector2(PANEL_X - 30, PROMPT_Y) * k, Color(UITheme.GOLD, 0.1), 2.0 * k)
	# side panel backing
	CardFace.box(self, Rect2(o + Vector2(PANEL_X - 4 + _ex, 4 - _ey) * k, Vector2(316, 1072 + _ey * 2.0) * k), 20 * k, Color(0.02, 0.025, 0.05, 0.55), Color(1, 1, 1, 0.05), 1)


# ================================================================ effects ===

func _sfx(name: String, pitch: float = 1.0) -> void:
	if sfx != null:
		sfx.play(name, pitch)


func _slot_of(c: Creature) -> BattleWidgets.TotemSlot:
	if c == null:
		return null
	for pi in 2:
		for s in slots[pi]:
			if s.creature == c:
				return s
	return null


func _center(s: Control) -> Vector2:
	return s.position + s.size * 0.5


func _float_text(pos: Vector2, text: String, col: Color, fsize: int = 44) -> void:
	var l := UITheme.label(text, fsize, col, "display_bold", 10)
	fx_layer.add_child(l)
	l.reset_size()
	l.position = pos - l.size * 0.5
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.12 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 56, 0.8 / speed).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8 / speed).set_delay(0.35 / speed)
	tw.tween_callback(l.queue_free)


func _pop(s: Control, from: float = 0.7) -> void:
	if s == null:
		return
	s.pivot_offset = s.size * 0.5
	s.scale = Vector2(from, from)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2.ONE, 0.22 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _banner(text: String, col: Color, bg: Color, hold: float = 0.5) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(holder)
	var strip := ColorRect.new()
	strip.color = bg
	strip.size = Vector2(1300, 110)
	strip.position = Vector2(FIELD_CX - 650, PROMPT_Y - 55)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(strip)
	var l := UITheme.label(text, 64, col, "display_bold", 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(1300, 110)
	l.position = Vector2(FIELD_CX - 650 - 200, PROMPT_Y - 55)
	holder.add_child(l)
	holder.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(holder, "modulate:a", 1.0, 0.15 / speed)
	tw.parallel().tween_property(l, "position:x", FIELD_CX - 650, 0.25 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold / speed)
	tw.tween_property(holder, "modulate:a", 0.0, 0.2 / speed)
	tw.tween_callback(holder.queue_free)
	await tw.finished


func fx_turn(pi: int) -> void:
	_refresh()
	queue_redraw()
	_sfx("turn", 1.0 if pi == me else 0.8)
	await _banner("YOUR TURN" if pi == me else "%s'S TURN" % game.players[pi].player_name.to_upper(),
		UITheme.GOLD if pi == me else Color("ff9a86"),
		Color(0.04, 0.06, 0.13, 0.88) if pi == me else Color(0.15, 0.04, 0.06, 0.88))


func fx_draw(pi: int, _cards: Array) -> void:
	_refresh()
	if pi == me:
		_sfx("card")
		await pause(0.2)


func fx_coin(_pi: int, heads: bool, label: String) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(holder)
	var back := Panel.new()
	back.add_theme_stylebox_override("panel", UITheme.sb(Color(0.04, 0.05, 0.1, 0.94), Color(UITheme.GOLD, 0.6), 22, 2, 14))
	back.position = Vector2(FIELD_CX - 300, PROMPT_Y - 170)
	back.size = Vector2(600, 340)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(back)
	var cap := UITheme.label(label, 28, UITheme.TEXT, "bold")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.size = Vector2(560, 70)
	cap.position = Vector2(FIELD_CX - 280, PROMPT_Y - 160)
	holder.add_child(cap)
	var coin := BattleWidgets.CoinView.new()
	coin.heads = heads
	coin.size = Vector2(150, 150)
	coin.position = Vector2(FIELD_CX - 75, PROMPT_Y - 85)
	holder.add_child(coin)
	var res := UITheme.label("", 44, UITheme.GOLD, "display_bold", 8)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res.size = Vector2(600, 60)
	res.position = Vector2(FIELD_CX - 300, PROMPT_Y + 92)
	holder.add_child(res)
	var tw := create_tween()
	tw.tween_method(coin.set_spin, 0.0, PI * 8.0, 0.85 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	_sfx("coin", 1.0 if heads else 0.8)
	res.text = "HEADS!" if heads else "TAILS"
	res.add_theme_color_override("font_color", UITheme.GOLD if heads else Color("c9cfe0"))
	_pop(res, 0.5)
	await pause(0.7)
	var tw2 := create_tween()
	tw2.tween_property(holder, "modulate:a", 0.0, 0.15 / speed)
	tw2.tween_callback(holder.queue_free)


func fx_message(text: String) -> void:
	_toast(text)
	await pause(1.2)


func fx_enter(c: Creature) -> void:
	_refresh()
	_sfx("card", 0.9)
	_pop(_slot_of(c))
	await pause(0.22)


func fx_evolve(c: Creature) -> void:
	_refresh()
	_sfx("evolve")
	var s := _slot_of(c)
	if s != null:
		s.flash_color = Color(1, 0.95, 0.7)
		s.set_flash(1.0)
		var tw := create_tween()
		tw.tween_method(s.set_flash, 1.0, 0.0, 0.6 / speed)
		_pop(s, 0.8)
		_float_text(_center(s) - Vector2(0, 40), "Awakened!", UITheme.GOLD)
	await pause(0.65)


func fx_energy(c: Creature, card: Card) -> void:
	var s := _slot_of(c)
	var el: String = card.provides()[0] if not card.provides().is_empty() else "any"
	# fly an orb from the hand to the Totem
	if s != null:
		var orb := OrbFx.new()
		orb.element = el
		orb.size = Vector2(60, 60)
		orb.position = Vector2(FIELD_CX - 30, (Y_HAND + 40) if c.owner == me else -60.0)
		fx_layer.add_child(orb)
		var tw := create_tween()
		tw.tween_property(orb, "position", _center(s) - Vector2(30, 30), 0.3 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		orb.queue_free()
	_refresh()
	_sfx("energy")
	_pop(s, 0.92)
	await pause(0.15)


func fx_trainer(pi: int, card: Card) -> void:
	_refresh()
	_sfx("card", 1.1)
	var v := BattleWidgets.HandCard.new()
	v.card = card
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size = Vector2(250, 350)
	v.position = Vector2(FIELD_CX - 125, PROMPT_Y - 175)
	v.pivot_offset = v.size * 0.5
	v.scale = Vector2(0.6, 0.6)
	v.modulate.a = 0.0
	fx_layer.add_child(v)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "scale", Vector2.ONE, 0.2 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "modulate:a", 1.0, 0.15 / speed)
	if pi == rival:
		_update_preview_card(card.id)
	await pause(1.1 if pi == rival else 0.5)
	var tw2 := create_tween()
	tw2.tween_property(v, "modulate:a", 0.0, 0.15 / speed)
	tw2.tween_callback(v.queue_free)
	await pause(0.12)


func fx_switch(pi: int) -> void:
	_refresh()
	_sfx("card", 0.8)
	_pop(slots[pi][0], 0.8)
	await pause(0.3)


func fx_attack(att: Creature, defn: Creature, atk: Dictionary) -> void:
	_refresh()
	var s := _slot_of(att)
	var d := _slot_of(defn)
	if s == null:
		return
	if att.owner == rival:
		_update_preview_card(att.top().id, att.attuned())
	_sfx("card", 0.6)
	var above := att.owner == me
	_float_text(_center(s) + Vector2(0, -s.size.y * 0.5 - 10 if above else s.size.y * 0.5 + 10), atk.name + "!", Color.WHITE, 40)
	if d != null:
		var home: Vector2 = s.get_meta("home")
		var dir := (_center(d) - _center(s)).normalized()
		var tw := create_tween()
		tw.tween_property(s, "position", home + dir * 60.0, 0.12 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "position", home, 0.22 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await pause(0.45)


func fx_damage(c: Creature, amount: int) -> void:
	_refresh()
	var s := _slot_of(c)
	if s == null:
		return
	_sfx("hit", randf_range(0.9, 1.1))
	_float_text(_center(s), "-%d" % amount, Color("ff5a4a"), 60)
	s.flash_color = Color(1, 0.2, 0.2)
	s.set_flash(1.0)
	var tw := create_tween()
	tw.tween_method(s.set_flash, 1.0, 0.0, 0.45 / speed)
	var home: Vector2 = s.get_meta("home")
	var sh := create_tween()
	for i in 5:
		sh.tween_property(s, "position", home + Vector2(randf_range(-9, 9), randf_range(-5, 5)), 0.04 / speed)
	sh.tween_property(s, "position", home, 0.04 / speed)
	await pause(0.55)


func fx_heal(c: Creature, amount: int) -> void:
	_refresh()
	var s := _slot_of(c)
	_sfx("heal")
	if s != null:
		_float_text(_center(s), "+%d" % amount, Color("7dff8a"), 50)
	await pause(0.45)


func fx_popup(c: Creature, text: String, col: Color) -> void:
	_refresh()
	var s := _slot_of(c)
	if s != null:
		_float_text(_center(s) + Vector2(0, -30), text, col, 38)
	await pause(0.45)


func fx_ko(c: Creature) -> void:
	_refresh()
	var s := _slot_of(c)
	if s == null:
		return
	_sfx("ko")
	_float_text(_center(s), "Knocked Out!", Color("ffdd55"), 46)
	s.pivot_offset = s.size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "modulate:a", 0.0, 0.5 / speed)
	tw.tween_property(s, "scale", Vector2(0.6, 0.6), 0.5 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "rotation", 0.2 if c.owner == me else -0.2, 0.5 / speed)
	await tw.finished
	s.set_creature(null)
	s.modulate.a = 1.0
	s.scale = Vector2.ONE
	s.rotation = 0.0
	await pause(0.15)


func fx_prize(pi: int, _card: Card) -> void:
	_refresh()
	_sfx("coin", 1.4)
	var p: Control = info[pi]
	_float_text(p.position + Vector2(170, 180), "Prize!", UITheme.GOLD, 34)
	await pause(0.35)


func fx_summon(pi: int, card: Card) -> void:
	_refresh()
	_sfx("summon")
	var el: String = card.def.get("element", "radiant")
	var holder := SummonFx.new()
	holder.card_id = card.id
	holder.element = el
	holder.size = DESIGN
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(holder)
	var tw := create_tween()
	tw.tween_property(holder, "t", 1.0, 1.6 / speed)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(holder, "modulate:a", 0.0, 0.3 / speed)
	tw2.tween_callback(holder.queue_free)
	if pi == rival:
		_update_preview_card(card.id)
	await pause(0.2)


func fx_gift(pi: int, patron: String) -> void:
	_sfx("gift")
	var p: PlayerState = game.players[pi]
	var holder := GiftFx.new()
	holder.patron = patron
	holder.gift = p.gift()
	holder.who = p.player_name
	holder.size = DESIGN
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(holder)
	var tw := create_tween()
	tw.tween_property(holder, "t", 1.0, 1.5 / speed)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(holder, "modulate:a", 0.0, 0.3 / speed)
	tw2.tween_callback(holder.queue_free)
	_refresh()
	await pause(0.2)


func fx_game_over(winner: int, reason: String) -> void:
	mode = "over"
	_hide_prompt()
	_refresh()
	await pause(0.5)
	var won := winner == me
	_result_won = won
	_sfx("win" if won else "lose")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -520
	box.offset_right = 520
	box.offset_top = -260
	box.offset_bottom = 260
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	dim.add_child(box)
	var head := UITheme.label("VICTORY" if won else ("DRAW" if winner == 2 else "DEFEAT"), 120,
		UITheme.GOLD if won else Color("c9cfe0"), "display_bold", 16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var why := UITheme.label(reason, 34, UITheme.TEXT, "body")
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(why)
	var cont := UITheme.button("Continue", true, 460)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.pressed.connect(func() -> void: finished.emit(won))
	box.add_child(cont)
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.7, 0.4)
	tw.parallel().tween_property(box, "modulate:a", 1.0, 0.5)
	cont.grab_focus.call_deferred()


# ============================================================ fx widgets ===

class PreviewCard:
	extends Control
	signal held
	var card_id := ""
	var attuned = null
	var _press := -1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		if _press >= 0.0:
			_press += delta

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = 0.0
			else:
				if _press >= 0.0:
					held.emit()
				_press = -1.0
			accept_event()

	func _draw() -> void:
		if card_id == "":
			CardFace.box(self, Rect2(Vector2.ZERO, size), 16, Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.08), 2)
			CardFace.text(self, CardFace.font("body"), Vector2(0, size.y * 0.5), "Tap a card to see it here", 22, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			return
		CardFace.draw_card(self, Rect2(Vector2.ZERO, size), card_id, {"compact": false, "attuned": attuned})


class OrbFx:
	extends Control
	var element := "any"

	func _draw() -> void:
		draw_circle(size * 0.5, size.x * 0.6, Color(Lore.color(element, 0), 0.25))
		CardFace.orb(self, size * 0.5, size.x * 0.4, element)


class SummonFx:
	extends Control
	var card_id := ""
	var element := "radiant"
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var col := Lore.color(element, 1)
		var light := Lore.color(element, 0)
		var dark := minf(1.0, t * 3.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72 * dark))
		var c := Vector2(BattleScreen.FIELD_CX, BattleScreen.PROMPT_Y)
		var k := clampf((t - 0.15) / 0.5, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		for i in 20:
			var a := TAU * i / 20.0 + t * 0.8
			var p1 := c
			var p2 := c + Vector2(cos(a), sin(a)) * 1300.0
			var p3 := c + Vector2(cos(a + 0.07), sin(a + 0.07)) * 1300.0
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(light, 0.08 * e))
		for i in 8:
			draw_circle(c, (520.0 - i * 55.0) * e, Color(col, 0.05 * e))
		var h := 560.0 * (0.5 + 0.5 * e)
		var w := h / CardFace.ASPECT
		CardFace.draw_card(self, Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)), card_id, {"compact": false})
		var flash := clampf(1.0 - absf(t - 0.62) * 8.0, 0.0, 1.0)
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(light, 0.6 * flash))
		if t > 0.3:
			CardFace.text(self, CardFace.font("display_bold"), Vector2(0, c.y + h * 0.5 + 60), "SUMMON", 56,
				Color(UITheme.GOLD, e), HORIZONTAL_ALIGNMENT_CENTER, size.x, 10)


class GiftFx:
	extends Control
	var patron := ""
	var gift := ""
	var who := ""
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var el := "any" if patron == "" else String(Lore.GODS[patron].element)
		var col := Lore.color(el, 1)
		var c := Vector2(BattleScreen.FIELD_CX, BattleScreen.PROMPT_Y)
		var k := clampf(t / 0.4, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55 * e))
		for i in 10:
			draw_circle(c, (420.0 - i * 40.0) * e, Color(col, 0.05 * e))
		draw_arc(c, 200 * e, 0, TAU, 96, Color(UITheme.GOLD, 0.8 * e), 4.0, true)
		CardFace.orb(self, c, 140 * e + 1.0, el)
		var god := "their own will" if patron == "" else "%s, %s" % [Lore.GODS[patron].name, Lore.GODS[patron].title]
		CardFace.text(self, CardFace.font("display_bold"), Vector2(0, c.y + 270), Lore.GIFTS.get(gift, {}).get("name", "Gift").to_upper(), 60,
			Color(UITheme.GOLD, e), HORIZONTAL_ALIGNMENT_CENTER, size.x, 10)
		CardFace.text(self, CardFace.font("body"), Vector2(0, c.y + 320), "%s calls on %s" % [who, god], 30,
			Color(1, 1, 1, 0.85 * e), HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
