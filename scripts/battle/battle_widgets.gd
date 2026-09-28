class_name BattleWidgets
extends RefCounted
## The pieces the duel screen is built from.


# ================================================================ TotemSlot ===
## A place on the field: an Active or Bench spot. Shows the Totem in it with
## remaining HP, attached Energy, conditions and the Attuned glow.
class TotemSlot:
	extends Control
	signal tapped(slot)
	signal held(slot)

	var owner_index := 0
	var is_active := false
	var bench_index := -1
	var creature: Creature = null
	var ghost_id := ""          # a card shown before it's really in play (setup)
	var highlight := ""         # "", "target", "selected"
	var flash := 0.0
	var flash_color := Color(1, 0.2, 0.2)
	var _t := 0.0
	var _press_t := -1.0
	var _held := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_creature(c: Creature) -> void:
		creature = c
		queue_redraw()

	func set_flash(v: float) -> void:
		flash = v
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if _press_t >= 0.0:
			_press_t += delta
			if _press_t > 0.42 and not _held:
				_held = true
				held.emit(self)
		if highlight != "" or (creature != null and creature.attuned()):
			queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press_t = 0.0
				_held = false
			else:
				if _press_t >= 0.0 and not _held:
					tapped.emit(self)
				_press_t = -1.0
			accept_event()

	func card_id() -> String:
		if creature != null:
			return creature.top().id
		return ghost_id

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var s := size.x / CardFace.W
		var id := card_id()
		if id == "":
			_draw_empty(r)
			return
		if creature != null and creature.attuned():
			var a := 0.45 + 0.35 * sin(_t * 3.0)
			CardFace.box(self, r.grow(5 * s + 2), 16 * s + 3, Color(0, 0, 0, 0), Color(UITheme.GOLD, a), maxf(2.0, 4 * s))
		CardFace.draw_card(self, r, id, {"compact": true, "hide_hp": true})
		if creature == null:
			draw_rect(r, Color(0, 0, 0, 0.15))
		else:
			_draw_hp(r, s)
			_draw_energy(r, s)
			_draw_conditions(r, s)
		if flash > 0.0:
			CardFace.box(self, r, 13 * s, Color(flash_color, flash * 0.55))
		_draw_highlight(r, s)

	func _draw_empty(r: Rect2) -> void:
		var pts := CardFace.round_rect_points(r.grow(-4), 14)
		pts.append(pts[0])
		var col := Color(1, 1, 1, 0.12)
		if highlight == "target":
			col = Color(UITheme.GOLD, 0.55 + 0.35 * sin(_t * 5.0))
			CardFace.box(self, r.grow(-4), 14, Color(UITheme.GOLD, 0.08))
		draw_polyline(pts, col, 3.0, true)
		if is_active:
			Glyphs.draw(self, "crown_sigil", r.get_center(), r.size.x * 0.18, Color(1, 1, 1, 0.08))

	func _draw_highlight(r: Rect2, s: float) -> void:
		if highlight == "":
			return
		var pulse := 0.6 + 0.4 * sin(_t * 5.0)
		var col := UITheme.GOLD if highlight == "target" else Color("8fd0ff")
		CardFace.box(self, r.grow(4), 16 * s + 4, Color(0, 0, 0, 0), Color(col, pulse), maxf(3.0, 5 * s))

	func _draw_hp(r: Rect2, s: float) -> void:
		var c := creature
		var mx := c.max_hp()
		var left := c.hp_left()
		var frac := float(left) / float(maxi(1, mx))
		var col := Color("7ee08a")
		if frac <= 0.25:
			col = Color("ff6a5a")
		elif frac <= 0.5:
			col = Color("ffd166")
		var pill := Rect2(r.position + Vector2(12, 12) * s, Vector2(118, 58) * s)
		CardFace.box(self, pill, 14 * s, Color(0.03, 0.03, 0.06, 0.82), Color(col, 0.7), maxf(1.0, 2 * s))
		var f := CardFace.font("display_bold")
		var num := str(left)
		CardFace.text(self, f, pill.position + Vector2(10, 42) * s, num, CardFace._fs(s, 40), Color.WHITE)
		var nw := f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, CardFace._fs(s, 40)).x
		if left != mx:
			CardFace.text(self, CardFace.font("bold"), pill.position + Vector2(14 * s + nw, 40 * s), "/%d" % mx, CardFace._fs(s, 20), Color(1, 1, 1, 0.6))
		var bar := Rect2(pill.position + Vector2(10, 48) * s, Vector2(98 * s, 5 * s))
		draw_rect(bar, Color(1, 1, 1, 0.15))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), col)

	func _draw_energy(r: Rect2, s: float) -> void:
		var es: Array = creature.energy
		if es.is_empty():
			return
		var rad := 17.0 * s * (1.4 if is_active else 1.6)
		rad = maxf(rad, 9.0)
		var gap := minf(rad * 2.1, (r.size.x - rad * 2.0) / maxf(1.0, es.size() - 1))
		var total := gap * (es.size() - 1)
		var y := r.end.y - rad * 0.2
		for i in es.size():
			var el: String = es[i].provides()[0] if not es[i].provides().is_empty() else "any"
			CardFace.orb(self, Vector2(r.get_center().x - total * 0.5 + i * gap, y), rad, el)

	const COND_COL := {
		"asleep": Color("b9a4ff"), "paralyzed": Color("ffe066"), "confused": Color("ff9ad5"),
		"frozen": Color("a8e6ff"), "poisoned": Color("9be15d"), "burned": Color("ff9a4a"),
	}

	func _draw_conditions(r: Rect2, s: float) -> void:
		var conds := creature.conditions()
		var y := r.position.y + 128 * s
		var f := CardFace.font("bold")
		var fs := CardFace._fs(s, 24)
		fs = maxi(fs, 11)
		for cnd in conds:
			var label: String = String(cnd).to_upper()
			var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18
			var rr := Rect2(Vector2(r.position.x + 10 * s, y), Vector2(w, fs + 10))
			CardFace.box(self, rr, (fs + 10) * 0.5, Color(COND_COL.get(cnd, Color.WHITE), 0.92))
			CardFace.text_in(self, f, rr, label, fs, Color("1a1420"))
			y += fs + 14


