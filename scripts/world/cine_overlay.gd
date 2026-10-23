class_name CineOverlay
extends CanvasLayer
## The movie look for the story's cutscenes: black bars top and bottom,
## subtitles low on the screen, title cards, and the player's choices.
##
## A line stays up long enough to read and then moves on by itself, like a
## film; a tap (or E, Space, Enter, pad A) moves it on sooner. Choices wait.
##
##   var cine := CineOverlay.new(); add_child(cine)
##   await cine.bars(true)
##   await cine.say("Bram", "Inside! All of you, inside!")
##   var i := await cine.choose(["Come with us!", "We'll come back!"])
##   await cine.caption("Dawn")

signal _next
signal _chosen(index: int)

const BAR := 0.115            # each bar's height, as a share of the screen
const READ_BASE := 1.5        # seconds a line stays up at least
const READ_PER_CHAR := 0.058  # and this much longer for each letter

var _root: Control
var _top: ColorRect
var _bot: ColorRect
var _black: ColorRect
var _who: Label
var _line: RichTextLabel
var _cap: Label
var _cap_sub: Label
var _choices: VBoxContainer
var _catch: Control
var _hint: Label
var _waiting := false
var _shown_at := 0
var _line_no := 0
var _bars_on := false
## true: a line moves on by itself once it's been up long enough to read.
## false (the game since 23 October: Gary, "all text you need to have to
## click, otherwise it's going too fast"): every subtitle, narration line and
## title card stays up until it's tapped (E, Space, Enter or a pad's A too),
## the "TAP TO CONTINUE" hint after a moment. A line with a voice recording
## playing (say with `timed`) moves on when the voice ends; a tap skips it.
var auto := false


func _ready() -> void:
	layer = 14
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)
	_catch = Control.new()
	_catch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_catch.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_tap())
	_root.add_child(_catch)
	_vignette = _make_vignette()
	_top = _bar(true)
	_bot = _bar(false)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.modulate.a = 0.0
	_root.add_child(_black)
	# subtitles: a gold name over a white line, centred low, with a soft shadow
	_who = UITheme.label("", 30, UITheme.GOLD, "display_bold", 8)
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_who.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_root.add_child(_who)
	_line = RichTextLabel.new()
	_line.bbcode_enabled = true
	_line.fit_content = true
	_line.scroll_active = false
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_font_size_override("normal_font_size", 38)
	_line.add_theme_font_size_override("italics_font_size", 38)
	_line.add_theme_font_size_override("bold_font_size", 38)
	_line.add_theme_constant_override("outline_size", 10)
	_line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_line.add_theme_constant_override("line_separation", 4)
	_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_root.add_child(_line)
	_hint = UITheme.label("▸", 30, UITheme.GOLD, "bold", 8)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.modulate.a = 0.0
	_root.add_child(_hint)
	# title cards ("Dawn", "The Thornwood road")
	_cap = UITheme.label("", 72, UITheme.GOLD, "display_bold", 14)
	_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_cap.offset_left = -900
	_cap.offset_right = 900
	_cap.offset_top = -80
	_cap.offset_bottom = 10
	_cap.modulate.a = 0.0
	_root.add_child(_cap)
	_cap_sub = UITheme.label("", 34, UITheme.TEXT, "display", 10)
	_cap_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_cap_sub.offset_left = -900
	_cap_sub.offset_right = 900
	_cap_sub.offset_top = 20
	_cap_sub.offset_bottom = 80
	_cap_sub.modulate.a = 0.0
	_root.add_child(_cap_sub)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 14)
	_choices.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_choices.visible = false
	_root.add_child(_choices)
	_root.resized.connect(_layout)
	SafeArea.watch(_root, _layout)
	_hide_line()


## A film's vignette: the corners darkened a little, in with the bars and
## out with them (23 October: a touch of cinema on every renderer; the
## subtitles and the picture's middle are untouched).
var _vignette: ColorRect
const VIGNETTE := 0.42

