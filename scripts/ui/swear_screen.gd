class_name SwearScreen
extends Control
## The swear screen for a sworn wager in a side story (Master Script v3, How
## to read: "Sworn wagers in side stories are played once, and the story
## follows the result. The swear screen shows the opponent's duel rule and
## says 'A sworn wager. Win or lose, it stands.' with Swear now and Not yet.")
##
## It says who is across the Circle and with what deck, what each side
## stakes, and the opponent's rule. Swear now can't be pressed until the
## screen has been up a moment (a line of light runs along it), so a thumb
## tapping through the conversation can't swear by accident; Not yet (or Esc,
## or the pad's B) backs out. Swearing is recorded in the save:
## flag "wager_<id>" = "sworn" (the story sets "won" or "lost" after the
## duel) and the id is added to "wagers_sworn".
##
##   var sworn := await SwearScreen.ask(world, {
##       "id": "mercy", "title": "Under the Bridge", "opponent": "The Sergeant",
##       "deck": "The Dawn Watch", "portrait": tex,
##       "win": "He walks away.", "lose": "Anselm goes with him.",
##       "rule": ["Licensed", "The Sergeant's Rites cost nothing while ..."]})

signal answered(sworn: bool)

const OATH := "A sworn wager. Win or lose, it stands."
## How long Swear now waits before it can be pressed (seconds).
const ARM_SECS := 1.4

var info := {}
var _t := 0.0
var _armed := false
var _done := false
var _panel: Control
var _swear: Button
var _not_yet: Button
var _arm_bar: ColorRect
var _ring := 0.0
var _flash := 0.0


## Shows the screen over `parent` (the world) and returns true if the player
## swore. Records the oath in the save when they do.
static func ask(parent: Node, p_info: Dictionary) -> bool:
	var layer := CanvasLayer.new()
	layer.layer = 18
	parent.add_child(layer)
	var s := SwearScreen.new()
	s.info = p_info
	layer.add_child(s)
	var sworn: bool = await s.answered
	if sworn:
		record(String(p_info.get("id", "")))
	await s._close_out(sworn)
	layer.queue_free()
	return sworn


## Writes the oath into the save.
static func record(id: String) -> void:
	if id == "":
		return
	Game.set_flag("wager_" + id, "sworn")
	var all: Array = Array(Game.flag("wagers_sworn", [])).duplicate()
	if not all.has(id):
		all.append(id)
	Game.set_flag("wagers_sworn", all)
	Game.save_game()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	SafeArea.fit(_panel, Vector2(40, 24), true)   # clear of the island and the home bar, at the text size chosen
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(centre)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(1180, 0)
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(col)
	# what this is
	var kicker := UITheme.label("A SWORN WAGER", 28, UITheme.GOLD_DIM, "display_bold", 6)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(kicker)
	var title := UITheme.label(String(info.get("title", "")).to_upper(), 60, UITheme.GOLD, "display_bold", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	# who's across the Circle
	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 24)
	col.add_child(who)
	var face := Face.new()
	face.tex = info.get("portrait", null)
	face.custom_minimum_size = Vector2(112, 112)
	who.add_child(face)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	who.add_child(names)
	names.add_child(UITheme.label(String(info.get("opponent", "")), 42, UITheme.TEXT, "display_bold", 6))
	names.add_child(UITheme.label(String(info.get("deck", "")), 28, UITheme.TEXT_DIM, "body", 4))
	# the stakes
	var stakes := HBoxContainer.new()
	stakes.add_theme_constant_override("separation", 20)
	col.add_child(stakes)
	stakes.add_child(_card("IF YOU WIN", String(info.get("win", "")), Color("8fe0a0")))
	stakes.add_child(_card("IF YOU LOSE", String(info.get("lose", "")), Color("ff9a8a")))
	# their rule
	var rule: Array = info.get("rule", [])
	if rule.size() >= 2:
		col.add_child(_card("DUEL RULE  ·  " + String(rule[0]).to_upper(), String(rule[1]), UITheme.GOLD))
	# the oath
	var oath := UITheme.label(OATH, 40, Color(0.95, 0.92, 0.84), "display", 8)
	oath.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(oath)
	# Not yet, and Swear now (armed after a moment)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	col.add_child(row)
	_not_yet = UITheme.button("Not yet", false, 360)
	_swear = UITheme.button("Swear now", true, 420)
	_swear.disabled = true
	row.add_child(_not_yet)
	row.add_child(_swear)
	_arm_bar = ColorRect.new()
	_arm_bar.color = Color(1.0, 0.95, 0.75, 0.9)
	_arm_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arm_bar.size = Vector2(0, 5)
	_swear.add_child(_arm_bar)
	_not_yet.pressed.connect(func() -> void: _answer(false))
	_swear.pressed.connect(func() -> void:
		if _armed:
			_answer(true))
	_not_yet.grab_focus.call_deferred()


## A box with a small heading over its words.
func _card(head: String, body: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UITheme.sb(Color(0.05, 0.06, 0.1, 0.92), Color(col, 0.55), 14, 2, 22))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(UITheme.label(head, 22, col, "display_bold"))
	var b := UITheme.label(body, 28, UITheme.TEXT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	return p


func _process(delta: float) -> void:
	_t += delta
	if not _armed and not _done:
		var k := clampf(_t / ARM_SECS, 0.0, 1.0)
		_arm_bar.position = Vector2(14, _swear.size.y - 11)
		_arm_bar.size = Vector2((_swear.size.x - 28) * k, 4)
		if k >= 1.0:
			_armed = true
			_swear.disabled = false
			_arm_bar.visible = false
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	if e.is_action_pressed("menu") or e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(sworn: bool) -> void:
	if _done:
		return
	_done = true
	_swear.disabled = true
	_not_yet.disabled = true
	answered.emit(sworn)


## Swearing: the ring of light closes round the words, and the screen goes.
func _close_out(sworn: bool) -> void:
	if sworn:
		var s := Sfx.new()
		add_child(s)
		s.play("sigil_strike" if Sfx.has_file("sigil_strike") else "gift", 0.9)
		var tw := create_tween()
		tw.tween_property(self, "_ring", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "_flash", 1.0, 0.25)
		tw.tween_property(self, "_flash", 0.0, 0.45)
		await tw.finished
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.3)
	await out.finished


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.01, 0.01, 0.025, 0.86))
	# a faint ring of light behind it all, that closes when the oath is sworn
	var c := s * 0.5
	var r := minf(s.x, s.y) * (0.56 - 0.3 * _ring)
	var a := 0.12 + 0.04 * sin(_t * 2.0) + 0.6 * _ring
	draw_arc(c, r, 0, TAU, 96, Color(UITheme.GOLD, a), 3.0 + 6.0 * _ring, true)
	draw_arc(c, r + 10.0, 0, TAU, 96, Color(UITheme.GOLD, a * 0.35), 2.0, true)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1.0, 0.97, 0.88, 0.55 * _flash))


## The opponent's face in a round gold frame.
class Face:
	extends Control
	var tex: Texture2D

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color("10142a"))
		if tex != null:
			DuelArt.rounded(self, Rect2(c - Vector2(r, r) + Vector2(4, 4), Vector2(r, r) * 2.0 - Vector2(8, 8)), r - 4.0, tex)
		draw_arc(c, r - 1.5, 0, TAU, 48, Color(UITheme.GOLD, 0.85), 3.0, true)
