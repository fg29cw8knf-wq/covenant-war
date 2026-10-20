class_name MirrorPicker
extends Control
## The attic's cracked mirror (Prologue P1, "Choose your look. (Tap a
## face.)"): the player's face in the glass, cracked across, and the four
## looks along the bottom. A look is there to choose the moment its model
## exists (assets/models/characters/player_<letter>.glb, with its face
## rendered to assets/art/characters/player_<letter>_portrait.png); one
## still to come shows "Coming soon" over Gary's painted reference for it,
## misted, when there is one (assets/art/characters/look_<letter>_preview.jpg),
## and a tap on it just shakes it. The step is gated: nothing else moves on
## until a look is chosen (a tap, or Enter / E / Space / a pad's A for the
## first one made).
##
##   var look: String = await MirrorPicker.choose(hud._root)   # "a"

signal picked(look: String)

const LOOKS := ["a", "b", "c", "d"]


## Whether a look has been made (its model is in the game).
static func made(look: String) -> bool:
	return ResourceLoader.exists("res://assets/models/characters/player_%s.glb" % look)

var _faces: Array = []
var _t := 0.0
var _done := false
var _shown_at := 0
var _sfx: Sfx


## Puts the mirror up over `parent` and waits for a look; returns its letter.
static func choose(parent: Control) -> String:
	var m := MirrorPicker.new()
	parent.add_child(m)
	var look: String = await m.picked
	var tw := m.create_tween()
	tw.tween_property(m, "modulate:a", 0.0, 0.5)
	tw.tween_callback(m.queue_free)
	return look


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	_sfx = Sfx.new()
	add_child(_sfx)
	var row := HBoxContainer.new()
	row.name = "Faces"
	row.add_theme_constant_override("separation", 36)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -560
	row.offset_right = 560
	row.offset_top = -330
	row.offset_bottom = -40
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for look in LOOKS:
		var f := Face.new()
		f.look = look
		f.made = made(look)
		f.custom_minimum_size = Vector2(220, 290)
		f.tapped.connect(_on_face)
		row.add_child(f)
		_faces.append(f)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	_shown_at = Time.get_ticks_msec()


func _on_face(f: Face) -> void:
	if _done or Time.get_ticks_msec() - _shown_at < 400:
		return
	if not f.made:
		f.shake()
		_sfx.play("ui_error")
		return
	_done = true
	_sfx.play("ui_select")
	f.chosen = true
	Game.set_flag("look", f.look)
	await get_tree().create_timer(0.6).timeout
	picked.emit(f.look)


func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		for f in _faces:
			if f.made:
				_on_face(f)
				return


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## The glass: dark at the edges like an old mirror in a dim room, and the
## crack running across it from the top left.
func _draw() -> void:
	var s := size
	for i in 14:
		var k := float(i) / 14.0
		var inset := Rect2(Vector2.ZERO, s).grow(-s.y * 0.04 * i)
		draw_rect(inset, Color(0.02, 0.015, 0.01, 0.045 * (1.0 - k)), false, s.y * 0.04)
	var c := Vector2(s.x * 0.27, s.y * 0.18)
	var crack := Color(0.92, 0.95, 1.0, 0.28)
	var arms := [[Vector2(-0.24, -0.2), 3], [Vector2(0.55, 0.12), 4], [Vector2(0.18, 0.48), 3], [Vector2(-0.12, 0.42), 2], [Vector2(0.3, -0.16), 2]]
	for a in arms:
		var p := c
		var d: Vector2 = a[0]
		for j in int(a[1]):
			var q: Vector2 = p + d * s.y * 0.22 + Vector2(sin(j * 2.3 + d.x * 9.0), cos(j * 1.7 + d.y * 7.0)) * s.y * 0.025
			draw_line(p, q, crack, 2.0, true)
			draw_line(p + Vector2(1, 1), q + Vector2(1, 1), Color(0, 0, 0, 0.18), 1.0, true)
			p = q
	draw_circle(c, 5.0, Color(1, 1, 1, 0.35))


## One face in the row: the look's portrait in an oval frame, or a misted
## one saying it's still to come.
class Face:
	extends Control
	signal tapped(f)
	var look := "a"
	var made := false
	var chosen := false
	var _shake := 0.0
	var _t := 0.0
	var _tex: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		if made:
			_tex = DollArt.portrait("player_" + look) if DollArt.has_portrait("player_" + look) else DollArt.portrait("player")
		else:
			var p := "res://assets/art/characters/look_%s_preview.jpg" % look
			if ResourceLoader.exists(p):
				_tex = load(p)

	func shake() -> void:
		_shake = 1.0

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			tapped.emit(self)

	func _process(delta: float) -> void:
		_t += delta
		_shake = move_toward(_shake, 0.0, delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		var off := Vector2(sin(_t * 60.0) * 10.0 * _shake, 0)
		var w := size.x
		var oval := Rect2(Vector2(10, 14) + off, Vector2(w - 20, size.y - 110))
		var c := oval.get_center()
		var rx := oval.size.x * 0.5
		var ry := oval.size.y * 0.5
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(0.06, 0.07, 0.1, 0.92))
		if _tex != null:
			# the portrait cropped to the oval (a look to come: its painted
			# reference, dim behind the mist)
			var uvs := PackedVector2Array()
			for p in pts:
				var u := (p - oval.position) / oval.size
				uvs.append(Vector2(0.12 + u.x * 0.76, 0.02 + u.y * 0.8) if made else Vector2(0.1 + u.x * 0.8, u.y * 0.9))
			draw_colored_polygon(pts, Color.WHITE if made else Color(0.42, 0.44, 0.5), uvs, _tex)
		if not made:
			# misted glass, and a question waiting to be answered
			for i in 5:
				draw_circle(c + Vector2(sin(i * 1.9) * rx * 0.3, cos(i * 2.7) * ry * 0.3), rx * (0.5 - i * 0.06), Color(0.5, 0.55, 0.65, 0.06))
			var f := CardFace.font("display_bold")
			CardFace.text(self, f, Vector2(off.x, c.y - 30), "?", 64, Color(UITheme.TEXT_DIM, 0.6), HORIZONTAL_ALIGNMENT_CENTER, w)
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		var rim := UITheme.GOLD if made else UITheme.GOLD_DIM.darkened(0.3)
		if made and not chosen:
			rim = Color(UITheme.GOLD, 0.7 + 0.3 * pulse)
		if chosen:
			rim = Color.WHITE
		pts.append(pts[0])
		draw_polyline(pts, rim, 6.0 if made else 3.0, true)
		if made and not chosen:
			draw_arc(c, maxf(rx, ry) + 10.0, 0, TAU, 48, Color(UITheme.GOLD, 0.15 * pulse), 6.0, true)
		var f2 := CardFace.font("display_bold")
		var label := "Look %s" % look.to_upper()
		CardFace.text(self, f2, Vector2(off.x, size.y - 50), label, 30, UITheme.GOLD if made else UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
		if not made:
			CardFace.text(self, CardFace.font("body"), Vector2(off.x, size.y - 16), "Coming soon", 22, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