# ================================================================ HandCard ===
class HandCard:
	extends Control
	signal tapped(v)
	signal held(v)

	var card: Card = null
	var face_down := false
	var playable := false
	var selected := false
	var dim := false
	var _press_t := -1.0
	var _held := false
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		if _press_t >= 0.0:
			_press_t += delta
			if _press_t > 0.42 and not _held:
				_held = true
				held.emit(self)
		if playable or selected:
			queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press_t = 0.0
				_held = false
			else:
				if _press_t >= 0.0 and not _held:
					tapped.emit(self)
				_press_t = -1.0
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var s := size.x / CardFace.W
		if face_down or card == null:
			CardFace.draw_back(self, r)
			return
		if selected:
			CardFace.box(self, r.grow(6), 18 * s + 6, Color(0, 0, 0, 0), Color("8fd0ff"), 5)
		elif playable:
			CardFace.box(self, r.grow(4), 16 * s + 4, Color(0, 0, 0, 0), Color(UITheme.GOLD, 0.55 + 0.3 * sin(_t * 3.5)), 3)
		CardFace.draw_card(self, r, card.id, {"compact": true})
		if dim:
			CardFace.box(self, r, 13 * s, Color(0, 0, 0, 0.35))


# ============================================================ ActionButton ===
## A tall button for the side panel: title, optional cost orbs, a value on
## the right (damage) and a small line of detail (or why it can't be used).
class ActionButton:
	extends Control
	signal pressed

	var title := ""
	var detail := ""
	var value := ""
	var orbs: Array = []
	var enabled := true
	var accent := false
	var glyph := ""
	var _down := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(0, 104)

	func setup(p_title: String, p_detail: String = "", p_enabled: bool = true) -> ActionButton:
		title = p_title
		detail = p_detail
		enabled = p_enabled
		return self

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed and enabled:
				_down = true
			elif not e.pressed and _down:
				_down = false
				pressed.emit()
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var bg := Color("1a2036")
		var edge := Color("4a4f6e")
		var fg := UITheme.TEXT
		if accent:
			bg = Color("c9973a")
			edge = Color("ffe6a0")
			fg = Color("1e1406")
		if not enabled:
			bg = Color("12151f")
			edge = Color("262a3c")
			fg = Color("6b6e82")
		if _down:
			bg = bg.darkened(0.2)
		CardFace.box(self, r, 16, bg, edge, 2)
		var x := 20.0
		if glyph != "":
			Glyphs.draw(self, glyph, Vector2(x + 18, r.size.y * 0.5), 18, fg if not accent else Color("1e1406"))
			x += 46
		for o in orbs:
			CardFace.orb(self, Vector2(x + 13, 30), 13, o)
			x += 29
		var tf := CardFace.font("display_bold")
		var ty := 42.0 if detail != "" else r.size.y * 0.5 + 12
		var tx := 20.0 if orbs.is_empty() and glyph == "" else x + 6
		if not orbs.is_empty():
			tx = 20.0
			ty = 76.0 if detail == "" else 70.0
		var avail := r.size.x - tx - 24 - (70 if value != "" else 0)
		var tsize := CardFace.fit_size(tf, title, 32, avail, 18)
		CardFace.text(self, tf, Vector2(tx, ty), title, tsize, fg)
		if value != "":
			CardFace.text(self, tf, Vector2(r.size.x - 104, r.size.y * 0.5 + 16), value, 44, fg, HORIZONTAL_ALIGNMENT_RIGHT, 84)
		if detail != "":
			var df := CardFace.font("body")
			var dsz := CardFace.fit_size(df, detail, 22, r.size.x - 40, 14)
			var dy := r.size.y - 16.0
			CardFace.text(self, df, Vector2(20, dy), detail, dsz, Color(fg, 0.75) if enabled else Color("8a6a6a"))


