class_name WorldHUD
extends CanvasLayer
## Everything drawn over the walkable world: the touch pad (drag = joystick,
## tap = walk there / talk, pinch or wheel = zoom), the Talk button, the zoom
## buttons, the pause menu (PauseMenu), the area title, the dialogue box,
## reward pop-ups and screen fades. The buttons and words sit inside the
## screen's safe area (SafeArea), clear of a phone's Dynamic Island and home
## bar; the pad, the vignette and the fades cover the whole screen.

signal talk_pressed
signal menu_action(action: String)
signal tapped(viewport_pos: Vector2)
## The camera's distance times `factor` (under 1 comes closer): a pinch, the
## wheel, a trackpad, or the + / - buttons.
signal zoom_by(factor: float)

## How far one tap of + or - zooms.
const ZOOM_STEP := 0.8

var pad: TouchPad
var dialogue: DialogueBox
var _root: Control
var _safe: Control         # the safe area: everything to read or tap goes in here
var _talk: TalkButton
var _talk_name: Label
var _menu_btn: IconButton
var _zoom_in: IconButton
var _zoom_out: IconButton
var _menu: Control
var _title: Control
var _fade: ColorRect
var _toast: Label
var _hint: PanelContainer
var _objective: Label
var _objective_tw: Tween
var _hint_text := ""       # the current first-steps hint; hidden while the controls are
## The way to where the objective is (set_way): a marker over the place when
## it's on screen, an arrow at the screen's edge pointing to it when not.
var way: WayMarker


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
	pad.zoomed.connect(func(f: float) -> void: zoom_by.emit(f))
	_root.add_child(pad)

	_safe = Control.new()
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_safe)
	SafeArea.fit(_safe, Vector2.ZERO, true)   # at the player's text and buttons size

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
	_safe.add_child(_talk)
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
	_safe.add_child(_talk_name)

	_menu_btn = IconButton.new()
	_menu_btn.glyph = "menu"
	_menu_btn.anchor_left = 1.0
	_menu_btn.anchor_right = 1.0
	_menu_btn.offset_left = -150
	_menu_btn.offset_right = -40
	_menu_btn.offset_top = 36
	_menu_btn.offset_bottom = 146
	_menu_btn.pressed.connect(open_menu)
	_safe.add_child(_menu_btn)

	# zoom: + over -, small, at the right-hand edge halfway down
	_zoom_in = _zoom_button("plus", -112, ZOOM_STEP)
	_zoom_out = _zoom_button("minus", 16, 1.0 / ZOOM_STEP)

	# the toast stays a child of the root (the pack tour lifts it over itself)
	_toast = UITheme.label("", 34, UITheme.GOLD, "display_bold", 10)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	SafeArea.watch(_toast, func() -> void:
		var m := SafeArea.insets()
		var k := SafeArea.ui_scale()
		var mid := (m.x - m.z) * 0.5
		var w := minf(700.0 * k, SafeArea.rect().size.x * 0.5 - 20.0)
		_toast.add_theme_font_size_override("font_size", roundi(34 * k))
		_toast.offset_left = mid - w
		_toast.offset_right = mid + w
		_toast.offset_top = m.y + 60 * k
		_toast.offset_bottom = m.y + 120 * k)

	_title = _make_title()
	_safe.add_child(_title)

	# first-steps hints ("Tap the ground to walk"), bottom centre
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.85), UITheme.GOLD_DIM, 20, 2, 18))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -440
	_hint.offset_right = 440
	_hint.offset_top = -170
	_hint.offset_bottom = -90
	_hint.modulate.a = 0.0
	_hint.visible = false
	var hl := UITheme.label("", 30, UITheme.TEXT, "bold")
	hl.name = "Text"
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_child(hl)
	_safe.add_child(_hint)
	# the current objective, top left
	way = WayMarker.new()
	way.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	way.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(way)
	_objective = UITheme.label("", 30, UITheme.GOLD, "bold", 10)
	_objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective.offset_left = 36
	_objective.offset_top = 28
	_objective.offset_right = 1100
	_objective.offset_bottom = 70
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.modulate.a = 0.0
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(_objective)

	dialogue = DialogueBox.new()
	_root.add_child(dialogue)

	_menu = PauseMenu.new()
	_menu.action.connect(func(what: String) -> void: menu_action.emit(what))
	_root.add_child(_menu)
	# "Tilly will remember that."
	Game.standing_changed.connect(func(who: String, by: int, _why: String) -> void:
		if by != 0:
			toast("%s will remember that." % Standing.display_name(who)))
	# "New in your pack: Deck and Codex"
	Game.feature_unlocked.connect(_on_feature_unlocked)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_root.add_child(_fade)
	# the fade sits under the dialogue, so lines can play over black (the vault, the end of a chapter)
	_root.move_child(_fade, dialogue.get_index())


