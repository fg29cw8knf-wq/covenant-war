class_name DialogueBox
extends Control
## Conversation box: portrait, name plate, typed-out text and choices.
## Usage:  await box.say("Bram", portrait, "Hello")   ·   var i = await box.choose(["Yes", "No"])

signal _advance
signal _chosen(index: int)

const CHARS_PER_SEC := 55.0
## New answers ignore keys this long, so a key mashed to get through the
## last line doesn't pick one by accident.
const CHOICE_GUARD_MS := 400

var _panel: PanelContainer
var _portrait: TextureRect
var _portrait_frame: PanelContainer
var _name: Label
var _name_plate: PanelContainer
var _text: RichTextLabel
var _hint: Label
var _choices: VBoxContainer
var _typing := false
var _waiting := false
var _t := 0.0
var _choices_at := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	theme = UITheme.make()

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.04, 0.05, 0.09, 0.93), Color(UITheme.GOLD_DIM, 0.9), 22, 2, 30))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.add_theme_stylebox_override("panel", UITheme.sb(Color("1a1f33"), UITheme.GOLD_DIM, 16, 3, 0))
	_portrait_frame.custom_minimum_size = Vector2(220, 220)
	_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.custom_minimum_size = Vector2(214, 214)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_name = UITheme.label("", 34, UITheme.GOLD, "display_bold")
	col.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(0, 150)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 34)
	_text.add_theme_font_size_override("bold_font_size", 34)
	_text.add_theme_constant_override("line_separation", 6)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_text)
	_hint = UITheme.label("↓", 30, UITheme.GOLD, "bold")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 14)
	_choices.anchor_left = 0.5
	_choices.anchor_right = 0.5
	_choices.anchor_top = 1.0
	_choices.anchor_bottom = 1.0
	_choices.visible = false
	add_child(_choices)
	resized.connect(_layout)
	SafeArea.watch(self, _layout)


## The box sits low and centred in the safe area (clear of a phone's Dynamic
## Island and home bar), drawn at the player's text size (SafeArea.ui_scale());
## the whole screen still takes the taps.
func _layout() -> void:
	var m := SafeArea.insets()
	var k := SafeArea.ui_scale()
	var mid := (m.x - m.z) * 0.5
	var w := minf(size.x - m.x - m.z - 80.0, 1560.0 * k)   # as drawn
	var lift := maxf(34.0, m.w + 12.0)
	_panel.scale = Vector2(k, k)
	_panel.custom_minimum_size = Vector2(w / k, 0)
	_panel.offset_left = mid - w * 0.5
	_panel.offset_right = _panel.offset_left + w / k
	_panel.offset_top = -lift - 296.0 * k
	_panel.offset_bottom = _panel.offset_top + 296.0
	var cw := minf(w * 0.6, 820.0 * k)
	var ch := _choices.get_combined_minimum_size().y
	_choices.scale = Vector2(k, k)
	_choices.offset_left = mid - cw * 0.5 + w * 0.22
	_choices.offset_right = _choices.offset_left + cw / k
	_choices.offset_top = -lift - 296.0 * k - 20.0 - ch * k
	_choices.offset_bottom = _choices.offset_top + ch


## An instruction to the player inside a line, in brackets (Gary's rule: the
## fourth wall stays up, so "(Tap the three lines at the top right of the
## screen to open the menu.)" is in brackets after Bram's words), drawn in
## the Objective line's gold italics so it reads as the game's note, not as
## something the speaker says. A bracket that starts with one of these verbs
## is one; a character's own aside in brackets isn't touched.
static var _instruction := RegEx.create_from_string("\\((?:Tap|Press|Click|Hold|Drag|Pinch|Swipe|Walk|Use|Left|Right|Open) [^()]*\\)")


static func mark_instructions(text: String) -> String:
	return _instruction.sub(text, "[color=#%s][i]$0[/i][/color]" % UITheme.GOLD.to_html(false), true)


## Show a line and wait for the player to tap through it. `hold` > 0 (a
## recording of it playing, VoiceLines) moves it on by itself after that
## long; a tap still does.
func say(speaker: String, portrait: Texture2D, text: String, hold := -1.0) -> void:
	_bark_n += 1   # a line said over a passing remark replaces it
	_line_no += 1
	var this_line := _line_no
	if hold > 0.0:
		get_tree().create_timer(hold, false).timeout.connect(func() -> void:
			if _waiting and _line_no == this_line:
				_advance.emit())
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 1.0
	visible = true
	_choices.visible = false
	_name.text = speaker
	_name.visible = speaker != ""
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null
	_text.text = mark_instructions(text)
	_text.visible_ratio = 0.0
	_typing = true
	_waiting = true
	_hint.visible = false
	var speed: float = CHARS_PER_SEC * float(Game.settings.get("text_speed", 1.0))
	var total := maxi(1, _text.get_total_character_count())
	var dur := total / speed
	var tw := create_tween()
	tw.tween_property(_text, "visible_ratio", 1.0, dur)
	tw.finished.connect(func() -> void:
		_typing = false
		_hint.visible = true)
	await _advance
	tw.kill()
	_waiting = false


