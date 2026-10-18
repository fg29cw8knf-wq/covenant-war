class_name BlankCardSlot
extends Control
## The blank card in a duel (Master Script v3: it sits in its own slot beside
## the deck, is never drawn, and flickers when the player is close to losing).
## Every story duel after the night of the Sigilfall (flag ash_marked) shows
## it; spec.blank_card = true / false says so outright. It sits just right of
## the player's own plate, level with its Deck count, and follows the plate
## wherever the layout puts it.

const CARD := Vector2(54, 76)
## Life left (a share of the most) at which it starts to flicker.
const CLOSE := 0.3

var screen     # DuelScreen
var _t := 0.0
var _flicker := 0.0
var _eye := 0.0        # the white eye in its ring of runes, showing (0 to 1)


## A faint image shows on the card, a white eye inside a ring of runes, then
## fades (Aldric's duel on the Sunspire, the first time Life drops below a third).
func show_eye(secs := 2.4) -> void:
	# it lifts a little out of its slot, so the image can be made out
	pivot_offset = Vector2(size.x * 0.5, size.y)
	z_index = 60
	var tw := create_tween()
	tw.tween_property(self, "_eye", 1.0, secs * 0.35).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "scale", Vector2(2.4, 2.4), secs * 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(secs * 0.3)
	tw.tween_property(self, "_eye", 0.0, secs * 0.35).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, secs * 0.35).set_trans(Tween.TRANS_SINE)
	await tw.finished
	z_index = 0


## Adds the slot to a duel screen, if this duel shows it.
static func attach(p_screen) -> void:
	var spec: Dictionary = p_screen.spec
	var on: bool = spec.get("blank_card", bool(spec.get("story", false)) and bool(Game.flag("ash_marked")))
	if not on:
		return
	var s := BlankCardSlot.new()
	s.name = "BlankCardSlot"
	s.screen = p_screen
	s.size = CARD + Vector2(16, 16)
	p_screen.stage.add_child(s)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Close to losing: low on Life.
func close_to_losing() -> bool:
	if screen == null or screen.game == null:
		return false
	var p: DuelPlayer = screen.game.players[screen.me]
	return p.life > 0 and float(p.life) <= float(p.max_life) * CLOSE


func _process(delta: float) -> void:
	_t += delta
	var panel: Control = screen.panels[screen.me]
	# just right of the plate, level with the Deck count (and clear of the
	# hand, which never comes further left than FIELD_CX - 500)
	position = panel.position + Vector2(panel.size.x - 6.0, 108)
	var want := 1.0 if close_to_losing() else 0.0
	_flicker = move_toward(_flicker, want, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var col := Color("e9eefc")
	var r := Rect2(Vector2(8, 8), CARD)
	# the slot it lies in
	CardFace.box(self, r.grow(6), 10, Color(0.03, 0.035, 0.07, 0.7), Color(UITheme.GOLD_DIM, 0.55), 1.5)
	# a steady glow, like a candle with the doors shut; close to losing it
	# stutters, bright and dim by turns
	var glow := 0.5 + 0.08 * sin(_t * 1.3)
	var a := 1.0
	if _flicker > 0.0:
		var n := sin(_t * 23.0) * sin(_t * 7.3 + 1.7) * sin(_t * 3.1 + 0.4)
		glow += _flicker * (0.55 * maxf(0.0, n) + 0.25 * absf(sin(_t * 11.0)))
		a = 1.0 - _flicker * 0.45 * maxf(0.0, -n)
	DuelFX.draw_glow(self, r.get_center(), CARD * (0.9 + glow * 0.5), Color(0.82, 0.9, 1.0, 0.35 * glow))
	# the card: white, and nothing on it
	CardFace.vgrad(self, r, 6, Color(0.97, 0.96, 0.92, a), Color(0.88, 0.89, 0.92, a))
	CardFace.box(self, r, 6, Color(0, 0, 0, 0), Color(col, 0.6 * a), 1.5)
	CardFace.box(self, r.grow(-5), 4, Color(0, 0, 0, 0), Color(0.75, 0.8, 0.95, 0.35 * a), 1.0)
	if _eye > 0.0:
		_draw_eye(r.get_center(), _eye)


## The seal: a white eye inside a ring of runes, faint, as if seen through the card.
func _draw_eye(c: Vector2, k: float) -> void:
	DuelFX.draw_glow(self, c, CARD * (1.2 + k * 0.6), Color(0.9, 0.95, 1.0, 0.55 * k))
	var ink := Color(0.55, 0.62, 0.85, 0.8 * k)
	var rad := CARD.x * 0.38
	draw_arc(c, rad, 0.0, TAU, 40, ink, 1.2, true)
	draw_arc(c, rad - 4.0, 0.0, TAU, 40, Color(ink, ink.a * 0.6), 1.0, true)
	for i in 12:
		var ang := TAU * i / 12.0 + 0.13
		var d := Vector2(cos(ang), sin(ang))
		var p := c + d * (rad - 2.0)
		var tang := Vector2(-d.y, d.x)
		# a little rune: a stroke and a tick, different by turns
		draw_line(p - tang * 1.6 - d * 1.2, p + tang * 1.6 + d * 1.2, ink, 1.0, true)
		if i % 2 == 0:
			draw_line(p, p + d * 1.8, ink, 1.0, true)
		else:
			draw_line(p - tang * 1.4, p + tang * 1.4, ink, 1.0, true)
	# the eye: an almond of white with a pale iris
	var w := rad * 0.72
	var h := rad * 0.42
	var pts := PackedVector2Array()
	for i in 25:
		var u := float(i) / 24.0
		pts.append(c + Vector2(lerpf(-w, w, u), -sin(u * PI) * h))
	for i in range(1, 24):
		var u := 1.0 - float(i) / 24.0
		pts.append(c + Vector2(lerpf(-w, w, u), sin(u * PI) * h))
	draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.85 * k))
	draw_polyline(pts + PackedVector2Array([pts[0]]), ink, 1.0, true)
	draw_circle(c, h * 0.62, Color(0.7, 0.8, 1.0, 0.9 * k))
	draw_circle(c, h * 0.3, Color(0.2, 0.25, 0.45, 0.9 * k))