# --------------------------------------------------------------- public ---

func set_talk_target(npc_name: String, duel: bool) -> void:
	var show := npc_name != ""
	_talk.visible = show
	_talk_name.visible = show
	_talk_name.text = npc_name
	_talk.glyph = "duel" if duel else "talk"
	_talk.queue_redraw()


## True while the round Talk button is up: someone is in reach and the
## player is free to move.
func talk_showing() -> bool:
	return _talk.visible and pad.visible


func set_controls_visible(v: bool) -> void:
	pad.visible = v
	_menu_btn.visible = v
	_zoom_in.visible = v
	_zoom_out.visible = v
	if not v:
		_talk.visible = false
		_talk_name.visible = false
	pad.reset()
	# the first-steps hint and the objective step aside for talking and cutscenes
	_hint.visible = v and _hint_text != ""
	_hint.modulate.a = 1.0 if _hint.visible else 0.0
	if _objective_tw != null and _objective_tw.is_valid():
		_objective_tw.kill()
	_objective.modulate.a = 1.0 if v and _objective.text != "" else 0.0
	way.shown = v


## The current task, shown top left while the player is free to move; "" clears it.
## While the controls are hidden (talking, cutscenes) it waits, and
## set_controls_visible shows it again.
func set_objective(text: String) -> void:
	if _objective_tw != null and _objective_tw.is_valid():
		_objective_tw.kill()
	_objective.text = text
	if not pad.visible:
		_objective.modulate.a = 0.0
		return
	_objective_tw = create_tween()
	_objective_tw.tween_property(_objective, "modulate:a", 1.0 if text != "" else 0.0, 0.4)


## The way to a place (29 October, Gary: "It's not clear for players how to
## get to Tam's mill"): `at` in the world, seen through `cam`, called
## `label`; null (or "" for the label) takes it away. Shown only while the
## player is free to move.
func set_way(cam: Camera3D, at: Variant, label := "") -> void:
	if at == null or label == "":
		way.target = Vector3.INF
		way.queue_redraw()
		return
	way.cam = cam
	way.target = at
	way.label = label


func show_area_title(title: String, subtitle: String) -> void:
	(_title.get_node("T") as Label).text = title.to_upper()
	(_title.get_node("S") as Label).text = subtitle
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.2)
	tw.tween_property(_title, "modulate:a", 0.0, 1.0)


## A standing instruction for new players; "" hides it.
func show_hint(text: String) -> void:
	_hint_text = text
	if text == "":
		if _hint.visible:
			var tw := create_tween()
			tw.tween_property(_hint, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func() -> void: _hint.visible = false)
		return
	(_hint.get_node("Text") as Label).text = text
	_hint.visible = true
	var tw2 := create_tween()
	tw2.tween_property(_hint, "modulate:a", 1.0, 0.4)


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


func open_menu(at_tab: String = "") -> void:
	(_menu as PauseMenu).open(at_tab)


func menu_open() -> bool:
	return _menu.visible


# ------------------------------------------------------------ the pack ---

var _unlocked_now: Array = []


## Parts of the pack opened in the same moment share one toast.
func _on_feature_unlocked(feature: String) -> void:
	if _unlocked_now.is_empty():
		_toast_unlocks.call_deferred()
	_unlocked_now.append(feature)


func _toast_unlocks() -> void:
	var names: Array = _unlocked_now.map(func(f): return String(Game.FEATURES.get(f, String(f).capitalize())))
	_unlocked_now = []
	if names.is_empty():
		return
	var said: String = names[-1] if names.size() == 1 else ", ".join(names.slice(0, -1)) + " and " + String(names[-1])
	toast("New in your pack: %s" % said)


