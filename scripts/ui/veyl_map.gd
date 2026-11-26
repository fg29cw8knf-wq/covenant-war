class_name VeylMap
extends Control
## The map of Veyl (Master Script v3, the last beat of Chapter 1: "The map of
## Veyl opens on six kingdoms, a Champion's banner flying over each." and the
## objective "Choose a kingdom. (Tap a banner on the map.)").
##
## Gary's painting (assets/art/map/veyl.jpg, 8 November: no writing on it)
## with the names and the banners drawn over it by the game, each where
## docs/veyl-map-prompt.md's table read it off the painting. The whole
## painting is always on the screen: on a screen wider or taller than it
## (a phone, a 16:10 Mac) the gap is filled with the painting again, blurred
## and dark, and the painting's own edge fades into that.
##
## Until offer() it's the painting and the six banners alone (a film's line
## is read over it); then the objective, the other places' names and the way
## back come up.
##
## A banner is a button: a tap (or the arrows and Enter, or a pad) opens the
## kingdom's card: its Champion's portrait, whose Seat it is, and its Kingdom
## Law. No kingdom's road is built yet (BUILT), so the card says so and goes
## back to the map; a built one gets "Set out" on its card, and closed(<id>).
## "Back to Solhaven" (Esc, a pad's B) closes the map with closed("").
##
##   var map := VeylMap.open_on(world)       # under a film's bars and subtitles
##   await Cine.say(world, "bram", "Pyreholt's nearest.")
##   map.offer("pyreholt")                    # the banners can be tapped now
##   var id: String = await map.closed        # "" = back to Solhaven
##   map.shut()

## The kingdom chosen ("" for back to Solhaven).
signal closed(id: String)

const ART := "res://assets/art/map/veyl.jpg"
const ART_SIZE := Vector2(1672.0, 941.0)
const OBJECTIVE := "Choose a kingdom. (Tap a banner on the map.)"
## The layer the map is drawn on when it's shown over the world: over the
## world's own buttons, under a film's bars, fades and subtitles (CineOverlay,
## 14) so Bram's line is read over it.
const LAYER := 13

## The six kingdoms whose Seats are still to win, as the Seat roll in the Sun
## Square has them ("Solhaven's Seat is already taken by then").
##   at:    where the kingdom is on the painting (a fraction of it)
##   pole:  where its banner's pole is planted, on clear ground beside it
##   fly:   which way the cloth flies (1 to the right, -1 to the left)
##   sign:  what's on the cloth. Pyreholt's is the script's: "the red banner
##          with a crown of flame". The script gives no other banner, so the
##          other five carry the sign of their Seat's god (as the Herald's
##          lantern does for a Champion with no portrait) on that sign's
##          colour, until Gary says what each one is.
const KINGDOMS := [
	{"id": "pyreholt", "name": "Pyreholt", "god": "pyrrhane", "champion": "vorn", "holder": "Warlord Vorn",
		"at": Vector2(0.22, 0.79), "pole": Vector2(0.158, 0.742), "fly": 1, "sign": "flame_crown", "cloth": "a8241b"},
	{"id": "hrimmark", "name": "Hrimmark", "god": "vaelith", "champion": "eiran", "holder": "King Eiran",
		"at": Vector2(0.55, 0.11), "pole": Vector2(0.607, 0.152), "fly": 1, "sign": "", "cloth": ""},
	{"id": "glyphmere", "name": "Glyphmere", "god": "aldrith", "champion": "crane", "holder": "Magister Tobias Crane",
		"at": Vector2(0.27, 0.12), "pole": Vector2(0.348, 0.166), "fly": 1, "sign": "", "cloth": ""},
	{"id": "somnara", "name": "Somnara", "god": "oriel", "champion": "maelis", "holder": "Sister Maelis",
		"at": Vector2(0.82, 0.14), "pole": Vector2(0.862, 0.175), "fly": 1, "sign": "", "cloth": ""},
	{"id": "stormreach", "name": "Stormreach", "god": "ixara", "champion": "rook", "holder": "Captain Rook",
		"at": Vector2(0.86, 0.43), "pole": Vector2(0.725, 0.432), "fly": -1, "sign": "", "cloth": ""},
	{"id": "umbravel", "name": "Umbravel", "god": "nocthra", "champion": "silk", "holder": "Silk",
		"at": Vector2(0.85, 0.81), "pole": Vector2(0.775, 0.80), "fly": -1, "sign": "", "cloth": ""},
]
## The places with no banner: the ones the story has been to, or named.
const PLACES := [
	["Solhaven", Vector2(0.553, 0.684)],
	["Ashford", Vector2(0.088, 0.612)],
	["The Thornwood", Vector2(0.285, 0.455)],
	["The Shardlands", Vector2(0.215, 0.365)],
]
## Where the wagon is: Solhaven (a ring of light on the road below its gate).
const HERE := Vector2(0.553, 0.653)
## The kingdoms with a road to take: none yet (Pyreholt is written, v1, and
## waits for Gary's yes; the other five aren't written).
const BUILT: Array = []

