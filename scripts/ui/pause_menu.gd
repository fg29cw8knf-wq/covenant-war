class_name PauseMenu
extends Control
## The pause menu over the walkable world: the player's stats (Hero), how the
## gods and people see them (Standing), their deck, the card collection
## (Codex), equipment and items, the controls for phone, tablet and
## computer, and the options. Emits action("resume" | "save" | "title").
##
## Deck edits are made on a copy and only become the real deck when they make
## a legal deck; leaving with an unfinished deck asks first.

signal action(what: String)

const TABS := [["hero", "Hero"], ["standing", "Standing"], ["deck", "Deck"], ["codex", "Codex"],
	["items", "Items"], ["howto", "How to Duel"], ["controls", "Controls"], ["options", "Options"]]

## What each attribute does in a duel, and its 7+ perk (see DuelRules).
const ATTR_TEXT := {
	"might": "Raw power. At 7: your Strikes deal +10 damage.",
	"resolve": "Staying power. At 7: every Totem you call has +10 HP.",
	"swiftness": "Speed. Helps you win the roll to go first. At 7: Shifting is free, twice a turn.",
	"cunning": "Traps and tricks. At 7: you get one more Ward slot.",
	"insight": "Reading the duel. At 7: look at your top card each Dawn, and +1 on Fate rolls.",
	"intellect": "Planning. At 7: one more card in your opening hand.",
	"presence": "Command. At 7: the first Totem you call each turn costs 1 less.",
}

var tab := "hero"
var _panel: PanelContainer
var _content: MarginContainer
var _tab_btns := {}
var _deck_work: Array = []
var _overlay: Control = null
var _toast: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 28
	_panel.offset_right = -28
	_panel.offset_top = 24
	_panel.offset_bottom = -24
	_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.04, 0.05, 0.09, 0.97), UITheme.PANEL_EDGE, 22, 2, 22))
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	_panel.add_child(col)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	col.add_child(bar)
	for t in TABS:
		var b := UITheme.button(t[1], false, 0)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 84)
		b.add_theme_font_size_override("font_size", 28)
		var key: String = t[0]
		b.pressed.connect(func() -> void: show_tab(key))
		bar.add_child(b)
		_tab_btns[key] = b
	var resume := UITheme.button("Resume", true, 210)
	resume.custom_minimum_size = Vector2(210, 84)
	resume.pressed.connect(request_close)
	bar.add_child(resume)
	_content = MarginContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("margin_left", 8)
	_content.add_theme_constant_override("margin_right", 8)
	col.add_child(_content)
	_toast = UITheme.label("", 30, UITheme.GOLD, "display_bold", 10)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -800
	_toast.offset_right = 800
	_toast.offset_top = -110
	_toast.offset_bottom = -60
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)


func open(at_tab: String = "") -> void:
	_deck_work = Array(Game.v2.get("deck", [])).duplicate()
	visible = true
	show_tab(at_tab if at_tab != "" else tab)


## Resume: commits a changed deck if it's legal, or asks what to do.
func request_close() -> void:
	if _overlay != null:
		return
	if _deck_changed():
		var probs := DuelCards.deck_problems(_deck_work)
		if probs.is_empty():
			Game.v2.deck = _deck_work.duplicate()
			Game.save_game()
		else:
			_confirm("Your deck isn't ready", "%s\nLeave without saving the changes to your deck?" % probs[0],
				"Keep editing", "Leave, undo changes", func(leave: bool) -> void:
					if leave:
						_deck_work = Array(Game.v2.get("deck", [])).duplicate()
						_close())
			return
	_close()


func _close() -> void:
	visible = false
	_clear()
	action.emit("resume")


func _deck_changed() -> bool:
	var a := _deck_work.duplicate()
	var b := Array(Game.v2.get("deck", [])).duplicate()
	a.sort()
	b.sort()
	return a != b


func toast(t: String) -> void:
	_toast.text = t
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Esc, Tab or a pad's Start closes what's on top: a card's detail or a
## question, else the menu. Caught in _input, before the buttons see it: a
## tab button clicked with the mouse keeps the keyboard focus, and Godot
## would use Tab to move that focus instead.
func _input(e: InputEvent) -> void:
	if not is_visible_in_tree() or not e.is_action_pressed("menu"):
		return
	get_viewport().set_input_as_handled()
	if _overlay != null:
		if _overlay.has_signal("closed"):
			_overlay.emit_signal("closed")   # a card's detail tidies itself away
		else:
			_overlay.queue_free()
			_overlay = null
	else:
		request_close()


