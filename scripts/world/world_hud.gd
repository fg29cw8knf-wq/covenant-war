class_name WorldHUD
extends CanvasLayer
## Everything drawn over the walkable world: the touch pad (drag = joystick,
## tap = walk there / talk), the Talk button, the menu, the area title, the
## dialogue box, reward pop-ups and screen fades.

signal talk_pressed
signal menu_action(action: String)
signal tapped(viewport_pos: Vector2)

var pad: TouchPad
var dialogue: DialogueBox
var _root: Control
var _talk: TalkButton
var _talk_name: Label
var _menu_btn: IconButton
var _menu: Control
var _title: Control
var _fade: ColorRect
var _toast: Label


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float strength = 0.42;\nvoid fragment() {\n\tvec2 uv = UV - 0.5;\n\tfloat d = length(uv * vec2(1.0, 0.75));\n\tCOLOR = vec4(0.06, 0.035, 0.02, smoothstep(0.38, 0.8, d) * strength);\n}\n"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	vignette.material = sm
	_root.add_child(vignette)

	pad = TouchPad.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.tapped.connect(func(p: Vector2) -> void: tapped.emit(p))
	_root.add_child(pad)

	_talk = TalkButton.new()
	_talk.anchor_left = 1.0
	_talk.anchor_right = 1.0
	_talk.anchor_top = 1.0
	_talk.anchor_bottom = 1.0
	_talk.offset_left = -250
	_talk.offset_right = -60
	_talk.offset_top = -250
	_talk.offset_bottom = -60
	_talk.visible = false
	_talk.pressed.connect(func() -> void: talk_pressed.emit())
	_root.add_child(_talk)
	_talk_name = UITheme.label("", 28, UITheme.TEXT, "display_bold", 8)
	_talk_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_name.anchor_left = 1.0
	_talk_name.anchor_right = 1.0
	_talk_name.anchor_top = 1.0
	_talk_name.anchor_bottom = 1.0
	_talk_name.offset_left = -400
	_talk_name.offset_right = 90
	_talk_name.offset_top = -300
	_talk_name.offset_bottom = -256
	_talk_name.visible = false
	_root.add_child(_talk_name)

	_menu_btn = IconButton.new()
	_menu_btn.glyph = "menu"
	_menu_btn.anchor_left = 1.0
	_menu_btn.anchor_right = 1.0
	_menu_btn.offset_left = -150
	_menu_btn.offset_right = -40
	_menu_btn.offset_top = 36
	_menu_btn.offset_bottom = 146
	_menu_btn.pressed.connect(open_menu)
	_root.add_child(_menu_btn)

	_toast = UITheme.label("", 34, UITheme.GOLD, "display_bold", 10)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -700
	_toast.offset_right = 700
	_toast.offset_top = 60
	_toast.offset_bottom = 120
	_toast.modulate.a = 0.0
	_root.add_child(_toast)

	_title = _make_title()
	_root.add_child(_title)

	dialogue = DialogueBox.new()
	_root.add_child(dialogue)

	_menu = _make_menu()
	_root.add_child(_menu)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_root.add_child(_fade)


# --------------------------------------------------------------- public ---

func set_talk_target(npc_name: String, duel: bool) -> void:
	var show := npc_name != ""
	_talk.visible = show
	_talk_name.visible = show
	_talk_name.text = npc_name
	_talk.glyph = "duel" if duel else "talk"
	_talk.queue_redraw()


func set_controls_visible(v: bool) -> void:
	pad.visible = v
	_menu_btn.visible = v
	if not v:
		_talk.visible = false
		_talk_name.visible = false
	pad.reset()


func show_area_title(title: String, subtitle: String) -> void:
	(_title.get_node("T") as Label).text = title.to_upper()
	(_title.get_node("S") as Label).text = subtitle
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.2)
	tw.tween_property(_title, "modulate:a", 0.0, 1.0)


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func fade(to_alpha: float, duration: float = 0.45) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if to_alpha > 0.5 else Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", to_alpha, duration)
	await tw.finished


## A big card reveal ("New Sigil!"); returns when the player taps.
func show_card_reward(card_id: String) -> void:
	var overlay := CardReveal.new()
	overlay.card_id = card_id
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(overlay)
	await overlay.closed
	overlay.queue_free()


func open_menu() -> void:
	_menu.visible = true
	(_menu.get_node("Box/Resume") as Button).grab_focus()


func menu_open() -> bool:
	return _menu.visible


# ---------------------------------------------------------------- build ---

func _make_title() -> Control:
	var c := VBoxContainer.new()
	c.set_anchors_preset(Control.PRESET_CENTER_TOP)
	c.offset_left = -700
	c.offset_right = 700
	c.offset_top = 150
	c.offset_bottom = 330
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UITheme.label("", 92, UITheme.GOLD, "display_bold", 16)
	t.name = "T"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(t)
	var s := UITheme.label("", 38, UITheme.TEXT, "display", 10)
	s.name = "S"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(s)
	c.modulate.a = 0.0
	return c


func _make_menu() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -300
	box.offset_right = 300
	box.offset_top = -330
	box.offset_bottom = 330
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	dim.add_child(box)
	var head := UITheme.label("PAUSED", 56, UITheme.GOLD, "display_bold")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var info := UITheme.label("", 28, UITheme.TEXT_DIM)
	info.name = "Info"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	for pair in [["Resume", "resume", true], ["Save game", "save", false], ["Title screen", "title", false]]:
		var b := UITheme.button(pair[0], pair[2], 520)
		b.name = pair[0].replace(" ", "")
		var act: String = pair[1]
		b.pressed.connect(func() -> void:
			if act == "resume":
				dim.visible = false
			menu_action.emit(act))
		box.add_child(b)
	(box.get_node("Resume") as Button).name = "Resume"
	dim.visibility_changed.connect(func() -> void:
		if dim.visible:
			info.text = "%s  ·  %s" % [Game.player_name, "Unsworn" if Lore.GODS.get(Game.profile.get("patron", ""), {}).is_empty() else "Sworn to " + Lore.GODS[Game.profile.patron].name])
	return dim