func _make_vignette() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.25, 1.0);
	float d = length(p) * 1.5;
	float v = smoothstep(0.55, 1.25, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", 0.0)
	r.material = m
	_root.add_child(r)
	return r


func _bar(top: bool) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.0, 0.0, 0.0, 1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.anchor_top = 0.0 if top else 1.0
	r.anchor_bottom = 0.0 if top else 1.0
	_root.add_child(r)
	return r


func _bar_h() -> float:
	return _root.size.y * BAR


## Room kept clear down the right-hand side (the campfire's deck card, while
## Bram talks about the deck): the words keep to the left of it.
var keep_right := 0.0:
	set(v):
		keep_right = v
		if _root != null:
			_layout()


## The bars span the whole width; the words keep to the safe area (clear of
## a phone's Dynamic Island and home bar).
func _layout() -> void:
	var h := _bar_h()
	var k := 1.0 if _bars_on else 0.0
	_top.offset_top = -h * (1.0 - k)
	_top.offset_bottom = h * k
	_bot.offset_top = -h * k
	_bot.offset_bottom = h * (1.0 - k)
	var m := SafeArea.insets()
	var ts := SafeArea.ui_scale()   # the player's text size
	var right := maxf(m.z, keep_right)
	var mid := (m.x - right) * 0.5
	var w := minf(_root.size.x - m.x - right - 120.0, 1500.0 * ts)
	for f in ["normal_font_size", "italics_font_size", "bold_font_size"]:
		_line.add_theme_font_size_override(f, roundi(38 * ts))
	_who.add_theme_font_size_override("font_size", roundi(30 * ts))
	# the line sits on the lower bar's edge, the name just above it
	var low := maxf(h, 60.0 + m.w)
	var base := -low - 18.0
	_line.offset_left = mid - w * 0.5
	_line.offset_right = mid + w * 0.5
	_line.offset_bottom = base
	_line.offset_top = base - 150.0 * ts
	_line.size.y = 0.0
	_who.offset_left = mid - w * 0.5
	_who.offset_right = mid + w * 0.5
	_hint.offset_left = -110 - m.z
	_hint.offset_right = -60 - m.z
	_hint.offset_top = -(low + m.w) * 0.5 - 24.0
	_hint.offset_bottom = _hint.offset_top + 48.0
	var cw := minf(_root.size.x - m.x - m.z - 160.0, 900.0 * ts)
	var ch := _choices.get_combined_minimum_size().y
	_choices.scale = Vector2(ts, ts)
	_choices.offset_left = mid - cw * 0.5
	_choices.offset_right = _choices.offset_left + cw / ts
	_choices.offset_top = base - ch * ts
	_choices.offset_bottom = _choices.offset_top + ch


## Slides the black bars in (or out).
func bars(on: bool, secs := 0.7) -> void:
	_bars_on = on
	var h := _bar_h()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	if _vignette != null:
		tw.tween_method(func(k: float) -> void:
			(_vignette.material as ShaderMaterial).set_shader_parameter("strength", k), 
			float((_vignette.material as ShaderMaterial).get_shader_parameter("strength")), VIGNETTE if on else 0.0, secs)
	tw.tween_property(_top, "offset_bottom", h if on else 0.0, secs)
	tw.tween_property(_top, "offset_top", 0.0 if on else -h, secs)
	tw.tween_property(_bot, "offset_top", -h if on else 0.0, secs)
	tw.tween_property(_bot, "offset_bottom", 0.0 if on else h, secs)
	await tw.finished
	_layout()


## Black at once (true) or clear at once (false): the first frame of a film.
func black(on: bool) -> void:
	_black.modulate.a = 1.0 if on else 0.0


## Bram's element chart over the scene, until a tap.
func chart() -> void:
	var holder := StoryScreen.ChartOverlay.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(holder)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(dim)
	var ch := ElementChart.new()
	ch.set_anchors_preset(Control.PRESET_CENTER)
	ch.size = ch.custom_minimum_size
	ch.position = (_root.size - ch.size) * 0.5 - Vector2(0, 20)
	holder.add_child(ch)
	var foot := UITheme.label("TAP TO GO ON  ▸", 24, UITheme.GOLD, "bold")
	foot.position = Vector2(_root.size.x * 0.5 - 200, ch.position.y + ch.size.y + 16)
	foot.size = Vector2(400, 40)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(foot)
	holder.modulate.a = 0.0
	holder.create_tween().tween_property(holder, "modulate:a", 1.0, 0.3)
	_chart = holder
	await holder.done
	_chart = null
	holder.queue_free()


var _chart: Control = null


## The dream the player tells Bram about (P1, before the attic wakes): the
## night sky as it's seen from the bed through the attic window, full of
## stars and a thin moon, held so it's plainly the sky for about two seconds,
## then an even fade to white over the whole of it (the Sigilfall before it
## happens: no front rising from the bottom, which read on a phone as black
## going white), a beat of pure white, then the cut to black on the drum.
## `secs` is the whole: 2 s of sky, the fade, and 0.7 s of white.
func dream_sky(secs := 5.2) -> void:
	var see := 2.0
	var hold := 0.7
	var fade := maxf(secs - see - hold, 0.5)
	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float t = 0.0;      // seconds into the dream
uniform float see = 2.0;    // the sky on its own this long
uniform float fade = 2.5;   // then white comes over it in this long
uniform float aspect = 1.78;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
// stars on a grid of cells, one in a few cells lit, each its own size and twinkle
float stars(vec2 uv, float cells, float keep, float size, float tm) {
	vec2 g = uv * cells;
	vec2 i = floor(g);
	float h = hash(i);
	if (h > keep) return 0.0;
	vec2 c = vec2(hash(i + 7.1), hash(i + 3.7)) * 0.7 + 0.15;
	float d = length(fract(g) - c);
	float tw = 0.75 + 0.25 * sin(tm * (2.0 + h * 6.0) + h * 40.0);
	float core = smoothstep(size, 0.0, d);
	float glow = smoothstep(size * 3.0, 0.0, d) * 0.25;
	return (core + glow) * tw * (0.6 + h / keep * 0.4);
}
void fragment() {
	vec2 uv = UV;
	vec2 su = vec2(uv.x * aspect, uv.y);
	// a very slow drift, the way a sky turns
	vec2 duv = su + vec2(t * 0.004, t * 0.0015);
	// the night: deep blue, lighter towards the horizon at the foot of the
	// window, with a faint band of the Milky Way across it
	vec3 night = mix(vec3(0.05, 0.08, 0.2), vec3(0.14, 0.2, 0.38), uv.y * uv.y);
	float band = smoothstep(0.35, 0.0, abs((uv.y - 0.3) - (uv.x - 0.5) * 0.5)) * (0.35 + 0.65 * noise(duv * vec2(4.0, 2.5)));
	vec3 col = night + vec3(0.25, 0.28, 0.4) * band * 0.35;
	float st = stars(duv, 56.0, 0.22, 0.09, t * 3.0) * 1.1 + stars(duv + 3.3, 20.0, 0.14, 0.11, t * 2.0) * 1.5
		+ stars(duv + 9.1, 9.0, 0.12, 0.13, t * 1.3) * 1.8;
	col += vec3(0.9, 0.93, 1.0) * st;
	// a thin moon, high and to the right: a bright disc with a dark disc over it
	vec2 mc = vec2(0.74 * aspect, 0.2);
	float md = length(su - mc);
	float moon = smoothstep(0.07, 0.062, md);
	float bite = smoothstep(0.07, 0.062, length(su - mc - vec2(0.028, -0.01)));
	float crescent = clamp(moon - bite, 0.0, 1.0);
	col = mix(col, vec3(0.98, 0.97, 0.9), crescent);
	col += vec3(0.6, 0.65, 0.8) * smoothstep(0.2, 0.06, md) * 0.12;
	// the attic window round it: its dark frame at the edges and the bars
	// across the middle, so it's plainly the sky seen from the bed
	vec2 e = abs(uv - 0.5) * 2.0;
	float frame = smoothstep(0.86, 0.99, max(e.x, e.y));
	float bars = max(smoothstep(0.045, 0.02, abs(uv.x - 0.5)), smoothstep(0.045, 0.02, abs(uv.y - 0.5)));
	vec3 wood = vec3(0.09, 0.06, 0.04);
	col = mix(col, wood, max(frame, bars * 0.95));
	// the white: once the sky's been seen, it comes evenly over all of it
	float white = smoothstep(0.0, 1.0, clamp((t - see) / fade, 0.0, 1.0));
	col = mix(col, vec3(1.0), white);
	COLOR = vec4(col, 1.0);
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("see", see)
	sm.set_shader_parameter("fade", fade)
	sm.set_shader_parameter("aspect", maxf(0.5, sky.size.x / maxf(1.0, sky.size.y)) if sky.size.y > 1.0 else 1.78)
	sky.material = sm
	_root.add_child(sky)
	_root.move_child(sky, _black.get_index() + 1)
	await get_tree().process_frame
	sm.set_shader_parameter("aspect", maxf(0.5, sky.size.x / maxf(1.0, sky.size.y)))
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void: sm.set_shader_parameter("t", k), 0.0, see + fade + hold, see + fade + hold)
	await tw.finished
	sky.queue_free()
	_black.modulate.a = 1.0


## Fades to black (1) or back (0).
func fade(to_alpha: float, secs := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", to_alpha, secs)
	await tw.finished


## A subtitle. `who` "" is narration (italic, no name). Returns when it's
## been tapped on (or, `timed`, when `hold` seconds are up: a voiced line
## held for its recording, which a tap still skips).
func say(who: String, text: String, hold := -1.0, timed := false) -> void:
	_who.text = who.to_upper()
	_who.visible = who != ""
	_line.text = "[center]%s[/center]" % (text if who != "" else "[i]%s[/i]" % text)
	_place_line()
	_line.modulate.a = 0.0
	_who.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_line, "modulate:a", 1.0, 0.25)
	tw.tween_property(_who, "modulate:a", 1.0, 0.25)
	_waiting = true
	_shown_at = Time.get_ticks_msec()
	_catch.mouse_filter = Control.MOUSE_FILTER_STOP
	var speed := maxf(0.4, float(Game.settings.get("text_speed", 1.0)))
	var secs := hold if hold > 0.0 else (READ_BASE + text.length() * READ_PER_CHAR) / speed
	var timer: SceneTreeTimer = null
	_line_no += 1
	var this_line := _line_no
	if auto or timed:
		timer = get_tree().create_timer(secs, false)
		# only this line's own timer may move it on (an earlier line tapped
		# through early still has its timer running)
		timer.timeout.connect(func() -> void:
			if _waiting and _line_no == this_line:
				_next.emit())
	_hint.modulate.a = 0.0
	var ht := create_tween()
	ht.tween_interval(0.8)
	ht.tween_property(_hint, "modulate:a", 0.75, 0.4)
	await _next
	ht.kill()
	_waiting = false
	_catch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_line()


func _place_line() -> void:
	_layout()
	await get_tree().process_frame
	var lh := _line.get_content_height()
	_line.offset_top = _line.offset_bottom - lh
	_who.offset_bottom = _line.offset_top - 2.0
	_who.offset_top = _who.offset_bottom - 44.0 * SafeArea.ui_scale()


func _hide_line() -> void:
	_line.modulate.a = 0.0
	_who.modulate.a = 0.0
	_hint.modulate.a = 0.0


## The player's answer, from the choices shown low on the screen.
func choose(options: Array) -> int:
	for c in _choices.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.text = options[i]
		b.custom_minimum_size = Vector2(0, UITheme.TOUCH)
		b.pressed.connect(func() -> void: _chosen.emit(i))
		# not for the first moment, so a tap meant for the last line can't pick
		b.disabled = true
		_choices.add_child(b)
		var guard := b.create_tween()   # dies with the button if it goes first
		guard.tween_interval(0.4)
		guard.tween_property(b, "disabled", false, 0.0)
	_choices.visible = true
	_choices.modulate.a = 0.0
	create_tween().tween_property(_choices, "modulate:a", 1.0, 0.25)
	_layout.call_deferred()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus.call_deferred()
	var idx: int = await _chosen
	_choices.visible = false
	for c in _choices.get_children():
		c.queue_free()
	return idx


## A title card in the middle of the screen, over whatever is showing. It
## stays until it's tapped; `timed` (a card over a story film's picture,
## which keeps its own time) it goes after `secs`.
func caption(text: String, sub := "", secs := 2.6, timed := false) -> void:
	_cap.text = text
	_cap_sub.text = sub
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cap, "modulate:a", 1.0, 0.8)
	tw.tween_property(_cap_sub, "modulate:a", 1.0 if sub != "" else 0.0, 1.0).set_delay(0.3)
	await tw.finished
	_waiting = true
	_catch.mouse_filter = Control.MOUSE_FILTER_STOP
	_line_no += 1
	var this_line := _line_no
	if auto or timed:
		get_tree().create_timer(secs, false).timeout.connect(func() -> void:
			if _waiting and _line_no == this_line:
				_next.emit())
	_hint.modulate.a = 0.0
	var ht := create_tween()
	ht.tween_interval(0.8)
	ht.tween_property(_hint, "modulate:a", 0.75, 0.4)
	await _next
	ht.kill()
	_waiting = false
	_catch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.modulate.a = 0.0
	var out := create_tween().set_parallel(true)
	out.tween_property(_cap, "modulate:a", 0.0, 0.8)
	out.tween_property(_cap_sub, "modulate:a", 0.0, 0.8)
	await out.finished


