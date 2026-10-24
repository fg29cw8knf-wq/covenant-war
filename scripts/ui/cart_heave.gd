class_name CartHeave
extends Control
## The cart off Corin (Master Script v7, P2): "Mash (E/X) repeatedly to heave
## the cart upward, then press (F/Square) at the precise moment to pull Corin
## clear." On a phone: tap HEAVE again and again, then tap PULL when the marker
## is in the gold. The meter sinks if the player stops; a pull at the wrong
## moment drops the cart back a little. It can't be failed, and it gets a
## little kinder the longer it takes.
##
##   var qte := CartHeave.open(hud._root, device, func(lift): village.set_cart_tip(1.0 - lift * 0.2))
##   await qte.done

signal done

## How much a heave lifts, how fast the cart sinks back (a second), and the
## marker's sweep (a second, there and back).
const HEAVE := 0.075
const SINK := 0.16
const SWEEP := 0.85
## The gold on the sweep bar (0..1), widening after this many seconds.
const GOLD := Vector2(0.6, 0.78)
const KIND_AFTER := 12.0
const HOW := {
	"phone": ["(Tap HEAVE again and again.)", "(Tap PULL when the marker's in the gold.)"],
	"tablet": ["(Tap HEAVE again and again.)", "(Tap PULL when the marker's in the gold.)"],
	"computer": ["(Press E again and again.)", "(Press F when the marker's in the gold.)"],
	"controller": ["(Press A again and again.)", "(Press X when the marker's in the gold.)"],
}

var device := "phone"
var lift := 0.0
var phase := "heave"
var marker := 0.0
var on_lift := Callable()
var _dir := 1.0
var _t := 0.0
var _closing := false
var _how: Label
var _meter: ColorRect
var _fill: ColorRect
var _sweep: Control
var _gold: ColorRect
var _mark: ColorRect
var _heave: Button
var _pull: Button


static func open(parent: Control, dev: String, lift_cb := Callable()) -> CartHeave:
	var q := CartHeave.new()
	q.device = dev
	q.on_lift = lift_cb
	parent.add_child(q)
	return q


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.make()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.sb(Color(0.03, 0.035, 0.07, 0.86), UITheme.GOLD_DIM, 22, 2, 24))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -430
	panel.offset_right = 430
	panel.offset_top = -330
	panel.offset_bottom = -40
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	var title := UITheme.label("Heave the cart off Corin.", 34, UITheme.GOLD, "display_bold")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_how = UITheme.label(String(HOW.get(device, HOW.phone)[0]), 26)
	_how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_how)
	# the meter: how far the cart's up
	_meter = ColorRect.new()
	_meter.color = Color(1, 1, 1, 0.08)
	_meter.custom_minimum_size = Vector2(760, 26)
	v.add_child(_meter)
	_fill = ColorRect.new()
	_fill.color = UITheme.GOLD
	_meter.add_child(_fill)
	# the sweep bar for the pull, with its gold
	_sweep = Control.new()
	_sweep.custom_minimum_size = Vector2(760, 30)
	_sweep.modulate.a = 0.25
	v.add_child(_sweep)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.1)
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sweep.add_child(track)
	_gold = ColorRect.new()
	_gold.color = Color(UITheme.GOLD, 0.55)
	_sweep.add_child(_gold)
	_mark = ColorRect.new()
	_mark.color = Color(1, 1, 1)
	_sweep.add_child(_mark)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	v.add_child(row)
	_heave = UITheme.button("HEAVE", true, 300)
	_heave.pressed.connect(heave)
	row.add_child(_heave)
	_pull = UITheme.button("PULL", false, 300)
	_pull.pressed.connect(pull)
	_pull.disabled = true
	row.add_child(_pull)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func heave() -> void:
	if _closing:
		return
	lift = minf(1.0, lift + HEAVE * (1.4 if _t > KIND_AFTER else 1.0))
	if lift >= 1.0 and phase == "heave":
		phase = "pull"
		_pull.disabled = false
		_how.text = String(HOW.get(device, HOW.phone)[1])
		create_tween().tween_property(_sweep, "modulate:a", 1.0, 0.2)


func pull() -> void:
	if _closing or phase != "pull":
		return
	var g := gold()
	if marker >= g.x and marker <= g.y:
		_closing = true
		phase = "done"
		_how.text = ""
		var tw := create_tween()
		tw.tween_interval(0.25)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		await tw.finished
		done.emit()
		queue_free()
		return
	# the wrong moment: the cart drops back a little, and it's heave again
	lift = maxf(0.0, lift - 0.28)
	phase = "heave"
	_pull.disabled = true
	_how.text = String(HOW.get(device, HOW.phone)[0])
	create_tween().tween_property(_sweep, "modulate:a", 0.25, 0.2)


## The gold, a little wider the longer it's taking.
func gold() -> Vector2:
	if _t > KIND_AFTER:
		return Vector2(GOLD.x - 0.08, GOLD.y + 0.08)
	return GOLD


func _unhandled_input(e: InputEvent) -> void:
	if _closing:
		return
	if e.is_action_pressed("interact", false):
		get_viewport().set_input_as_handled()
		heave()
	elif e.is_action_pressed("pull", false):
		get_viewport().set_input_as_handled()
		pull()


func _process(delta: float) -> void:
	_t += delta
	if phase == "heave":
		lift = maxf(0.0, lift - SINK * delta)
	elif phase == "pull":
		marker += _dir * delta / SWEEP
		if marker > 1.0:
			marker = 2.0 - marker
			_dir = -1.0
		elif marker < 0.0:
			marker = -marker
			_dir = 1.0
	if on_lift.is_valid():
		on_lift.call(lift)
	var w := _meter.size.x
	_fill.position = Vector2.ZERO
	_fill.size = Vector2(w * lift, _meter.size.y)
	var sw := _sweep.size.x
	var g := gold()
	_gold.position = Vector2(sw * g.x, 0)
	_gold.size = Vector2(sw * (g.y - g.x), _sweep.size.y)
	_mark.position = Vector2(sw * marker - 3.0, -4.0)
	_mark.size = Vector2(6.0, _sweep.size.y + 8.0)