# =============================================================== InfoPanel ===
## A duellist's summary: portrait, name, god, prizes left, deck, discard, hand.
class InfoPanel:
	extends Control
	signal discard_tapped(pi)

	var pi := 0
	var player: PlayerState = null
	var portrait: Texture2D = null
	var is_turn := false
	var mine := true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var local: Vector2 = e.position
			if _discard_rect().has_point(local):
				discard_tapped.emit(pi)
			accept_event()

	func _discard_rect() -> Rect2:
		return Rect2(Vector2(size.x * 0.5 + 6, size.y - 118), Vector2(size.x * 0.5 - 18, 100))

	func _draw() -> void:
		if player == null:
			return
		var r := Rect2(Vector2.ZERO, size)
		var edge := UITheme.GOLD if is_turn else Color("3a3f5c")
		CardFace.box(self, r, 20, Color(0.04, 0.05, 0.09, 0.9), edge, 3 if is_turn else 2)
		# portrait + name
		var pr := Rect2(Vector2(16, 16), Vector2(96, 96))
		CardFace.box(self, pr, 14, Color("1a1f33"), Color(UITheme.GOLD_DIM, 0.8), 2)
		if portrait != null:
			CardFace.draw_cover(self, pr.grow(-3), portrait, 0.3)
		var nf := CardFace.font("display_bold")
		var nm := player.player_name
		CardFace.text(self, nf, Vector2(126, 52), nm, CardFace.fit_size(nf, nm, 30, size.x - 140, 16), UITheme.TEXT)
		var god := player.patron()
		var gname: String = "Unsworn" if god == "" else Lore.GODS[god].name
		var gel := "any" if god == "" else String(Lore.GODS[god].element)
		CardFace.orb(self, Vector2(140, 84), 13, gel)
		CardFace.text(self, CardFace.font("bold"), Vector2(160, 93), gname, 24, UITheme.TEXT_DIM)
		# gift
		var gift := player.gift()
		if gift != "":
			var used := player.gift_used
			CardFace.text(self, CardFace.font("body"), Vector2(18, 146), ("Gift used" if used else "Gift: " + Lore.GIFTS[gift].name), 22,
				Color(UITheme.TEXT_DIM, 0.6) if used else UITheme.GOLD)
		# prizes
		CardFace.text(self, CardFace.font("bold"), Vector2(18, 188), "PRIZES", 20, UITheme.TEXT_DIM)
		for i in BattleGame.PRIZE_COUNT:
			var left := i < player.prizes.size()
			var c := Vector2(122 + i * 40, 181)
			Glyphs.draw(self, "prize", c, 16, UITheme.GOLD if left else Color(1, 1, 1, 0.12))
		# deck / hand / discard tiles
		_tile(Rect2(Vector2(12, size.y - 118), Vector2(size.x * 0.5 - 18, 100)), "deck", "DECK %d" % player.deck.size(), "HAND %d" % player.hand.size())
		_tile(_discard_rect(), "retreat", "DISCARD", str(player.discard.size()))

	func _tile(r: Rect2, glyph: String, a: String, b: String) -> void:
		CardFace.box(self, r, 14, Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.1), 1)
		CardFace.text(self, CardFace.font("bold"), r.position + Vector2(12, 34), a, 22, UITheme.TEXT)
		CardFace.text(self, CardFace.font("bold"), r.position + Vector2(12, 76), b, 22, UITheme.TEXT_DIM)


