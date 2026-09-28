class_name StoryScreen
extends CanvasLayer
## Full-screen story moments: a painted scene with narration and dialogue,
## plus the name entry and starter-deck choice of the prologue.
##
## Scene art is loaded from res://assets/art/story/<scene>.png (16:9) when it
## exists; until then each scene is drawn in code.

var _root: Control
var _bg: StoryBG
var box: DialogueBox
var _fade: ColorRect


func _ready() -> void:
	layer = 15
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	add_child(_root)
	_bg = StoryBG.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_bg)
	box = DialogueBox.new()
	_root.add_child(box)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)


func fade(to_alpha: float, dur: float = 0.6) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if to_alpha > 0.5 else Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", to_alpha, dur)
	await tw.finished


## Show a scene and play lines over it: each is {"text", "who"?}.
func scene(id: String, lines: Array) -> void:
	if _bg.scene != id:
		await fade(1.0, 0.5)
		_bg.set_scene(id)
		await fade(0.0, 0.8)
	for ln in lines:
		var who: String = ln.get("who", "")
		var nm := ""
		var portrait: Texture2D = null
		if who != "":
			nm = ln.get("name", who.capitalize())
			if who == "player":
				nm = Game.player_name
			portrait = DollArt.portrait(who)
		await box.say(nm, portrait, String(ln.text).replace("{name}", Game.player_name))
	box.close()


## Ask for the player's name; returns it.
func ask_name(default_name: String = "Ash") -> String:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -440
	panel.offset_right = 440
	panel.offset_top = -210
	panel.offset_bottom = 210
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var q := UITheme.label("What is your name?", 44, UITheme.GOLD, "display_bold")
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)
	var edit := LineEdit.new()
	edit.text = default_name
	edit.max_length = 14
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(600, 96)
	edit.select_all_on_focus = true
	v.add_child(edit)
	var ok := UITheme.button("That's me", true, 400)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	edit.grab_focus.call_deferred()
	var done := [false]
	ok.pressed.connect(func() -> void: done[0] = true)
	edit.text_submitted.connect(func(_t: String) -> void: done[0] = true)
	while not done[0]:
		await get_tree().process_frame
	var n := edit.text.strip_edges()
	panel.queue_free()
	return n if n != "" else default_name


## Show the three starter decks; returns the chosen deck id.
func choose_starter() -> String:
	var ids: Array = []
	for id in SigilDB.DECKS:
		if SigilDB.DECKS[id].get("starter", false):
			ids.append(id)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(holder)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dim)
	var head := UITheme.label("Choose your first deck", 56, UITheme.GOLD, "display_bold", 10)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -800
	head.offset_right = 800
	head.offset_top = 40
	head.offset_bottom = 120
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(head)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_left = -900
	row.offset_right = 900
	row.offset_top = -380
	row.offset_bottom = 460
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 50)
	holder.add_child(row)
	var chosen := [""]
	for id in ids:
		var d: Dictionary = SigilDB.DECKS[id]
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(500, 0)
		col.add_theme_constant_override("separation", 14)
		row.add_child(col)
		var card := BattleWidgets.HandCard.new()
		card.card = Card.new(0, d.mascot, 0)
		card.custom_minimum_size = Vector2(330, 462)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.playable = true
		col.add_child(card)
		var nm := UITheme.label(d.name.to_upper(), 44, UITheme.GOLD, "display_bold")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nm)
		var els := ElementRow.new()
		els.elements = d.elements
		els.custom_minimum_size = Vector2(0, 50)
		col.add_child(els)
		var desc := UITheme.label(d.desc, 28, UITheme.TEXT)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(480, 0)
		col.add_child(desc)
		var pick := UITheme.button("Choose " + d.name, true, 420)
		pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var deck_id: String = id
		pick.pressed.connect(func() -> void: chosen[0] = deck_id)
		card.tapped.connect(func(_v) -> void: _zoom(d.mascot))
		col.add_child(pick)
	while chosen[0] == "":
		await get_tree().process_frame
	holder.queue_free()
	return chosen[0]


