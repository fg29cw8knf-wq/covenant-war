class_name Codex
extends RefCounted
## The card collection: every v2 card as a grid (cards the player doesn't own
## yet are greyed out), and a detail view for one card with its painting,
## description, attacks, how to get it and, for Totems, how far its
## Ascended form has come. Used by the pause menu's Codex and Deck tabs.
##
## The deck being edited is passed in as `deck` (an Array of card ids); the
## pause menu commits it to Game.v2.deck only when it is legal.

const CELL := Vector2(186, 260)
const KIND_ORDER := {"totem": 0, "rite": 1, "ward": 2, "summon": 3}
const FILTERS := [["all", "All"], ["owned", "Owned"], ["totem", "Totems"], ["rite", "Rites"], ["ward", "Wards"], ["summon", "Summons"], ["conditions", "Conditions"]]


static func owned(id: String) -> int:
	return int(Game.v2.get("collection", {}).get(id, 0))


static func count_in(deck: Array, id: String) -> int:
	var n := 0
	for c in deck:
		if c == id:
			n += 1
	return n


## Every card in collection order: by element, then kind, then cost.
static func all_ids() -> Array:
	var ids: Array = DuelCards.CARDS.keys()
	var el_order := {}
	for i in Lore.CORE_ELEMENTS.size():
		el_order[Lore.CORE_ELEMENTS[i]] = i
	ids.sort_custom(func(a, b):
		var da: Dictionary = DuelCards.CARDS[a]
		var db: Dictionary = DuelCards.CARDS[b]
		var ka := int(KIND_ORDER.get(da.kind, 9))
		var kb := int(KIND_ORDER.get(db.kind, 9))
		if ka != kb:
			return ka < kb
		var ea := int(el_order.get(da.get("element", "any"), 50))
		var eb := int(el_order.get(db.get("element", "any"), 50))
		if ea != eb:
			return ea < eb
		var ra := _root_of(a)
		var rb := _root_of(b)
		if ra != rb:
			return ra < rb
		var sa := int(da.get("stage", 0))
		var sb := int(db.get("stage", 0))
		if sa != sb:
			return sa < sb
		return int(da.get("cost", 0)) < int(db.get("cost", 0)) if int(da.get("cost", 0)) != int(db.get("cost", 0)) else String(a) < String(b))
	return ids


## The Basic Totem an Ascended (or Exalted) card grows from.
static func _root_of(id: String) -> String:
	var d: Dictionary = DuelCards.CARDS[id]
	var guard := 0
	while d.kind == "totem" and d.get("ascends_from", "") != "" and guard < 5:
		id = d.ascends_from
		d = DuelCards.CARDS[id]
		guard += 1
	return id


## How far along the chain an Ascension card sits (1 = Ascended, 2 = Exalted).
static func _chain_index(id: String) -> int:
	var d: Dictionary = DuelCards.CARDS[id]
	return int(d.get("stage", 0))


## Attunement progress towards the next Ascension of a Basic Totem, or of
## this Ascension card itself: {"have", "need", "next", "root", "state"}.
## state: "filling" (this is the one being filled), "done" (already
## manifested), "later" (an earlier step comes first), "none".
static func ascension_progress(id: String) -> Dictionary:
	var v: Dictionary = Game.v2
	var d: Dictionary = DuelCards.CARDS[id]
	if d.kind != "totem":
		return {"state": "none"}
	var root := _root_of(id)
	var done := int(v.get("stage", {}).get(root, 0))
	var have := int(v.get("attune", {}).get(root, 0))
	var next := DuelRewards.next_ascension(root, done)
	if int(d.get("stage", 0)) == 0:
		if next == "":
			return {"state": "none" if DuelRewards.next_ascension(root, 0) == "" else "done", "root": root}
		return {"state": "filling", "have": have, "need": DuelRewards.store_needed(done), "next": next, "root": root}
	var idx := _chain_index(id)
	if idx <= done:
		return {"state": "done", "root": root, "next": id}
	if idx == done + 1:
		return {"state": "filling", "have": have, "need": DuelRewards.store_needed(done), "next": id, "root": root}
	return {"state": "later", "root": root, "next": next}


