class_name UITheme
extends RefCounted
## The shared look for menus, buttons, panels and text.
## Sizes are for the 1920 x 1080 base resolution; the game scales it to the screen.

const BG := Color("0b0d15")
const PANEL := Color(0.055, 0.065, 0.11, 0.94)
const PANEL_EDGE := Color("6b5a32")
const GOLD := Color("f2c96b")
const GOLD_DIM := Color("b08f4a")
const TEXT := Color("ece7da")
const TEXT_DIM := Color("9c9aa8")
const MINE := Color("8fd0ff")
const THEIRS := Color("ffb09a")

## Minimum touch target (in base pixels) for anything tappable.
const TOUCH := 96


static func sb(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 14, bw: int = 2,
		pad: int = 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if border.a > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


static var _theme: Theme


static func make() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = CardFace.font("body")
	t.default_font_size = 30

	t.set_stylebox("normal", "Button", sb(Color("1a2036"), Color("4a4f6e")))
	t.set_stylebox("hover", "Button", sb(Color("242b48"), GOLD_DIM))
	t.set_stylebox("pressed", "Button", sb(Color("121628"), GOLD))
	t.set_stylebox("disabled", "Button", sb(Color("14182a"), Color("2a2e44")))
	t.set_stylebox("focus", "Button", sb(Color(0, 0, 0, 0), Color(GOLD, 0.8), 14, 3))
	t.set_font("font", "Button", CardFace.font("display_bold"))
	t.set_font_size("font_size", "Button", 32)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("5a5d72"))

	t.add_type("AccentButton")
	t.set_type_variation("AccentButton", "Button")
	t.set_stylebox("normal", "AccentButton", sb(Color("c9973a"), Color("ffe6a0"), 16, 2))
	t.set_stylebox("hover", "AccentButton", sb(Color("dcaa48"), Color("fff2c8"), 16, 2))
	t.set_stylebox("pressed", "AccentButton", sb(Color("a87a26"), Color("ffe6a0"), 16, 2))
	t.set_stylebox("disabled", "AccentButton", sb(Color("3a3528"), Color("4d4633"), 16, 2))
	t.set_color("font_color", "AccentButton", Color("1e1406"))
	t.set_color("font_hover_color", "AccentButton", Color("1e1406"))
	t.set_color("font_pressed_color", "AccentButton", Color("1e1406"))
	t.set_color("font_disabled_color", "AccentButton", Color("77705a"))
	t.set_font_size("font_size", "AccentButton", 36)

	t.add_type("ChoiceButton")
	t.set_type_variation("ChoiceButton", "Button")
	t.set_stylebox("normal", "ChoiceButton", sb(Color(0.08, 0.09, 0.15, 0.96), Color(GOLD_DIM, 0.8), 12, 2, 28))
	t.set_stylebox("hover", "ChoiceButton", sb(Color(0.13, 0.14, 0.22, 0.98), GOLD, 12, 2, 28))
	t.set_stylebox("pressed", "ChoiceButton", sb(Color(0.2, 0.17, 0.08, 0.98), GOLD, 12, 2, 28))
	t.set_font("font", "ChoiceButton", CardFace.font("bold"))
	t.set_font_size("font_size", "ChoiceButton", 32)

	t.set_color("font_color", "Label", TEXT)
	t.set_font("font", "Label", CardFace.font("body"))

	t.set_stylebox("panel", "PanelContainer", sb(PANEL, PANEL_EDGE, 18, 2, 24))
	t.set_stylebox("panel", "Panel", sb(PANEL, PANEL_EDGE, 18, 2, 24))

	t.set_font("normal_font", "RichTextLabel", CardFace.font("body"))
	t.set_font("bold_font", "RichTextLabel", CardFace.font("bold"))
	t.set_font_size("normal_font_size", "RichTextLabel", 30)
	t.set_font_size("bold_font_size", "RichTextLabel", 30)
	t.set_color("default_color", "RichTextLabel", TEXT)

	var le := sb(Color("0f1322"), GOLD_DIM, 12, 2, 20)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", sb(Color("0f1322"), GOLD, 12, 2, 20))
	t.set_font("font", "LineEdit", CardFace.font("display_bold"))
	t.set_font_size("font_size", "LineEdit", 40)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", GOLD)

	var grab := sb(Color("59638f"), Color(0, 0, 0, 0), 6, 0, 0)
	for sbar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sbar, grab)
		t.set_stylebox("grabber_highlight", sbar, sb(GOLD_DIM, Color(0, 0, 0, 0), 6, 0, 0))
		t.set_stylebox("grabber_pressed", sbar, sb(GOLD, Color(0, 0, 0, 0), 6, 0, 0))
		t.set_stylebox("scroll", sbar, sb(Color(1, 1, 1, 0.04), Color(0, 0, 0, 0), 6, 0, 0))
	_theme = t
	return t


static func label(text: String, size: int = 30, color: Color = TEXT, kind: String = "body",
		outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", CardFace.font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, accent: bool = false, min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	if accent:
		b.theme_type_variation = "AccentButton"
	b.custom_minimum_size = Vector2(min_w, TOUCH)
	b.focus_mode = Control.FOCUS_ALL
	return b
