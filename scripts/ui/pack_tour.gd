class_name PackTour
extends Control
## Bram's gated tour of the pack (the pause menu), run by the world right after
## he hands over the first deck: await hud.pack_tour(steps). It looks and works
## like the duel's DuelTutor: Bram speaks in a box at the edge of the screen, an
## explanation waits for a tap (or E / Space / Enter), and an instruction lights
## up the one thing to tap while everything else is locked; a wrong tap shakes
## the box. Nothing else works while it runs: no walking, talking or other tabs.
##
## A step is {"say": "...", "who": "Bram", "do": "...", "focus": "..."}.
## Without "do" it's an explanation; with "do" only that action works:
##   menu        open the pack (the ☰ button, or Esc / Tab)
##   tab:deck    tap the Deck tab (tab:codex, tab:hero... the same way)
##   card        tap any card in the grid on show (card:<id>: that card)
##   close       close the card (its Close button, or Esc)
##   resume      close the pack (Resume, or Esc)
## "focus" (on an explanation) spotlights deck_grid or codex_grid (the cards in
## view), detail (the open card's face), tabs or menu_button. Every line is
## kept on the How to Duel page, under "Your pack".

signal _tapped

## Bram's lines when he hands over the Spark deck (the tour hud.pack_tour() runs by default).
const FIRST_DECK := [
	{"say": "Before you go losing it: everything you carry lives in your pack. Tap it, up in the corner.", "do": "menu"},
	{"say": "Tap Deck.", "do": "tab:deck"},
	{"say": "That's the twelve you'll duel with tonight. Shuffled before every duel, and you draw from the top.", "focus": "deck_grid"},
	{"say": "Twelve's a beginner's deck. A proper one is thirty, and you build it yourself from what you find. Not tonight."},
	{"say": "Tap any card. It'll tell you everything about itself.", "do": "card"},
	{"say": "What it costs, its element, what every move does. Read before you play. Corin never does.", "focus": "detail"},
	{"say": "Close it.", "do": "close"},
	{"say": "Now the Codex.", "do": "tab:codex"},
	{"say": "Every card you find gets written in here: your own, and any you see played against you. It's short tonight. It won't stay short.", "focus": "codex_grid"},
	{"say": "Close your pack. Corin's waiting, and patience was never his Sigil.", "do": "resume"},
]

## The How to Duel heading the lines are kept under.
const GROUP := "Your pack"