func _zoom(id: String) -> void:
	var z := BattleWidgets.ZoomOverlay.new()
	z.card_id = id
	z.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(z)
	z.closed.connect(z.queue_free)


class ElementRow:
	extends Control
	var elements: Array = []

	func _draw() -> void:
		var n := elements.size()
		for i in n:
			var c := Vector2(size.x * 0.5 + (i - (n - 1) * 0.5) * 70.0, size.y * 0.5)
			CardFace.orb(self, c, 22, elements[i])


## Painted-in-code backdrops for the prologue (replaced by art when present).
class StoryBG:
	extends Control
	var scene := ""
	var _tex: Texture2D = null
	var _t := 0.0
	var _rng := RandomNumberGenerator.new()
	var _stars: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rng.seed = 11
		for i in 160:
			_stars.append(Vector3(_rng.randf(), _rng.randf() * 0.7, _rng.randf()))

	func set_scene(id: String) -> void:
		scene = id
		_t = 0.0
		var p := "res://assets/art/story/%s.png" % id
		_tex = load(p) if ResourceLoader.exists(p) else null
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if _tex != null:
			# slow push-in on the painting
			var k := 1.0 + minf(_t, 20.0) * 0.004
			var rr := Rect2(r.get_center() - r.size * k * 0.5, r.size * k)
			CardFace.draw_cover(self, rr, _tex, 0.5)
			return
		match scene:
			"sigilfall":
				_sky(r, Color("0a0f2e"), Color("3b2a5c"))
				_stars_draw(r)
				_falling(r)
				_village(r, Color("07080f"))
			"card":
				_sky(r, Color("05060c"), Color("141026"))
				_stars_draw(r)
				var c := r.get_center() + Vector2(0, -60)
				for i in 14:
					draw_circle(c, (520.0 - i * 34.0) * (1.0 + sin(_t * 1.5) * 0.02), Color(1, 0.95, 0.8, 0.025))
				for i in 18:
					var a := TAU * i / 18.0 + _t * 0.05
					draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * 900, c + Vector2(cos(a + 0.05), sin(a + 0.05)) * 900]), Color(1, 0.9, 0.6, 0.04))
				var h := r.size.y * 0.5
				var w := h / CardFace.ASPECT
				var cr := Rect2(c - Vector2(w, h) * 0.5 + Vector2(0, sin(_t * 1.2) * 8.0), Vector2(w, h))
				CardFace.box(self, cr.grow(10), 24, Color(1, 0.95, 0.8, 0.25 + 0.1 * sin(_t * 2.0)))
				CardFace.box(self, cr, 18, Color("f3ead2"), UITheme.GOLD, 4)
				Glyphs.draw(self, "crown_sigil", cr.get_center(), w * 0.25, Color(UITheme.GOLD, 0.35 + 0.25 * sin(_t * 2.0)))
			"heralds":
				_sky(r, Color("f2b77a"), Color("5a3a6e"), true)
				var base := r.size.y * 0.78
				draw_rect(Rect2(0, base, r.size.x, r.size.y - base), Color("1a1320"))
				var cx := r.size.x * 0.5
				for i in 8:
					var x := cx + (i - 3.5) * r.size.x * 0.1
					var el := "any" if i == 7 else String(Lore.GODS[Lore.GODS.keys()[i]].element)
					draw_rect(Rect2(x - 26, base - 260, 52, 260), Color("1a1320"))
					var bc := Lore.color(el, 1).darkened(0.2) if i < 7 else Color("d8d4c8")
					draw_colored_polygon(PackedVector2Array([Vector2(x - 40, base - 250), Vector2(x + 40, base - 250), Vector2(x + 40, base - 110), Vector2(x, base - 80), Vector2(x - 40, base - 110)]), bc)
					Glyphs.draw(self, el, Vector2(x, base - 180), 24, Color(1, 1, 1, 0.85))
			"fire":
				_sky(r, Color("2a0a08"), Color("c2461c"), true)
				for i in 60:
					var p := Vector2(fmod(i * 97.3, r.size.x), r.size.y - fmod(_t * (40 + i % 7 * 12) + i * 53.0, r.size.y))
					draw_circle(p, 2.0 + i % 3, Color(1.0, 0.6 + (i % 5) * 0.06, 0.2, 0.7))
				_village(r, Color("0a0405"))
			"road":
				_sky(r, Color("1c2a4a"), Color("d98a5a"), true)
				_stars_draw(r, 0.5)
				var hz := r.size.y * 0.66
				draw_colored_polygon(PackedVector2Array([Vector2(0, hz), Vector2(r.size.x * 0.3, hz - 90), Vector2(r.size.x * 0.6, hz - 30), Vector2(r.size.x, hz - 120), Vector2(r.size.x, r.size.y), Vector2(0, r.size.y)]), Color("241a2a"))
				draw_colored_polygon(PackedVector2Array([Vector2(r.size.x * 0.46, hz), Vector2(r.size.x * 0.54, hz), Vector2(r.size.x * 0.8, r.size.y), Vector2(r.size.x * 0.2, r.size.y)]), Color("3a2b30"))
			_:
				_sky(r, Color("07080f"), Color("141a33"))

	func _sky(r: Rect2, top: Color, bottom: Color, warm: bool = false) -> void:
		CardFace.vgrad_rect(self, r, top, bottom)
		if warm:
			draw_circle(Vector2(r.size.x * 0.5, r.size.y * 0.78), r.size.x * 0.35, Color(bottom.lightened(0.3), 0.12))

	func _stars_draw(r: Rect2, alpha: float = 1.0) -> void:
		for s in _stars:
			var tw := 0.5 + 0.5 * sin(_t * (1.0 + s.z * 3.0) + s.z * 10.0)
			draw_circle(Vector2(s.x * r.size.x, s.y * r.size.y), 1.0 + s.z * 1.6, Color(1, 1, 1, (0.25 + 0.6 * tw) * alpha))

	func _falling(r: Rect2) -> void:
		for i in 14:
			var speed := 0.18 + (i % 5) * 0.05
			var ph := fmod(_t * speed + i * 0.137, 1.0)
			var start := Vector2(fmod(i * 331.0, r.size.x * 1.2) - r.size.x * 0.1, -80)
			var dir := Vector2(0.35, 1.0).normalized()
			var head := start + dir * ph * r.size.y * 1.3
			var col := Lore.color(Lore.CORE_ELEMENTS[i % Lore.CORE_ELEMENTS.size()], 0)
			draw_line(head - dir * 180, head, Color(col, 0.0), 1)
			for k in 10:
				var a := head - dir * (180.0 * k / 10.0)
				var b := head - dir * (180.0 * (k + 1) / 10.0)
				draw_line(a, b, Color(col, 0.9 * (1.0 - k / 10.0)), 4.0 - k * 0.3, true)
			draw_circle(head, 5, Color(1, 1, 1, 0.9))
			draw_circle(head, 14, Color(col, 0.25))

	func _village(r: Rect2, col: Color) -> void:
		var y := r.size.y * 0.8
		var pts := PackedVector2Array([Vector2(0, r.size.y), Vector2(0, y)])
		var x := 0.0
		var i := 0
		while x < r.size.x:
			var w := 110.0 + (i * 37 % 60)
			var h := 60.0 + (i * 53 % 90)
			pts.append(Vector2(x, y - h * 0.6))
			pts.append(Vector2(x + w * 0.5, y - h))
			pts.append(Vector2(x + w, y - h * 0.6))
			x += w
			i += 1
		pts.append(Vector2(r.size.x, y))
		pts.append(Vector2(r.size.x, r.size.y))
		draw_colored_polygon(pts, col)
		# lit windows
		for k in 16:
			var wx := fmod(k * 173.0, r.size.x)
			draw_rect(Rect2(wx, y - 30 - (k % 3) * 14, 10, 14), Color(1, 0.75, 0.35, 0.55 + 0.3 * sin(_t * 2 + k)))