func _clear() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	for c in _content.get_children():
		c.queue_free()


func show_tab(key: String) -> void:
	tab = key
	for k in _tab_btns:
		_tab_btns[k].button_pressed = k == key
	_clear()
	var page: Control
	match key:
		"hero": page = _hero()
		"standing": page = _standing()
		"deck": page = _deck()
		"codex": page = _codex()
		"items": page = _items()
		"howto": page = _howto()
		"controls": page = _controls()
		_: page = _options()
	_content.add_child(page)


# ================================================================== hero ===

func _hero() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 44)
	# --- left: who you are
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(520, 0)
	left.add_theme_constant_override("separation", 12)
	hb.add_child(left)
	var pic := Portrait.new()
	pic.tex = DollArt.portrait("player")
	pic.custom_minimum_size = Vector2(300, 300)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(pic)
	left.add_child(UITheme.label(Game.player_name, 58, UITheme.GOLD, "display_bold"))
	var patron := String(Game.profile.get("patron", ""))
	var gift_id := Lore.UNSWORN_GIFT if patron == "" else String(Lore.GODS[patron].gift)
	var sworn := "Unsworn: kneels to no god (+1 to every attribute)" if patron == "" else "Sworn to %s, %s (+3 %s)" % [Lore.GODS[patron].name, Lore.GODS[patron].title, Lore.ATTRIBUTE_NAMES[Lore.GODS[patron].attribute]]
	left.add_child(_wrap(sworn, 28, UITheme.TEXT))
	left.add_child(_wrap("Divine Gift: [b]%s[/b]. %s Once per duel." % [Lore.GIFTS[gift_id].name, DuelCards.gift_text(gift_id)], 26, UITheme.TEXT_DIM, true))
	var mins := int(Game.play_seconds / 60.0)
	left.add_child(UITheme.label("%s  ·  played %dh %02dm" % [_area_name(), mins / 60, mins % 60], 24, UITheme.TEXT_DIM))
	# --- right: rank, attributes, Resonance
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	hb.add_child(right)
	var v: Dictionary = Game.v2
	var rank := int(v.get("rank", 1))
	var rk := HBoxContainer.new()
	rk.add_theme_constant_override("separation", 20)
	right.add_child(rk)
	rk.add_child(UITheme.label("SIGIL RANK %d" % rank, 40, UITheme.GOLD, "display_bold"))
	var xb := Meter.new()
	xb.value = float(v.get("xp", 0)) / float(DuelRewards.xp_to_next(rank))
	xb.text = "%d / %d to Rank %d" % [int(v.get("xp", 0)), DuelRewards.xp_to_next(rank), rank + 1]
	xb.custom_minimum_size = Vector2(520, 44)
	xb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rk.add_child(xb)
	var seals: Array = v.get("seals", [])
	right.add_child(UITheme.label("Seals %d of 7  ·  your Rank can climb to %d (each kingdom's Seal raises it)  ·  cards up to %s answer you" % [
		seals.size(), Game.rank_cap(), Lore.TIER_NAMES[DuelRewards.tier_cap(rank)]], 24, UITheme.TEXT_DIM))
	var pts := int(v.get("points", 0))
	var head := HBoxContainer.new()
	right.add_child(head)
	head.add_child(UITheme.label("ATTRIBUTES", 32, UITheme.GOLD, "display_bold"))
	var pl := UITheme.label("   %d point%s to place: tap +" % [pts, "" if pts == 1 else "s"] if pts > 0 else "   Rank up to earn points to place", 26, UITheme.GOLD if pts > 0 else UITheme.TEXT_DIM)
	head.add_child(pl)
	right.add_child(UITheme.label("Each point adds %d Life in a duel and helps the Fate rolls of cards that draw on it." % DuelRules.life_per_attribute, 22, UITheme.TEXT_DIM))
	var gear := Items.gear_bonus(Game.equipped)
	for a in Lore.ATTRIBUTES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		right.add_child(row)
		var g := GlyphIcon.new()
		g.glyph = a
		g.custom_minimum_size = Vector2(54, 64)
		row.add_child(g)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tv)
		tv.add_child(UITheme.label(Lore.ATTRIBUTE_NAMES[a], 28, UITheme.TEXT, "display_bold"))
		var desc := UITheme.label(ATTR_TEXT[a], 21, UITheme.TEXT_DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(desc)
		var p := Pips.new()
		p.base = int(Game.profile.get("base", {}).get(a, 3))
		p.total = int(Game.profile.get("attributes", {}).get(a, 3))
		p.gear = int(gear.get(a, 0))
		p.custom_minimum_size = Vector2(330, 40)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(p)
		var val := UITheme.label(str(p.total), 34, UITheme.GOLD if p.total >= DuelRules.perk_level else UITheme.TEXT, "display_bold")
		val.custom_minimum_size = Vector2(46, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val)
		var plus := UITheme.button("+", true, 72)
		plus.custom_minimum_size = Vector2(72, 64)
		plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		plus.visible = pts > 0
		plus.disabled = p.base >= 10
		var attr: String = a
		plus.pressed.connect(func() -> void:
			if Game.spend_point(attr):
				Game.save_game()
				show_tab("hero"))
		row.add_child(plus)
	var tgt := String(v.get("target", ""))
	var res := "Your wins build Resonance towards [b]%s[/b]: %d / %d. Change it in the Codex." % [DuelCards.CARDS[tgt].name, int(v.get("banked", {}).get(tgt, 0)), DuelRewards.card_cost(tgt)] if tgt != "" and DuelCards.CARDS.has(tgt) \
		else "Your wins make Resonance. Pick a card in the Codex to build it towards."
	right.add_child(_wrap(res + "  Attunement pool: %d." % int(v.get("pool", 0)), 24, UITheme.TEXT_DIM, true))
	return _scroll(hb)


func _area_name() -> String:
	match Game.area:
		"ashford": return "Ashford"
		"solhaven": return "Solhaven"
	return Game.area.capitalize()


# ============================================================== standing ===

func _standing() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UITheme.label("THE GODS", 34, UITheme.GOLD, "display_bold"))
	v.add_child(_wrap("Every god is watching who might take the Throne. What you say and do moves them, and they remember.", 24, UITheme.TEXT_DIM))
	for g in Lore.GREAT_GODS:
		v.add_child(_standing_row(g))
	v.add_child(_gap(16))
	v.add_child(UITheme.label("PEOPLE", 34, UITheme.GOLD, "display_bold"))
	var met := Standing.people_met()
	if met.is_empty():
		v.add_child(_wrap("Nobody yet. The people you meet will appear here.", 24, UITheme.TEXT_DIM))
	for p in met:
		v.add_child(_standing_row(p))
	return _scroll(v)


