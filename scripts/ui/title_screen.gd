class_name TitleScreen
extends CanvasLayer
## The title screen, drawn over a slow flight across Solhaven.

signal new_game
signal continue_game
signal watch_opening
signal open_lab

var _root: Control
var _t := 0.0
var _logo: Control


func _ready() -> void:
	layer = 5
	Music.play(["menu_theme"], 1.5, true)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	float left = smoothstep(0.75, 0.0, UV.x);
	float bottom = smoothstep(0.35, 1.0, UV.y);
	COLOR = vec4(0.02, 0.02, 0.05, clamp(left * 0.78 + bottom * 0.35, 0.0, 0.9));
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	shade.material = sm
	_root.add_child(shade)

	_logo = Logo.new()
	_logo.anchor_top = 0.0
	_logo.anchor_bottom = 0.0
	_logo.offset_left = 110
	_logo.offset_top = 120
	_logo.offset_right = 1200
	_logo.offset_bottom = 420
	_root.add_child(_logo)

	var box := VBoxContainer.new()
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 120
	box.offset_right = 620
	box.offset_top = -680
	box.offset_bottom = -120
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 22)
	_root.add_child(box)
	if Game.has_save():
		var cont := UITheme.button("Continue", true, 500)
		cont.pressed.connect(func() -> void: continue_game.emit())
		box.add_child(cont)
		var info := UITheme.label(Game.save_summary(), 26, UITheme.TEXT_DIM)
		box.add_child(info)
		cont.grab_focus.call_deferred()
	var ng := UITheme.button("New Game", not Game.has_save(), 500)
	ng.pressed.connect(func() -> void: new_game.emit())
	box.add_child(ng)
	if not Game.has_save():
		ng.grab_focus.call_deferred()
	var lab := UITheme.button("Duel Lab", false, 500)
	lab.pressed.connect(func() -> void: open_lab.emit())
	box.add_child(lab)
	var movie := UITheme.button("Watch the opening", false, 500)
	movie.pressed.connect(func() -> void: watch_opening.emit())
	box.add_child(movie)

	var ver := UITheme.label("Early build %s" % ProjectSettings.get_setting("application/config/version", ""), 22, Color(1, 1, 1, 0.4))
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -400
	ver.offset_right = -40
	ver.offset_top = -70
	ver.offset_bottom = -30
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(ver)
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 1.2)


class Logo:
	extends Control
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		CardFace.text(self, CardFace.font("body"), Vector2(4, y + 100), "Seven gods. One throne. You hold the cards.", 30, Color(UITheme.TEXT, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
		# a slowly turning sigil beside the name
		var c := Vector2(1010, 170)
		var r := 90.0 + sin(_t * 1.3) * 3.0
		draw_circle(c, r * 1.3, Color(gold, 0.05))
		draw_arc(c, r, 0, TAU, 96, Color(gold, 0.55), 3.0, true)
		for i in 7:
			var a := _t * 0.2 + TAU * i / 7.0
			var god: String = Lore.GODS.keys()[i]
			CardFace.orb(self, c + Vector2(cos(a), sin(a)) * r, 16, Lore.GODS[god].element)
		Glyphs.draw(self, "crown_sigil", c, 46, gold)