## Bram's gated tour of the pack (PackTour), right after he hands over the
## first deck: each line waits for the player, and nothing else works until
## it's done (no walking, talking or other taps). Steps default to
## PackTour.FIRST_DECK. A tab the tour needs is unlocked if it isn't yet.
func pack_tour(steps: Array = []) -> void:
	var w := get_parent() as World
	var was_busy := w.busy if w != null else false
	if w != null:
		w.busy = true
	var keep := {"menu": _menu_btn.visible, "talk": _talk.visible, "talk_name": _talk_name.visible}
	dialogue.close()
	pad.reset()
	_talk.visible = false
	_talk_name.visible = false
	_menu_btn.visible = true   # the pack has to be there to be tapped
	var tour := PackTour.new()
	_root.add_child(tour)
	var toast_at := _toast.get_index()
	_root.move_child(_toast, _root.get_child_count() - 1)   # "New in your pack" shows over the tour
	await tour.run(self, steps if not steps.is_empty() else PackTour.FIRST_DECK)
	_root.move_child(_toast, toast_at)
	tour.queue_free()
	_menu_btn.visible = keep.menu
	_talk.visible = keep.talk
	_talk_name.visible = keep.talk_name
	if w != null and is_instance_valid(w):
		w.busy = was_busy


# ---------------------------------------------------------------- build ---

## A small + or - at the right-hand edge, `top` below the middle of the screen.
func _zoom_button(glyph: String, top: float, factor: float) -> IconButton:
	var b := IconButton.new()
	b.glyph = glyph
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 0.5
	b.anchor_bottom = 0.5
	b.offset_left = -136
	b.offset_right = -40
	b.offset_top = top
	b.offset_bottom = top + 96
	b.pressed.connect(func() -> void: zoom_by.emit(factor))
	_safe.add_child(b)
	return b


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


func close_menu() -> void:
	_menu.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _menu.visible or not visible:
		return   # the pause menu handles its own keys; nothing while a duel is up
	if event.is_action_pressed("menu") and _menu_btn.visible and (not dialogue.visible or dialogue.barking()):
		open_menu()
		get_viewport().set_input_as_handled()


# ============================================================== widgets ===

## Full-screen touch surface: drag for a floating joystick, tap to walk/talk;
## two fingers pinch to zoom, as do the mouse wheel and a trackpad.
class TouchPad:
	extends Control
	signal tapped(pos: Vector2)
	## The camera's distance times this (under 1 comes closer).
	signal zoomed(factor: float)
	const RADIUS := 120.0
	## One notch of a mouse wheel.
	const WHEEL_STEP := 0.9
	var vector := Vector2.ZERO
	var _down := false
	var _drag := false
	var _start := Vector2.ZERO
	var _pos := Vector2.ZERO
	var _t0 := 0
	var _touches := {}          # finger index -> where it is
	var _pinch := 0.0           # how far apart two fingers were (0: not pinching)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func reset() -> void:
		_down = false
		_drag = false
		vector = Vector2.ZERO
		_touches.clear()
		_pinch = 0.0
		queue_redraw()

	## The distance between the first two fingers down.
	func _spread() -> float:
		var ps: Array = _touches.values()
		return (ps[0] as Vector2).distance_to(ps[1]) if ps.size() >= 2 else 0.0

	func _gui_input(e: InputEvent) -> void:
		# two fingers: a pinch, which also lets go of the joystick (and the tap)
		if e is InputEventScreenTouch:
			if e.pressed:
				_touches[e.index] = e.position
			else:
				_touches.erase(e.index)
			if _touches.size() >= 2:
				_down = false
				_drag = false
				vector = Vector2.ZERO
				_pinch = _spread()
				queue_redraw()
			else:
				_pinch = 0.0
			accept_event()
			return
		if e is InputEventScreenDrag:
			if _touches.has(e.index):
				_touches[e.index] = e.position
			if _pinch > 0.0 and _touches.size() >= 2:
				var d := _spread()
				if d > 8.0:
					zoomed.emit(_pinch / d)   # fingers apart: closer
					_pinch = d
			accept_event()
			return
		if e is InputEventMagnifyGesture:   # a Mac trackpad's pinch
			if e.factor > 0.0:
				zoomed.emit(1.0 / e.factor)
			accept_event()
			return
		if e is InputEventPanGesture:   # two fingers sliding on a trackpad: like the wheel
			zoomed.emit(exp(clampf(e.delta.y, -4.0, 4.0) * 0.08))
			accept_event()
			return
		if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var notches: float = e.factor if e.factor > 0.0 else 1.0
			zoomed.emit(pow(WHEEL_STEP, notches if e.button_index == MOUSE_BUTTON_WHEEL_UP else -notches))
			accept_event()
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if _touches.size() >= 2:
				accept_event()   # the first finger of a pinch, lifting: not a tap
				return
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
		elif e is InputEventMouseMotion and _down and _touches.size() < 2:
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