func _standing_row(who: String) -> Control:
	var r := StandingRow.new()
	r.who = who
	r.custom_minimum_size = Vector2(0, 112)
	return r


# ================================================================== deck ===

func _deck() -> Control:
	if not Game.has_deck():
		return _empty_page("No deck yet", "Bram keeps his old decks in the cellar of the Crooked Lantern. You'll have one of your own before long.")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	v.add_child(top)
	var counts := {}
	for id in _deck_work:
		var k: String = DuelCards.CARDS[id].kind
		counts[k] = int(counts.get(k, 0)) + 1
	top.add_child(UITheme.label("YOUR DECK  %d / %d" % [_deck_work.size(), DuelRules.deck_size], 38, UITheme.GOLD, "display_bold"))
	var parts := []
	for k in ["totem", "rite", "ward", "summon"]:
		if counts.has(k):
			parts.append("%d %s%s" % [counts[k], k.capitalize(), "" if int(counts[k]) == 1 else "s"])
	var comp := UITheme.label("  ·  ".join(parts), 26, UITheme.TEXT_DIM)
	comp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(comp)
	var add := UITheme.button("Add cards from the Codex", false, 0)
	add.custom_minimum_size = Vector2(0, 76)
	add.add_theme_font_size_override("font_size", 26)
	add.pressed.connect(func() -> void: show_tab("codex"))
	top.add_child(add)
	var probs := DuelCards.deck_problems(_deck_work)
	var st := UITheme.label(("Ready to duel." if not _deck_changed() else "Ready. Your changes are saved when you leave the menu.") if probs.is_empty() else "Not ready: " + probs[0],
		26, Color("8fe0a0") if probs.is_empty() else Color("ff8a80"))
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(st)
	var ids := []
	for id in Codex.all_ids():
		if _deck_work.has(id):
			ids.append(id)
	var grid := Codex.Grid.new()
	grid.show_filters = false
	grid.only = ids
	grid.deck = _deck_work
	grid.counts_from_deck = true
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.card_tapped.connect(func(id: String) -> void: _open_card(id))
	v.add_child(grid)
	return v


# ================================================================= codex ===

func _codex() -> Control:
	var grid := Codex.Grid.new()
	grid.deck = _deck_work
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.card_tapped.connect(func(id: String) -> void: _open_card(id))
	return grid


