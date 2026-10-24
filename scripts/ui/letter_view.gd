class_name LetterView
extends Control
## A letter held up to the screen to read (Tam's note from Ironvault): a
## folded-open sheet with the words written on it and the wax seal, a coin
## crossed with a key, at the foot. A tap (or E / Space / Enter / a pad's A)
## puts it down once it's had a moment to be read.
##
##   await LetterView.read(hud._root, LetterView.TAM)

signal closed

## Tam's letter, word for word (Master Script v3, P1 · Tam and the note).
## Master Script v7: a demand of foreclosure, in legal script, with a dark
## red wax seal.
const TAM := "To T. Hayes, miller, of Ashford.\n\nDemand of foreclosure: seventy crowns for seed-barley, with three winters' interest, now four hundred crowns, due at midnight tonight. If unpaid, the millwheel and water rights revert to Ironvault.\n\nIronvault thanks you for your custom."

var body := ""
var _t := 0.0
var _ready_at := 1.2
var _done := false


static func read(parent: Control, text: String) -> void:
	var lv := LetterView.new()
	lv.body = text
	parent.add_child(lv)
	await lv.closed
	var tw := lv.create_tween()
	tw.tween_property(lv, "modulate:a", 0.0, 0.35)
	tw.tween_callback(lv.queue_free)
	await tw.finished


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		_close()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _done or _t < _ready_at:
		return
	_done = true
	closed.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.01, 0.01, 0.02, 0.62))
	var h := minf(s.y * 0.86, 900.0)
	var w := minf(h * 0.78, s.x - 80.0)
	var r := Rect2((s - Vector2(w, h)) * 0.5 + Vector2(0, -10), Vector2(w, h))
	# the sheet: warm paper, darker at the edges, the fold across the middle
	CardFace.box(self, r, 6, Color(0.86, 0.8, 0.66), Color(0.55, 0.45, 0.3), 2, 18, Color(0, 0, 0, 0.6), Vector2(0, 8))
	for i in 6:
		draw_rect(r.grow(-i * 6.0), Color(0.45, 0.33, 0.18, 0.05), false, 6.0)
	var fold := r.position.y + r.size.y * 0.5
	draw_line(Vector2(r.position.x + 8, fold), Vector2(r.end.x - 8, fold), Color(0.5, 0.4, 0.26, 0.35), 2.0)
	draw_line(Vector2(r.position.x + 8, fold + 2), Vector2(r.end.x - 8, fold + 2), Color(1, 1, 1, 0.12), 1.0)
	# the words, in a clerk's hand (the display face, dark ink)
	var f := CardFace.font("display")
	var size_px := int(clampf(w / 19.0, 22.0, 40.0))
	var margin := w * 0.11
	var y := r.position.y + h * 0.12
	var ink := Color(0.16, 0.11, 0.07)
	for para in body.split("\n"):
		if para == "":
			y += size_px * 0.6
			continue
		var words := para.split(" ")
		var line := ""
		for word in words:
			var trial := word if line == "" else line + " " + word
			if f.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > w - margin * 2.0 and line != "":
				CardFace.text(self, f, Vector2(r.position.x + margin, y + size_px), line, size_px, ink)
				y += size_px * 1.45
				line = word
			else:
				line = trial
		if line != "":
			CardFace.text(self, f, Vector2(r.position.x + margin, y + size_px), line, size_px, ink)
			y += size_px * 1.45
	# the seal: red wax, a coin crossed with a key
	var sc := Vector2(r.get_center().x, r.end.y - h * 0.13)
	var sr := w * 0.075
	draw_circle(sc + Vector2(3, 4), sr * 1.05, Color(0, 0, 0, 0.25))
	for i in 9:
		var a := TAU * i / 9.0
		draw_circle(sc + Vector2(cos(a), sin(a)) * sr * 0.82, sr * 0.32, Color(0.5, 0.07, 0.06))
	draw_circle(sc, sr, Color(0.56, 0.08, 0.07))
	draw_arc(sc, sr * 0.55, 0, TAU, 32, Color(0.3, 0.03, 0.03), sr * 0.12, true)   # the coin
	var kd := Vector2(cos(-0.8), sin(-0.8))
	var a0 := sc - kd * sr * 0.8
	var a1 := sc + kd * sr * 0.6
	draw_line(a0, a1, Color(0.3, 0.03, 0.03), sr * 0.14, true)                     # the key's shaft
	draw_arc(a1 + kd * sr * 0.18, sr * 0.2, 0, TAU, 16, Color(0.3, 0.03, 0.03), sr * 0.1, true)   # its bow
	var n := Vector2(-kd.y, kd.x)
	draw_line(a0, a0 + n * sr * 0.28, Color(0.3, 0.03, 0.03), sr * 0.12, true)       # its bit
	if _t > _ready_at:
		var a := 0.6 + 0.3 * sin(_t * 4.0)
		CardFace.text(self, CardFace.font("body"), Vector2(0, r.end.y + 46), "Tap to put it down", 28, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, s.x)