## The way to the objective's place (set_way): over the place itself, a gold
## marker bobbing above it with its name and how far; when it's off the
## screen (or behind the camera), a gold arrow at the edge, pointing the way
## to turn, with the name beside it.
class WayMarker:
	extends Control
	var cam: Camera3D
	var target := Vector3.INF
	var label := ""
	var shown := true
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if target != Vector3.INF:
			queue_redraw()

	func _draw() -> void:
		if not shown or target == Vector3.INF or cam == null or not is_instance_valid(cam) or not cam.is_inside_tree():
			return
		var k := SafeArea.ui_scale()
		var vp := get_viewport_rect().size
		var over := target + Vector3(0, 2.3, 0)
		var behind := cam.is_position_behind(over)
		var sp := cam.unproject_position(over)
		var dist := cam.global_position.distance_to(target)
		var gold := Color(1.0, 0.82, 0.38)
		var dark := Color(0.06, 0.04, 0.02, 0.75)
		var font := CardFace.font("bold")
		var fs := roundi(34 * k)
		var margin := 110.0 * k
		# (clear of the objective at the top and the hints and buttons at the
		# foot and the right)
		var inner := Rect2(Vector2(margin, margin * 2.4), vp - Vector2(margin * 2.6, margin * 4.2))
		if not behind and inner.has_point(sp):
			# over the place: a diamond bobbing, its name and how far under it
			var bob := sin(_t * 3.0) * 8.0 * k
			var c := sp + Vector2(0, bob)
			var r := 34.0 * k
			var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)])
			draw_colored_polygon(pts, dark)
			var pin := PackedVector2Array([c + Vector2(0, -r * 0.7), c + Vector2(r * 0.48, 0), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.48, 0)])
			draw_colored_polygon(pin, gold)
			draw_line(c + Vector2(0, r), sp + Vector2(0, r + 26.0 * k), Color(gold, 0.6), 2.0 * k)
			var words := "%s  ·  %d m" % [label, roundi(dist)]
			var ts := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var at := c + Vector2(-ts.x * 0.5, -r - 14.0 * k)
			draw_rect(Rect2(at + Vector2(-10 * k, -ts.y + 4 * k), Vector2(ts.x + 20 * k, ts.y + 6 * k)), dark)
			draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, gold)
			return
		# off the screen: an arrow at its edge, the way to turn
		var mid := vp * 0.5
		var d := sp - mid
		if behind:
			d = -d
			if d.length() < 1.0:
				d = Vector2(0, 1)
		d = d.normalized()
		# where the line from the middle along d meets the inner rect
		var tx := INF
		var ty := INF
		if absf(d.x) > 0.001:
			tx = ((inner.end.x if d.x > 0 else inner.position.x) - mid.x) / d.x
		if absf(d.y) > 0.001:
			ty = ((inner.end.y if d.y > 0 else inner.position.y) - mid.y) / d.y
		var p := mid + d * minf(tx, ty)
		var pulse := 1.0 + 0.12 * sin(_t * 4.0)
		var r2 := 56.0 * k * pulse
		draw_circle(p, r2 * 1.35, Color(gold, 0.16 + 0.08 * sin(_t * 4.0)))
		var perp := Vector2(-d.y, d.x)
		var tip := p + d * r2
		var tri := PackedVector2Array([tip, p - d * r2 * 0.6 + perp * r2 * 0.8, p - d * r2 * 0.25, p - d * r2 * 0.6 - perp * r2 * 0.8])
		draw_colored_polygon(PackedVector2Array([tip + d * 4 * k, p - d * r2 * 0.75 + perp * r2, p - d * r2 * 0.3, p - d * r2 * 0.75 - perp * r2]), dark)
		draw_colored_polygon(tri, gold)
		var words2 := "%s  ·  %d m" % [label, roundi(dist)]
		var ts2 := font.get_string_size(words2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var lp := p - d * (r2 + 22.0 * k) - Vector2(ts2.x * 0.5, -ts2.y * 0.35)
		lp.x = clampf(lp.x, 12.0 * k, vp.x - ts2.x - 12.0 * k)
		lp.y = clampf(lp.y, ts2.y + 12.0 * k, vp.y - 12.0 * k)
		draw_rect(Rect2(lp + Vector2(-10 * k, -ts2.y + 4 * k), Vector2(ts2.x + 20 * k, ts2.y + 6 * k)), dark)
		draw_string(font, lp, words2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, gold)
