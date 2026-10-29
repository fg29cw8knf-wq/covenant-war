class_name ElementChart
extends Control
## The full element chart, as Bram shows it at the campfire and as the pause
## menu's How to Duel page keeps it: each of the twelve core elements, what it
## beats and what beats it. Hitting a weakness deals half again as much.
##
## The columns are as wide as the words in them (29 October, Gary: "In the
## how to duel some of the text goes out of the text box": the HURT BY column
## was set at two thirds of a fixed width, and an element hurt by three ran
## past the chart's right edge). The chart is at least WIDTH wide, and wider
## when its longest row needs it.

const ROW := 54.0
const TOP := 64.0
const WIDTH := 980.0
const PAD := 30.0        # in from the box's sides
const COL_GAP := 44.0    # between the columns
const ITEM_GAP := 26.0   # between two elements in a column
const NAME_SIZE := 26
const ITEM_SIZE := 22
const HEAD_SIZE := 22

var _beats_x := 0.0
var _hurt_x := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_measure()


## Lays out the columns: the element names, then BEATS, then HURT BY, each
## as wide as its widest row, with the spare room (if any) shared out.
func _measure() -> void:
	var body := CardFace.font("bold")
	var head := CardFace.font("display_bold")
	var name_w := 0.0
	var beats_w := head.get_string_size("BEATS", HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_SIZE).x
	var hurt_w := head.get_string_size("HURT BY", HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_SIZE).x
	for el in Lore.CORE_ELEMENTS:
		var d: Dictionary = Lore.ELEMENTS[el]
		name_w = maxf(name_w, 58.0 + body.get_string_size(String(d.name), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x)
		beats_w = maxf(beats_w, _orbs_width(d.strong, body))
		hurt_w = maxf(hurt_w, _orbs_width(d.weak, body))
	var need := PAD + name_w + COL_GAP + beats_w + COL_GAP + hurt_w + PAD + 12.0   # (a little more room at the right, past the stripe's end)
	var spare := maxf(0.0, WIDTH - need) / 2.0   # into the two gaps
	_beats_x = PAD + name_w + COL_GAP + spare
	_hurt_x = _beats_x + beats_w + COL_GAP + spare
	custom_minimum_size = Vector2(maxf(WIDTH, need), TOP + ROW * Lore.CORE_ELEMENTS.size() + 16.0)


func _draw() -> void:
	var w := size.x
	var fnt := CardFace.font("display_bold")
	var body := CardFace.font("bold")
	CardFace.box(self, Rect2(Vector2.ZERO, size), 18, Color(0.035, 0.04, 0.08, 0.96), UITheme.GOLD_DIM, 2.0)
	CardFace.text(self, fnt, Vector2(PAD, 42), "ELEMENT", HEAD_SIZE, UITheme.GOLD)
	CardFace.text(self, fnt, Vector2(_beats_x, 42), "BEATS", HEAD_SIZE, UITheme.GOLD)
	CardFace.text(self, fnt, Vector2(_hurt_x, 42), "HURT BY", HEAD_SIZE, UITheme.GOLD)
	draw_line(Vector2(24, TOP - 6), Vector2(w - 24, TOP - 6), Color(UITheme.GOLD_DIM, 0.7), 2.0)
	for i in Lore.CORE_ELEMENTS.size():
		var el: String = Lore.CORE_ELEMENTS[i]
		var d: Dictionary = Lore.ELEMENTS[el]
		var y := TOP + ROW * i + ROW * 0.5
		if i % 2 == 1:
			draw_rect(Rect2(24, y - ROW * 0.5, w - 48, ROW), Color(1, 1, 1, 0.03))
		CardFace.orb(self, Vector2(PAD + 26, y), 17, el)
		CardFace.text(self, body, Vector2(PAD + 58, y + 9), String(d.name), NAME_SIZE, UITheme.TEXT)
		_orbs(Vector2(_beats_x, y), d.strong, body)
		_orbs(Vector2(_hurt_x, y), d.weak, body)


func _orbs(at: Vector2, els: Array, body: Font) -> void:
	var x := at.x
	for el in els:
		CardFace.orb(self, Vector2(x + 14, at.y), 13, el)
		var nm := String(Lore.ELEMENTS[el].name)
		CardFace.text(self, body, Vector2(x + 34, at.y + 8), nm, ITEM_SIZE, Color(UITheme.TEXT, 0.9))
		x += 34 + body.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, ITEM_SIZE).x + ITEM_GAP


## How wide a column's row of elements is drawn, orb to the end of the last name.
static func _orbs_width(els: Array, body: Font) -> float:
	var w := 0.0
	for el in els:
		w += 34 + body.get_string_size(String(Lore.ELEMENTS[el].name), HORIZONTAL_ALIGNMENT_LEFT, -1, ITEM_SIZE).x + ITEM_GAP
	return maxf(0.0, w - ITEM_GAP)


## Any row drawn past the chart's box, or into the next column (the tests).
func overflows() -> Array:
	var out := []
	var body := CardFace.font("bold")
	for el in Lore.CORE_ELEMENTS:
		var d: Dictionary = Lore.ELEMENTS[el]
		var name_end := PAD + 58.0 + body.get_string_size(String(d.name), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		if name_end > _beats_x - 8.0:
			out.append("%s's name runs into BEATS" % d.name)
		if _beats_x + _orbs_width(d.strong, body) > _hurt_x - 8.0:
			out.append("%s's BEATS runs into HURT BY" % d.name)
		if _hurt_x + _orbs_width(d.weak, body) > size.x - 24.0:
			out.append("%s's HURT BY runs out of the chart" % d.name)
	return out
