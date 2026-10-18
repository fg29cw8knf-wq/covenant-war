class_name Ledger
extends VBoxContainer
## Morrowen's Ledger: a page of the pause menu (PauseMenu's Ledger tab).
## Accounts are the story and its side stories, what's still open and what's
## settled, a sentence or two each in Morrowen's words; People is everyone
## met, with their face, her one line on them and how they stand with you.
## The words come from LedgerEntries (worked out from the story's flags).

## Which of the two the page opens on (it remembers while the game runs).
static var section := "accounts"

const INK := Color(0.93, 0.89, 0.8)
const KIND := {"story": "THE STORY", "side": "A SIDE STORY"}

var _body: VBoxContainer
var _btns := {}


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	add_child(top)
	var head := UITheme.label("MORROWEN'S LEDGER", 36, UITheme.GOLD, "display_bold")
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(head)
	for k in [["accounts", "Accounts"], ["people", "People"]]:
		var b := UITheme.button(k[1], false, 230)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(230, 72)
		b.add_theme_font_size_override("font_size", 26)
		var key: String = k[0]
		b.pressed.connect(func() -> void: show_section(key))
		top.add_child(b)
		_btns[key] = b
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(sc)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	sc.add_child(_body)
	show_section(section)


func show_section(key: String) -> void:
	section = key
	for k in _btns:
		_btns[k].button_pressed = k == key
	for c in _body.get_children():
		c.queue_free()
	if key == "people":
		_people()
	else:
		_accounts()


# ============================================================== accounts ===

func _accounts() -> void:
	var all := LedgerEntries.accounts()
	if all.is_empty():
		_body.add_child(_dim("Nothing written yet."))
		return
	var open := all.filter(func(a): return a.open)
	var done := all.filter(func(a): return not a.open)
	if not open.is_empty():
		_body.add_child(_heading("STILL OPEN"))
		for a in open:
			_body.add_child(_account(a, true))
	if not done.is_empty():
		_body.add_child(_heading("SETTLED"))
		for a in done:
			_body.add_child(_account(a, false))


func _account(a: Dictionary, is_open: bool) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edge := Color(UITheme.GOLD, 0.55) if is_open else Color(UITheme.GOLD_DIM, 0.28)
	p.add_theme_stylebox_override("panel", UITheme.sb(Color(0.07, 0.065, 0.06, 0.92), edge, 14, 2, 26))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var t := UITheme.label(String(a.title), 30, UITheme.GOLD if is_open else Color(UITheme.GOLD, 0.85), "display_bold")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	var tag := UITheme.label("%s  ·  %s" % [String(a.place).to_upper(), KIND.get(a.kind, "")], 20, UITheme.TEXT_DIM, "bold")
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(tag)
	var words := UITheme.label(String(a.text), 27, INK)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size = Vector2(400, 0)
	v.add_child(words)
	return p


# ================================================================ people ===

func _people() -> void:
	var all := LedgerEntries.people()
	if all.is_empty():
		_body.add_child(_dim("Nobody yet."))
		return
	# two to a row when there's room (a wide screen at the usual text size)
	var avail := (SafeArea.rect().size.x - 100.0) / SafeArea.ui_scale()
	var cols := 2 if avail >= 1500.0 else 1
	var places := []
	for p in all:
		if not places.has(p.place):
			places.append(p.place)
	for place in places:
		_body.add_child(_heading(String(place).to_upper()))
		var grid := GridContainer.new()
		grid.columns = cols
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_child(grid)
		for p in all:
			if p.place == place:
				grid.add_child(_person(p))


func _person(p: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.07, 0.065, 0.06, 0.92), Color(UITheme.GOLD_DIM, 0.28), 14, 2, 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	var face := Face.new()
	var id := String(p.id)
	face.tex = DollArt.portrait(id) if DollArt.has_portrait(id) else DollArt.portrait(String(p.look))
	face.custom_minimum_size = Vector2(104, 104)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	# her line, the name at its head in gold
	var text := String(p.text)
	var cut := text.find(". ")
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", 26)
	rt.add_theme_font_size_override("bold_font_size", 26)
	rt.add_theme_color_override("default_color", INK)
	rt.custom_minimum_size = Vector2(300, 0)
	if cut > 0:
		rt.text = "[b][color=#%s]%s[/color][/b]%s" % [UITheme.GOLD.to_html(false), text.substr(0, cut + 1), text.substr(cut + 1)]
	else:
		rt.text = text
	col.add_child(rt)
	# how they stand with you, for the people who can hold an opinion
	if Standing.PEOPLE.has(id) or Standing.value(id) != 0:
		var v := Standing.value(id)
		var word := UITheme.label("%s  %s" % [Standing.level_name(id).to_upper(), ("%+d" % v) if v != 0 else ""], 20,
			UITheme.GOLD if v > 1 else (Color("ff8a80") if v < -1 else UITheme.TEXT_DIM), "bold")
		col.add_child(word)
	return box


# ================================================================ helpers ===

func _heading(t: String) -> Control:
	var l := UITheme.label(t, 26, UITheme.GOLD_DIM, "display_bold")
	l.custom_minimum_size = Vector2(0, 44)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


func _dim(t: String) -> Control:
	var l := UITheme.label(t, 28, UITheme.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A face in a round gold frame.
class Face:
	extends Control
	var tex: Texture2D

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color("10142a"))
		if tex != null:
			DuelArt.rounded(self, Rect2(c - Vector2(r, r) + Vector2(3, 3), Vector2(r, r) * 2.0 - Vector2(6, 6)), r - 3.0, tex)
		draw_arc(c, r - 1.0, 0, TAU, 48, Color(UITheme.GOLD, 0.7), 2.0, true)