## Why wins can't build Resonance towards this card yet, or "" if they can.
static func resonance_block(id: String) -> String:
	var v: Dictionary = Game.v2
	var d: Dictionary = DuelCards.CARDS[id]
	var tier := int(d.get("tier", 1))
	if d.kind == "summon":
		return "Summons can't be crystallised. The story hands them to you."
	if DuelCards.is_ascension(id):
		return "Ascended cards don't crystallise from wins. They manifest through Attunement (below)."
	if tier > DuelRewards.MAX_RESONANCE_TIER:
		return "Too rare to crystallise from a duel. Only the story holds these."
	if not v.get("codex", {}).has(id):
		return "You haven't seen this card played yet. Once you have, your wins can build towards it."
	if tier > DuelRewards.tier_cap(int(v.get("rank", 1))):
		return "Answers you from Sigil Rank %d (you're Rank %d)." % [DuelRewards.TIER_RANK[tier], int(v.get("rank", 1))]
	if tier == 4 and String(v.codex[id]) != "champion":
		return "A Relic: you have to see a Champion play it first."
	return ""


static func pretty(s: String) -> String:
	s = s.strip_edges()
	if s == "":
		return s
	s = s.substr(0, 1).to_upper() + s.substr(1)
	if not s.ends_with("."):
		s += "."
	return s


## The full write-up for the detail view (BBCode).
static func describe(id: String) -> String:
	var d: Dictionary = DuelCards.CARDS[id]
	var tier := int(d.get("tier", 1))
	var el: String = d.get("element", "any")
	var gold := UITheme.GOLD.to_html(false)
	var dim := UITheme.TEXT_DIM.to_html(false)
	var lines := []
	var kind_word: String = {"totem": "%s Totem" % DuelCards.stage_name(int(d.get("stage", 0))), "rite": "Rite", "ward": "Ward", "summon": "Summon"}.get(d.kind, d.kind)
	var bits := [kind_word]
	if el != "any":
		bits.append(Lore.element_name(el))
	bits.append("%s (tier %d)" % [Lore.TIER_NAMES[tier], tier])
	var cost_word := "Ascend cost" if DuelCards.is_ascension(id) else "Cost"
	bits.append("%s %d Essence" % [cost_word, int(d.get("cost", 0))])
	lines.append("[color=#%s]%s[/color]" % [dim, "  ·  ".join(bits)])
	lines.append("")
	lines.append("[i]%s[/i]" % pretty(String(d.get("art", ""))))
	lines.append("")
	match d.kind:
		"totem":
			var aff: String = d.get("affinity", "")
			var hp_line := "[b]%d HP[/b]" % int(d.hp)
			if aff != "":
				hp_line += "   ·   draws on [b]%s[/b] (its Fate rolls and Attuned bonus)" % Lore.ATTRIBUTE_NAMES[aff]
			lines.append(hp_line)
			var weak: Array = Lore.weak_to(el)
			if not weak.is_empty():
				lines.append("Weak to %s: takes ×%s damage from them." % [" and ".join(weak.map(func(w): return Lore.element_name(w))), str(DuelRules.weakness_mult)])
			for k in d.get("keywords", []):
				var kd: Dictionary = DuelCards.KEYWORDS[k]
				lines.append("[color=#%s][b]%s[/b][/color]: %s" % [gold, kd.name, kd.text])
			var at := DuelCardFace.attuned_text(d)
			if at != "":
				var mine := int(Game.profile.get("attributes", {}).get(aff, 0))
				var need := int(d.attuned.get("min", 99))
				var state := "[color=#%s]active for you[/color]" % gold if mine >= need else "you have %d" % mine
				lines.append("[color=#%s][b]Attuned[/b][/color] at %s (%s)." % [gold, at, state])
			if DuelCards.is_ascension(id):
				lines.append("Played on top of [b]%s[/b] to Ascend it." % DuelCards.CARDS[d.ascends_from].name)
			lines.append("")
			lines.append("[color=#%s][b]ATTACKS[/b][/color]" % gold)
			for m in d.get("moves", []):
				var cost := int(m.get("cost", 0))
				var cw := "Strike, free" if cost == 0 else "%d Essence" % cost
				var dmg := ""
				if m.has("fate"):
					dmg = "roll a d20"
				elif int(m.get("damage", 0)) > 0:
					dmg = "%d damage" % int(m.damage)
				var head := "[b]%s[/b]  [color=#%s](%s)[/color]" % [m.name, dim, cw]
				if dmg != "":
					head += "  ·  %s" % dmg
				lines.append(head)
				var det := DuelCardFace.move_detail(m)
				if det != "":
					lines.append("    [color=#%s]%s[/color]" % [dim, det])
		"rite":
			lines.append(DuelCards.card_text(id))
			lines.append("[color=#%s]Cast on your turn, then discard.[/color]" % dim)
		"ward":
			lines.append(DuelCards.card_text(id))
			lines.append("[color=#%s]Set face down. Springs on your opponent's turn.[/color]" % dim)
		"summon":
			lines.append("[b]%s[/b]" % d.move.name)
			lines.append(DuelCards.card_text(id))
	return "\n".join(lines)