func close_menu() -> void:
	_menu.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and _menu_btn.visible and not dialogue.visible:
		if _menu.visible:
			_menu.visible = false
		else:
			open_menu()
		get_viewport().set_input_as_handled()


# ============================================================== widgets ===

## Full-screen touch surface: drag for a floating joystick, tap to walk/talk.
class TouchPad:
	extends Control
	signal tapped(pos: Vector2)
	const RADIUS := 120.0
	var vector := Vector2.ZERO
	var _down := false
	var _drag := false
	var _start := Vector2.ZERO
	var _pos := Vector2.ZERO
	var _t0 := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func reset() -> void:
		_down = false
		_drag = false
		vector = Vector2.ZERO
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
				_drag = false
				_start = e.position
				_pos = e.position
				_t0 = Time.get_ticks_msec()
			else:
				if _down and not _drag and Time.get_ticks_msec() - _t0 < 450:
					tapped.emit(get_global_transform_with_canvas() * e.position)
				reset()
			accept_event()
		elif e is InputEventMouseMotion and _down:
			_pos = e.position
			if not _drag and _pos.distance_to(_start) > 24.0:
				_drag = true
			if _drag:
				var d := _pos - _start
				if d.length() > RADIUS:
					_start += d - d.normalized() * RADIUS
				vector = (_pos - _start) / RADIUS
				queue_redraw()
			accept_event()

	func _draw() -> void:
		if not _drag:
			return
		draw_circle(_start, RADIUS, Color(0, 0, 0, 0.22))
		draw_arc(_start, RADIUS, 0, TAU, 64, Color(1, 1, 1, 0.35), 4.0, true)
		draw_circle(_start + vector * RADIUS, 48, Color(1, 1, 1, 0.55))
		draw_arc(_start + vector * RADIUS, 48, 0, TAU, 40, Color(UITheme.GOLD, 0.8), 4.0, true)


## Big round action button.
class TalkButton:
	extends Control
	signal pressed
	var glyph := "talk"
	var _down := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
			elif _down:
				_down = false
				pressed.emit()
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 4
		if _down:
			r *= 0.94
		draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.35))
		draw_circle(c, r, Color("1a2036") if not _down else Color("2a2440"))
		draw_arc(c, r, 0, TAU, 64, UITheme.GOLD, 5.0, true)
		draw_arc(c, r - 12, 0, TAU, 64, Color(UITheme.GOLD, 0.3), 2.0, true)
		Glyphs.draw(self, glyph, c, r * 0.46, UITheme.GOLD)


## Small square icon button (menu etc).
class IconButton:
	extends Control
	signal pressed
	var glyph := "menu"
	var _down := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
			elif _down:
				_down = false
				pressed.emit()
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		CardFace.box(self, r, 18, Color(0.05, 0.06, 0.1, 0.8 if not _down else 0.95), Color(UITheme.GOLD, 0.7), 2)
		Glyphs.draw(self, glyph, size * 0.5, minf(size.x, size.y) * 0.28, UITheme.GOLD)


## "New Sigil!" overlay: the card grows in with a glow; tap to close.
class CardReveal:
	extends Control
	signal closed
	var card_id := ""
	var _t := 0.0
	var _ready_to_close := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.6:
			_ready_to_close = true
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and _ready_to_close:
			closed.emit()
			accept_event()

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("interact") and _ready_to_close:
			closed.emit()
			get_viewport().set_input_as_handled()

	func _draw() -> void:
		var k := clampf(_t / 0.5, 0.0, 1.0)
		var ease := 1.0 - pow(1.0 - k, 3.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.03, 0.75 * ease))
		var ch := minf(size.y * 0.66, 760.0)
		var cw := ch / CardFace.ASPECT
		var c := size * 0.5 + Vector2(0, -30)
		var sc := 0.6 + 0.4 * ease
		for i in 10:
			draw_circle(c, (ch * 0.62) * (1.0 - i * 0.08) * sc, Color(UITheme.GOLD, 0.035 * ease))
		var rays := 16
		for i in rays:
			var a := TAU * i / rays + _t * 0.15
			var p1 := c + Vector2(cos(a), sin(a)) * ch * 0.25
			var p2 := c + Vector2(cos(a + 0.08), sin(a + 0.08)) * ch * 0.95
			var p3 := c + Vector2(cos(a - 0.08), sin(a - 0.08)) * ch * 0.95
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(UITheme.GOLD, 0.05 * ease))
		var r := Rect2(c - Vector2(cw, ch) * 0.5 * sc, Vector2(cw, ch) * sc)
		CardFace.draw_card(self, r, card_id, {"compact": false})
		var f := CardFace.font("display_bold")
		CardFace.text(self, f, Vector2(0, r.position.y - 30), "NEW SIGIL", 52, Color(UITheme.GOLD, ease), HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0, 0, 0, 0.9 * ease))
		if _ready_to_close:
			CardFace.text(self, CardFace.font("body"), Vector2(0, r.end.y + 56), "Tap to continue", 30, Color(1, 1, 1, 0.6 + 0.3 * sin(_t * 4.0)), HORIZONTAL_ALIGNMENT_CENTER, size.x)