## Asks the player's name (the Herald reads it out); returns it.
func ask_name(question: String, default_name: String) -> String:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -440
	panel.offset_right = 440
	panel.offset_top = -200
	panel.offset_bottom = 200
	panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.035, 0.07, 0.92), UITheme.GOLD_DIM, 22, 2, 30))
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var q := UITheme.label(question, 40, UITheme.GOLD, "display_bold")
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size = Vector2(780, 0)
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
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.4)
	# with a controller, start on the button (the default name), not the text
	if Input.get_connected_joypads().is_empty():
		edit.grab_focus.call_deferred()
	else:
		ok.grab_focus.call_deferred()
	var done := [false]
	ok.pressed.connect(func() -> void: done[0] = true)
	edit.text_submitted.connect(func(_t: String) -> void: done[0] = true)
	while not done[0]:
		await get_tree().process_frame
	var n := edit.text.strip_edges()
	panel.queue_free()
	return n if n != "" else default_name


## Bram's chest: the four starter decks side by side. Returns the chosen id.
func choose_deck(heading: String) -> String:
	var ids: Array = DuelCards.DECKS.keys()
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(holder)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.03, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dim)
	var head := UITheme.label(heading, 56, UITheme.GOLD, "display_bold", 10)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -800
	head.offset_right = 800
	head.offset_top = 30
	head.offset_bottom = 110
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(head)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_left = -930
	row.offset_right = 930
	row.offset_top = -400
	row.offset_bottom = 470
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	holder.add_child(row)
	var chosen := [""]
	var first_pick: Button = null
	for id in ids:
		var d: Dictionary = DuelCards.DECKS[id]
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(440, 0)
		col.add_theme_constant_override("separation", 12)
		row.add_child(col)
		var card := StoryScreen.StarterCard.new()
		card.card_id = d.mascot
		card.custom_minimum_size = Vector2(300, 420)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(card)
		var nm := UITheme.label(String(d.name).to_upper(), 40, UITheme.GOLD, "display_bold")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nm)
		var els := StoryScreen.ElementRow.new()
		els.elements = d.elements
		els.custom_minimum_size = Vector2(0, 50)
		col.add_child(els)
		var desc := UITheme.label(d.desc, 24, UITheme.TEXT)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(420, 0)
		col.add_child(desc)
		var pick := UITheme.button("Choose " + String(d.name), true, 380)
		pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var deck_id: String = id
		pick.pressed.connect(func() -> void: chosen[0] = deck_id)
		col.add_child(pick)
		if first_pick == null:
			first_pick = pick
	holder.modulate.a = 0.0
	create_tween().tween_property(holder, "modulate:a", 1.0, 0.4)
	if first_pick != null:
		first_pick.grab_focus.call_deferred()   # arrows or the d-pad move along, Enter or A picks
	while chosen[0] == "":
		await get_tree().process_frame
	holder.queue_free()
	return chosen[0]


func _tap() -> void:
	if _waiting and Time.get_ticks_msec() - _shown_at > 250:
		_next.emit()


func _unhandled_input(e: InputEvent) -> void:
	if _waiting and e.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()
	elif _chart != null and e.is_action_pressed("interact"):
		_chart.call("tap")
		get_viewport().set_input_as_handled()