var _bark_n := 0
var _line_no := 0


## A line said in passing, while the player keeps walking (Bram following
## you to the green): it types out, stays up long enough to read and goes by
## itself. Taps and keys go straight through it to the world. Returns once
## it's gone (or a real line has replaced it).
func bark(speaker: String, portrait: Texture2D, text: String) -> void:
	_bark_n += 1
	var n := _bark_n
	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choices.visible = false
	_waiting = false
	_typing = false
	_hint.visible = false
	_name.text = speaker
	_name.visible = speaker != ""
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null
	_text.text = text
	_text.visible_ratio = 0.0
	modulate.a = 1.0
	var speed: float = CHARS_PER_SEC * float(Game.settings.get("text_speed", 1.0))
	var total := maxi(1, _text.get_total_character_count())
	var tw := create_tween()
	tw.tween_property(_text, "visible_ratio", 1.0, total / speed)
	tw.tween_interval(1.6 + total * 0.045 / maxf(0.4, float(Game.settings.get("text_speed", 1.0))))
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	await tw.finished
	if n == _bark_n:
		visible = false
		modulate.a = 1.0
		mouse_filter = Control.MOUSE_FILTER_STOP


## True while a passing remark (bark) is up.
func barking() -> bool:
	return visible and mouse_filter == Control.MOUSE_FILTER_IGNORE


## How long a line takes to type out as far as `phrase` (0 when the phrase
## is "" or not in the line), so something can happen on those words.
static func reach_secs(text: String, phrase: String) -> float:
	if phrase == "":
		return 0.0
	var plain := RegEx.create_from_string("\\[[^\\]]*\\]").sub(text, "", true)
	var i := plain.find(phrase)
	if i < 0:
		return 0.0
	return float(i) / (CHARS_PER_SEC * float(Game.settings.get("text_speed", 1.0)))


## Offer choices under the current line; returns the chosen index.
func choose(options: Array) -> int:
	_bark_n += 1
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 1.0
	visible = true
	_hint.visible = false
	_text.visible_ratio = 1.0
	_typing = false
	for c in _choices.get_children():
		_choices.remove_child(c)   # gone now, so the new first answer is child 0
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.text = options[i]
		b.custom_minimum_size = Vector2(0, UITheme.TOUCH)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: _chosen.emit(i))
		b.gui_input.connect(_on_choice_key.bind(b, i))
		_choices.add_child(b)
	_choices.visible = true
	_choices_at = Time.get_ticks_msec()
	_layout.call_deferred()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus.call_deferred()
	var idx: int = await _chosen
	_choices.visible = false
	return idx


func close() -> void:
	if barking():
		return   # a passing remark goes by itself
	visible = false
	_choices.visible = false


func _gui_input(event: InputEvent) -> void:
	if _choices.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or barking():
		return
	if _choices.visible:
		_refocus_choices(event)
		return
	if event.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()


## Keys and pads on an answer. The arrow keys, W / S, the left stick and the
## d-pad move between answers (Godot moves the focus for all but W / S);
## Enter, E or a pad's A picks the one with focus. Space never picks: it's
## the key for getting through text. Nothing picks in the answers' first
## moment either. Clicks and taps are left to the button.
func _on_choice_key(e: InputEvent, b: Button, i: int) -> void:
	if not (e is InputEventKey or e is InputEventJoypadButton or e is InputEventJoypadMotion):
		return
	if e is InputEventKey and (e.is_action("move_up") or e.is_action("move_down")) \
			and not (e.is_action("ui_up") or e.is_action("ui_down")):
		b.accept_event()
		if e.is_pressed() and not e.is_echo():
			var to := i + (1 if e.is_action("move_down") else -1)
			if to >= 0 and to < _choices.get_child_count():
				(_choices.get_child(to) as Control).grab_focus()
		return
	if not (e.is_action("interact") or e.is_action("ui_accept")):
		return
	b.accept_event()
	if not e.is_pressed() or e.is_echo():
		return
	if e is InputEventKey and (e.physical_keycode == KEY_SPACE or e.keycode == KEY_SPACE):
		return
	if Time.get_ticks_msec() - _choices_at >= CHOICE_GUARD_MS:
		_chosen.emit(i)


## The answers lost the keyboard focus (a click beside them): the next arrow,
## stick or pick key gives it back to the first answer.
func _refocus_choices(event: InputEvent) -> void:
	if _choices.get_child_count() == 0 or not event.is_pressed() or event.is_echo():
		return
	var f := get_viewport().gui_get_focus_owner()
	if f != null and f.get_parent() == _choices:
		return
	for a in ["ui_up", "ui_down", "move_up", "move_down", "interact"]:
		if event.is_action_pressed(a):
			(_choices.get_child(0) as Control).grab_focus()
			get_viewport().set_input_as_handled()
			return


func _tap() -> void:
	if not _waiting:
		return
	if _typing:
		_text.visible_ratio = 1.0
		_typing = false
		_hint.visible = true
	else:
		_advance.emit()


func _process(delta: float) -> void:
	if _hint.visible:
		_t += delta
		_hint.modulate.a = 0.55 + 0.45 * sin(_t * 5.0)