# ================================================================= views ===

## The collection grid with its filter row.
class Grid:
	extends VBoxContainer
	signal card_tapped(id: String)
	var deck: Array = []
	var only: Array = []            # if set, show just these ids (the Deck tab)
	var counts_from_deck := false   # badges show copies in the deck, not owned
	var filter := "all"
	var show_filters := true
	var _grid: GridContainer
	var _scroll: ScrollContainer
	var _summary: Label
	var _filter_btns := {}

	func _ready() -> void:
		add_theme_constant_override("separation", 14)
		if show_filters:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			add_child(row)
			for f in Codex.FILTERS:
				var b := UITheme.button(f[1], false, 0)
				b.custom_minimum_size = Vector2(150, 72)
				b.add_theme_font_size_override("font_size", 26)
				b.toggle_mode = true
				var key: String = f[0]
				b.pressed.connect(func() -> void:
					filter = key
					rebuild())
				row.add_child(b)
				_filter_btns[key] = b
			_summary = UITheme.label("", 24, UITheme.TEXT_DIM)
			_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(_summary)
		_scroll = ScrollContainer.new()
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(_scroll)
		_grid = GridContainer.new()
		_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # so a one-column list fills the width
		_grid.add_theme_constant_override("h_separation", 16)
		_grid.add_theme_constant_override("v_separation", 16)
		_scroll.add_child(_grid)
		_scroll.resized.connect(_fit_columns)
		rebuild()

	func _fit_columns() -> void:
		var w := _scroll.size.x - 24.0
		_grid.columns = 1 if filter == "conditions" else maxi(1, int((w + 16.0) / (Codex.CELL.x + 16.0)))

	## The conditions and boons the player has met, each with Bram's
	## explanation of what it does and how long it lasts.
	func _rebuild_conditions() -> void:
		var met := Game.conditions_met()
		var n := 0
		for id in DuelConditions.DEFS.keys() + DuelConditions.BOONS.keys():
			if not met.has(id):
				continue
			n += 1
			var row := ConditionRow.new()
			row.id = id
			row.custom_minimum_size = Vector2(0, 96)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_grid.add_child(row)
		if n == 0:
			var l := UITheme.label("No conditions met yet. The first time one lands in a duel, Bram explains it and it's kept here.", 26, UITheme.TEXT_DIM)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_grid.add_child(l)
		if _summary != null:
			_summary.text = "You've met %d of %d conditions and boons" % [n, DuelConditions.DEFS.size() + DuelConditions.BOONS.size()]

	func rebuild() -> void:
		if _grid == null:
			return
		for c in _grid.get_children():
			c.queue_free()
		if filter == "conditions":
			_rebuild_conditions()
			for k in _filter_btns:
				_filter_btns[k].button_pressed = k == filter
			_fit_columns()
			return
		var ids := []
		if not only.is_empty():
			ids = only
		else:
			for id in Codex.all_ids():
				var d: Dictionary = DuelCards.CARDS[id]
				match filter:
					"owned":
						if Codex.owned(id) <= 0:
							continue
					"totem", "rite", "ward", "summon":
						if d.kind != filter:
							continue
				ids.append(id)
		for id in ids:
			var cell := Cell.new()
			cell.id = id
			cell.owned = Codex.owned(id)
			cell.in_deck = Codex.count_in(deck, id)
			cell.deck_badge = counts_from_deck
			cell.custom_minimum_size = Codex.CELL
			cell.tapped.connect(func(cid: String) -> void: card_tapped.emit(cid))
			_grid.add_child(cell)
		for k in _filter_btns:
			_filter_btns[k].button_pressed = k == filter
		if _summary != null:
			var total := DuelCards.CARDS.size()
			var have := 0
			for id in DuelCards.CARDS:
				if Codex.owned(id) > 0:
					have += 1
			_summary.text = "You own %d of %d cards  ·  tap a card for its details" % [have, total]
		_fit_columns()

	func refresh_counts() -> void:
		for c in _grid.get_children():
			if c is Cell:
				c.owned = Codex.owned(c.id)
				c.in_deck = Codex.count_in(deck, c.id)
				c.queue_redraw()