func _open_card(id: String) -> void:
	var d := Codex.Detail.new()
	d.id = id
	d.deck = _deck_work if Game.has_deck() else null
	d.closed.connect(func() -> void:
		d.queue_free()
		_overlay = null
		show_tab(tab))
	d.changed.connect(func() -> void: Game.save_game())
	add_child(d)
	_overlay = d


# ================================================================= items ===

func _items() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(UITheme.label("EQUIPMENT", 34, UITheme.GOLD, "display_bold"))
	v.add_child(_wrap("Charms are found and earned on your journey. Each one you wear lifts an attribute, and counts in every duel.", 24, UITheme.TEXT_DIM))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 20)
	v.add_child(slots)
	var owned := Items.gear_owned()
	for s in Items.SLOTS:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.07, 0.08, 0.13, 0.95), Color(UITheme.GOLD_DIM, 0.6), 16, 2, 22))
		slots.add_child(box)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 6)
		box.add_child(bv)
		bv.add_child(UITheme.label(Items.SLOT_NAMES[s].to_upper(), 24, UITheme.GOLD_DIM, "bold"))
		var worn := String(Game.equipped.get(s, ""))
		if worn != "":
			bv.add_child(UITheme.label(Items.ITEMS[worn].name, 32, UITheme.GOLD, "display_bold"))
			bv.add_child(UITheme.label(Items.bonus_text(worn), 26, UITheme.TEXT))
		else:
			bv.add_child(UITheme.label("Empty", 32, Color(1, 1, 1, 0.35), "display_bold"))
			bv.add_child(UITheme.label(Items.SLOT_HINTS[s], 22, UITheme.TEXT_DIM))
		for id in owned:
			if String(Items.ITEMS[id].slot) != s:
				continue
			var wearing: bool = worn == id
			var b := UITheme.button(("Take off " if wearing else "Wear ") + String(Items.ITEMS[id].name), false, 0)
			b.custom_minimum_size = Vector2(0, 72)
			b.add_theme_font_size_override("font_size", 24)
			var slot: String = s
			var item: String = id
			b.pressed.connect(func() -> void:
				Game.equip(slot, "" if wearing else item)
				show_tab("items"))
			bv.add_child(b)
	v.add_child(_gap(10))
	v.add_child(UITheme.label("CARRIED", 34, UITheme.GOLD, "display_bold"))
	var carried := Items.story_items()
	if carried.is_empty():
		v.add_child(_wrap("Nothing yet.", 24, UITheme.TEXT_DIM))
	for id in carried:
		var d: Dictionary = Items.ITEMS[id]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		row.add_child(UITheme.label(d.name, 30, UITheme.TEXT, "display_bold"))
		row.add_child(_wrap(d.text, 24, UITheme.TEXT_DIM))
		v.add_child(row)
	return _scroll(v)


# ============================================================== controls ===

## "phone", "tablet" or "computer", from the device the game is running on.
## (DisplayServer.is_touchscreen_available() can't be used: the project
## emulates touch from the mouse, which makes it true everywhere.)
static func device_kind() -> String:
	var touch := OS.has_feature("mobile")
	if OS.has_feature("web"):
		touch = OS.has_feature("web_ios") or OS.has_feature("web_android")
		if not touch:
			# an iPad's Safari says it's a Mac; touch points give it away
			var mt = JavaScriptBridge.eval("navigator.maxTouchPoints || 0", true)
			touch = mt != null and int(mt) > 1
	if not touch:
		return "computer"
	var s := DisplayServer.window_get_size()
	var r := float(maxi(s.x, s.y)) / float(maxi(1, mini(s.x, s.y)))
	return "tablet" if r < 1.6 else "phone"


