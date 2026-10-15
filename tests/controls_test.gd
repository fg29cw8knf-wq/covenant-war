extends Node
## Checks the pause menu's Controls page against the game, the way a player
## would use it: real key presses, pad buttons, the left stick and mouse
## clicks (Input.parse_input_event) on a running Ashford, the dialogue box,
## the pause menu, a card reveal, a story screen, the opening movie, the
## notice and title screens, a duel and Bram's duel lessons.
## Prints PASS or FAIL for each control, then "CONTROLS TEST: ok" (or the
## failures) and exits 1 if anything failed. It runs rendered or headless
## (headless is much quicker on a busy machine; input works the same):
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 960x540 res://tests/controls_test.tscn
##   godot --headless res://tests/controls_test.tscn

## A short talk of our own for Seamus, so the test doesn't hang on the story's lines.
const LINES := [
	{"who": "seamus", "say": "One."},
	{"who": "seamus", "say": "Two."},
	{"who": "seamus", "say": "Three."},
]
const ASK := [
	{"who": "seamus", "say": "Pick one."},
	{"choice": ["Alpha", "Beta", "Gamma"], "then": [[{"set": "ctl_pick_0"}], [{"set": "ctl_pick_1"}], [{"set": "ctl_pick_2"}]]},
	{"who": "seamus", "say": "Done."},
]
## The Lantern Duel's decks, dealt in order: Brookfin is always in the first hand.
const MY_DECK := ["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask",
	"healing_draught", "bulwark", "essence_flask", "healing_draught", "essence_flask", "bulwark", "travellers_pack"]
const RIVAL_DECK := ["cinderpup", "essence_flask", "healing_draught", "essence_flask", "travellers_pack", "essence_flask",
	"firebrand", "essence_flask", "healing_draught", "essence_flask", "healing_draught", "essence_flask"]
## A lesson of our own: explanations to tap through, then two instructions.
const LESSON := {
	"events": {"intro": [{"say": "Tutor one."}, {"say": "Tutor two."}, {"say": "Tutor three."}, {"say": "Tutor four."},
		{"say": "Tutor five."}, {"say": "Tutor six."}, {"say": "Roll.", "do": "die"}]},
	"turns": [[{"say": "Turn one."}, {"say": "Tap Brookfin.", "do": "card:brookfin"}]],
}

const SPACE := {"name": "Space", "kind": "key", "code": KEY_SPACE}
const ENTER := {"name": "Enter", "kind": "key", "code": KEY_ENTER}
const KP_ENTER := {"name": "keypad Enter", "kind": "key", "code": KEY_KP_ENTER}
const E := {"name": "E", "kind": "key", "code": KEY_E}
const ESC := {"name": "Esc", "kind": "key", "code": KEY_ESCAPE}
const PAD_A := {"name": "pad A", "kind": "pad", "code": JOY_BUTTON_A}

var fails: Array = []
var passes := 0
var world: World
var hud: WorldHUD
var dlg: DialogueBox
var _mask := 0
var _settings_file = null   # the player's settings file as it was, put back at the end


func _ready() -> void:
	# the notice and the first-steps hints save settings ("seen the notice");
	# other tests (menu_test) behave differently once those are set
	if FileAccess.file_exists(Game.SETTINGS_PATH):
		_settings_file = FileAccess.get_file_as_string(Game.SETTINGS_PATH)
	_watchdog()
	await frames(5)
	# the mouse lands where it's sent (design coordinates to the window's and back)
	mouse_to(Vector2(960, 540))
	await frames(1)
	check("test: mouse events land where they're aimed", get_viewport().get_mouse_position().distance_to(Vector2(960, 540)) < 2.0,
		"landed at %s" % get_viewport().get_mouse_position())
	await _world()
	await _story()
	await _movie()
	await _notice()
	await _title()
	await _duel()
	await _lesson()
	print("")
	if fails.is_empty():
		print("CONTROLS TEST: ok (%d checks)" % passes)
	else:
		print("CONTROLS TEST: %d FAILED of %d: %s" % [fails.size(), fails.size() + passes, ", ".join(fails)])
	_quit(1 if not fails.is_empty() else 0)