var _t := 0.0
var _back_art: TextureRect
var _art: TextureRect
var _over: Control                 # everything laid over the painting
var _ui: Control                   # the objective and the way back, in the safe area
var _objective: Label
var _back: Button
var _banners: Array = []           # Banner, in KINGDOMS' order
var _names: Array = []             # [Label, Vector2 (the place)]
var _here: Here
var _card: Control
var _map_rect := Rect2()
var _offered := false
var _closing := false
var _sfx: Sfx


## Shows the map over `parent` (the world), on its own layer; its banners
## can't be tapped until offer(). shut() takes it away again.
static func open_on(parent: Node, layer_no := LAYER) -> VeylMap:
	var layer := CanvasLayer.new()
	layer.layer = layer_no
	layer.name = "VeylMapLayer"
	parent.add_child(layer)
	var m := VeylMap.new()
	m.name = "VeylMap"
	layer.add_child(m)
	return m


static func kingdom(id: String) -> Dictionary:
	for k in KINGDOMS:
		if String(k.id) == id:
			return k
	return {}


## The colours of a kingdom's banner: [the cloth, the sign on it].
static func colours(k: Dictionary) -> Array:
	var el := String(Lore.GODS[String(k.god)].element)
	var c: Array = Lore.ELEMENTS[el].colors
	var cloth := Color(String(k.cloth)) if String(k.cloth) != "" else Color(String(c[1])).darkened(0.12)
	return [cloth, Color(String(c[0]))]


static func sign_of(k: Dictionary) -> String:
	return String(k.sign) if String(k.sign) != "" else String(Lore.GODS[String(k.god)].element)


