class_name DuelEffectTip
extends Control
## What a Totem's effects do, opened by tapping one of the badges over its
## head (DuelStatusMarks; 12 November, evening, Gary: yes to "tapping it
## could show the effect's name and what it does, like tapping a card").
## Every effect it carries, the tapped one first: its sign on its badge with
## its turns-left dots, its name in its colour, what kind it is and how long
## it lasts, and what it does. A tap anywhere closes it, as the card zoom.

signal closed

const ICONS := "res://assets/art/fx/status/"

var screen = null          # DuelScreen
var totem: DuelTotem
var focus := ""            # the effect tapped
var mine := true           # the player's own Totem (else the rival's)
var anchor := Vector2.ZERO # where the badge was tapped, to open out of
var cures := {}            # what you hold that cures which (DuelScreen._cures, this Totem's)
var t := 0.0:
	set(v):
		t = v
		_lay()

var _panel: PanelContainer
var _foot: Label
var _opened_at := 0
var _closing := false
var _fs := 28


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 130


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sr := _safe()
	_fs = int(clampf(sr.size.y * 0.03, 22.0, 46.0))
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.04, 0.08, 0.95), UITheme.GOLD_DIM, 18, 2, int(_fs * 0.9)))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(_fs * 0.7))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	var who := ("YOUR " if mine else "THEIR ") + totem.card_name().to_upper()
	var head := UITheme.label(who, int(_fs * 1.05), UITheme.GOLD, "bold", 3)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var fx: Array = DuelStatusMarks.effects_of(totem)
	if fx.has(focus):
		fx.erase(focus)
		fx.push_front(focus)
	for id in fx:
		col.add_child(_row(String(id), id == focus))
	_foot = UITheme.label("TAP ANYWHERE TO CLOSE", int(_fs * 0.8), UITheme.GOLD, "bold", 4)
	_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_foot)
	_opened_at = Time.get_ticks_msec()
	resized.connect(_lay)
	t = 0.0
	var tw := create_tween()
	tw.tween_property(self, "t", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## One effect: its badge, then its name, kind and how long, and what it does.
func _row(id: String, lead: bool) -> Control:
	var c := DuelConditions.color(id)
	var rc: Color = DuelStatusMarks.FLOOR_COL.get(id, c)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(_fs * 0.6))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := Badge.new()
	b.sign = load(ICONS + String(DuelStatusMarks.BADGES.get(id, "pip")) + ".png")
	b.col = rc
	b.total = DuelStatusMarks.pip_total(id)
	b.lit = turns_left(totem, id)
	b.custom_minimum_size = Vector2(_fs * 2.6, _fs * 3.0)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not lead:
		b.modulate = Color(1, 1, 1, 0.85)
	row.add_child(b)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", int(_fs * 0.15))
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	var nm := UITheme.label(DuelConditions.display_name(id).to_upper(), int(_fs * (1.1 if lead else 0.95)), rc.lerp(Color.WHITE, 0.25), "bold", 3)
	words.add_child(nm)
	var how := UITheme.label(lasting(totem, id), int(_fs * 0.8), UITheme.TEXT_DIM, "body")
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(how)
	var what := UITheme.label(DuelConditions.describe(id), int(_fs * (0.95 if lead else 0.85)), UITheme.TEXT, "body")
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(what)
	if cures.has(id):
		# (you hold a way to cure it: say which, and whether it's ready now)
		var cu: Dictionary = cures[id]
		var by := " or ".join(PackedStringArray(cu.get("by", [])))
		var line := ("Your %s can cure this now." if int(cu.get("level", 0)) >= 2 else "Your %s can cure this, but not just now.") % by
		var cl := UITheme.label(line, int(_fs * 0.85), UITheme.GOLD, "bold", 3)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(cl)
		b.cure = int(cu.get("level", 0))
	return row


## The turns an effect has left (Doomed: the Dawns before it falls), for
## its dots; 0 for one that lasts until cured, broken free or used up.
static func turns_left(t: DuelTotem, id: String) -> int:
	if DuelConditions.is_condition(id):
		var c: Dictionary = t.cond(DuelConditions.kind_of(id))
		if id == "doomed":
			return 3 - int(c.get("dawns", 0))
		return int(c.get("left", 0))
	if t.boons.has(id):
		return int((t.boons[id] as Dictionary).get("left", 0))
	return 0


