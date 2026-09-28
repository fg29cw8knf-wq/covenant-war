class_name DialogueBox
extends Control
## Conversation box: portrait, name plate, typed-out text and choices.
## Usage:  await box.say("Bram", portrait, "Hello")   ·   var i = await box.choose(["Yes", "No"])

signal _advance
signal _chosen(index: int)

const CHARS_PER_SEC := 55.0

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
	_layout()


func _layout() -> void:
	var w := minf(size.x - 80.0, 1560.0)
	_panel.custom_minimum_size = Vector2(w, 0)
	_panel.offset_left = -w * 0.5
	_panel.offset_right = w * 0.5
	_panel.offset_top = -330
	_panel.offset_bottom = -34
	var cw := minf(w * 0.6, 820.0)
	_choices.offset_left = -cw * 0.5 + w * 0.22
	_choices.offset_right = cw * 0.5 + w * 0.22
	_choices.offset_bottom = -350
	_choices.offset_top = -350 - _choices.get_combined_minimum_size().y


## Show a line and wait for the player to tap through it.
func say(speaker: String, portrait: Texture2D, text: String) -> void:
	visible = true
	_choices.visible = false
	_name.text = speaker
	_name.visible = speaker != ""
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null
	_text.text = text
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


## Offer choices under the current line; returns the chosen index.
func choose(options: Array) -> int:
	visible = true
	_hint.visible = false
	_text.visible_ratio = 1.0
	_typing = false
	for c in _choices.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.text = options[i]
		b.custom_minimum_size = Vector2(0, UITheme.TOUCH)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: _chosen.emit(i))
		_choices.add_child(b)
	_choices.visible = true
	_layout.call_deferred()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus.call_deferred()
	var idx: int = await _chosen
	_choices.visible = false
	return idx


func close() -> void:
	visible = false
	_choices.visible = false


func _gui_input(event: InputEvent) -> void:
	if _choices.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choices.visible:
		return
	if event.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()


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