## A Champion's portrait (Gary's, assets/art/champions), or null.
static func portrait(k: Dictionary) -> Texture2D:
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/art/champions/%s.%s" % [String(k.champion), ext]
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	_sfx = Sfx.new()
	add_child(_sfx)
	var black := ColorRect.new()
	black.color = Color(0.02, 0.02, 0.04)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var tex: Texture2D = load(ART) if ResourceLoader.exists(ART) else null
	# the painting again behind itself, blurred and dark: what fills a screen
	# that isn't the painting's shape
	_back_art = TextureRect.new()
	_back_art.texture = _soft(tex)
	_back_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_back_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_art.modulate = Color(0.3, 0.3, 0.36)
	add_child(_back_art)
	_art = TextureRect.new()
	_art.texture = tex
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.material = _edge_material()
	add_child(_art)
	_over = Control.new()
	_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_over)
	# the places with no banner
	for p in PLACES:
		var l := UITheme.label(String(p[0]), 26, Color(0.95, 0.9, 0.78), "display", 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# (they come up with the objective: while Bram's line is on the
		# screen it sits where Solhaven's name does)
		l.modulate.a = 0.0
		_over.add_child(l)
		_names.append([l, p[1]])
	_here = Here.new()
	_over.add_child(_here)
	# the six banners
	for k in KINGDOMS:
		var b := Banner.new()
		b.info = k
		b.name = "Banner_" + String(k.id)
		b.disabled = true
		b.phase = float(_banners.size()) * 1.7
		b.pressed.connect(_on_banner.bind(b))
		b.focus_entered.connect(func() -> void: _sfx.play("ui_select", 1.0, -8.0))
		_over.add_child(b)
		_banners.append(b)
	# the objective (where the world shows it: top left) and the way back
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	SafeArea.fit(_ui, Vector2(36, 28), true)
	_objective = UITheme.label(OBJECTIVE, 30, UITheme.GOLD, "bold", 10)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.custom_minimum_size = Vector2(330, 0)
	_objective.size = Vector2(330, 0)
	_objective.modulate.a = 0.0
	_ui.add_child(_objective)
	_back = UITheme.button("Back to Solhaven", false, 300)
	_back.modulate.a = 0.0
	_back.disabled = true
	_back.pressed.connect(func() -> void: _choose(""))
	_ui.add_child(_back)
	SafeArea.watch(self, _layout)
	resized.connect(_layout)
	_layout()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	_sfx.play("page_turn", 0.85, -2.0)


func _process(delta: float) -> void:
	_t += delta


## Lays the painting, the names and the banners out for the screen as it is.
func _layout() -> void:
	if _art == null:
		return
	var s := size
	if s.x < 8.0 or s.y < 8.0:
		return
	var k := minf(s.x / ART_SIZE.x, s.y / ART_SIZE.y)
	_map_rect = Rect2((s - ART_SIZE * k) * 0.5, ART_SIZE * k)
	_art.position = _map_rect.position
	_art.size = _map_rect.size
	# the painting's edge fades into what's behind it only where there's
	# something behind it
	var mat := _art.material as ShaderMaterial
	mat.set_shader_parameter("fade", Vector2(0.07 if _map_rect.position.x > 2.0 else 0.0,
		0.07 if _map_rect.position.y > 2.0 else 0.0))
	var ui := SafeArea.ui_scale()
	var safe := SafeArea.rect()
	for n in _names:
		var l := n[0] as Label
		l.add_theme_font_size_override("font_size", int(round(26.0 * ui)))
		l.reset_size()
		var c := _at(n[1])
		l.position = Vector2(clampf(c.x - l.size.x * 0.5, safe.position.x + 6.0, safe.end.x - l.size.x - 6.0), c.y - l.size.y * 0.5)
	_here.position = _at(HERE)
	for b: Banner in _banners:
		b.lay(_at(b.info.pole), ui, safe)
	_objective.position = Vector2.ZERO
	# the way back: bottom middle, the one stretch of the painting's foot
	# with no kingdom on it (Pyreholt's name is to its left, Umbravel's to
	# its right, at every text size)
	_back.reset_size()
	_back.position = Vector2((_ui.size.x - _back.size.x) * 0.5, _ui.size.y - _back.size.y)
	if _card != null and is_instance_valid(_card):
		_card.queue_redraw()


## A place on the painting (a fraction of it), on the screen.
func _at(frac: Vector2) -> Vector2:
	return _map_rect.position + frac * _map_rect.size


## Lets the player choose: the banners wake, the objective and the way back
## come up. `nearest` is the kingdom Bram has just named: its banner stirs,
## and a keyboard or a pad starts on it.
func offer(nearest := "") -> void:
	if _offered:
		return
	_offered = true
	for b: Banner in _banners:
		b.disabled = false
	_back.disabled = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_objective, "modulate:a", 1.0, 0.5)
	tw.tween_property(_back, "modulate:a", 1.0, 0.5)
	for n in _names:
		tw.tween_property(n[0], "modulate:a", 1.0, 0.5)
	var first: Banner = _banner(nearest)
	if first == null and not _banners.is_empty():
		first = _banners[0]
	if first != null:
		first.grab_focus.call_deferred()