## One condition or boon the player has met: its colour, name, kind, how long
## it lasts and what it does.
class ConditionRow:
	extends Control
	var id := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := DuelConditions.color(id)
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, r, 14, Color(0.06, 0.07, 0.12, 0.9), Color(col, 0.5), 2.0)
		draw_rect(Rect2(0, 10, 10, size.y - 20), col)
		var fnt := CardFace.font("display_bold")
		var body := CardFace.font("body")
		CardFace.text(self, fnt, Vector2(30, 38), DuelConditions.display_name(id), 28, col)
		var kind := DuelConditions.kind_of(id)
		var turns := DuelConditions.turns(id)
		var lasts := ""
		if DuelConditions.breaks_free(id):
			lasts = "until it breaks free or is cured"
		elif turns == 0:
			lasts = "until cured" if DuelConditions.is_condition(id) else "until used up"
		else:
			lasts = "%d turn%s" % [turns, "" if turns == 1 else "s"]
		var tag := ("%s condition" % DuelConditions.KIND_NAMES.get(kind, "").capitalize()) if kind != "" else "Boon"
		CardFace.text(self, CardFace.font("bold"), Vector2(30, 66), "%s  ·  lasts %s" % [tag, lasts], 20, UITheme.TEXT_DIM)
		var what := DuelConditions.describe(id)
		CardFace.text(self, body, Vector2(size.x * 0.42, 40), what, CardFace.fit_size(body, what, 24, size.x * 0.56), UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.56)


