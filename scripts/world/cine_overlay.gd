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
var _bars_on := false
## false: every line waits for a tap (for tests, or a player who reads slowly)
var auto := true


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
	_layout()
	_hide_line()


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


func _layout() -> void:
	var h := _bar_h()
	var k := 1.0 if _bars_on else 0.0
	_top.offset_top = -h * (1.0 - k)
	_top.offset_bottom = h * k
	_bot.offset_top = -h * k
	_bot.offset_bottom = h * (1.0 - k)
	var w := minf(_root.size.x - 120.0, 1500.0)
	# the line sits on the lower bar's edge, the name just above it
	var base := -maxf(h, 60.0) - 18.0
	_line.offset_left = -w * 0.5
	_line.offset_right = w * 0.5
	_line.offset_bottom = base
	_line.offset_top = base - 150.0
	_line.size.y = 0.0
	_who.offset_left = -w * 0.5
	_who.offset_right = w * 0.5
	_hint.offset_left = -110
	_hint.offset_right = -60
	_hint.offset_top = -maxf(h, 60.0) * 0.5 - 24.0
	_hint.offset_bottom = _hint.offset_top + 48.0
	var cw := minf(_root.size.x - 160.0, 900.0)
	_choices.offset_left = -cw * 0.5
	_choices.offset_right = cw * 0.5
	_choices.offset_bottom = base
	_choices.offset_top = base - _choices.get_combined_minimum_size().y


## Slides the black bars in (or out).
func bars(on: bool, secs := 0.7) -> void:
	_bars_on = on
	var h := _bar_h()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
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


## Fades to black (1) or back (0).
func fade(to_alpha: float, secs := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", to_alpha, secs)
	await tw.finished


## A subtitle. `who` "" is narration (italic, no name). Returns when it's been
## read (or tapped on). `hold` overrides how long it stays up.
func say(who: String, text: String, hold := -1.0) -> void:
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
	if auto:
		timer = get_tree().create_timer(secs)
		timer.timeout.connect(func() -> void:
			if _waiting:
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
	_who.offset_top = _who.offset_bottom - 44.0


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
		_choices.add_child(b)
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


## A title card in the middle of the screen, over whatever is showing.
func caption(text: String, sub := "", secs := 2.6) -> void:
	_cap.text = text
	_cap_sub.text = sub
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cap, "modulate:a", 1.0, 0.8)
	tw.tween_property(_cap_sub, "modulate:a", 1.0 if sub != "" else 0.0, 1.0).set_delay(0.3)
	tw.chain().tween_interval(secs)
	tw.chain().set_parallel(true)
	tw.tween_property(_cap, "modulate:a", 0.0, 0.8)
	tw.tween_property(_cap_sub, "modulate:a", 0.0, 0.8)
	await tw.finished


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
	edit.grab_focus.call_deferred()
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
	holder.modulate.a = 0.0
	create_tween().tween_property(holder, "modulate:a", 1.0, 0.4)
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
