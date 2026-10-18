class_name DeckBoxes
extends CanvasLayer
## Bram's four old decks set out in a row (v3, the campfire): "Choose your
## deck. (Tap a box to see it. Tap again to choose.)" The boxes are 3D nodes
## in the scene; this takes the taps (and the keys: left and right move along,
## E / Space / Enter or pad A taps), shows the objective, and a card for the
## deck being looked at. The film says Bram's lines.
##
##   var picker := DeckBoxes.new(); w.add_child(picker)
##   picker.setup(w.cam, boxes, ids)
##   var r: Dictionary = await picker.tapped      # {"index": i, "again": bool}
##   picker.show_deck(i) / picker.hide_deck() / picker.finish()

signal tapped(result: Dictionary)

const OBJECTIVE := "Choose your deck. (Tap a box to see it. Tap again to choose.)"

var cam: Camera3D
var boxes: Array = []        # Node3D, one per deck
var ids: Array = []          # deck ids, in the same order
var seen := -1               # the box last tapped (shown)
var focus := 0               # the box keys would tap
var listening := false       # taps are taken only between Bram's lines
var _root: Control
var _catch: Control
var _objective: Label
var _info: PanelContainer
var _glow: OmniLight3D
var _t := 0.0


func setup(p_cam: Camera3D, p_boxes: Array, p_ids: Array) -> DeckBoxes:
	cam = p_cam
	boxes = p_boxes
	ids = p_ids
	return self


func _ready() -> void:
	layer = 13   # under the film's subtitles (14), over the world
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)
	_catch = Control.new()
	_catch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catch.mouse_filter = Control.MOUSE_FILTER_STOP
	_catch.gui_input.connect(_on_input)
	_root.add_child(_catch)
	# the objective, top left, like the world's own
	_objective = UITheme.label(OBJECTIVE, roundi(30 * SafeArea.ui_scale()), UITheme.GOLD, "bold", 10)
	_objective.position = Vector2(40, 96)
	_objective.size = Vector2(1100, 50)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_objective)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.85, 0.55)
	_glow.light_energy = 0.0
	_glow.omni_range = 1.4


## Taps are listened for until the next one; returns {"index", "again"}.
func listen() -> void:
	listening = true


func _on_input(e: InputEvent) -> void:
	if not listening:
		return
	var pos := Vector2(-1, -1)
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
	if pos.x < 0:
		return
	var i := box_at(pos)
	if i >= 0:
		tap(i)


## Which box is under a point on the screen (-1 for none): the nearest box
## centre to the tap, within reach.
func box_at(pos: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in boxes.size():
		var b: Node3D = boxes[i]
		if cam.is_position_behind(b.global_position):
			continue
		var sp := cam.unproject_position(b.global_position + Vector3(0, 0.05, 0))
		var d := sp.distance_to(pos)
		# how big a box looks: its width on screen, generously
		var edge := cam.unproject_position(b.global_position + cam.global_transform.basis.x * 0.16)
		var reach := maxf(60.0, sp.distance_to(edge) * 1.6)
		if d < reach and d < best_d:
			best_d = d
			best = i
	return best


## Taps box i: the first time (or another box) it's shown; the same box
## again chooses it.
func tap(i: int) -> void:
	if not listening or i < 0 or i >= boxes.size():
		return
	listening = false
	focus = i
	var again := i == seen
	seen = i
	tapped.emit({"index": i, "again": again})


func _unhandled_input(e: InputEvent) -> void:
	if not listening:
		return
	if e.is_action_pressed("ui_left") or e.is_action_pressed("move_left"):
		focus = posmod(focus - 1, boxes.size())
		_mark(focus)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("ui_right") or e.is_action_pressed("move_right"):
		focus = posmod(focus + 1, boxes.size())
		_mark(focus)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		tap(focus)


## A warm light on the box the keys are on (or the one being looked at).
func _mark(i: int) -> void:
	if i < 0 or i >= boxes.size():
		return
	var b: Node3D = boxes[i]
	if _glow.get_parent() != null:
		_glow.get_parent().remove_child(_glow)
	b.add_child(_glow)
	_glow.position = Vector3(0, 0.35, 0.1)
	_glow.light_energy = 1.4


## The card for deck i, at the side of the screen: its mascot, its name, its
## elements and what it's like.
func show_deck(i: int) -> void:
	hide_deck()
	_mark(i)
	var d: Dictionary = DuelCards.DECKS[ids[i]]
	_info = PanelContainer.new()
	_info.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.035, 0.07, 0.9), UITheme.GOLD_DIM, 20, 2, 22))
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.add_child(col)
	var card := StoryScreen.StarterCard.new()
	card.card_id = d.mascot
	card.custom_minimum_size = Vector2(250, 350)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(card)
	var nm := UITheme.label(String(d.name).to_upper(), 36, UITheme.GOLD, "display_bold")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(nm)
	var els := StoryScreen.ElementRow.new()
	els.elements = d.elements
	els.custom_minimum_size = Vector2(0, 46)
	els.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(els)
	var desc := UITheme.label(d.desc, 22, UITheme.TEXT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(330, 0)
	col.add_child(desc)
	_root.add_child(_info)
	_info.reset_size()
	# drawn at the player's text size (Options: Text and buttons size), as
	# much of it as fits between the film's bars
	var vs := _root.get_viewport_rect().size
	var m := SafeArea.insets()
	var room := vs.y * (1.0 - 2.0 * CineOverlay.BAR) - 24.0
	var k := clampf(room / maxf(1.0, _info.size.y), 0.7, SafeArea.ui_scale())
	_info.scale = Vector2(k, k)
	var sz := _info.size * k
	_info.position = Vector2(vs.x - m.z - sz.x - 48, maxf(vs.y * CineOverlay.BAR + 12.0, (vs.y - sz.y) * 0.42))
	_info.modulate.a = 0.0
	create_tween().tween_property(_info, "modulate:a", 1.0, 0.3)


func hide_deck() -> void:
	if _info != null and is_instance_valid(_info):
		_info.queue_free()
	_info = null


## Done: the objective and the card go, and the boxes stop listening.
func finish() -> void:
	listening = false
	hide_deck()
	if _glow.get_parent() != null:
		_glow.get_parent().remove_child(_glow)
	_glow.queue_free()
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	if _glow != null and is_instance_valid(_glow) and _glow.get_parent() != null:
		_glow.light_energy = 1.2 + 0.3 * sin(_t * 3.0)
	_objective.modulate.a = 1.0 if listening or _info != null else 0.7
	# just under the film's top bar, whatever the screen, clear of a phone's
	# notch and rounded corners
	var vs := _root.get_viewport_rect().size
	var m := SafeArea.insets()
	_objective.position = Vector2(40.0 + m.x, maxf(vs.y * CineOverlay.BAR, m.y) + 14.0)
	_objective.size.x = minf(1100.0, vs.x - 80.0 - m.x - m.z)