## One card in the grid: the card face, greyed out if not owned, with badges.
class Cell:
	extends Control
	signal tapped(id: String)
	var id := ""
	var owned := 0
	var in_deck := 0
	var deck_badge := false
	var _press := Vector2.ZERO
	var _down := false
	static var _grey_shader: Shader

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		if _grey_shader == null:
			_grey_shader = Shader.new()
			_grey_shader.code = """shader_type canvas_item;
uniform float grey = 0.0;
void fragment() {
	float l = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(l) * 0.5 + 0.03, grey);
}"""
		var m := ShaderMaterial.new()
		m.shader = _grey_shader
		material = m

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
				_press = e.global_position
			elif _down:
				_down = false
				if e.global_position.distance_to(_press) < 24.0:
					tapped.emit(id)

	func _draw() -> void:
		var have := owned > 0 or deck_badge
		(material as ShaderMaterial).set_shader_parameter("grey", 0.0 if have else 0.92)
		var r := Rect2(Vector2.ZERO, size)
		DuelCardFace.draw_card(self, r, id, {"compact": true})
		var f := CardFace.font("display_bold")
		if not have:
			CardFace.box(self, r, 12, Color(0, 0, 0, 0.35))
			var lock := Rect2(Vector2(size.x * 0.5 - 70, size.y * 0.38), Vector2(140, 40))
			CardFace.box(self, lock, 20, Color(0, 0, 0, 0.7), Color(1, 1, 1, 0.3), 2)
			CardFace.text_in(self, CardFace.font("bold"), lock, "NOT OWNED", 20, Color(1, 1, 1, 0.8))
		else:
			var n := in_deck if deck_badge else owned
			var b := Rect2(Vector2(size.x - 66, 8), Vector2(58, 40))
			CardFace.box(self, b, 20, Color(0.04, 0.04, 0.08, 0.9), Color(UITheme.GOLD, 0.9), 2)
			CardFace.text_in(self, f, b, "×%d" % n, 24, UITheme.GOLD)
			if not deck_badge and in_deck > 0:
				var db := Rect2(Vector2(8, size.y - 44), Vector2(94, 34))
				CardFace.box(self, db, 17, Color(0.1, 0.35, 0.55, 0.92))
				CardFace.text_in(self, CardFace.font("bold"), db, "DECK %d" % in_deck, 18, Color.WHITE)
		# Attunement towards the Ascended form, as a thin bar along the bottom
		var p := Codex.ascension_progress(id)
		if p.get("state", "") == "filling" and int(p.get("have", 0)) > 0:
			var k := clampf(float(p.have) / float(p.need), 0.0, 1.0)
			var br := Rect2(Vector2(14, size.y - 8), Vector2(size.x - 28, 5))
			draw_rect(br, Color(0, 0, 0, 0.7))
			draw_rect(Rect2(br.position, Vector2(br.size.x * k, br.size.y)), UITheme.GOLD)