## Gives up after 20 minutes of real time (a slow, shared machine can take a while).
func _watchdog() -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1200000:
		await get_tree().create_timer(5.0).timeout
	print("FAIL  test: timed out")
	_quit(1)


## Puts the settings file back as it was, then quits.
func _quit(code: int) -> void:
	if _settings_file is String:
		var f := FileAccess.open(Game.SETTINGS_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(_settings_file)
			f.close()
	elif FileAccess.file_exists(Game.SETTINGS_PATH):
		DirAccess.remove_absolute(Game.SETTINGS_PATH)
	get_tree().quit(code)


func check(what: String, ok: bool, why: String = "") -> void:
	if ok:
		passes += 1
		print("PASS  ", what)
	else:
		fails.append(what)
		print("FAIL  ", what, ("   (" + why + ")") if why != "" else "")


# ================================================================ world ===

func _world() -> void:
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")   # no opening flight or welcome: straight to walking about
	world = World.new().setup("ashford", "green")
	add_child(world)
	await until(func() -> bool: return world.hud != null and world.hud._fade.modulate.a < 0.05 and not world.busy, 8.0)
	hud = world.hud
	dlg = hud.dialogue
	await secs(0.5)
	await _walking()
	await _talking()
	await _answers()
	await _pause_menu()
	await _card_reveal()
	world.queue_free()
	world = null
	await frames(4)


func _walking() -> void:
	var dirs := {"left": Vector3.LEFT, "right": Vector3.RIGHT, "up": Vector3.FORWARD, "down": Vector3.BACK}
	for t in [["D", KEY_D, "right"], ["A", KEY_A, "left"], ["W", KEY_W, "up"], ["S", KEY_S, "down"],
			["the right arrow", KEY_RIGHT, "right"], ["the left arrow", KEY_LEFT, "left"],
			["the up arrow", KEY_UP, "up"], ["the down arrow", KEY_DOWN, "down"]]:
		var p0 := world.player.global_position
		key(t[1], true)
		await secs(0.35)
		key(t[1], false)
		await secs(0.2)
		var d: float = (world.player.global_position - p0).dot(dirs[t[2]])
		check("walk %s with %s" % [t[2], t[0]], d > 0.8, "moved %.2f m" % d)
	var p1 := world.player.global_position
	await secs(0.3)
	check("walking stops when the key is let go", world.player.global_position.distance_to(p1) < 0.05)
	for t in [["right", JOY_AXIS_LEFT_X, 1.0], ["left", JOY_AXIS_LEFT_X, -1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var p0 := world.player.global_position
		stick(t[1], t[2])
		await secs(0.35)
		stick(t[1], 0.0)
		await secs(0.2)
		var d: float = (world.player.global_position - p0).dot(dirs[t[0]])
		check("walk %s with the left stick" % t[0], d > 0.8, "moved %.2f m" % d)
	# drag anywhere: a joystick appears under the thumb
	var s := Vector2(560, 640)
	var p2 := world.player.global_position
	mouse_to(s)
	await frames(1)
	mouse_button(s, true)
	await frames(2)
	for k in 6:
		mouse_to(s + Vector2(20.0 * (k + 1), 0))
		await frames(1)
	await secs(0.35)
	mouse_button(s + Vector2(120, 0), false)
	await secs(0.2)
	var dd := (world.player.global_position - p2).dot(Vector3.RIGHT)
	check("walk by dragging on the screen (the joystick)", dd > 0.8, "moved %.2f m" % dd)
	# tap / click the ground
	var goal := world.player.global_position + Vector3(-3.0, 0, 0)
	await click(world.cam.unproject_position(goal))
	await secs(1.4)
	var miss := Vector2(world.player.global_position.x - goal.x, world.player.global_position.z - goal.z).length()
	check("click the ground to walk there", miss < 0.8, "%.2f m short" % miss)


## Stands the player in front of an NPC, close enough for the round button.
func _go_near(id: String) -> Dictionary:
	var n: Dictionary = world._npc_by_id(id)
	world._move_target = null
	world._talk_target = null
	world.player.global_position = n.body.global_position + Vector3(0, 0, 1.6)
	world.player.velocity = Vector3.ZERO
	world._focus = world._cam_focus_target()
	await until(func() -> bool: return world._near == n and hud._talk.visible and not world.busy, 3.0)
	return n


func _typed() -> void:
	await until(func() -> bool: return not dlg._typing, 3.0)
	await frames(2)


func _talking() -> void:
	var n := await _go_near("seamus")
	check("the round Talk button shows beside Seamus", hud._talk.visible)
	# each way to start a talk, each way to move on a line, and the key that
	# closes the last line must not open the talk again
	var runs := [[SPACE, E, ENTER], [ENTER, SPACE, PAD_A], [E, PAD_A, SPACE], [PAD_A, ENTER, E]]
	for r in runs:
		n.def.talk = LINES.duplicate(true)
		await until(func() -> bool: return not world.busy and world._near == n and hud._talk.visible, 3.0)
		await frames(3)
		var s: Dictionary = r[0]
		_down(s)
		await frames(1)
		var started := world.busy and dlg.visible
		check("%s starts a talk when the round button shows" % s.name, started, "busy %s, box %s" % [world.busy, dlg.visible])
		await frames(1)
		_up(s)
		await frames(2)
		if not started:
			continue
		await _typed()
		_echo(s)
		await frames(2)
		check("holding %s doesn't race through the lines" % s.name, dlg._text.text == "One.", "now on '%s'" % dlg._text.text)
		await _press(r[1])
		check("next line with %s" % r[1].name, dlg._text.text == "Two.", "on '%s'" % dlg._text.text)
		await _typed()
		await _press(r[2])
		check("next line with %s" % r[2].name, dlg._text.text == "Three.", "on '%s'" % dlg._text.text)
		await _typed()
		_down(s)
		await frames(2)
		var closed := not world.busy and not dlg.visible
		_up(s)
		await frames(6)
		check("%s on the last line ends the talk without starting it again" % s.name, closed and not world.busy and not dlg.visible,
			"busy %s, box %s" % [world.busy, dlg.visible])
	# the mouse (or a finger): the round button, the person, the box
	n.def.talk = LINES.duplicate(true)
	await frames(3)
	await click(center_of(hud._talk))
	check("click the round Talk button", world.busy and dlg.visible)
	await _typed()
	await click(center_of(dlg._panel))
	check("click the conversation box for the next line", dlg._text.text == "Two.", "on '%s'" % dlg._text.text)
	await _typed()
	await click(Vector2(300, 300))
	await _typed()
	await click(Vector2(300, 300))
	check("click on the last line ends the talk", not world.busy and not dlg.visible)
	await until(func() -> bool: return not world.busy and hud._talk.visible, 2.0)
	await click(world.cam.unproject_position(n.body.global_position + Vector3(0, 1.3, 0)))
	check("click the person to talk", world.busy and dlg.visible)
	for k in 3:
		await _typed()
		await click(center_of(dlg._panel))
	await until(func() -> bool: return not world.busy, 2.0)
	# from further away: walks over, then talks
	var far := await _go_near("seamus")
	world.player.global_position = far.body.global_position + Vector3(0, 0, 4.2)
	world._focus = world._cam_focus_target()
	await until(func() -> bool: return world._near == null, 2.0)
	await frames(4)
	await click(world.cam.unproject_position(far.body.global_position + Vector3(0, 1.3, 0)))
	var walked := await until(func() -> bool: return world.busy and dlg.visible, 4.0)
	check("click someone further off: walk over and talk", walked)
	for k in 3:
		await _typed()
		await press(KEY_E)
	await until(func() -> bool: return not world.busy, 2.0)
	# nothing while the pause menu is open, or in a cutscene
	await _go_near("seamus")
	hud.open_menu()
	await frames(2)
	await press(KEY_E)
	await _press(PAD_A)
	check("E or A does nothing while the pause menu is open", not world.busy and not dlg.visible)
	hud.close_menu()
	await frames(2)
	world.cine = true
	await press(KEY_E)
	await press(KEY_SPACE)
	check("E or Space does nothing in a cutscene", not world.busy and not dlg.visible)
	world.cine = false
	await frames(2)


func _answers() -> void:
	var n := await _go_near("seamus")
	var keyb := [
		# [start, then: the inputs to move to the answer, the input that picks, the answer]
		[E, [{"name": "the down arrow", "kind": "key", "code": KEY_DOWN}], ENTER, 1, "the arrow keys and Enter"],
		[ENTER, [{"name": "S", "kind": "key", "code": KEY_S}, {"name": "S", "kind": "key", "code": KEY_S},
			{"name": "W", "kind": "key", "code": KEY_W}, {"name": "S", "kind": "key", "code": KEY_S}], E, 2, "W / S and E"],
		[PAD_A, [{"name": "stick down", "kind": "stick", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}], PAD_A, 1, "the left stick and A"],
		[PAD_A, [{"name": "d-pad down", "kind": "pad", "code": JOY_BUTTON_DPAD_DOWN}], PAD_A, 1, "the d-pad and A"],
	]
	for r in keyb:
		for i in 3:
			Game.flags.erase("ctl_pick_%d" % i)
		n.def.talk = ASK.duplicate(true)
		await until(func() -> bool: return not world.busy and hud._talk.visible, 3.0)
		await frames(3)
		await _press(r[0])
		await _typed()
		await press(KEY_SPACE)   # the question's line: on to the answers
		await frames(1)
		await press(KEY_SPACE)   # a mashed Space, as the answers appear
		await secs(0.5)
		await press(KEY_SPACE)   # and a deliberate one
		var none: bool = not Game.flag("ctl_pick_0") and not Game.flag("ctl_pick_1") and not Game.flag("ctl_pick_2")
		check("Space doesn't pick an answer (%s run)" % r[4], none and dlg._choices.visible)
		var f := get_viewport().gui_get_focus_owner()
		check("the first answer has keyboard focus (%s run)" % r[4], f != null and f.get_parent() == dlg._choices and f.get_index() == 0)
		for mv in r[1]:
			await _press(mv)
			await frames(2)
		await _press(r[2])
		await frames(2)
		check("pick an answer with %s" % r[4], Game.flag("ctl_pick_%d" % r[3]) and dlg._text.text == "Done.",
			"picked %s, on '%s'" % [[Game.flag("ctl_pick_0"), Game.flag("ctl_pick_1"), Game.flag("ctl_pick_2")], dlg._text.text])
		await _typed()
		await press(KEY_E)
		await until(func() -> bool: return not world.busy, 2.0)
	# click (tap) an answer
	for i in 3:
		Game.flags.erase("ctl_pick_%d" % i)
	n.def.talk = ASK.duplicate(true)
	await until(func() -> bool: return not world.busy and hud._talk.visible, 3.0)
	await click(center_of(hud._talk))
	await _typed()
	await click(center_of(dlg._panel))
	await secs(0.3)
	await click(center_of(dlg._choices.get_child(2)))
	await frames(2)
	check("click an answer", Game.flag("ctl_pick_2") and dlg._text.text == "Done.")
	await _typed()
	await click(center_of(dlg._panel))
	await until(func() -> bool: return not world.busy, 2.0)


func _pause_menu() -> void:
	await until(func() -> bool: return not world.busy and hud._menu_btn.visible, 3.0)
	var menu: PauseMenu = hud._menu
	for k in [["Esc", KEY_ESCAPE], ["Tab", KEY_TAB]]:
		await press(k[1])
		check("%s opens the pause menu" % k[0], hud.menu_open())
		await press(k[1])
		check("%s closes the pause menu" % k[0], not hud.menu_open())
	await _press({"name": "Start", "kind": "pad", "code": JOY_BUTTON_START})
	check("Start opens the pause menu", hud.menu_open())
	await _press({"name": "Start", "kind": "pad", "code": JOY_BUTTON_START})
	check("Start closes the pause menu", not hud.menu_open())
	await click(center_of(hud._menu_btn))
	check("tap ☰ opens the pause menu", hud.menu_open())
	# a tab clicked with the mouse takes keyboard focus; Tab and Esc must still close the menu
	await click(center_of(menu._tab_btns["controls"]))
	check("click a menu tab (and it takes the keyboard focus)", menu.tab == "controls"
		and get_viewport().gui_get_focus_owner() == menu._tab_btns["controls"])
	await press(KEY_TAB)
	check("Tab closes the menu after a tab was clicked", not hud.menu_open())
	await press(KEY_ESCAPE)
	await click(center_of(menu._tab_btns["options"]))
	await press(KEY_ESCAPE)
	check("Esc closes the menu after a tab was clicked", not hud.menu_open())
	await press(KEY_ESCAPE)
	var resume: Button = null
	for b in menu._tab_btns.values()[0].get_parent().get_children():
		if b is Button and (b as Button).text == "Resume":
			resume = b
	await click(center_of(resume))
	check("click Resume closes the menu", not hud.menu_open())
	# Esc on a card's detail closes the detail, then the menu
	hud.open_menu("codex")
	await frames(4)
	menu._open_card("cinderpup")
	await frames(4)
	await press(KEY_ESCAPE)
	check("Esc closes a card's detail in the menu", menu._overlay == null and hud.menu_open())
	await press(KEY_ESCAPE)
	check("Esc again closes the menu", not hud.menu_open())
	await frames(4)


func _card_reveal() -> void:
	world.busy = true   # a reveal only ever comes in the middle of a talk
	for way in [E, SPACE, ENTER, PAD_A, {"name": "a click", "kind": "click"}]:
		var done := [false]
		var run := func() -> void:
			await hud.show_card_reward("wren")
			done[0] = true
		run.call()
		await frames(2)
		await _press(way)
		var early: bool = done[0]
		await secs(0.8)
		await _press(way)
		check("%s closes the NEW SIGIL card (not in its first moment)" % way.name, done[0] and not early, "early %s, done %s" % [early, done[0]])
		await until(func() -> bool: return done[0], 1.0)
	world.busy = false


# ================================================================ story ===

func _story() -> void:
	var story := StoryScreen.new()
	add_child(story)
	await frames(2)
	var done := [false]
	var run := func() -> void:
		await story.scene("card", [{"text": "First."}, {"text": "Second."}, {"chart": "elements"}, {"text": "Third."}])
		done[0] = true
	run.call()
	var box := story.box
	await until(func() -> bool: return box.visible and box._text.text == "First." and not box._typing, 6.0)
	await frames(2)
	await press(KEY_SPACE)
	check("story: next line with Space", box._text.text == "Second.")
	await until(func() -> bool: return not box._typing, 3.0)
	await press(KEY_ENTER)
	var chart := await until(func() -> bool: return _chart(story) != null, 2.0)
	check("story: the element chart comes up", chart)
	await secs(0.6)
	await press(KEY_E)
	await frames(3)
	check("story: E goes on from the element chart (tap to go on)", _chart(story) == null and box._text.text == "Third.")
	await until(func() -> bool: return not box._typing, 3.0)
	await _press(PAD_A)
	await until(func() -> bool: return done[0], 2.0)
	check("story: next line with A", done[0])
	story.queue_free()
	await frames(3)


func _chart(story: StoryScreen) -> Control:
	for c in story._root.get_children():
		if c is StoryScreen.ChartOverlay and not c.is_queued_for_deletion():
			return c
	return null


# ================================================================ movie ===

func _movie() -> void:
	# the title's focused button sits under the movie; it mustn't take the keys
	var layer := CanvasLayer.new()
	add_child(layer)
	var under := Button.new()
	under.text = "Underneath"
	layer.add_child(under)
	var hits := [0]
	under.pressed.connect(func() -> void: hits[0] += 1)
	for way in [SPACE, ENTER, E, PAD_A]:
		under.grab_focus()
		var m := OpeningMovie.new()
		add_child(m)
		await secs(0.3)
		await _press(way)
		await secs(0.3)
		check("movie: %s shows Skip" % way.name, m._skip.modulate.a > 0.5 and not m._done)
		await _press(way)
		check("movie: %s again skips" % way.name, m._done)
		check("movie: the button under the movie didn't take %s" % way.name, hits[0] == 0, "pressed %d times" % hits[0])
		await _gone(m)
	for way in [ESC, {"name": "Start", "kind": "pad", "code": JOY_BUTTON_START}]:
		var m := OpeningMovie.new()
		add_child(m)
		await secs(0.3)
		await _press(way)
		check("movie: %s skips straight away" % way.name, m._done)
		await _gone(m)
	layer.queue_free()
	await frames(2)


# =============================================================== notice ===

func _notice() -> void:
	for way in [ENTER, SPACE, E, PAD_A, ESC]:
		var n := NoticeScreen.new()
		add_child(n)
		await secs(1.5)
		await _press(way)
		check("notice: %s carries on" % way.name, n._done)
		await _gone(n)


# ================================================================ title ===

func _title() -> void:
	var title := TitleScreen.new()
	add_child(title)
	await frames(4)
	var f := get_viewport().gui_get_focus_owner()
	check("title: the first button has keyboard focus", f is Button and (f as Button).text in ["Continue", "New Game"])
	var got := [""]
	title.watch_opening.connect(func() -> void: got[0] = "watch")
	title.open_lab.connect(func() -> void: got[0] = "lab")
	for i in 6:
		var fo := get_viewport().gui_get_focus_owner()
		if fo is Button and (fo as Button).text == "Watch the opening":
			break
		await press(KEY_DOWN)
	await press(KEY_ENTER)
	check("title: the down arrow then Enter", got[0] == "watch")
	got[0] = ""
	await press(KEY_UP)
	await press(KEY_SPACE)
	check("title: the up arrow then Space", got[0] == "lab")
	got[0] = ""
	await _press(PAD_A)
	check("title: A presses the button with focus", got[0] == "lab")
	title.queue_free()
	await frames(3)


# ================================================================= duel ===

func _duel_spec(lesson: Dictionary) -> Dictionary:
	var spec := {"decks": [MY_DECK.duplicate(), RIVAL_DECK.duplicate()], "names": ["Sprout", "Corin"],
		"profiles": [Lore.new_profile("Sprout"), Lore.new_profile("Corin")], "ai": [false, true],
		"difficulty": 0.25, "life": 25, "stacked": [true, true], "first": 0, "speed": 6.0}
	if not lesson.is_empty():
		spec["tutorial"] = lesson
	return spec


func _hand(ds: DuelScreen, id: String) -> Control:
	for hv in ds.hand_views:
		if hv.card.id == id:
			return hv
	return null


func _duel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var ds := DuelScreen.new().configure(_duel_spec({}))
	layer.add_child(ds)
	if not await until(func() -> bool: return ds.mode == "main", 30.0):
		check("duel: reaches the player's turn", false)
		return
	await secs(0.6)
	await press(KEY_ESCAPE)
	check("duel: Esc with nothing selected opens the duel menu", ds.lab_panel.visible)
	await press(KEY_ESCAPE)
	check("duel: Esc closes the duel menu", not ds.lab_panel.visible)
	var menu_btn: Control = null
	for c in ds.stage.get_children():
		if c is DuelViews.IconButton:
			menu_btn = c
	await click(center_of(menu_btn))
	check("duel: click ☰ opens the duel menu", ds.lab_panel.visible)
	await click(center_of(menu_btn))
	check("duel: click ☰ again closes it", not ds.lab_panel.visible)
	var hv := _hand(ds, "brookfin")
	await click(center_of(hv))
	await secs(0.3)
	check("duel: click a card in your hand to look at it and pick it", ds.sel_card != null and ds.detail.visible and ds.pending == "call")
	await press(KEY_SPACE)
	check("duel: Space with a card picked doesn't end the turn", ds.mode == "main" and ds.sel_card != null)
	await press(KEY_ESCAPE)
	check("duel: Esc cancels the picked card", ds.sel_card == null and ds.pending == "" and not ds.lab_panel.visible)
	await secs(0.3)
	await click(center_of(hv))
	await secs(0.3)
	await click(center_of(hv), MOUSE_BUTTON_RIGHT)
	check("duel: right-click (on the card) cancels", ds.sel_card == null and ds.pending == "", "card %s, pending '%s'" % [ds.sel_card, ds.pending])
	await secs(0.3)
	await click(center_of(hv))
	await secs(0.3)
	await click(Vector2(220, 560), MOUSE_BUTTON_RIGHT)
	check("duel: right-click (on the board) cancels", ds.sel_card == null and ds.pending == "", "card %s, pending '%s'" % [ds.sel_card, ds.pending])
	await secs(0.3)
	await click(center_of(hv))
	await secs(0.3)
	var cancel: Control = null
	for c in ds.actions.get_children():
		if c is Button and (c as Button).text == "Cancel":
			cancel = c
	check("duel: a Cancel button shows while picking a slot", cancel != null)
	if cancel != null:
		await click(center_of(cancel))
		check("duel: tap Cancel", ds.sel_card == null and ds.pending == "")
	await secs(0.3)
	await click(center_of(hv))
	await secs(0.3)
	var v0: Control = ds.views[ds.me][0]
	await click(ds.stage.get_global_transform_with_canvas() * (v0.position + Vector2(-20, v0.size.y * 0.5)))
	check("duel: a tap just beside a slot doesn't throw the choice away", ds.sel_card != null and ds.pending == "call")
	await click(ds.stage.get_global_transform_with_canvas() * Vector2(220, 590))
	check("duel: tap an empty part of the board to change your mind", ds.sel_card == null and ds.pending == "",
		"card %s, pending '%s'" % [ds.sel_card, ds.pending])
	await secs(0.3)
	# call Brookfin: the card, then the empty middle slot
	if ds.sel_card == null:
		await click(center_of(hv))
		await secs(0.3)
	await click(center_of(ds.views[ds.me][1]))
	var called := await until(func() -> bool: return ds.game.players[ds.me].slots[1] != null and ds.mode == "main", 15.0)
	check("duel: click a Totem, then an empty slot, to call it", called)
	await secs(0.4)
	var turn := ds.game.turn
	await press(KEY_SPACE)
	check("duel: Space with nothing selected ends the turn", ds.mode != "main")
	var back := await until(func() -> bool: return ds.mode == "main" and ds.game.turn > turn, 40.0)
	check("duel: the rival plays and it's the player's turn again", back)
	if back:
		await secs(0.6)
		await click(center_of(ds.views[ds.me][1]))
		await secs(0.3)
		check("duel: click your Totem to see its moves", ds.sel_totem != null)
		await press(KEY_ESCAPE)
		check("duel: Esc cancels the picked Totem", ds.sel_totem == null and not ds.lab_panel.visible)
		await secs(0.3)
		await click(center_of(ds.gift_btn))
		check("duel: click the Gift medallion (it answers)", ds.actions.get_child_count() > 0 or ds.pending == "gift")
		await press(KEY_ESCAPE)
		await secs(0.3)
		if ds.pending != "" or ds.sel_totem != null or ds.sel_card != null:
			await press(KEY_ESCAPE)
		if ds.lab_panel.visible:
			await press(KEY_ESCAPE)
		turn = ds.game.turn
		await click(center_of(ds.end_btn))
		check("duel: click the big emblem to end the turn", ds.mode != "main")
	ds._leave("quit")
	layer.queue_free()
	await frames(3)


func _lesson() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var ds := DuelScreen.new().configure(_duel_spec(LESSON))
	layer.add_child(ds)
	if not await until(func() -> bool: return ds.tutor != null and ds.tutor.blocking and ds.tutor.text_label.text == "Tutor one.", 30.0):
		check("lesson: Bram's first line comes up", false)
		return
	var tu := ds.tutor
	var steps := [[SPACE, "Tutor two."], [ENTER, "Tutor three."], [E, "Tutor four."], [KP_ENTER, "Tutor five."],
		[PAD_A, "Tutor six."], [{"name": "a click", "kind": "click"}, "Roll."]]
	for s in steps:
		await secs(0.45)   # a line ignores taps for its first moment
		await _press(s[0])
		await frames(2)
		check("lesson: %s goes on from TAP TO CONTINUE" % s[0].name, tu.text_label.text == s[1], "on '%s'" % tu.text_label.text)
	for way in [SPACE, ENTER, E, PAD_A]:
		await _press(way)
		await frames(2)
	check("lesson: no key skips 'tap the die'", not tu.event_step.is_empty())
	ds._on_die_tapped(true)
	if not await until(func() -> bool: return tu.blocking and tu.text_label.text == "Turn one.", 30.0):
		check("lesson: the turn's first line comes up", false)
		ds._leave("quit")
		layer.queue_free()
		return
	await secs(0.45)
	await press(KEY_SPACE)
	await frames(2)
	check("lesson: Space goes on to an instruction", tu.text_label.text == "Tap Brookfin." and not tu.blocking and tu.gating())
	var q := tu.queue.size()
	for way in [SPACE, ENTER, E, PAD_A, ESC]:
		await _press(way)
		await frames(2)
	check("lesson: no key skips 'Tap Brookfin', ends the turn or opens the menu",
		tu.queue.size() == q and ds.mode == "main" and not ds.lab_panel.visible, "queue %d -> %d, mode %s" % [q, tu.queue.size(), ds.mode])
	await click(center_of(_hand(ds, "brookfin")))
	await frames(2)
	check("lesson: clicking the card Bram asks for moves it on", tu.queue.size() < q)
	ds._leave("quit")
	layer.queue_free()
	await frames(3)


# ================================================================ input ===

func _send(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func key(code: Key, down: bool = true, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	e.echo = echo
	_send(e)


## A key pressed and let go a few frames later, as a person would.
func press(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(2)


func pad(button: JoyButton, down: bool = true) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = down
	e.pressure = 1.0 if down else 0.0
	_send(e)


func stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	_send(e)


## Design (canvas) coordinates to the window's, where real mouse events arrive.
func _win(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func mouse_to(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _win(p)
	e.global_position = e.position
	e.button_mask = _mask
	_send(e)


func mouse_button(p: Vector2, down: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var bit := MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
	_mask = (_mask | bit) if down else (_mask & ~bit)
	var e := InputEventMouseButton.new()
	e.position = _win(p)
	e.global_position = e.position
	e.button_index = button
	e.pressed = down
	e.button_mask = _mask
	_send(e)


## The pointer moves there, presses and lets go: a quick click (a tap on
## the walkable world is a press and release under half a second apart).
func click(p: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	mouse_to(p)
	await frames(1)
	mouse_button(p, true, button)
	mouse_button(p, false, button)
	await frames(2)


func center_of(c: Control) -> Vector2:
	if c == null:
		return Vector2(-100, -100)
	return c.get_global_transform_with_canvas() * (c.size * 0.5)


## Inputs as data: {"name", "kind": key | pad | stick | click, "code" | "axis"/"value"}.
func _down(i: Dictionary) -> void:
	match String(i.kind):
		"key":
			key(i.code, true)
		"pad":
			pad(i.code, true)
		"stick":
			stick(i.axis, i.value)
		"click":
			mouse_to(Vector2(960, 300))
			mouse_button(Vector2(960, 300), true)


func _up(i: Dictionary) -> void:
	match String(i.kind):
		"key":
			key(i.code, false)
		"pad":
			pad(i.code, false)
		"stick":
			stick(i.axis, 0.0)
		"click":
			mouse_button(Vector2(960, 300), false)


## What holding a key down sends: repeats marked as echoes.
func _echo(i: Dictionary) -> void:
	if String(i.kind) == "key":
		for k in 3:
			key(i.code, true, true)


func _press(i: Dictionary) -> void:
	_down(i)
	await frames(2)
	_up(i)
	await frames(2)


# ============================================================== waiting ===

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


## Waits (up to 2 s) for a screen that's closing to free itself.
func _gone(n: Node) -> void:
	var w: WeakRef = weakref(n)
	await until(func() -> bool: return w.get_ref() == null, 2.0)


## Waits until cond() is true (or `timeout` seconds of game time pass);
## returns whether it was.
func until(cond: Callable, timeout: float = 4.0) -> bool:
	var t := 0.0
	while not cond.call():
		if t > timeout:
			return false
		await get_tree().process_frame
		t += get_process_delta_time()
	return true