## Bram names a kingdom: its banner lifts in the wind for a moment.
func stir(id: String) -> void:
	var b := _banner(id)
	if b != null:
		b.stir()


func _banner(id: String) -> Banner:
	for b: Banner in _banners:
		if String(b.info.id) == id:
			return b
	return null


func is_offered() -> bool:
	return _offered


## The banner of a kingdom, for a test to press.
func banner_button(id: String) -> Button:
	return _banner(id)


func back_button() -> Button:
	return _back


func card_open() -> bool:
	return _card != null and is_instance_valid(_card)


## Where everything is on the screen, for a test: {name: Rect2}.
func rects() -> Dictionary:
	var out := {}
	for b: Banner in _banners:
		# (what's drawn and can be pressed: its names, and its pole and cloth)
		out[String(b.info.name)] = Rect2(b.global_position + b.plate().position, b.plate().size)
		out[String(b.info.name) + "'s banner"] = Rect2(b.global_position + b.cloth().position, b.cloth().size)
	for n in _names:
		out[String((n[0] as Label).text)] = (n[0] as Label).get_global_rect()
	out["objective"] = _objective.get_global_rect()
	out["back"] = _back.get_global_rect()
	out["painting"] = _map_rect
	return out


func _unhandled_input(e: InputEvent) -> void:
	if not _offered or _closing:
		return
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if card_open():
			_close_card()
		else:
			_choose("")


func _on_banner(b: Banner) -> void:
	if not _offered or _closing or card_open():
		return
	_open_card(b.info)


func _choose(id: String) -> void:
	if _closing or not _offered:
		return
	_closing = true
	for b: Banner in _banners:
		b.disabled = true
	_back.disabled = true
	closed.emit(id)


## Takes the map away (its layer too, when open_on made one).
func shut(secs := 0.5) -> void:
	_closing = true
	if secs > 0.0 and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, secs)
		await tw.finished
	var p := get_parent()
	if p is CanvasLayer and p.name == "VeylMapLayer":
		p.queue_free()
	else:
		queue_free()


# ------------------------------------------------------------ the card ---

