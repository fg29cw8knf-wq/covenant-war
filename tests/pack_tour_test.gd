extends Node
## Bram's pack tour in Ashford, played tap by tap with real input events: a
## new game (no cards, no Deck or Codex), the Spark deck handed over, Deck and
## Codex unlocked, then every step of PackTour.FIRST_DECK. At each instruction
## it first tries wrong taps and keys (they must be blocked and nudge), then
## does the right thing; explanations are moved on by a tap, E, Space and
## Enter in turn. Then a short tour driven only by Tab and Esc. Saves a
## screenshot of every step. Ends with "PACK TOUR TEST: ok".
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/pack_tour_test.tscn -- <out_dir> [WxH] [ui=1.3]

const SPARK := ["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask", "healing_draught",
	"bulwark", "essence_flask", "healing_draught", "essence_flask", "bulwark", "travellers_pack"]

var out_dir := "user://"
var size := Vector2i(1600, 900)
var problems := []
var world: World
var hud: WorldHUD
var menu: PauseMenu
var tour: PackTour
var _explained := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1 and "x" in args[1]:
		var p: PackedStringArray = args[1].split("x")
		size = Vector2i(int(p[0]), int(p[1]))
	get_window().size = size
	get_viewport().scaling_3d_scale = 0.5   # the village behind at half resolution (software GL is slow); the UI stays sharp
	Game.settings["first_steps"] = 2      # no "tap the ground" hints over the tour
	Game.new_game("Sprout", "")
	for a in args:
		if a.begins_with("ui="):
			Game.settings["ui_scale"] = float(a.trim_prefix("ui="))   # Options > Text and buttons size
	Game.set_flag("arrived_ashford")      # skip the opening flight and Bram's welcome (World._arrive)
	world = World.new().setup("ashford", "green")
	add_child(world)
	hud = world.hud
	menu = hud._menu
	await _frames(20)
	await get_tree().create_timer(4.2).timeout   # the fade in and the area title
	_expect(Game.v2.deck.is_empty() and Game.v2.collection.is_empty() and Game.v2.codex.is_empty(), "a new game has cards")
	_expect(not Game.unlocked("deck") and not Game.unlocked("codex"), "Deck or Codex open before Bram's deck")
	# Bram hands over the Spark deck
	Game.give_first_deck(SPARK)
	Game.unlock("deck")
	Game.unlock("codex")
	var start := world.player.global_position
	var done := [false]
	var run := func() -> void:
		await hud.pack_tour()
		done[0] = true
	run.call()
	await _frames(2)
	for c in hud._root.get_children():
		if c is PackTour:
			tour = c
	_expect(tour != null, "the tour didn't start")
	if tour == null:
		_finish()
		return
	var steps: Array = PackTour.FIRST_DECK
	for i in steps.size():
		var st: Dictionary = steps[i]
		if not await _until(func() -> bool: return tour.index == i):
			problems.append("step %d never showed" % (i + 1))
			break
		await get_tree().create_timer(0.45).timeout   # past the tap guard, and the box has faded in
		await _shot("%02d_%s" % [i + 1, String(st.get("do", st.get("focus", "say"))).replace(":", "_")])
		if st.has("do"):
			await _wrong(i, String(st.do))
			await _right(String(st.do))
		else:
			if st.has("focus") and not tour._rect(String(st.focus)).has_area():
				problems.append("step %d: nothing to spotlight for '%s'" % [i + 1, st.focus])
			await _explanation_go(i)
		if not await _until(func() -> bool: return done[0] or not is_instance_valid(tour) or tour.index > i):
			problems.append("step %d (%s) didn't move on" % [i + 1, st.get("do", "explanation")])
			break
	await _until(func() -> bool: return done[0])
	await _frames(4)
	await _shot("11_after")
	_expect(not menu.visible, "the pack is still open after the tour")
	_expect(not world.busy, "the world is still busy after the tour")
	_expect(world.player.global_position.distance_to(start) < 0.05, "the player moved during the tour")
	var kept := Game.lessons().filter(func(l): return String(l.group) == PackTour.GROUP)
	_expect(kept.size() == steps.size(), "not every line is on the How to Duel page (%d)" % kept.size())
	hud.open_menu("howto")
	await _frames(8)
	await _shot("12_howto")
	menu.request_close()
	await _frames(4)
	await _keyboard_tour()
	_finish()


