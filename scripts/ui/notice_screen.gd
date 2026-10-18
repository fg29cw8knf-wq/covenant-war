class_name NoticeScreen
extends CanvasLayer
## The first thing the game shows: who made it and owns it, and a word from
## Gary about why there are adverts. The first time it waits for a tap; after
## that it moves on by itself after AUTO_SECONDS (or sooner, with a tap).

signal finished

const AUTO_SECONDS := 7.0
const MIN_SECONDS := 1.2

const OWNERSHIP := "The Covenant War: Throne of Ages, and everything in it (the story, the characters, the artwork, the music and the creatures), was created by and belongs to Gary Mannion."
const NOTE := "I want this game to stay free for everyone, so it shows a few adverts. I know they can be annoying, which is why I've kept them to a minimum. Every one you see helps fund the game and keeps new chapters coming. Thank you for playing."
const SIGN_OFF := "Gary"
const COPYRIGHT := "© 2026 Gary Mannion. All rights reserved."

var _root: Control
var _t := 0.0
var _done := false
var _first_time := true
var _continue: Button


func _ready() -> void:
	layer = 40
	_first_time = not bool(Game.settings.get("seen_notice", false))
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_finish())
	add_child(_root)

	var bg := Backdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -640
	col.offset_right = 640
	col.offset_top = -430
	col.offset_bottom = 430
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 26)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(col)

	var made := UITheme.label("CREATED BY", 26, UITheme.GOLD_DIM, "bold")
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(made)
	var name_l := UITheme.label("GARY MANNION", 78, UITheme.GOLD, "display_bold", 12)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_l)
	col.add_child(_rule())
	col.add_child(_para(OWNERSHIP, 30, UITheme.TEXT))
	var head := UITheme.label("A note from Gary", 40, UITheme.GOLD, "display_bold")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	col.add_child(_para(NOTE, 30, Color(UITheme.TEXT, 0.92)))
	var sig := UITheme.label("~ " + SIGN_OFF, 34, UITheme.GOLD, "display")
	sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sig)
	_continue = UITheme.button("Continue", true, 420)
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.pressed.connect(_finish)
	_continue.modulate.a = 0.0
	col.add_child(_continue)

	var cp := UITheme.label(COPYRIGHT, 22, Color(1, 1, 1, 0.45))
	cp.anchor_left = 0.0
	cp.anchor_right = 1.0
	cp.anchor_top = 1.0
	cp.anchor_bottom = 1.0
	cp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(cp)
	SafeArea.watch(cp, func() -> void:   # above a phone's home bar
		var b := maxf(24.0, SafeArea.insets().w)
		cp.offset_top = -40 - b
		cp.offset_bottom = -b)

	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.8)


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = Color(UITheme.GOLD, 0.5)
	r.custom_minimum_size = Vector2(520, 2)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return r


func _para(text: String, fs: int, c: Color) -> Label:
	var l := UITheme.label(text, fs, c)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1180, 0)
	return l


func _process(delta: float) -> void:
	_t += delta
	if _t > MIN_SECONDS and _continue.modulate.a == 0.0:
		create_tween().tween_property(_continue, "modulate:a", 1.0, 0.4)
		_continue.grab_focus()
	if not _first_time and _t > AUTO_SECONDS:
		_finish()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or e.is_action_pressed("menu"):
		_finish()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _done or _t < MIN_SECONDS:
		return
	_done = true
	Game.settings["seen_notice"] = true
	Game.save_settings()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.6)
	await tw.finished
	finished.emit()
	queue_free()


## Deep night, a slow gold glow and rising motes, like the title.
class Backdrop:
	extends Control
	var _t := 0.0
	var _motes: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 1171
		for i in 90:
			_motes.append(Vector4(rng.randf(), rng.randf(), rng.randf(), rng.randf()))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		CardFace.vgrad_rect(self, r, Color("0d1020"), Color("030308"))
		var c := Vector2(size.x * 0.5, size.y * 0.42)
		for i in 9:
			draw_circle(c, size.y * (0.75 - i * 0.07), Color(UITheme.GOLD, 0.012 + 0.004 * sin(_t * 0.6)))
		for m: Vector4 in _motes:
			var pos := Vector2(fmod(m.x + _t * 0.004 * (m.z - 0.5), 1.0), fmod(m.y + 1.0 - _t * 0.01 * (0.3 + m.w), 1.0)) * size
			draw_circle(pos, 1.0 + m.z * 2.2, Color(UITheme.GOLD, 0.08 + 0.25 * m.w))
