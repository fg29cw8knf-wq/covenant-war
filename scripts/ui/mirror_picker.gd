class_name MirrorPicker
extends Control
## The attic's cracked mirror (Prologue P1, "Choose your look."): the player
## in the glass (the camera stands in the mirror, looking back at them, head
## and shoulders), cracked across, and the four looks along the bottom. Tap
## a face and that look appears in the glass: the real model, lit as the
## attic is, its idle playing (the figure in front of the mirror is swapped
## for it, through `preview`), and the face row shows which is up. "That's
## me." (a line in the dialogue's style) keeps it; until then nothing else
## moves on. Keys and a pad: left and right show each look in turn, Enter /
## E / Space / A keeps the one in the glass. (Until 22 October a tap on a
## face chose it at once; Gary asked to see each look first.)
##
## A look is there to choose the moment its model exists
## (assets/models/characters/player_<letter>.glb, with its face rendered to
## assets/art/characters/player_<letter>_portrait.png): all four since 20
## October (A Gary's first young man, B his second, with stubble and a
## strap, C the dark-haired young woman in green, D the bearded man in
## blue). A look still to come would show "Coming soon" over Gary's painted
## reference for it, misted, if one were there
## (assets/art/characters/look_<letter>_preview.jpg), and a tap on it would
## just shake it.
##
##   var look: String = await MirrorPicker.choose(hud._root, func(look: String) -> void: ...)   # "a"

signal picked(look: String)

const LOOKS := ["a", "b", "c", "d"]
const CONFIRM := "That's me."


## Whether a look has been made (its model is in the game). On the phone
## link looks B, C and D are in the "looks" pack, fetched the first time one
## of them is shown (Packs.need("looks") in the preview), so until then
## their files aren't there to see: a pack the build has counts as made.
static func made(look: String) -> bool:
	if ResourceLoader.exists("res://assets/models/characters/player_%s.glb" % look):
		return true
	return look != "a" and Packs.in_build("looks")

var _faces: Array = []
var _t := 0.0
var _done := false
var _busy := false          # a look is being put in the glass
var _up: Face = null        # the look in the glass
var _shown_at := 0
var _sfx: Sfx
var _confirm: Button
var _preview: Callable      # preview(look): puts that look in the glass (awaited)


## Puts the mirror up over `parent` and waits for a look to be kept; returns
## its letter. `preview(look)` is called (and awaited) each time a look is
## to be shown in the glass; the look in the glass to begin with is `first`
## (the player's look as the attic was built).
static func choose(parent: Control, preview: Callable, first := "a") -> String:
	var m := MirrorPicker.new()
	m._preview = preview
	parent.add_child(m)
	m.show_up(first)
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
	# "That's me." keeps the look in the glass: by the faces, out of the
	# way of the face in the glass, in the dialogue's own style
	_confirm = Button.new()
	_confirm.text = CONFIRM
	_confirm.theme_type_variation = "ChoiceButton"
	_confirm.focus_mode = Control.FOCUS_NONE   # (keys are handled below)
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_confirm.offset_left = -170
	_confirm.offset_right = 170
	_confirm.offset_top = -420
	_confirm.offset_bottom = -348
	_confirm.pressed.connect(_on_confirm)
	_confirm.modulate.a = 0.0
	add_child(_confirm)
	# the row and the line keep clear of a phone's home bar
	SafeArea.watch(row, func() -> void:
		var b := SafeArea.insets().w
		row.offset_top = -330 - b
		row.offset_bottom = -40 - b
		_confirm.offset_top = -420 - b
		_confirm.offset_bottom = -348 - b)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	_shown_at = Time.get_ticks_msec()


## The look in the glass now (no preview: it's already there).
func show_up(look: String) -> void:
	for f in _faces:
		if f.look == look and f.made:
			_set_up(f)


func _set_up(f: Face) -> void:
	_up = f
	for o in _faces:
		o.up = o == f
	if _confirm.modulate.a == 0.0:
		create_tween().tween_property(_confirm, "modulate:a", 1.0, 0.4)


## A face tapped: that look goes in the glass.
func _on_face(f: Face) -> void:
	if _done or _busy or Time.get_ticks_msec() - _shown_at < 400:
		return
	if not f.made:
		f.shake()
		_sfx.play("ui_error")
		return
	if f == _up:
		return
	_busy = true
	_sfx.play("ui_select")
	_set_up(f)
	if _preview.is_valid():
		await _preview.call(f.look)
	_busy = false


## "That's me.": the look in the glass is kept.
func _on_confirm() -> void:
	if _done or _busy or _up == null:
		return
	_done = true
	_sfx.play("ui_select")
	_up.chosen = true
	Game.set_flag("look", _up.look)
	await get_tree().create_timer(0.5).timeout
	picked.emit(_up.look)


## The next made look along from the one in the glass (dir -1 or 1).
func _step(dir: int) -> void:
	if _done or _busy:
		return
	var i := _faces.find(_up) if _up != null else (-1 if dir > 0 else _faces.size())
	for k in _faces.size():
		i = wrapi(i + dir, 0, _faces.size())
		if _faces[i].made:
			_on_face(_faces[i])
			return


func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	if e.is_action_pressed("move_left") or e.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_step(-1)
	elif e.is_action_pressed("move_right") or e.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_step(1)
	elif e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _up != null:
			_on_confirm()
		else:
			_step(1)


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
## one saying it's still to come. `up`: the one in the glass now.
class Face:
	extends Control
	signal tapped(f)
	var look := "a"
	var made := false
	var up := false
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
		if made and not up:
			rim = Color(UITheme.GOLD, 0.55 + 0.25 * pulse)
		if up or chosen:
			rim = Color.WHITE
		pts.append(pts[0])
		draw_polyline(pts, rim, 7.0 if up else (5.0 if made else 3.0), true)
		if up:
			# the one in the glass: a steady white halo
			draw_arc(c, maxf(rx, ry) + 12.0, 0, TAU, 48, Color(1, 1, 1, 0.35), 8.0, true)
		elif made:
			draw_arc(c, maxf(rx, ry) + 10.0, 0, TAU, 48, Color(UITheme.GOLD, 0.12 * pulse), 6.0, true)
		var f2 := CardFace.font("display_bold")
		var label := "Look %s" % look.to_upper()
		CardFace.text(self, f2, Vector2(off.x, size.y - 50), label, 30, Color.WHITE if up else (UITheme.GOLD if made else UITheme.TEXT_DIM), HORIZONTAL_ALIGNMENT_CENTER, w)
		if up:
			CardFace.text(self, CardFace.font("body"), Vector2(off.x, size.y - 16), "In the glass", 22, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)
		elif not made:
			CardFace.text(self, CardFace.font("body"), Vector2(off.x, size.y - 16), "Coming soon", 22, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
