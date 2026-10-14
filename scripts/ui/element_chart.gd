class_name ElementChart
extends Control
## The full element chart, as Bram shows it at the campfire and as the pause
## menu's How to Duel page keeps it: each of the twelve core elements, what it
## beats and what beats it. Hitting a weakness deals half again as much.

const ROW := 54.0
const TOP := 64.0
const WIDTH := 980.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, TOP + ROW * Lore.CORE_ELEMENTS.size() + 16.0)


func _draw() -> void:
	var w := size.x
	var fnt := CardFace.font("display_bold")
	var body := CardFace.font("bold")
	CardFace.box(self, Rect2(Vector2.ZERO, size), 18, Color(0.035, 0.04, 0.08, 0.96), UITheme.GOLD_DIM, 2.0)
	CardFace.text(self, fnt, Vector2(30, 42), "ELEMENT", 22, UITheme.GOLD)
	CardFace.text(self, fnt, Vector2(w * 0.36, 42), "BEATS", 22, UITheme.GOLD)
	CardFace.text(self, fnt, Vector2(w * 0.68, 42), "HURT BY", 22, UITheme.GOLD)
	draw_line(Vector2(24, TOP - 6), Vector2(w - 24, TOP - 6), Color(UITheme.GOLD_DIM, 0.7), 2.0)
	for i in Lore.CORE_ELEMENTS.size():
		var el: String = Lore.CORE_ELEMENTS[i]
		var d: Dictionary = Lore.ELEMENTS[el]
		var y := TOP + ROW * i + ROW * 0.5
		if i % 2 == 1:
			draw_rect(Rect2(24, y - ROW * 0.5, w - 48, ROW), Color(1, 1, 1, 0.03))
		CardFace.orb(self, Vector2(56, y), 17, el)
		CardFace.text(self, body, Vector2(88, y + 9), String(d.name), 26, UITheme.TEXT)
		_orbs(Vector2(w * 0.36, y), d.strong, body)
		_orbs(Vector2(w * 0.68, y), d.weak, body)


func _orbs(at: Vector2, els: Array, body: Font) -> void:
	var x := at.x
	for el in els:
		CardFace.orb(self, Vector2(x + 14, at.y), 13, el)
		var nm := String(Lore.ELEMENTS[el].name)
		CardFace.text(self, body, Vector2(x + 34, at.y + 8), nm, 22, Color(UITheme.TEXT, 0.9))
		x += 48 + body.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 14