## A short tour with only keys: Tab opens the pack, Esc closes it.
func _keyboard_tour() -> void:
	var done := [false]
	var run := func() -> void:
		await hud.pack_tour([{"say": "Open your pack.", "do": "menu"}, {"say": "And close it.", "do": "resume"}])
		done[0] = true
	run.call()
	await _frames(2)
	for c in hud._root.get_children():
		if c is PackTour and not c.is_queued_for_deletion():
			tour = c
	if not await _until(func() -> bool: return is_instance_valid(tour) and tour.index == 0):
		problems.append("the keyboard tour didn't start")
		return
	await _key(KEY_E)
	_expect(not menu.visible and tour.index == 0, "E opened the pack")
	await _key(KEY_TAB)
	_expect(await _until(func() -> bool: return done[0] or tour.index == 1), "Tab didn't open the pack")
	await _shot("13_keys_open")
	await _key(KEY_ESCAPE)
	_expect(await _until(func() -> bool: return done[0]), "Esc didn't close the pack")
	_expect(not menu.visible, "the pack is still open")


# ------------------------------------------------------------ the steps ---

## Wrong taps and keys first: nothing may change, and each one nudges.
func _wrong(i: int, d: String) -> void:
	var before := tour.nudges
	var tab_before := menu.tab
	var open_before := menu.visible
	var card_before := menu.open_card_id()
	match d:
		"menu":
			await _click(_view_size() * Vector2(0.5, 0.72))    # the ground: no walking
			await _key(KEY_E)                                   # talk / interact
			await _hold(KEY_W, 8)                               # walking
			_expect(world._move_target == null, "a tap on the ground set a walk target")
		"tab:deck":
			await _click(_center("tab:codex"))
			await _shot("%02db_wrong_tap" % (i + 1))
			await _key(KEY_TAB)                                 # the menu key mustn't close the pack
		"card":
			await _click(_center("tab:hero"))
			await _click(_center("resume"))
		"close":
			await _click(Vector2(12, 12))                       # the dark edge, which would normally close it
		"tab:codex":
			await _click(_center("tab:hero"))
			await _key(KEY_ENTER)
		"resume":
			await _click(_center("tab:options"))
			await _key(KEY_SPACE)
	await _frames(3)
	_expect(tour.index == i, "step %d moved on after a wrong tap" % (i + 1))
	_expect(menu.tab == tab_before and menu.visible == open_before and menu.open_card_id() == card_before,
		"step %d: a wrong tap changed the pack (%s)" % [i + 1, d])
	_expect(tour.nudges > before, "step %d: a wrong tap didn't nudge" % (i + 1))


## The right tap.
func _right(d: String) -> void:
	var target := d
	if d == "card":
		target = "card:brookfin"
	var c := _center(target)
	if c == Vector2(-1, -1):
		problems.append("nothing on screen for '%s'" % d)
		return
	await _click(c)


## Explanations move on with a tap, then E, Space and Enter in turn. Esc
## first, which must do nothing.
func _explanation_go(i: int) -> void:
	var open_before := menu.visible
	await _key(KEY_ESCAPE)
	await _frames(2)
	_expect(tour.index == i and menu.visible == open_before, "Esc did something during an explanation")
	match _explained % 4:
		0:
			await _click(_view_size() * Vector2(0.3, 0.5))
		1:
			await _key(KEY_E)
		2:
			await _key(KEY_SPACE)
		3:
			await _key(KEY_ENTER)
	_explained += 1


# ---------------------------------------------------------------- input ---

## The centre of something the tour knows about, in the HUD's space.
func _center(what: String) -> Vector2:
	var r: Rect2 = tour._rect(what) if what in ["menu", "menu_button"] else menu.tour_rect(what)
	return r.get_center() if r.has_area() else Vector2(-1, -1)


func _view_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## A real left click (press and release) at a point in the HUD's space.
func _click(p: Vector2) -> void:
	var wp := get_tree().root.get_final_transform() * p
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = wp
		e.global_position = wp
		Input.parse_input_event(e)
		await _frames(1)


func _key(k: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = pressed
		Input.parse_input_event(e)
		await _frames(1)


func _hold(k: Key, frames: int) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(frames)
	var up: InputEventKey = e.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


# -------------------------------------------------------------- helpers ---

func _until(cond: Callable, secs := 90.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > secs * 1000.0:
			return false
		await get_tree().process_frame
	return true


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _finish() -> void:
	print("PACK TOUR TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS " + str(problems)))
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/tour_%s.png" % [out_dir, name])