const CONTROLS := {
	"phone": {
		"name": "Phone",
		"note": "Turn your phone sideways. In Safari, Share > Add to Home Screen gives you a full-screen app.",
		"explore": [
			["Walk", "Drag anywhere on the screen: a joystick appears under your thumb."],
			["Walk to a spot", "Tap the ground."],
			["Talk or duel", "Walk up to someone and tap the round button (bottom right), or tap them."],
			["Next line", "Tap the conversation box."],
			["Answer", "Tap the answer you want."],
			["Pause menu", "Tap ☰ at the top right."],
		],
		"duel": [
			["Look at a card", "Tap it in your hand to see the whole card."],
			["Call a Totem", "Tap it in your hand, then tap an empty slot."],
			["Attack", "Tap your Totem, choose a move, then tap the target."],
			["Rite or Ward", "Tap the card, then the button that appears (or its target)."],
			["Your god's Gift", "Tap the medallion beside End Turn (once a duel)."],
			["End your turn", "Tap the big emblem, bottom right."],
			["Change your mind", "Tap Cancel, or tap an empty part of the board."],
			["Duel menu", "Tap ☰ at the top right: speed, the duel log, restart."],
		],
	},
	"tablet": {
		"name": "iPad / tablet",
		"note": "Everything works the same as on a phone, with more room. Hold it sideways. A keyboard case works too: the computer keys apply.",
		"explore": [
			["Walk", "Drag anywhere on the screen, or tap the ground to walk there."],
			["Talk or duel", "Tap the round button (bottom right) when it appears, or tap the person."],
			["Next line", "Tap the conversation box."],
			["Answer", "Tap the answer you want."],
			["Pause menu", "Tap ☰ at the top right."],
		],
		"duel": [
			["Look at a card", "Tap it in your hand."],
			["Call a Totem", "Tap it in your hand, then tap an empty slot."],
			["Attack", "Tap your Totem, choose a move, then tap the target."],
			["Rite or Ward", "Tap the card, then the button that appears (or its target)."],
			["Your god's Gift", "Tap the medallion beside End Turn."],
			["End your turn", "Tap the big emblem, bottom right."],
			["Change your mind", "Tap Cancel."],
			["Duel menu", "Tap ☰ at the top right."],
		],
	},
	"computer": {
		"name": "Laptop / computer",
		"note": "Mouse or trackpad: click wherever the phone version says tap.",
		"explore": [
			["Walk", "W A S D or the arrow keys."],
			["Walk to a spot", "Click the ground."],
			["Talk or duel", "E, Space or Enter when the round button shows, or click the person."],
			["Next line", "Click, or E / Space / Enter."],
			["Answer", "Click it, or pick it with the arrow keys and press Enter (or E)."],
			["Pause menu", "Esc or Tab."],
		],
		"duel": [
			["Look at a card", "Click it in your hand."],
			["Call a Totem", "Click it, then click an empty slot."],
			["Attack", "Click your Totem, choose a move, then click the target."],
			["Rite or Ward", "Click the card, then the button that appears (or its target)."],
			["Your god's Gift", "Click the medallion beside End Turn."],
			["End your turn", "Space (with nothing selected), or click the big emblem."],
			["Change your mind", "Esc or right-click."],
			["Duel menu", "Esc with nothing selected, or click ☰."],
			["Bram's lessons", "Click, or E / Space / Enter, to go on."],
		],
	},
	"controller": {
		"name": "Controller",
		"note": "Xbox, PlayStation and MFi controllers work while exploring. Duels need taps or the mouse for now.",
		"explore": [
			["Walk", "Left stick."],
			["Talk or duel", "A (Cross on PlayStation)."],
			["Next line", "A (Cross)."],
			["Answer", "Left stick or d-pad to choose, then A (Cross)."],
			["Pause menu", "Start (Options)."],
		],
		"duel": [
			["Duels", "Use touch or the mouse for now. Full controller duels come later."],
			["Bram's lessons", "A (Cross) moves his explanations on. When he says tap, use touch or the mouse."],
		],
	},
}


func _controls() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var here := device_kind()
	var body := VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var btns := {}
	var fill := func(kind: String) -> void:
		for c in body.get_children():
			c.queue_free()
		for k in btns:
			btns[k].button_pressed = k == kind
		var d: Dictionary = CONTROLS[kind]
		var note := _wrap(d.note, 24, UITheme.TEXT_DIM)
		body.add_child(note)
		var cols := HBoxContainer.new()
		cols.add_theme_constant_override("separation", 40)
		cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(cols)
		for part in [["EXPLORING", d.explore], ["DUELLING", d.duel]]:
			var c := VBoxContainer.new()
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.add_theme_constant_override("separation", 8)
			cols.add_child(c)
			c.add_child(UITheme.label(part[0], 30, UITheme.GOLD, "display_bold"))
			for line in part[1]:
				var r := HBoxContainer.new()
				r.add_theme_constant_override("separation", 16)
				var a := UITheme.label(line[0], 25, UITheme.TEXT, "bold")
				a.custom_minimum_size = Vector2(230, 0)
				r.add_child(a)
				var how := UITheme.label(line[1], 25, Color(UITheme.TEXT, 0.85))
				how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				how.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				r.add_child(how)
				c.add_child(r)
	for k in ["phone", "tablet", "computer", "controller"]:
		var label: String = CONTROLS[k].name + ("  (this device)" if k == here else "")
		var b := UITheme.button(label, false, 0)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 72)
		b.add_theme_font_size_override("font_size", 25)
		var kind: String = k
		b.pressed.connect(func() -> void: fill.call(kind))
		row.add_child(b)
		btns[k] = b
	v.add_child(_scroll(body))
	fill.call(here)
	return v