# ================================================================ CoinView ===
class CoinView:
	extends Control
	var heads := true
	var spin := 0.0

	func set_spin(v: float) -> void:
		spin = v
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var sx := absf(cos(spin))
		var show_heads := heads if fmod(spin, TAU) < PI * 0.5 or fmod(spin, TAU) > PI * 1.5 else not heads
		draw_set_transform(c, 0, Vector2(maxf(sx, 0.02), 1))
		draw_circle(Vector2.ZERO, r, Color("8a6a1c"))
		draw_circle(Vector2.ZERO, r * 0.9, UITheme.GOLD if show_heads else Color("c9cfe0"))
		draw_arc(Vector2.ZERO, r * 0.78, 0, TAU, 48, Color(0, 0, 0, 0.2), 3, true)
		if sx > 0.25:
			Glyphs.draw(self, "radiant" if show_heads else "umbral", Vector2.ZERO, r * 0.5, Color(0, 0, 0, 0.45))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ============================================================ ZoomOverlay ===
## A full-height view of one card, for reading on a phone. Tap to close.
class ZoomOverlay:
	extends Control
	signal closed
	var card_id := ""
	var attuned = null

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and not e.pressed:
			closed.emit()
			accept_event()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.03, 0.8))
		var h := size.y * 0.9
		var w := h / CardFace.ASPECT
		CardFace.draw_card(self, Rect2((size - Vector2(w, h)) * 0.5, Vector2(w, h)), card_id, {"compact": false, "attuned": attuned})


# ============================================================= CardPicker ===
## A modal grid for choosing cards (search the deck, discard Energy, ...).
class CardPicker:
	extends Control
	signal done(picked: Array)

	var cards: Array = []
	var min_n := 1
	var max_n := 1
	var title := ""
	var view_only := false
	var units := 0              # for Energy payments: total units needed
	var _picked: Array = []
	var _grid: GridContainer
	var _status: Label
	var _confirm: Button

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		theme = UITheme.make()
		var dim := ColorRect.new()
		dim.color = Color(0.01, 0.01, 0.04, 0.82)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 60
		box.offset_right = -60
		box.offset_top = 40
		box.offset_bottom = -40
		box.add_theme_constant_override("separation", 18)
		add_child(box)
		var t := UITheme.label(title, 38, UITheme.GOLD, "display_bold")
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(t)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(center)
		_grid = GridContainer.new()
		_grid.columns = clampi(cards.size(), 1, 7)
		_grid.add_theme_constant_override("h_separation", 22)
		_grid.add_theme_constant_override("v_separation", 22)
		center.add_child(_grid)
		for c in cards:
			var v := HandCard.new()
			v.card = c
			v.custom_minimum_size = Vector2(200, 280)
			v.playable = not view_only
			v.tapped.connect(_on_tap)
			v.held.connect(func(hv) -> void: _zoom(hv.card.id))
			_grid.add_child(v)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 30)
		box.add_child(row)
		_status = UITheme.label("", 28, UITheme.TEXT_DIM)
		row.add_child(_status)
		_confirm = UITheme.button("Close" if view_only else "Confirm", true, 320)
		_confirm.pressed.connect(func() -> void: done.emit(_picked.duplicate()))
		row.add_child(_confirm)
		_update()

	func _on_tap(v) -> void:
		if view_only:
			_zoom(v.card.id)
			return
		if _picked.has(v.card):
			_picked.erase(v.card)
			v.selected = false
		else:
			if max_n == 1:
				_picked.clear()
				for other in _grid.get_children():
					other.selected = false
			if _picked.size() < max_n:
				_picked.append(v.card)
				v.selected = true
		v.queue_redraw()
		_update()

	func _zoom(id: String) -> void:
		var z := ZoomOverlay.new()
		z.card_id = id
		z.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(z)
		z.closed.connect(z.queue_free)

	func _update() -> void:
		if view_only:
			_status.text = "%d card(s)" % cards.size()
			return
		if units > 0:
			var u := 0
			for c in _picked:
				u += c.energy_units()
			_status.text = "Energy chosen: %d / %d" % [u, units]
			_confirm.disabled = u < units
		else:
			_status.text = "Chosen %d  (choose %s)" % [_picked.size(), str(min_n) if min_n == max_n else "%d-%d" % [min_n, max_n]]
			_confirm.disabled = _picked.size() < min_n
