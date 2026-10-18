class_name TitleScreen
extends CanvasLayer
## The title screen: the opening movie's last frame brought to life. Gary's
## painting of the Throne (assets/art/title/title_key_art) breathes under a slow
## camera drift, light rays fan out from the Throne, the eight lights circle it,
## cloud wisps (title_clouds, added as light) drift across the front, gold motes
## rise, and the title shimmers. New Game pushes the camera into the Throne and
## floods the screen white. Without the painting it falls back to the old 3D
## flight over Solhaven (main.gd builds that backdrop).

signal new_game
signal continue_game
signal watch_opening
signal open_lab

const KEY_ART := "res://assets/art/title/title_key_art"
const CLOUDS := "res://assets/art/title/title_clouds"
## Where the Throne sits in the painting (0-1 across and down).
const THRONE_UV := Vector2(0.625, 0.555)

var _root: Control
var _logo: Control
var _ui: Control
var _backdrop: Backdrop
var _flash: ColorRect
var _leaving := false


static func art_path(base: String) -> String:
	for ext in ["jpg", "png"]:
		if ResourceLoader.exists("%s.%s" % [base, ext]):
			return "%s.%s" % [base, ext]
	return ""


## True when the painted title screen can be shown.
static func has_art() -> bool:
	return art_path(KEY_ART) != ""


func _ready() -> void:
	layer = 5
	Music.play(["menu_theme"], 1.5, true)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	add_child(_root)

	if has_art():
		_backdrop = Backdrop.new()
		_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root.add_child(_backdrop)

	# a soft shade on the left so the title and buttons read over the painting
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	float left = smoothstep(0.62, 0.0, UV.x);
	float bottom = smoothstep(0.55, 1.0, UV.y);
	float edge = smoothstep(0.35, 0.0, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)) * 2.0);
	COLOR = vec4(0.02, 0.02, 0.05, clamp(left * 0.62 + bottom * 0.22 + edge * 0.35, 0.0, 0.85));
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	shade.material = sm
	_root.add_child(shade)

	# everything that fades when leaving, in the safe area (clear of a phone's
	# Dynamic Island and home bar); the painting goes to the edges
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ui)
	SafeArea.fit(_ui)

	_logo = Logo.new()
	_logo.anchor_top = 0.0
	_logo.anchor_bottom = 0.0
	_logo.offset_left = 110
	_logo.offset_top = 96
	_logo.offset_right = 1200
	_logo.offset_bottom = 500
	_ui.add_child(_logo)

	var box := VBoxContainer.new()
	box.anchor_top = 0.0
	box.anchor_bottom = 0.0
	box.offset_left = 120
	box.offset_right = 620
	box.offset_top = 584
	box.offset_bottom = 1060
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 16)
	_ui.add_child(box)
	if Game.has_save():
		var cont := UITheme.button("Continue", true, 500)
		cont.pressed.connect(func() -> void: _leave(continue_game))
		box.add_child(cont)
		var info := UITheme.label(Game.save_summary(), 24, UITheme.TEXT_DIM)
		box.add_child(info)
		cont.grab_focus.call_deferred()
	var ng := UITheme.button("New Game", not Game.has_save(), 500)
	ng.pressed.connect(func() -> void: _leave(new_game))
	box.add_child(ng)
	if not Game.has_save():
		ng.grab_focus.call_deferred()
	var lab := UITheme.button("Duel Lab", false, 500)
	lab.pressed.connect(func() -> void: open_lab.emit())
	box.add_child(lab)
	var movie := UITheme.button("Watch the opening", false, 500)
	movie.pressed.connect(func() -> void: watch_opening.emit())
	box.add_child(movie)
	# on a short safe area (a phone's home bar) the buttons and title move up to fit
	SafeArea.watch(box, func() -> void:
		var need := box.get_combined_minimum_size().y
		box.offset_top = minf(584.0, SafeArea.rect().size.y - need - 24.0)
		box.offset_bottom = box.offset_top + need
		_logo.offset_top = clampf(box.offset_top - 452.0, 24.0, 96.0)
		_logo.offset_bottom = _logo.offset_top + 404.0)

	var ver := UITheme.label("%s   ·   Early build %s" % [NoticeScreen.COPYRIGHT, Packs.build_label()], 22, Color(1, 1, 1, 0.6), "body", 6)
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -1100
	ver.offset_right = -40
	ver.offset_top = -70
	ver.offset_bottom = -30
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui.add_child(ver)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 1.2)