var hud: WorldHUD
var menu: PauseMenu
var step: Dictionary = {}
var running := false
var blocking := false      # an explanation is up: a tap moves on
var index := -1            # the step showing now
var nudges := 0            # wrong taps so far
var box: PanelContainer
var who_label: Label
var text_label: Label
var foot_label: Label
var portrait: TextureRect
var _sfx: Sfx
var _shown_at := 0
var _dim := 0.0
var _dim_now := 0.0
var _pulse := 0.0
var _t := 0.0
var _shake: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.make()
	_sfx = Sfx.new()
	add_child(_sfx)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.sb(Color(0.035, 0.04, 0.08, 0.96), UITheme.GOLD, 20, 3, 24))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.visible = false
	add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(124, 124)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	who_label = UITheme.label("", 24, UITheme.GOLD, "bold")
	col.add_child(who_label)
	text_label = UITheme.label("", 31, UITheme.TEXT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(760, 0)
	col.add_child(text_label)
	foot_label = UITheme.label("", 22, UITheme.GOLD, "bold")
	foot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(foot_label)


## Plays the steps in order; returns once the last one is done.
func run(p_hud: WorldHUD, steps: Array) -> void:
	hud = p_hud
	menu = hud._menu as PauseMenu
	running = true
	# a tab the tour sends the player to is opened first, so it can't get stuck
	for st in steps:
		var d := String((st as Dictionary).get("do", ""))
		if d.begins_with("tab:") and PauseMenu.LOCKED_TABS.has(d.substr(4)):
			Game.unlock(d.substr(4))
	if not menu.visible:
		menu.tab = "hero"   # the pack opens where the tour expects it
	for i in steps.size():
		if not is_inside_tree():
			return
		index = i
		var st: Dictionary = steps[i]
		_keep(st)
		if st.has("do"):
			await _instruct(st)
		else:
			await _explain(st)
	running = false
	blocking = false
	step = {}
	_hide()


## True while the tour is waiting on the player.
func waiting_for() -> String:
	if not running:
		return ""
	return "tap" if blocking else String(step.get("do", ""))


# ------------------------------------------------------------------ steps ---

func _explain(st: Dictionary) -> void:
	step = st
	blocking = true
	_show_box(st, "TAP TO CONTINUE  ▸")
	_dim = 0.42 if String(st.get("focus", "")) == "" else 0.55
	_shown_at = Time.get_ticks_msec()
	await _tapped
	_sfx.play("ui_tap")
	blocking = false


func _instruct(st: Dictionary) -> void:
	step = st
	_show_box(st, "YOUR MOVE  ▸")
	_dim = 0.5
	while is_inside_tree() and not _done(String(st.do)):
		await get_tree().process_frame


## Has the player done what the step asks?
func _done(d: String) -> bool:
	match d:
		"menu":
			return menu.visible
		"resume":
			return not menu.visible
		"card":
			return menu.open_card_id() != ""
		"close":
			return menu.open_card_id() == ""
	if d.begins_with("tab:"):
		return menu.visible and menu.tab == d.substr(4) and menu.open_card_id() == ""
	if d.begins_with("card:"):
		return menu.open_card_id() == d.substr(5)
	return true   # something this tour doesn't know: don't get stuck on it


## Every line goes on the How to Duel page, in the order it was said.
func _keep(st: Dictionary) -> void:
	var say := String(st.get("say", ""))
	if say != "":
		Game.learn("%s:%s" % [GROUP, say.sha1_text().left(12)], GROUP, String(st.get("who", "Bram")), say)


# ------------------------------------------------------------------ input ---

## The one place a tap gets through while an instruction is up.
func _has_point(p: Vector2) -> bool:
	if not running:
		return false
	if blocking or not step.has("do"):
		return true
	return not _rect(String(step.do)).has_point(p)


func _gui_input(e: InputEvent) -> void:
	if not running:
		return
	if e is InputEventMouseButton:
		accept_event()
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if blocking:
				_tap()
			else:
				nudge()
	elif e is InputEventMouseMotion or e is InputEventScreenTouch or e is InputEventScreenDrag:
		accept_event()


## Keys and pad buttons: E / Space / Enter moves an explanation on; Esc or
## Tab opens or closes what the step asks for. Nothing else gets through.
func _input(e: InputEvent) -> void:
	if not running or not (e is InputEventKey or e is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not e.is_pressed() or e.is_echo():
		return
	if blocking:
		if e.is_action_pressed("interact"):
			_tap()
		return
	if not step.has("do"):
		return
	if e.is_action_pressed("menu"):
		match String(step.do):
			"menu":
				hud.open_menu()
			"resume":
				menu.request_close()
			"close":
				menu.close_card()
			_:
				nudge()
	elif e.is_action_pressed("interact"):
		nudge()


func _tap() -> void:
	if blocking and Time.get_ticks_msec() - _shown_at > 350:
		_tapped.emit()


## Something else was tapped: shake the box so the eye finds it.
func nudge() -> void:
	nudges += 1
	_sfx.play("ui_error")
	_pulse = 1.0
	if not box.visible:
		return
	if _shake != null and _shake.is_valid():
		_shake.kill()
	_place_box()
	var x := box.position.x
	_shake = box.create_tween()
	for k in 4:
		_shake.tween_property(box, "position:x", x + (14.0 if k % 2 == 0 else -14.0), 0.05)
	_shake.tween_property(box, "position:x", x, 0.05)


# ---------------------------------------------------------------- drawing ---

## What the spotlight is on: the thing to tap, or what's being explained.
func _spot() -> String:
	return String(step.do) if step.has("do") else String(step.get("focus", ""))


## Where `what` is on screen, in this control's space (empty if not showing).
func _rect(what: String) -> Rect2:
	var r := Rect2()
	if what == "":
		return r
	if what == "menu" or what == "menu_button":
		var b: Control = hud._menu_btn
		if b.is_visible_in_tree() and not menu.visible:
			r = b.get_global_rect()
	else:
		r = menu.tour_rect(what)
	if not r.has_area():
		return Rect2()
	return get_global_transform().affine_inverse() * r


func _show_box(st: Dictionary, footer: String) -> void:
	var who := String(st.get("who", "Bram"))
	who_label.text = who.to_upper()
	text_label.text = String(st.get("say", ""))
	foot_label.text = footer
	var look := who.to_lower()
	portrait.texture = DollArt.portrait(look) if DollArt.LOOKS.has(look) else null
	portrait.visible = portrait.texture != null
	var was := box.visible
	box.visible = true
	box.reset_size()
	box.modulate.a = 0.0 if not was else 0.4
	box.create_tween().tween_property(box, "modulate:a", 1.0, 0.2)
	_place_box()


func _hide() -> void:
	box.visible = false
	_dim = 0.0


## Bottom centre, unless that would cover what's lit; then bottom right or
## left, then the top, then the middle (the least covered, if all would).
func _place_box() -> void:
	var sz := box.get_combined_minimum_size()
	box.size = sz
	var f := _rect(_spot()).grow(24.0)
	var s := SafeArea.rect()   # clear of a phone's Dynamic Island and home bar
	var x := s.position.x + (s.size.x - sz.x) * 0.5
	var low := s.end.y - sz.y - 36.0
	var spots := [Vector2(x, low), Vector2(s.end.x - sz.x - 36.0, low), Vector2(s.position.x + 36.0, low),
		Vector2(x, s.position.y + 36.0), Vector2(x, s.position.y + (s.size.y - sz.y) * 0.5)]
	var best: Vector2 = spots[0]
	var least := INF
	for p in spots:
		var a := Rect2(p, sz).intersection(f).get_area() if f.has_area() else 0.0
		if a < least:
			least = a
			best = p
		if a <= 0.0:
			break
	box.position = best


func _process(delta: float) -> void:
	_t += delta
	_dim_now = move_toward(_dim_now, _dim, delta * 2.5)
	_pulse = move_toward(_pulse, 0.0, delta * 2.0)
	if box.visible and (_shake == null or not _shake.is_valid()):
		_place_box()
	queue_redraw()


## Dims everything but what to tap (or what's being explained), rings it in
## gold and, for an instruction, points at it.
func _draw() -> void:
	if _dim_now <= 0.005:
		return
	var shade := Color(0, 0, 0, _dim_now)
	var f := _rect(_spot())
	if not f.has_area():
		draw_rect(Rect2(Vector2.ZERO, size), shade)
		return
	var r := f.grow(10.0)
	draw_rect(Rect2(0, 0, size.x, maxf(0.0, r.position.y)), shade)
	draw_rect(Rect2(0, r.end.y, size.x, maxf(0.0, size.y - r.end.y)), shade)
	draw_rect(Rect2(0, r.position.y, maxf(0.0, r.position.x), r.size.y), shade)
	draw_rect(Rect2(r.end.x, r.position.y, maxf(0.0, size.x - r.end.x), r.size.y), shade)
	var glow := 0.55 + 0.45 * sin(_t * 5.0)
	draw_rect(r, Color(UITheme.GOLD, 0.6 + 0.4 * glow), false, 6.0 + 4.0 * _pulse)
	draw_rect(r.grow(8.0), Color(UITheme.GOLD, 0.18 * glow), false, 6.0)
	if blocking:
		return
	# a bouncing arrow above it (or below, near the top of the screen)
	var bob := sin(_t * 6.0) * 12.0
	var cx := r.get_center().x
	var w := 34.0
	var h := 40.0
	if r.position.y > 120.0:
		var tip := Vector2(cx, r.position.y - 14.0 - bob)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-w, -h), tip + Vector2(w, -h)]), UITheme.GOLD)
	else:
		var tip2 := Vector2(cx, r.end.y + 14.0 + bob)
		draw_colored_polygon(PackedVector2Array([tip2, tip2 + Vector2(-w, h), tip2 + Vector2(w, h)]), UITheme.GOLD)