# =========================================================== how to duel ===

## Every lesson Bram has given, in the order he gave it (Game.lessons()),
## under the heading each belongs to, with the element chart once he's shown it.
func _howto() -> Control:
	var lessons: Array = Game.lessons()
	if lessons.is_empty():
		return _empty_page("How to Duel", "Bram hasn't taught you anything yet. Every lesson he gives is kept here, so you can read it again.")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(_wrap("Everything Bram has told you about duelling, in the order he said it.", 24, UITheme.TEXT_DIM))
	var groups := []
	for l in lessons:
		if not groups.has(l.group):
			groups.append(l.group)
	for g in groups:
		v.add_child(_gap(10))
		v.add_child(UITheme.label(String(g).to_upper(), 30, UITheme.GOLD, "display_bold"))
		for l in lessons:
			if l.group != g:
				continue
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 16)
			var who := UITheme.label(String(l.who).to_upper(), 23, UITheme.GOLD_DIM, "bold")
			who.custom_minimum_size = Vector2(110, 0)
			r.add_child(who)
			var say := UITheme.label(String(l.say), 25, UITheme.TEXT)
			say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			say.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(say)
			v.add_child(r)
		if g == "The elements":
			var chart := ElementChart.new()
			chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			v.add_child(chart)
	v.add_child(_gap(20))
	return _scroll(v)


# =============================================================== options ===

func _options() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.add_child(_slider("Music", "music", 0.8, func() -> void: Music.apply_volume()))
	v.add_child(_slider("Sound effects", "sfx", 0.9, func() -> void: pass))
	v.add_child(_slider("Text speed", "text_speed", 1.0, func() -> void: pass, 0.5, 2.5))
	v.add_child(_check("Full violence (blood when Totems fall)", String(Game.settings.get("violence", "full")) == "full", func(on: bool) -> void:
		Game.settings["violence"] = "full" if on else "reduced"))
	v.add_child(_check("3D duel field", bool(Game.settings.get("duel_3d", true)), func(on: bool) -> void:
		Game.settings["duel_3d"] = on))
	v.add_child(_check("Show advert placeholders (this early build only)", bool(Game.settings.get("ad_previews", true)), func(on: bool) -> void:
		Game.settings["ad_previews"] = on))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	var save := UITheme.button("Save game", false, 360)
	save.pressed.connect(func() -> void:
		if Game.save_game():
			toast("Game saved"))
	row.add_child(save)
	var title := UITheme.button("Save and quit to title", false, 460)
	title.pressed.connect(func() -> void:
		_confirm("Quit to the title screen?", "Your game is saved first.", "Stay", "Quit to title", func(yes: bool) -> void:
			if yes:
				visible = false
				_clear()
				action.emit("title")))
	row.add_child(title)
	v.add_child(_gap(10))
	v.add_child(UITheme.label("The Covenant War: Throne of Ages  ·  made by Gary Mannion  ·  early build %s" % ProjectSettings.get_setting("application/config/version", ""), 22, UITheme.TEXT_DIM))
	v.add_child(UITheme.label(NoticeScreen.COPYRIGHT, 22, UITheme.TEXT_DIM))
	return _scroll(v)


func _slider(label: String, key: String, def: float, after: Callable, lo := 0.0, hi := 1.0) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var l := UITheme.label(label, 30, UITheme.TEXT, "bold")
	l.custom_minimum_size = Vector2(300, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Game.settings.get(key, def))
	s.custom_minimum_size = Vector2(700, 64)
	s.add_theme_icon_override("grabber", _grabber())
	s.add_theme_icon_override("grabber_highlight", _grabber())
	s.add_theme_stylebox_override("slider", UITheme.sb(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 8, 0, 4))
	s.add_theme_stylebox_override("grabber_area", UITheme.sb(Color(UITheme.GOLD, 0.6), Color(0, 0, 0, 0), 8, 0, 4))
	s.add_theme_stylebox_override("grabber_area_highlight", UITheme.sb(UITheme.GOLD, Color(0, 0, 0, 0), 8, 0, 4))
	s.value_changed.connect(func(x: float) -> void:
		Game.settings[key] = x
		Game.save_settings()
		after.call())
	row.add_child(s)
	return row


static var _switch_tex := {}