## Full-screen detail for one card. `deck` is the deck being edited (or null
## when the deck can't be changed yet); changed is emitted after an edit.
class Detail:
	extends Control
	signal closed
	signal changed
	var id := ""
	var deck = null
	var _info: RichTextLabel
	var _meters: HBoxContainer
	var _buttons: HBoxContainer
	var _status: Label
	var _art: Control

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		theme = UITheme.make()
		var dim := ColorRect.new()
		dim.color = Color(0.01, 0.01, 0.03, 0.88)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				closed.emit())
		add_child(dim)
		var panel := PanelContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 60
		panel.offset_right = -60
		panel.offset_top = 40
		panel.offset_bottom = -40
		add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 40)
		panel.add_child(hb)
		_art = BigCard.new()
		_art.set("id", id)
		_art.custom_minimum_size = Vector2(560, 0)
		_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hb.add_child(_art)
		var right := VBoxContainer.new()
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right.add_theme_constant_override("separation", 14)
		hb.add_child(right)
		var top := HBoxContainer.new()
		right.add_child(top)
		var d: Dictionary = DuelCards.CARDS[id]
		var name_l := UITheme.label(d.name, 58, UITheme.GOLD, "display_bold")
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(name_l)
		var x := UITheme.button("Close", false, 180)
		x.pressed.connect(func() -> void: closed.emit())
		top.add_child(x)
		_meters = HBoxContainer.new()
		_meters.add_theme_constant_override("separation", 24)
		right.add_child(_meters)
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right.add_child(sc)
		_info = RichTextLabel.new()
		_info.bbcode_enabled = true
		_info.fit_content = true
		_info.scroll_active = false
		_info.mouse_filter = Control.MOUSE_FILTER_PASS
		_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_info.add_theme_font_size_override("normal_font_size", 27)
		_info.add_theme_font_size_override("bold_font_size", 27)
		_info.add_theme_font_size_override("italics_font_size", 27)
		_info.add_theme_font_override("italics_font", CardFace.font("body"))
		sc.add_child(_info)
		_status = UITheme.label("", 26, UITheme.TEXT_DIM)
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(_status)
		_buttons = HBoxContainer.new()
		_buttons.add_theme_constant_override("separation", 14)
		right.add_child(_buttons)
		_refresh()

	func _refresh() -> void:
		var v: Dictionary = Game.v2
		var d: Dictionary = DuelCards.CARDS[id]
		var gold := UITheme.GOLD.to_html(false)
		var text := Codex.describe(id)
		# --- yours?
		var n := Codex.owned(id)
		var lines := ["", "[color=#%s][b]YOUR COLLECTION[/b][/color]" % gold]
		if n > 0:
			var in_deck := Codex.count_in(deck, id) if deck != null else 0
			lines.append("You own %d.%s" % [n, ("  %d in your deck." % in_deck) if deck != null else ""])
		else:
			lines.append("Not in your collection yet.")
		# --- how to get one
		var block := Codex.resonance_block(id)
		if block != "":
			lines.append(block)
		else:
			var banked := int(v.get("banked", {}).get(id, 0))
			var cost := DuelRewards.card_cost(id)
			var target := String(v.get("target", "")) == id
			lines.append("Each win makes Resonance. Point it at this card and %d Resonance crystallises a copy. %s" % [cost,
				"[color=#%s]Your wins are building towards it: %d / %d.[/color]" % [gold, banked, cost] if target else ("Banked so far: %d / %d." % [banked, cost] if banked > 0 else "")])
		# --- Ascension
		var p := Codex.ascension_progress(id)
		if String(p.get("state", "")) == "filling" and Codex.owned(String(p.root)) <= 0 and int(p.get("have", 0)) <= 0:
			p = {"state": "unowned", "root": p.root, "next": p.next}
		match String(p.get("state", "none")):
			"unowned":
				lines.append("")
				lines.append("Once you own %s, spare copies and your Attunement pool can make it Ascend into %s." % [DuelCards.CARDS[p.root].name, DuelCards.CARDS[p.next].name])
			"filling":
				var nxt: String = p.next
				var root: String = p.root
				lines.append("")
				lines.append("[color=#%s][b]ASCENSION[/b][/color]" % gold)
				if nxt == id:
					lines.append("Manifests from %s's Attunement: [b]%d / %d[/b]." % [DuelCards.CARDS[root].name, int(p.have), int(p.need)])
				else:
					lines.append("Attunement towards [b]%s[/b]: [b]%d / %d[/b]." % [DuelCards.CARDS[nxt].name, int(p.have), int(p.need)])
				lines.append("Re-absorb spare copies of %s (each worth %d) or pour in your Attunement pool (%d points, worth half) to fill it." % [
					DuelCards.CARDS[root].name, DuelRewards.copy_points(root), int(v.get("pool", 0))])
			"done":
				if DuelCards.is_ascension(id):
					lines.append("")
					lines.append("[color=#%s]Manifested through Attunement.[/color]" % gold)
			"later":
				lines.append("")
				lines.append("Manifests from %s's Attunement, after %s." % [DuelCards.CARDS[p.root].name, DuelCards.CARDS[p.next].name])
		_info.text = text + "\n" + "\n".join(lines)
		# the two progress bars that matter most, always in view
		for c in _meters.get_children():
			c.queue_free()
		if block == "":
			var banked := int(v.get("banked", {}).get(id, 0))
			var cost := DuelRewards.card_cost(id)
			_meter("RESONANCE TOWARDS A NEW COPY", float(banked) / float(cost), "%d / %d" % [banked, cost])
		if String(p.get("state", "")) == "filling":
			var nxt_name: String = DuelCards.CARDS[p.next].name
			_meter(("ATTUNEMENT TOWARDS %s" % nxt_name.to_upper()) if p.next != id else "ATTUNEMENT TO MANIFEST IT",
				float(p.have) / float(p.need), "%d / %d" % [int(p.have), int(p.need)])
		elif String(p.get("state", "")) == "done" and DuelCards.is_ascension(id):
			_meter("ATTUNEMENT", 1.0, "Manifested")
		# --- buttons
		for c in _buttons.get_children():
			c.queue_free()
		_status.text = ""
		if block == "" and String(v.get("target", "")) != id and not DuelCards.is_ascension(id):
			_add("Build towards this", func() -> void:
				Game.set_resonance_target(id)
				_status.text = "Your wins now build Resonance towards %s." % d.name
				_after())
		if p.get("state", "") == "filling":
			var root: String = p.root
			if Game.spare_copies(root) > 0:
				_add("Re-absorb a spare %s" % DuelCards.CARDS[root].name, func() -> void:
					var made := Game.reabsorb(root, 1)
					_status.text = "%s manifests!" % DuelCards.CARDS[made].name if made != "" else "+%d Attunement." % DuelRewards.copy_points(root)
					_after())
			if int(v.get("pool", 0)) > 0:
				_add("Pour in the pool", func() -> void:
					var need := int(p.need) - int(p.have)
					var made := Game.pour_pool(root, mini(int(v.pool), need * 2))
					_status.text = "%s manifests!" % DuelCards.CARDS[made].name if made != "" else "The pool flows in."
					_after())
		if deck != null and n > 0:
			var tier := int(d.get("tier", 1))
			var in_deck := Codex.count_in(deck, id)
			var add := _add("Add to deck", func() -> void:
				deck.append(id)
				_after())
			add.disabled = in_deck >= n or in_deck >= int(DuelCards.TIER_MAX_COPIES[tier]) or d.kind == "summon" and in_deck >= 1
			var rem := _add("Take out of deck", func() -> void:
				deck.erase(id)
				_after())
			rem.disabled = in_deck <= 0
			if add.disabled and in_deck < n:
				_status.text = "A deck can hold %d of a %s card." % [int(DuelCards.TIER_MAX_COPIES[tier]), Lore.TIER_NAMES[tier]]

	func _meter(caption: String, k: float, words: String) -> void:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(UITheme.label(caption, 20, UITheme.GOLD_DIM, "bold"))
		var m := PauseMenu.Meter.new()
		m.value = k
		m.text = words
		m.custom_minimum_size = Vector2(0, 40)
		box.add_child(m)
		_meters.add_child(box)

	func _add(t: String, f: Callable) -> Button:
		var b := UITheme.button(t, false, 0)
		b.custom_minimum_size = Vector2(0, 88)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(f)
		_buttons.add_child(b)
		return b

	func _after() -> void:
		changed.emit()
		var keep := _status.text
		_refresh()
		if keep != "":
			_status.text = keep
		_art.queue_redraw()


## A big full card face that fits its box.
class BigCard:
	extends Control
	var id := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if id == "":
			return
		var h := minf(size.y, size.x * CardFace.ASPECT)
		var w := h / CardFace.ASPECT
		var r := Rect2(Vector2((size.x - w) * 0.5, (size.y - h) * 0.5), Vector2(w, h))
		for i in 6:
			draw_circle(r.get_center(), h * (0.55 - i * 0.06), Color(UITheme.GOLD, 0.025))
		DuelCardFace.draw_card(self, r, id, {"attrs": Game.profile.get("attributes", {}), "compact": false})
		if Codex.owned(id) <= 0:
			CardFace.box(self, r, 12, Color(0, 0, 0, 0.45))
			var tag := Rect2(Vector2(r.position.x + r.size.x * 0.5 - 120, r.position.y + r.size.y * 0.45), Vector2(240, 54))
			CardFace.box(self, tag, 27, Color(0, 0, 0, 0.75), Color(1, 1, 1, 0.35), 2)
			CardFace.text_in(self, CardFace.font("bold"), tag, "NOT OWNED YET", 24, Color(1, 1, 1, 0.85))