## A kingdom's card: its Champion, whose Seat it is, its Law, and its road.
func _open_card(k: Dictionary) -> void:
	_sfx.play("card_flip", 1.0, -3.0)
	var ui := SafeArea.ui_scale()
	_card = Control.new()
	_card.name = "KingdomCard"
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_close_card())
	_card.add_child(dim)
	var fit := Control.new()
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(fit)
	SafeArea.fit(fit, Vector2(40, 24), true)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fit.add_child(centre)
	var panel := PanelContainer.new()
	var cols: Array = colours(k)
	var edge: Color = (cols[0] as Color).lerp(UITheme.GOLD, 0.45)
	var sb := UITheme.sb(Color(0.045, 0.05, 0.085, 0.97), edge, 18, 3)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 24
	panel.add_theme_stylebox_override("panel", sb)
	centre.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 34)
	panel.add_child(row)
	# the Champion
	var face := Portrait.new()
	face.tex = portrait(k)
	face.sign_name = sign_of(k)
	face.edge = edge
	face.custom_minimum_size = Vector2(340, 340)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(minf(700.0, (SafeArea.rect().size.x / ui) - 520.0), 0)
	col.add_theme_constant_override("separation", 10)
	row.add_child(col)
	var god: Dictionary = Lore.GODS[String(k.god)]
	var kicker := UITheme.label(("For %s, %s" % [String(god.name), String(god.title)]).to_upper(), 24, UITheme.GOLD_DIM, "display_bold", 6)
	kicker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(kicker)
	col.add_child(UITheme.label(String(k.name).to_upper(), 64, UITheme.GOLD, "display_bold", 10))
	var holder := UITheme.label("Champion  ·  %s" % String(k.holder), 34, UITheme.TEXT, "display", 6)
	holder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(holder)
	# the Kingdom Law (every duel fought there follows it)
	var law := PanelContainer.new()
	var lsb := UITheme.sb(Color(0.08, 0.09, 0.14, 0.9), Color(edge.r, edge.g, edge.b, 0.5), 12, 2)
	lsb.content_margin_left = 20
	lsb.content_margin_right = 20
	lsb.content_margin_top = 12
	lsb.content_margin_bottom = 14
	law.add_theme_stylebox_override("panel", lsb)
	col.add_child(law)
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 2)
	law.add_child(lcol)
	lcol.add_child(UITheme.label("KINGDOM LAW  ·  " + DuelLaws.law_name(String(k.god)).to_upper(), 22, UITheme.GOLD_DIM, "bold", 4))
	var ltext := UITheme.label(DuelLaws.describe(String(k.god)), 28, UITheme.TEXT, "body", 4)
	ltext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lcol.add_child(ltext)
	# the road there
	var built := BUILT.has(String(k.id))
	if not built:
		var note := UITheme.label("The road to %s isn't in the game yet." % String(k.name), 26, UITheme.TEXT_DIM, "body", 4)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(note)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	col.add_child(buttons)
	var back := UITheme.button("Back to the map", not built, 320)
	back.name = "BackToMap"
	back.pressed.connect(_close_card)
	buttons.add_child(back)
	if built:
		var go := UITheme.button("Set out for %s" % String(k.name), true, 380)
		go.name = "SetOut"
		go.pressed.connect(func() -> void:
			_close_card()
			_choose(String(k.id)))
		buttons.add_child(go)
		go.grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()
	_card.set_meta("kingdom", String(k.id))
	_card.modulate.a = 0.0
	panel.pivot_offset = panel.get_combined_minimum_size() * 0.5
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.22)


## The card's "Back to the map", for a test to press (null with no card up).
func card_back_button() -> Button:
	if not card_open():
		return null
	return _card.find_child("BackToMap", true, false) as Button


func card_kingdom() -> String:
	return String(_card.get_meta("kingdom", "")) if card_open() else ""


func _close_card() -> void:
	if not card_open():
		return
	var id := String(_card.get_meta("kingdom", ""))
	var c := _card
	_card = null
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 0.0, 0.16)
	tw.tween_callback(c.queue_free)
	var b := _banner(id)
	if b != null and not _closing:
		b.grab_focus.call_deferred()


# ------------------------------------------------------------ the look ---

## The painting behind the painting: a soft blur of it, made once when the
## map opens by shrinking it to a few dozen pixels and growing it again (a
## blur drawn every frame, twenty-five taps a pixel, was the slowest thing on
## the screen). Drawn dark (the rect's modulate).
static func _soft(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return tex
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGB8)
	img.resize(40, 22, Image.INTERPOLATE_LANCZOS)
	img.resize(320, 180, Image.INTERPOLATE_CUBIC)
	return ImageTexture.create_from_image(img)


## The painting's edges fading out (only on the sides `fade` names), and a
## little dark round its rim so the names read.
static func _edge_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 fade = vec2(0.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = 1.0;
	if (fade.x > 0.0) {
		a *= smoothstep(0.0, fade.x, UV.x) * smoothstep(0.0, fade.x, 1.0 - UV.x);
	}
	if (fade.y > 0.0) {
		a *= smoothstep(0.0, fade.y, UV.y) * smoothstep(0.0, fade.y, 1.0 - UV.y);
	}
	vec2 d = (UV - vec2(0.5)) * vec2(1.0, 1.0);
	float v = smoothstep(0.42, 0.78, length(d));
	c.rgb *= 1.0 - 0.38 * v;
	COLOR = vec4(c.rgb, c.a * a);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## A soft round glow, made once.
static var _glow_tex: Texture2D

static func glow() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.32))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_glow_tex = gt
	return _glow_tex


# ============================================================== the parts ===