## New Game and Continue push the camera into the Throne and flood the screen
## white before the game takes over; without the painting they just go.
func _leave(sig: Signal) -> void:
	if _leaving:
		return
	_leaving = true
	if _backdrop == null:
		sig.emit()
		return
	_flash.mouse_filter = Control.MOUSE_FILTER_STOP
	Music.stop(1.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "push", 1.0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_flash, "color", Color(1, 1, 1, 1), 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_ui, "modulate:a", 0.0, 0.5)
	tw.chain().tween_property(_flash, "color", Color(0, 0, 0, 1), 0.35)
	await tw.finished
	sig.emit()


## The painting, the rays, the lights, the wisps and the motes.
class Backdrop:
	extends Control
	var art: Texture2D
	var clouds: Texture2D
	var push := 0.0           # 0 at rest, 1 fully pushed into the Throne
	var _t := 0.0
	var _rays: ColorRect
	var _rays_mat: ShaderMaterial
	var _wisps: Wisps
	var _motes: Array = []
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		art = load(TitleScreen.art_path(TitleScreen.KEY_ART))
		var cp := TitleScreen.art_path(TitleScreen.CLOUDS)
		if cp != "":
			clouds = load(cp)
		_rng.seed = 7
		for i in 140:
			_motes.append(Vector4(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()))

	func _ready() -> void:
		_rays = ColorRect.new()
		_rays.color = Color.WHITE
		_rays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
