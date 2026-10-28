class_name PuzzleMenu
extends Control
## Bram's Riddles (27 October): the list of one-turn duel puzzles
## (DuelPuzzles), each with its first line and a tick once it's solved.
## Main plays the one picked (Main.show_puzzles) and comes back here.

signal play(index: int)
signal closed

const DESIGN := Vector2(1920, 1080)
const CARD := Vector2(860, 172)

var stage: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Music.play(["menu_theme"], 1.0, true)
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := DuelArt.arena("ashford")
	if art != null:
		var pic := TextureRect.new()
		pic.texture = art
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)
		var dim := ColorRect.new()
		dim.color = Color(UITheme.BG, 0.82)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
	stage = Control.new()
	stage.size = DESIGN
	add_child(stage)
	_build()
	resized.connect(_fit)
	SafeArea.watch(self, _fit)


func _fit() -> void:
	var m := SafeArea.insets()
	var s := Rect2(Vector2(m.x, m.y), size - Vector2(m.x + m.z, m.y + m.w))
	var k := minf(s.size.x / DESIGN.x, s.size.y / DESIGN.y)
	stage.scale = Vector2(k, k)
	stage.position = (s.position + (s.size - DESIGN * k) * 0.5).floor()


func _build() -> void:
	var t := UITheme.label("Bram's Riddles", 58, UITheme.GOLD, "display_bold", 8)
	t.position = Vector2(80, 30)
	stage.add_child(t)
	var solved := DuelPuzzles.solved()
	var n := 0
	for i in DuelPuzzles.count():
		if solved.has(String(DuelPuzzles.get_puzzle(i).id)):
			n += 1
	var sub := UITheme.label("Bram sets the board. You have one turn to empty their Life. Each riddle teaches a trick.   %d of %d solved." % [n, DuelPuzzles.count()], 26, UITheme.TEXT_DIM)
	sub.position = Vector2(84, 104)
	stage.add_child(sub)
	# (28 October: thirteen riddles now, more than a screen holds: they scroll)
	var sc := ScrollContainer.new()
	sc.position = Vector2(80, 150)
	sc.size = Vector2(CARD.x * 2 + 40, 770)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.scroll_deadzone = 14
	stage.add_child(sc)
	var inner := Control.new()
	var rows := int(ceil(DuelPuzzles.count() / 2.0))
	inner.custom_minimum_size = Vector2(CARD.x * 2 + 40, rows * (CARD.y + 16))
	sc.add_child(inner)
	for i in DuelPuzzles.count():
		var pz := DuelPuzzles.get_puzzle(i)
		var at := Vector2((i % 2) * (CARD.x + 40), (i / 2) * (CARD.y + 16))
		inner.add_child(_card(i, pz, solved.has(String(pz.id)), at))
	var back := UITheme.button("Back", false, 260)
	back.position = Vector2(80, 940)
	back.pressed.connect(func() -> void: closed.emit())
	stage.add_child(back)


## One riddle: its number, name, first line, and SOLVED once it is.
func _card(i: int, pz: Dictionary, done: bool, at: Vector2) -> Control:
	var b := Button.new()
	b.position = at
	b.size = CARD
	b.custom_minimum_size = CARD
	var edge: Color = UITheme.GOLD if done else UITheme.GOLD_DIM
	b.add_theme_stylebox_override("normal", UITheme.sb(Color(0.05, 0.06, 0.1, 0.94), edge, 18, 2, 0))
	b.add_theme_stylebox_override("hover", UITheme.sb(Color(0.09, 0.1, 0.16, 0.96), UITheme.GOLD, 18, 2, 0))
	b.add_theme_stylebox_override("pressed", UITheme.sb(Color(0.12, 0.1, 0.05, 0.96), UITheme.GOLD, 18, 2, 0))
	b.add_theme_stylebox_override("focus", UITheme.sb(Color(0.09, 0.1, 0.16, 0.96), UITheme.GOLD, 18, 3, 0))
	b.pressed.connect(func() -> void: play.emit(i))
	var num := UITheme.label(str(i + 1), 64, UITheme.GOLD if done else UITheme.GOLD_DIM, "display_bold", 6)
	num.position = Vector2(28, 30)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(num)
	var nm := UITheme.label(String(pz.title), 36, UITheme.TEXT, "display_bold", 4)
	nm.position = Vector2(118, 22)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	var first := String(pz.riddle)
	var stop := first.find(". ")
	if stop > 0:
		first = first.substr(0, stop + 1)
	var line := UITheme.label(first, 24, UITheme.TEXT_DIM)
	line.position = Vector2(120, 76)
	line.size = Vector2(CARD.x - 150, 84)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(line)
	if done:
		var tick := UITheme.label("SOLVED", 22, Color("8fe39a"), "bold")
		tick.position = Vector2(CARD.x - 140, 28)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tick)
	return b