## A Champion's banner: a pole planted beside the kingdom, the cloth flying
## from its head in the kingdom's colour with its sign on it, and under the
## pole's foot the kingdom's name and its Champion's.
class Banner extends Button:
	const POLE := 132.0
	const CLOTH := Vector2(98.0, 62.0)
	const STRIPS := 14

	var info := {}
	var phase := 0.0
	var _t := 0.0
	var _foot := Vector2.ZERO      # the pole's foot, in this control
	var _ui := 1.0
	var _hot := 0.0                # 0..1: under the pointer, or the one the keys are on
	var _stir := 0.0               # the wind Bram's line puts in it
	var _name_size := Vector2.ZERO
	var _holder_size := Vector2.ZERO

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for s in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())

	func _font(kind: String) -> Font:
		return CardFace.font(kind)

	## Puts the banner's pole at `foot` (on the map screen), sized for the
	## text size `ui`, its names kept inside `safe`.
	func lay(foot: Vector2, ui: float, safe: Rect2) -> void:
		_ui = ui
		var nf := int(round(30.0 * ui))
		var hf := int(round(22.0 * ui))
		_name_size = _font("display_bold").get_string_size(String(info.name), HORIZONTAL_ALIGNMENT_LEFT, -1, nf)
		_holder_size = _font("body").get_string_size(String(info.holder), HORIZONTAL_ALIGNMENT_LEFT, -1, hf)
		var half := maxf(maxf(_name_size.x, _holder_size.x) * 0.5 + 18.0, CLOTH.x + 16.0)
		half = maxf(half, UITheme.TOUCH * 0.5)
		var up := POLE + 18.0
		var down := 10.0 + _name_size.y + _holder_size.y + 8.0
		size = Vector2(half * 2.0, up + down)
		custom_minimum_size = size
		# the names stay on the screen: the whole banner slides in from an edge
		var x := clampf(foot.x - half, safe.position.x + 4.0, safe.end.x - size.x - 4.0)
		position = Vector2(x, foot.y - up)
		_foot = Vector2(foot.x - x, up)
		pivot_offset = _foot
		queue_redraw()

	func stir() -> void:
		_stir = 1.0

	## The dark plate its two names are written on (in this control).
	func plate() -> Rect2:
		var w := maxf(_name_size.x, _holder_size.x) + 28.0
		return Rect2(Vector2(size.x * 0.5 - w * 0.5, _foot.y + 8.0), Vector2(w, _name_size.y + _holder_size.y + 6.0))

	## Its pole and its cloth, with the room the wind takes (in this control).
	func cloth() -> Rect2:
		var dir := float(int(info.fly))
		var head := _foot + Vector2(0, -POLE)
		var tip := head.x + dir * (CLOTH.x + 6.0)
		var x0 := minf(head.x - 9.0, tip)
		var x1 := maxf(head.x + 9.0, tip)
		return Rect2(x0, head.y - 16.0, x1 - x0, POLE + 16.0)

	## Pressed only where there's something of it: the control is a box
	## round a pole, a cloth to one side and a plate under them, and its
	## empty corners can lie over a neighbour's name.
	func _has_point(p: Vector2) -> bool:
		return plate().grow(6.0).has_point(p) or cloth().grow(8.0).has_point(p)

	func _process(delta: float) -> void:
		_t += delta
		var want := 1.0 if (not disabled and (is_hovered() or has_focus())) else 0.0
		_hot = move_toward(_hot, want, delta * 5.0)
		_stir = move_toward(_stir, 0.0, delta * 0.45)
		queue_redraw()

	## How far the cloth hangs off its line at `u` along it (0 the pole, 1
	## the tails).
	func _wave(u: float) -> float:
		var lift := 1.0 + _stir * 0.9 + _hot * 0.25
		return (sin(_t * 2.5 * (1.0 + _stir * 0.4) - u * 5.6 + phase) * 5.0 * pow(u, 0.8) * lift
			+ sin(_t * 1.3 - u * 2.7 + phase * 2.0) * 3.0 * u
			+ u * u * (7.0 - 5.0 * _stir))

	func _slope(u: float) -> float:
		return cos(_t * 2.5 * (1.0 + _stir * 0.4) - u * 5.6 + phase)

	## The cloth's colour at `u` along it: lighter where a fold faces the
	## light, darker in its hollow, and flat by the pole where it's held.
	func _shade(cloth: Color, u: float) -> Color:
		var sh := 0.84 + 0.2 * _slope(u) * minf(1.0, u * 2.6)
		if sh > 1.0:
			return cloth.lerp(Color(1, 1, 1), (sh - 1.0) * 0.9)
		return Color(cloth.r * sh, cloth.g * sh, cloth.b * sh, 1.0)

	func _draw() -> void:
		var cols: Array = VeylMap.colours(info)
		var cloth: Color = cols[0]
		var sign_col: Color = cols[1]
		var dir := float(int(info.fly))
		var head := _foot + Vector2(0, -POLE)
		var lit := maxf(_hot, _stir * 0.8)
		# the light behind a banner the pointer's on (or Bram has named)
		if lit > 0.01:
			var gc := sign_col
			gc.a = 0.5 * lit
			var gr := 150.0 + 14.0 * sin(_t * 3.0)
			draw_texture_rect(VeylMap.glow(), Rect2(head + Vector2(dir * CLOTH.x * 0.5, CLOTH.y * 0.5) - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, gc)
		# the pole: its shadow on the ground, the wood, a line of light on it
		draw_line(_foot + Vector2(2, 1), _foot + Vector2(26, 9), Color(0, 0, 0, 0.35), 5.0, true)
		draw_circle(_foot, 6.0, Color(0, 0, 0, 0.4))
		draw_line(_foot, head + Vector2(0, -6), Color("2a1b10"), 7.0, true)
		draw_line(_foot + Vector2(-1.2, 0), head + Vector2(-1.2, -6), Color("8a6a44"), 2.2, true)
		# the cloth, in strips from the pole out to its two tails
		var top0 := head + Vector2(dir * 3.0, 2.0)
		var pts_top := PackedVector2Array()
		var pts_bot := PackedVector2Array()
		for i in STRIPS:
			var u0 := float(i) / STRIPS
			var u1 := float(i + 1) / STRIPS
			var c0 := _shade(cloth, u0)
			var c1 := _shade(cloth, u1)
			var x0 := dir * u0 * CLOTH.x
			var x1 := dir * u1 * CLOTH.x
			var n0 := _notch(u0)
			var n1 := _notch(u1)
			var a := top0 + Vector2(x0, _wave(u0))
			var b := top0 + Vector2(x1, _wave(u1))
			var cols4 := PackedColorArray([c0, c1, c1, c0])
			if n0 <= 0.0 and n1 <= 0.0:
				draw_polygon(PackedVector2Array([a, b, b + Vector2(0, CLOTH.y), a + Vector2(0, CLOTH.y)]), cols4)
			else:
				# the two tails, either side of the cut
				var h0 := maxf(CLOTH.y * 0.5 * (1.0 - n0), 0.6)
				var h1 := maxf(CLOTH.y * 0.5 * (1.0 - n1), 0.6)
				draw_polygon(PackedVector2Array([a, b, b + Vector2(0, h1), a + Vector2(0, h0)]), cols4)
				draw_polygon(PackedVector2Array([a + Vector2(0, CLOTH.y - h0), b + Vector2(0, CLOTH.y - h1), b + Vector2(0, CLOTH.y), a + Vector2(0, CLOTH.y)]), cols4)
			if i == 0:
				pts_top.append(a)
				pts_bot.append(a + Vector2(0, CLOTH.y))
			pts_top.append(b)
			pts_bot.append(b + Vector2(0, CLOTH.y))
		# its hems
		var hem := cloth.darkened(0.45)
		hem.a = 0.9
		draw_polyline(pts_top, cloth.lightened(0.35), 2.0, true)
		draw_polyline(pts_bot, hem, 2.0, true)
		# the sign on it, riding the cloth
		var su := 0.4
		var sc := top0 + Vector2(dir * su * CLOTH.x, _wave(su) + CLOTH.y * 0.5)
		var r := CLOTH.y * 0.4
		Glyphs.draw(self, VeylMap.sign_of(info), sc + Vector2(1.5, 2.0), r, Color(0, 0, 0, 0.35))
		Glyphs.draw(self, VeylMap.sign_of(info), sc, r, sign_col.lerp(Color(1, 1, 1), 0.25 + 0.4 * lit))
		# the pole's head
		draw_circle(head + Vector2(0, -8), 6.5, Color("5a4312"))
		draw_circle(head + Vector2(0, -8), 5.0, UITheme.GOLD)
		draw_circle(head + Vector2(-1.5, -9.5), 1.8, Color(1, 1, 0.9, 0.9))
		# the names, on a dark plate so they read over any ground
		var nf := int(round(30.0 * _ui))
		var hf := int(round(22.0 * _ui))
		var plate := plate()
		var psb := UITheme.sb(Color(0.03, 0.03, 0.06, 0.58 + 0.2 * lit), Color(sign_col.r, sign_col.g, sign_col.b, 0.25 + 0.6 * lit), 12, 2)
		draw_style_box(psb, plate)
		var name_col := UITheme.TEXT.lerp(UITheme.GOLD, lit)
		var f := _font("display_bold")
		var np := Vector2(size.x * 0.5 - _name_size.x * 0.5, plate.position.y + 2.0 + f.get_ascent(nf))
		draw_string_outline(f, np, String(info.name), HORIZONTAL_ALIGNMENT_LEFT, -1, nf, 8, Color(0.02, 0.02, 0.05, 0.95))
		draw_string(f, np, String(info.name), HORIZONTAL_ALIGNMENT_LEFT, -1, nf, name_col)
		var bf := _font("body")
		var hp := Vector2(size.x * 0.5 - _holder_size.x * 0.5, plate.position.y + 2.0 + _name_size.y + bf.get_ascent(hf))
		draw_string_outline(bf, hp, String(info.holder), HORIZONTAL_ALIGNMENT_LEFT, -1, hf, 6, Color(0.02, 0.02, 0.05, 0.95))
		draw_string(bf, hp, String(info.holder), HORIZONTAL_ALIGNMENT_LEFT, -1, hf, Color(0.86, 0.84, 0.8))

	## How far into the cut between the tails `u` is: 0 before it, 1 at the tips.
	func _notch(u: float) -> float:
		return clampf((u - 0.74) / 0.26, 0.0, 1.0)


## Where the wagon is: a ring of gold light that breathes.
class Here extends Control:
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var p := fmod(_t * 0.55, 1.0)
		var c := UITheme.GOLD
		draw_arc(Vector2.ZERO, 9.0 + 22.0 * p, 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.75 * (1.0 - p)), 3.0, true)
		draw_circle(Vector2.ZERO, 7.5, Color(0.05, 0.04, 0.02, 0.8))
		draw_circle(Vector2.ZERO, 5.5, c)


## A Champion's portrait in a frame of the kingdom's colour (its sign, with no
## portrait in the game).
class Portrait extends Control:
	var tex: Texture2D
	var sign_name := ""
	var edge := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UITheme.sb(Color(0.03, 0.03, 0.06), Color(0, 0, 0, 0), 14, 0), r)
		var inner := r.grow(-6.0)
		if tex != null:
			draw_texture_rect(tex, inner, false)
		else:
			Glyphs.draw(self, sign_name, r.get_center(), size.x * 0.3, edge)
		draw_style_box(UITheme.sb(Color(0, 0, 0, 0), edge, 14, 6), r)
		draw_style_box(UITheme.sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0.5), 10, 2), inner)