render_mode blend_add;
uniform vec2 center = vec2(0.62, 0.5);
uniform float strength = 0.55;
uniform float aspect = 1.7778;
void fragment() {
	vec2 d = UV - center;
	d.x *= aspect;
	float dist = length(d);
	float ang = atan(d.y, d.x);
	float r = 0.55 + 0.45 * sin(ang * 9.0 + TIME * 0.21);
	r *= 0.5 + 0.5 * sin(ang * 23.0 - TIME * 0.13 + 1.3);
	r *= 0.6 + 0.4 * sin(ang * 5.0 + TIME * 0.07);
	float fall = smoothstep(0.85, 0.06, dist) * smoothstep(0.0, 0.1, dist);
	float up = 0.45 + 0.55 * smoothstep(0.35, -0.3, d.y);
	float a = r * fall * up * strength;
	COLOR = vec4(vec3(1.0, 0.86, 0.55) * a, a);
}"""
		_rays_mat = ShaderMaterial.new()
		_rays_mat.shader = sh
		_rays.material = _rays_mat
		add_child(_rays)
		if clouds != null:
			_wisps = Wisps.new()
			_wisps.tex = clouds
			_wisps.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(_wisps)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	## The painting's rectangle this frame: a slow breathing zoom and drift,
	## plus the push into the Throne when leaving.
	func art_rect() -> Rect2:
		var r := Rect2(Vector2.ZERO, size)
		var zoom := 1.06 + 0.025 * sin(_t * 0.09) + push * 0.9
		var drift := Vector2(sin(_t * 0.06) * 0.008, cos(_t * 0.045) * 0.006) * size
		var ts := Vector2(art.get_width(), art.get_height())
		var k := maxf(r.size.x / ts.x, r.size.y / ts.y) * zoom
		var sz := ts * k
		# zoom about the Throne so the push-in flies straight at it
		var pivot := THRONE_UV_SCREEN()
		var pos := pivot - TitleScreen.THRONE_UV * sz + drift * (1.0 - push)
		# never show the edge of the painting
		pos.x = clampf(pos.x, r.size.x - sz.x, 0.0)
		pos.y = clampf(pos.y, r.size.y - sz.y, 0.0)
		return Rect2(pos, sz)

	func THRONE_UV_SCREEN() -> Vector2:
		return Vector2(size.x * 0.56, size.y * 0.52)

	func throne_pos() -> Vector2:
		var ar := art_rect()
		return ar.position + TitleScreen.THRONE_UV * ar.size

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color.BLACK)
		var ar := art_rect()
		draw_texture_rect(art, ar, false)
		var tp := throne_pos()
		_rays_mat.set_shader_parameter("center", tp / size)
		_rays_mat.set_shader_parameter("aspect", size.x / size.y)
		_rays_mat.set_shader_parameter("strength", 0.55 + push * 0.8)
		if _wisps != null:
			_wisps.t = _t
		# the Throne's glow and the eight lights
		var glow := 0.08 + 0.03 * sin(_t * 0.8)
		for i in 6:
			draw_circle(tp, size.y * (0.07 + i * 0.035), Color(UITheme.GOLD, glow * (1.0 - i / 6.0)))
		var rx := size.x * (0.11 + push * 0.12)
		var ry := size.y * (0.04 + push * 0.05)
		for i in 8:
			var ang := _t * 0.35 + TAU * i / 8.0
			var p := tp + Vector2(cos(ang) * rx, sin(ang) * ry)
			var behind := sin(ang) < 0.0
			var el := "any" if i == 7 else String(Lore.GODS[Lore.GREAT_GODS[i]].element)
			var col := Color.WHITE if i == 7 else Lore.color(el, 0)
			var sc := 0.8 if behind else 1.0
			draw_circle(p, 26 * sc, Color(col, 0.14))
			draw_circle(p, 9 * sc, Color(col, 0.95))
			draw_circle(p, 3.5 * sc, Color(1, 1, 1, 0.9))
		# gold motes rising
		for m: Vector4 in _motes:
			var pos: Vector2 = Vector2(fmod(m.x + _t * 0.006 * (m.z - 0.5), 1.0), fmod(m.y + 1.0 - _t * 0.012 * (0.3 + m.w), 1.0)) * size
			var a: float = 0.12 + 0.3 * m.w * (0.6 + 0.4 * sin(_t * 1.7 + m.x * 20.0))
			draw_circle(pos, 1.2 + m.z * 2.4, Color(UITheme.GOLD, a))


## Cloud wisps painted on black, added as light, drifting at two speeds.
class Wisps:
	extends Control
	var tex: Texture2D
	var t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var ts := Vector2(tex.get_width(), tex.get_height())
		for layer in [[1.35, 0.012, 0.30, 0.58], [1.9, 0.021, 0.22, 0.72]]:
			var sc: float = layer[0]
			var speed: float = layer[1]
			var alpha: float = layer[2]
			var ybias: float = layer[3]
			var w := size.x * sc
			var h := w * ts.y / ts.x
			var x := -fmod(t * speed * size.x, w)
			var y := size.y * ybias - h * 0.5
			for k in 2:
				draw_texture_rect(tex, Rect2(Vector2(x + k * w, y), Vector2(w, h)), false, Color(1, 1, 1, alpha))


class Logo:
	extends Control
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# a slow shimmer sweeping across whatever this control draws
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
void fragment() {
	float band = fract((SCREEN_UV.x * 1.6 + SCREEN_UV.y * 0.6) * 0.5 - TIME * 0.06);
	float s = smoothstep(0.42, 0.5, band) * smoothstep(0.58, 0.5, band);
	COLOR.rgb += COLOR.a * s * vec3(0.55, 0.5, 0.35);
}"""
		var m := ShaderMaterial.new()
		m.shader = sh
		material = m

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := CardFace.font("display_bold")
		var gold := UITheme.GOLD
		CardFace.text(self, CardFace.font("display"), Vector2(6, 40), "THE", 44, Color(gold, 0.9), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		CardFace.text(self, f, Vector2(0, 150), "COVENANT", 128, gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.05, 0.03, 0.01, 0.9))
		CardFace.text(self, f, Vector2(0, 258), "WAR", 128, gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.05, 0.03, 0.01, 0.9))
		var y := 300.0
		draw_line(Vector2(4, y), Vector2(560, y), Color(gold, 0.6), 2.0)
		CardFace.text(self, CardFace.font("display"), Vector2(4, y + 50), "THRONE  OF  AGES", 40, UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		CardFace.text(self, CardFace.font("body"), Vector2(4, y + 96), "Seven gods. One throne. You hold the cards.", 30, Color(UITheme.TEXT, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
		CardFace.text(self, CardFace.font("bold"), Vector2(4, y + 136), "MADE  BY  GARY  MANNION", 26, Color(gold, 0.95), HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
		# a slowly turning sigil beside the name
		var c := Vector2(1010, 170)
		var r := 90.0 + sin(_t * 1.3) * 3.0
		draw_circle(c, r * 1.3, Color(gold, 0.05))
		draw_arc(c, r, 0, TAU, 96, Color(gold, 0.55), 3.0, true)
		for i in 7:
			var a := _t * 0.2 + TAU * i / 7.0
			var god: String = Lore.GREAT_GODS[i]
			CardFace.orb(self, c + Vector2(cos(a), sin(a)) * r, 16, Lore.GODS[god].element)
		Glyphs.draw(self, "crown_sigil", c, 46, gold)