## A big on/off switch for the options, easy to hit with a thumb.
static func _switch(on: bool) -> Texture2D:
	if _switch_tex.has(on):
		return _switch_tex[on]
	var w := 96
	var h := 52
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := Color(UITheme.GOLD, 0.9) if on else Color(1, 1, 1, 0.18)
	var knob_x := w - h * 0.5 if on else h * 0.5
	for y in h:
		for x in w:
			var cx := clampf(float(x), h * 0.5, w - h * 0.5)
			var d := Vector2(x + 0.5 - cx, y + 0.5 - h * 0.5).length()
			var a := clampf(h * 0.5 - d, 0.0, 1.0)
			var c := Color(track, track.a * a)
			var dk := Vector2(x + 0.5 - knob_x, y + 0.5 - h * 0.5).length()
			var ka := clampf(h * 0.5 - 5.0 - dk, 0.0, 1.0)
			if ka > 0.0:
				c = c.lerp(Color(1, 1, 1, 1) if on else Color("c9c6d6"), ka)
				c.a = maxf(c.a, ka)
			img.set_pixel(x, y, c)
	_switch_tex[on] = ImageTexture.create_from_image(img)
	return _switch_tex[on]


static var _grab_tex: Texture2D


static func _grabber() -> Texture2D:
	if _grab_tex == null:
		var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
		for y in 40:
			for x in 40:
				var d := Vector2(x - 19.5, y - 19.5).length()
				var a := clampf(19.0 - d, 0.0, 1.0)
				var c := UITheme.GOLD if d < 15.0 else Color("1a2036")
				img.set_pixel(x, y, Color(c, a))
		_grab_tex = ImageTexture.create_from_image(img)
	return _grab_tex


func _check(label: String, on: bool, f: Callable) -> Control:
	var c := CheckButton.new()
	c.text = label
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 28)
	c.custom_minimum_size = Vector2(0, 72)
	c.add_theme_icon_override("checked", _switch(true))
	c.add_theme_icon_override("unchecked", _switch(false))
	c.add_theme_icon_override("checked_disabled", _switch(true))
	c.add_theme_icon_override("unchecked_disabled", _switch(false))
	c.toggled.connect(func(x: bool) -> void:
		f.call(x)
		Game.save_settings())
	return c


# ================================================================ helpers ===

func _wrap(t: String, fs: int, c: Color, bb := false) -> Control:
	if bb:
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.text = t
		r.add_theme_font_size_override("normal_font_size", fs)
		r.add_theme_font_size_override("bold_font_size", fs)
		r.add_theme_color_override("default_color", c)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return r
	var l := UITheme.label(t, fs, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _scroll(inner: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(inner)
	return s


func _empty_page(head: String, body: String) -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	var h := UITheme.label(head, 44, UITheme.GOLD, "display_bold")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var b := UITheme.label(body, 28, UITheme.TEXT_DIM)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	return v


## A yes/no box over the menu. done(yes) is called with the answer.
func _confirm(head: String, body: String, no_text: String, yes_text: String, done: Callable) -> void:
	var o := Control.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(o)
	_overlay = o
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -520
	p.offset_right = 520
	p.offset_top = -200
	p.offset_bottom = 200
	o.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var h := UITheme.label(head, 40, UITheme.GOLD, "display_bold")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var b := UITheme.label(body, 28, UITheme.TEXT)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	var no := UITheme.button(no_text, true, 360)
	var yes := UITheme.button(yes_text, false, 360)
	row.add_child(no)
	row.add_child(yes)
	var finish := func(ans: bool) -> void:
		o.queue_free()
		_overlay = null
		done.call(ans)
	no.pressed.connect(func() -> void: finish.call(false))
	yes.pressed.connect(func() -> void: finish.call(true))
	no.grab_focus.call_deferred()


# ================================================================ widgets ===

class Portrait:
	extends Control
	var tex: Texture2D

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, r, 22, Color("10142a"), Color(UITheme.GOLD, 0.8), 3)
		if tex != null:
			DuelArt.rounded(self, r.grow(-6), 18, tex)


class GlyphIcon:
	extends Control
	var glyph := "might"

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 26, Color(UITheme.GOLD, 0.12))
		Glyphs.draw(self, glyph, c, 17, UITheme.GOLD)


