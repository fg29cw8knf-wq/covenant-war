class_name DeckReveal
extends Control
## A gift of cards, shown big: one card ("NEW SIGIL", Tilly's Lantern Moth) or
## a whole deck fanned out (Bram's Spark deck). Tap, or E / Space / Enter,
## when it says so, to go on.
##
##   var r := DeckReveal.new(); r.cards = ["lantern_moth"]; r.title = "NEW SIGIL"
##   layer.add_child(r); await r.closed

signal closed

var cards: Array = []
var title := "NEW SIGIL"
var subtitle := ""
var _t := 0.0
var _ready_to_close := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.5 + cards.size() * 0.06:
		_ready_to_close = true
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)) and _ready_to_close:
		_close()
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and _ready_to_close:
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if not _ready_to_close:
		return
	_ready_to_close = false
	closed.emit()


func _draw() -> void:
	var k := clampf(_t / 0.45, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - k, 3.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.01, 0.03, 0.78 * ease))
	var n := maxi(1, cards.size())
	var ch := minf(size.y * (0.62 if n == 1 else 0.42), 740.0)
	var cw := ch * 0.72
	var c := size * 0.5 + Vector2(0, 10 if n == 1 else 40)
	# a soft gold glow and slow rays behind
	for i in 10:
		draw_circle(c, ch * (0.66 if n == 1 else 1.2) * (1.0 - i * 0.08), Color(UITheme.GOLD, 0.03 * ease))
	for i in 16:
		var a := TAU * i / 16.0 + _t * 0.12
		var p1 := c + Vector2(cos(a), sin(a)) * ch * 0.2
		var p2 := c + Vector2(cos(a + 0.07), sin(a + 0.07)) * ch * 1.1
		var p3 := c + Vector2(cos(a - 0.07), sin(a - 0.07)) * ch * 1.1
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(UITheme.GOLD, 0.045 * ease))
	var top_y := c.y - ch * 0.5
	if n == 1:
		var sc := 0.6 + 0.4 * ease
		var r := Rect2(c - Vector2(cw, ch) * 0.5 * sc, Vector2(cw, ch) * sc)
		DuelCardFace.draw_card(self, r, String(cards[0]), {"compact": false})
		top_y = r.position.y
	else:
		# fanned out in an arc, dealt in one at a time
		var spread := minf(size.x * 0.82, n * cw * 0.62)
		for i in n:
			var di := clampf((_t - 0.15 - i * 0.06) / 0.35, 0.0, 1.0)
			if di <= 0.0:
				continue
			var e := 1.0 - pow(1.0 - di, 3.0)
			var u := (i - (n - 1) * 0.5) / maxf(1.0, (n - 1) * 0.5)
			var pos := c + Vector2(u * spread * 0.5, absf(u) * absf(u) * ch * 0.16)
			pos = c.lerp(pos, e) + Vector2(0, (1.0 - e) * 120.0)
			var ang := u * 0.32 * e
			draw_set_transform(pos, ang, Vector2.ONE)
			DuelCardFace.draw_card(self, Rect2(Vector2(-cw, -ch) * 0.5, Vector2(cw, ch)), String(cards[i]), {"compact": true})
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		top_y = c.y - ch * 0.62
	var f := CardFace.font("display_bold")
	CardFace.text(self, f, Vector2(0, top_y - (110 if subtitle != "" else 40)), title, 56, Color(UITheme.GOLD, ease), HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0, 0, 0, 0.9 * ease))
	if subtitle != "":
		CardFace.text(self, CardFace.font("body"), Vector2(0, top_y - 50), subtitle, 30, Color(1, 1, 1, 0.85 * ease), HORIZONTAL_ALIGNMENT_CENTER, size.x, 6, Color(0, 0, 0, 0.8 * ease))
	if _ready_to_close:
		var bottom := c.y + ch * (0.5 if n == 1 else 0.7)
		var low := size.y - maxf(30.0, SafeArea.insets().w + 16.0)   # above a phone's home bar
		CardFace.text(self, CardFace.font("body"), Vector2(0, minf(bottom + 56, low)), "Tap to continue", 30, Color(1, 1, 1, 0.6 + 0.3 * sin(_t * 4.0)), HORIZONTAL_ALIGNMENT_CENTER, size.x)