## What kind it is and how long it lasts, in a line.
static func lasting(t: DuelTotem, id: String) -> String:
	var kind := "Boon"
	if DuelConditions.is_condition(id):
		kind = "%s condition" % DuelConditions.KIND_NAMES.get(DuelConditions.kind_of(id), "")
	var n := turns_left(t, id)
	var how := ""
	if id == "shielded":
		how = "%d shield left" % t.shield
	elif id == "doomed":
		how = "%d Dawn%s left" % [n, "" if n == 1 else "s"]
	elif DuelConditions.turns(id) > 0:
		how = "%d more turn%s" % [n, "" if n == 1 else "s"]
		if DuelConditions.breaks_free(id):
			how += ", or till it breaks free at a Dawn"
	elif DuelConditions.breaks_free(id):
		how = "Till it breaks free at a Dawn"
	elif DuelConditions.is_boon(id):
		how = "Till it's used"
	else:
		how = "Till it's cured"
	return "%s · %s" % [kind, how]


func _safe() -> Rect2:
	return screen._safe_rect() if screen != null else Rect2(Vector2.ZERO, size)


func _lay() -> void:
	if _panel == null:
		return
	var sr := _safe()
	var w := minf(sr.size.x * 0.92, _fs * 24.0)
	_panel.size = Vector2(w, 0)
	_panel.reset_size()
	_panel.size.x = w
	var ps := _panel.get_combined_minimum_size()
	var h := minf(ps.y, sr.size.y * 0.86)
	var to := Rect2(sr.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))
	var k := 0.85 + 0.15 * t
	_panel.size = to.size
	_panel.pivot_offset = to.size * 0.5
	_panel.scale = Vector2(k, k)
	var from := to.position
	if anchor != Vector2.ZERO:
		from = anchor - to.size * 0.5
	_panel.position = from.lerp(to.position, t)
	_panel.modulate.a = clampf(t * 1.5, 0.0, 1.0)
	_foot.position = Vector2(sr.position.x, minf(sr.end.y - _fs * 1.6, to.end.y + _fs * 0.8))
	_foot.size = Vector2(sr.size.x, _fs * 1.4)
	_foot.modulate.a = clampf(t * 2.0 - 1.0, 0.0, 1.0)
	queue_redraw()


func _process(_d: float) -> void:
	if screen != null and not _closing:
		if (screen.tutor != null and screen.tutor.blocking) or screen.mode == "over":
			close()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, 0.62 * t))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		if Time.get_ticks_msec() - _opened_at > 150:
			close()


func _input(e: InputEvent) -> void:
	if _closing:
		return
	var key_close: bool = e.is_action_pressed("menu") or e.is_action_pressed("interact") or e.is_action_pressed("ui_cancel") \
		or (e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_B or e.physical_keycode == KEY_ESCAPE)) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B)
	var right_click: bool = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT
	if key_close or right_click:
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	if screen != null and screen.sfx != null:
		screen.sfx.play("ui_back")
	var tw := create_tween()
	tw.tween_property(self, "t", 0.0, 0.14).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		closed.emit()
		queue_free())


## The badge as it is over the Totem's head: its sign on a dark disc in a rim
## of its colour, and its dots under it.
class Badge:
	extends Control
	var sign: Texture2D
	var col := Color.WHITE
	var total := 0
	var lit := 0
	var cure := 0   # 1: you hold a cure for it, 2: you can use it now

	func _draw() -> void:
		var r := minf(size.x, size.y * 0.8) * 0.5
		var c := Vector2(size.x * 0.5, r)
		if cure > 0:
			for k in 6:
				draw_circle(c, r * (1.0 + 0.06 * (k + 1)), Color(1.0, 0.8, 0.3, (0.16 if cure >= 2 else 0.08) * (1.0 - k / 6.0)))
		draw_circle(c, r, Color(col, 1.0))
		draw_circle(c, r * 0.86, Color(col.r * 0.16, col.g * 0.16, col.b * 0.16, 1.0))
		if sign != null:
			var s := r * 1.5
			draw_texture_rect(sign, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false, col.lerp(Color.WHITE, 0.4))
		if total > 0:
			var pr := r * 0.13
			var gap := pr * 2.8
			for k in total:
				var p := Vector2(c.x + (k - (total - 1) * 0.5) * gap, c.y + r + pr * 2.6)
				draw_circle(p, pr, Color(col.lerp(Color.WHITE, 0.3), 1.0 if k < lit else 0.22))