## Ten pips: earned (gold), blessing (pale) and equipment (blue).
class Pips:
	extends Control
	var base := 3
	var total := 3
	var gear := 0

	func _draw() -> void:
		var n := 10
		var gap := 6.0
		var w := (size.x - gap * (n - 1)) / n
		var bless_to := total - gear
		for i in n:
			var r := Rect2(Vector2(i * (w + gap), 4), Vector2(w, size.y - 8))
			var col := Color(1, 1, 1, 0.08)
			if i < base:
				col = UITheme.GOLD
			elif i < bless_to:
				col = Color("fff2cf")
			elif i < total:
				col = Color("8fd0ff")
			CardFace.box(self, r, 5, col)
			if i == DuelRules.perk_level - 1:
				draw_line(r.position + Vector2(r.size.x + gap * 0.5, -4), r.position + Vector2(r.size.x + gap * 0.5, r.size.y + 4), Color(1, 1, 1, 0.35), 2.0)


## A progress bar with words on it.
class Meter:
	extends Control
	var value := 0.0
	var text := ""

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, r, size.y * 0.5, Color(1, 1, 1, 0.08), Color(UITheme.GOLD, 0.5), 2)
		var k := clampf(value, 0.0, 1.0)
		if k > 0.0:
			CardFace.box(self, Rect2(r.position, Vector2(maxf(size.y, r.size.x * k), r.size.y)), size.y * 0.5, Color(UITheme.GOLD, 0.75))
		CardFace.text_in(self, CardFace.font("bold"), r, text, 22, Color.WHITE)


## One god or person: picture, name, a meter from -10 to +10 and why.
class StandingRow:
	extends Control
	var who := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var h := size.y
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, r.grow(-2), 16, Color(1, 1, 1, 0.035))
		var c := Vector2(h * 0.5 + 8, h * 0.5)
		var rad := h * 0.4
		var god := Standing.is_god(who)
		var col := UITheme.GOLD
		if god:
			col = Lore.color(Lore.GODS[who].element, 0)
			if not DuelArt.god_medallion(self, c, rad, who, col):
				draw_circle(c, rad, Lore.color(Lore.GODS[who].element, 2))
				Glyphs.draw(self, Lore.GODS[who].element, c, rad * 0.6, col)
		else:
			var tex := DollArt.portrait(String(Standing.PEOPLE[who].look))
			DuelArt.rounded(self, Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), rad, tex)
			draw_arc(c, rad, 0, TAU, 48, Color(UITheme.GOLD, 0.7), 2.0, true)
		var x := h + 30.0
		var name := Standing.display_name(who)
		var sub: String = "%s" % Lore.GODS[who].title if god else String(Standing.PEOPLE[who].role)
		CardFace.text(self, CardFace.font("display_bold"), Vector2(x, h * 0.36), name, 32, UITheme.TEXT)
		CardFace.text(self, CardFace.font("body"), Vector2(x, h * 0.62), sub, 22, UITheme.TEXT_DIM)
		var why := Standing.reasons(who)
		var last: String = why[-1] if not why.is_empty() else ("They don't know you yet." if not god else "Watching. Nothing you've done has moved them yet.")
		CardFace.text(self, CardFace.font("body"), Vector2(x, h * 0.88), last, 21, Color(UITheme.TEXT, 0.7))
		# the meter
		var v := Standing.value(who)
		var mw := minf(520.0, size.x * 0.32)
		var mr := Rect2(Vector2(size.x - mw - 30, h * 0.5 - 8), Vector2(mw, 16))
		CardFace.box(self, mr, 8, Color(1, 1, 1, 0.08))
		var mid := mr.position.x + mr.size.x * 0.5
		var k := float(v) / 10.0
		if v > 0:
			CardFace.box(self, Rect2(Vector2(mid, mr.position.y), Vector2(mr.size.x * 0.5 * k, mr.size.y)), 8, UITheme.GOLD)
		elif v < 0:
			var w := mr.size.x * 0.5 * -k
			CardFace.box(self, Rect2(Vector2(mid - w, mr.position.y), Vector2(w, mr.size.y)), 8, Color("e0606a"))
		draw_line(Vector2(mid, mr.position.y - 6), Vector2(mid, mr.end.y + 6), Color(1, 1, 1, 0.5), 2.0)
		var word := Standing.level_name(who)
		CardFace.text(self, CardFace.font("display_bold"), Vector2(mr.position.x, mr.position.y - 14), word, 26,
			UITheme.GOLD if v > 1 else (Color("ff8a80") if v < -1 else UITheme.TEXT), HORIZONTAL_ALIGNMENT_CENTER, mr.size.x)
		CardFace.text(self, CardFace.font("bold"), Vector2(mr.position.x, mr.end.y + 26), "%+d" % v if v != 0 else "0", 20,
			UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, mr.size.x)
