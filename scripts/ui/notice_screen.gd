class_name NoticeScreen
extends CanvasLayer
## The first thing the game shows: who made it and owns it, and a word from
## Gary about why there are adverts. It stays up until Continue is pressed
## (or the interact key / pad button, which is the same thing): no timer, and
## a tap on the page itself doesn't count, so nobody loses it to a stray
## thumb. (Until 20 October it moved on by itself after seven seconds on every
## launch but the first, and any tap dismissed it; Gary asked for it to wait.)

signal finished

const MIN_SECONDS := 1.2

const OWNERSHIP := "The Covenant War: Throne of Ages, and everything in it (the story, the characters, the artwork, the music and the creatures), was created by and belongs to Gary Mannion."
const NOTE := "I want this game to stay free for everyone, so it shows a few adverts. I know they can be annoying, which is why I've kept them to a minimum. Every one you see helps fund the game and keeps new chapters coming. Thank you for playing."
const SIGN_OFF := "Gary"
const COPYRIGHT := "© 2026 Gary Mannion. All rights reserved."

var _root: Control
var _t := 0.0
var _done := false
var _continue: Button


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.make()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # (swallows taps; only Continue moves on)
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
	# drawn at the player's text size (Options), as big as fits in the safe
	# area (clear of a phone's Dynamic Island and home bar), centred in it
	SafeArea.watch(col, func() -> void:
		var r := SafeArea.rect()
		r.position.y += 16.0
		r.size.y -= 16.0 + 64.0   # (the copyright line at the foot)
		var need := col.get_combined_minimum_size()
		var w := maxf(need.x, 1280.0)
		var h := maxf(need.y, 1.0)
		var k := minf(SafeArea.ui_scale(), minf((r.size.x - 40.0) / w, r.size.y / h))
		col.pivot_offset = Vector2(w, h) * 0.5
		col.scale = Vector2(k, k)
		var c := r.get_center() - SafeArea.screen().get_center()
		col.offset_left = -w * 0.5 + c.x
		col.offset_right = w * 0.5 + c.x
		col.offset_top = -h * 0.5 + c.y
		col.offset_bottom = h * 0.5 + c.y)

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


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact"):   # a keyboard's or a pad's Continue
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
