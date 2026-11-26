extends Node
## The last beat of Chapter 1 (Master Script v3: "Next time the game opens:
## dawn. The wagon rolls out of Solhaven ... The map of Veyl opens on six
## kingdoms, a Champion's banner flying over each." Bram: "Pyreholt's
## nearest." Objective: "Choose a kingdom. (Tap a banner on the map.)").
##
## Opens Solhaven from a save at the chapter's end and checks, in order:
## the dawn plays by itself (the wagon out through the open gate and moving
## south, Wren sat on its roof and carried with it); the map opens under the
## film; Bram's line is the script's, word for word, and nothing else is
## said; the objective is the script's; a real click on Pyreholt's banner
## opens its card, a real click on "Back to the map" closes it, and a real
## click on "Back to Solhaven" hands back the square by day (the wagon home
## in the stable yard and level, Wren stood in the square, the story light
## over the wagon, the player free); Bram's list is headed by "The map of
## Veyl", which opens the map again with no line and no dawn; and opening
## Solhaven a second time goes straight to the square.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 --fixed-fps 10 \
##       res://tests/veyl_dawn_test.tscn -- <out_dir> keys      # with stills (only those frames are drawn)
##   godot --headless --fixed-fps 10 res://tests/veyl_dawn_test.tscn -- <out_dir>   # just the run and its checks
## Ends with "VEYL DAWN TEST: PASS".

const Films := preload("res://scripts/world/solhaven/films.gd")
const LINE := "Pyreholt's nearest."
const OBJECTIVE := "Choose a kingdom. (Tap a banner on the map.)"

var out_dir := "user://"
var world: World
var _keys := false
var _shooting := false
var _shots := 0
var _frame := 0
var _fails := 0
var _line_frames := 0
var _lines: Array = []
var _last_line := ""
var _hold_lines := false
var _pick := ""           # the answer to pick in the next talk's list
var _asked: Array = []    # the lists the talk has shown


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	_keys = "keys" in args
	if _keys:
		RenderingServer.render_loop_enabled = false
	Game.new_game("Rowan", "tidegrove")
	for f in ["ash_marked", "first_deck", "bram_deck", "hob_gift", "beat_hunter", "thornwood_done", "arrived_solhaven",
			"beat_hale", "beat_wren", "wren_joined", "trial_light_passed", "beat_aldric", "ch1_done", "met_bram_square"]:
		Game.set_flag(f)
	for i in 7:
		Game.set_flag("c%d_done" % (i + 1))
	Game.set_flag("gate_choice", "children")
	Game.set_flag("solmaris_favour", "refused")
	await _play()


func _open_world() -> void:
	if world != null:
		world.queue_free()
		await _frames(3)
	world = World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(6)


func _play() -> void:
	_check(Films.dawn_due(), "the dawn is due once Chapter 1 is done")
	_hold_lines = true
	await _open_world()
	var v: Node3D = world.get_meta("solhaven_set")
	# the wagon's roll: out through the gate, and moving south
	var t := 0
	while t < 400 and not (world.cine and v.wagon.position.z > 31.5):
		await _frames(1)
		t += 1
	_check(world.cine and v.wagon.position.z > 31.5, "the dawn plays by itself: the wagon is out on the road (z %.1f)" % v.wagon.position.z)
	_check(v.gate_is_open(), "the Golden Gate stands open")
	_check(absf(wrapf(v.wagon.rotation.y - PI, -PI, PI)) < 0.01, "the wagon faces south")
	var z0: float = v.wagon.position.z
	await _shot("dawn_roll_1")
	await _frames(14)
	await _shot("dawn_roll_2")
	_check(v.wagon.position.z > z0 + 0.5, "it's rolling (%.1f to %.1f)" % [z0, v.wagon.position.z])
	var wf = Cine.fig(world, "wren")
	var wb := Cine.body(world, "wren")
	if wf is Figure3D:
		var seat: Vector3 = v.wagon.to_global(Vector3(0.1, 0, 1.72))
		_check(Vector2(wb.global_position.x - seat.x, wb.global_position.z - seat.z).length() < 0.2, "Wren is carried on the wagon's roof")
		_check((wf as Figure3D).seat > 2.0, "and sat on it (seat %.2f)" % (wf as Figure3D).seat)
	for id in ["bram", "player"]:
		var rf = Cine.fig(world, id)
		var rb := Cine.body(world, id)
		if rf is Figure3D:
			var at: Vector3 = v.wagon.to_global(Vector3(0.44 if id == "bram" else -0.44, 0, -1.42))
			_check(Vector2(rb.global_position.x - at.x, rb.global_position.z - at.z).length() < 0.2 and (rf as Figure3D).seat > 1.0,
				"%s is sat on the wagon's seat, and carried with it (seat %.2f)" % [id, (rf as Figure3D).seat])
	_check(not world.hud._title.modulate.a > 0.01, "no place-name card over the dawn")
	await _frames(22)
	await _shot("dawn_roll_3")
	# the map opens under the film, and Bram speaks
	t = 0
	while t < 600 and _map() == null:
		await _frames(1)
		t += 1
	_check(_map() != null, "the map of Veyl opens")
	t = 0
	while t < 400 and _lines.is_empty():
		await _frames(1)
		t += 1
	_check(_lines == ["BRAM: " + LINE], "Bram says the script's line, and only that (%s)" % [_lines])
	_check(not _map().is_offered(), "no banner can be pressed while he speaks")
	_check(not bool(Game.flag("veyl_dawn")), "the dawn isn't marked seen until he's said it")
	await _shot("map_brams_line")
	_hold_lines = false
	t = 0
	while t < 300 and not _map().is_offered():
		await _frames(1)
		t += 1
	await _wait(0.8)
	var map := _map()
	_check(map.is_offered(), "then the banners can be chosen")
	_check(bool(Game.flag("veyl_dawn")), "the dawn is marked seen")
	_check(String(Game.flag("objective", "")) == OBJECTIVE and map._objective.text == OBJECTIVE, "the objective is the script's (%s)" % Game.flag("objective", ""))
	_check(get_viewport().gui_get_focus_owner() == map.banner_button("pyreholt"), "the keys start on Pyreholt, the one Bram named")
	await _shot("map_offered")
	# real clicks: nothing of the film's is left over the map to swallow them
	await _click(map.banner_button("pyreholt"))
	await _wait(0.4)
	_check(map.card_kingdom() == "pyreholt", "a click on Pyreholt's banner opens Pyreholt's card (%s)" % map.card_kingdom())
	await _shot("map_card")
	if map.card_open():
		await _click(map.card_back_button())
		await _wait(0.4)
	_check(not map.card_open(), "a click on \"Back to the map\" closes it")
	await _click(map.back_button())
	await _until_free(900)
	_check(_map() == null, "\"Back to Solhaven\" takes the map away")
	_check(not world.busy and not world.cine, "and the player is free in the square")
	_check(v.wagon.position.distance_to(v.SPOTS.wagon) < 0.05 and v.wagon.rotation.length() < 0.001, "the wagon is home in the stable yard, and level (%s, %s)" % [v.wagon.position, v.wagon.rotation])
	_check(v.sun.light_energy > 1.1 and v.sun.rotation_degrees.x < -30.0, "it's day")
	_check(v.marker.visible and v.marker.position.distance_to(v.SPOTS.wagon) < 0.1, "the story light is over the wagon")
	for id in ["wren", "bram", "player"]:
		var f = Cine.fig(world, id)
		var b := Cine.body(world, id)
		if f is Figure3D:
			_check((f as Figure3D).seat < 0.0 and b.visible and absf(b.global_position.y) < 0.3 and b.global_position.distance_to(v.SPOTS.wagon) < 30.0,
				"%s is down off the wagon, standing in the square (%s)" % [id, b.global_position])
	_check(world.hud._objective.text == OBJECTIVE, "the square shows the objective (%s)" % world.hud._objective.text)
	await _shot("square_after")
	# Bram's list: the map first, and it opens the map with no line
	_lines = []
	_pick = "The map of Veyl"
	_talk("bram")
	t = 0
	while t < 600 and _map() == null:
		await _frames(1)
		t += 1
	_check(_map() != null, "Bram's \"The map of Veyl\" opens the map")
	_check(not _asked.is_empty() and String(_asked[0][0]) == "The map of Veyl", "it heads his list (%s)" % [_asked])
	if _map() != null:
		await _wait(0.6)
		_check(_map().is_offered(), "its banners can be chosen at once")
		_check(not _lines.has("BRAM: " + LINE), "and Bram doesn't say his line again")
		await _shot("map_from_bram")
		var e := InputEventAction.new()
		e.action = "ui_cancel"
		e.pressed = true
		Input.parse_input_event(e)
		await _until_free(900)
		_check(_map() == null and not world.busy, "Esc closes it, back in the square")
	# a second opening of the game: straight to the square
	_check(not Films.dawn_due(), "the dawn isn't due again")
	await _open_world()
	await _until_free(600)
	_check(_map() == null and not world.cine and not world.busy, "opening Solhaven again goes straight to the square")
	var v2: Node3D = world.get_meta("solhaven_set")
	_check(v2.marker.visible and v2.wagon.position.distance_to(v2.SPOTS.wagon) < 0.05, "the light over the wagon, the wagon in the yard")
	print("VEYL DAWN TEST: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)


func _map() -> VeylMap:
	if world == null or not is_instance_valid(world):
		return null
	var l := world.get_node_or_null("VeylMapLayer")
	if l == null or l.is_queued_for_deletion():
		return null
	return l.get_node_or_null("VeylMap") as VeylMap


func _talk(id: String) -> void:
	var n = world._npc_by_id(id)
	world.player.global_position = n.body.global_position + Vector3(0.0, 0, 1.6)
	world._focus = world._cam_focus_target()
	await _frames(4)
	world._talk(n)


## A press and a release of the mouse on the middle of `c`, as a player's.
func _click(c: Control) -> void:
	if c == null:
		_check(false, "nothing there to click")
		return
	var at := c.get_global_rect().get_center()
	# (canvas to window: the game's canvas is stretched to the window)
	var win := get_viewport().get_screen_transform() * at
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = win
		e.global_position = win
		Input.parse_input_event(e)
		await _frames(2)


func _process(_d: float) -> void:
	_frame += 1
	if world == null or not is_instance_valid(world):
		return
	# the dialogue box
	if world.hud != null and world.hud.dialogue._waiting:
		_line_frames += 1
		if _line_frames == 2:
			_note(world.hud.dialogue._text.get_parsed_text())
		if _line_frames > 3:
			_line_frames = 0
			world.hud.dialogue._advance.emit()
	elif world.hud != null and world.hud.dialogue._choices.visible:
		var opts: Array = []
		for b in world.hud.dialogue._choices.get_children():
			if b is Button:
				opts.append((b as Button).text)
		if _asked.is_empty() or _asked[-1] != opts:
			_asked.append(opts)
		var i := opts.find(_pick)
		world.hud.dialogue._chosen.emit(i if i >= 0 else opts.size() - 1)   # (else the leave line)
	# the film's subtitles
	if world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		if ov._waiting:
			_line_frames += 1
			if _line_frames == 4:
				_note(ov._who.text + ": " + ov._line.get_parsed_text())
			if _line_frames > 12 and not _hold_lines:
				_line_frames = 0
				ov._next.emit()
		elif not world.hud.dialogue._waiting:
			_line_frames = 0


func _note(line: String) -> void:
	if line == _last_line or line.strip_edges() == ":" or line.strip_edges() == "":
		return
	_last_line = line
	_lines.append(line)
	print("LINE %5d  %s" % [_frame, line])


func _check(ok: bool, what: String) -> void:
	print("VEYL DAWN %s: %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails += 1


func _until_free(max_frames: int) -> void:
	var t := 0
	await _frames(6)
	while t < max_frames:
		await _frames(1)
		t += 1
		if not world.busy and not world.cine and world.hud.pad.visible and _map() == null:
			await _frames(8)
			if not world.busy and not world.cine:
				return
	_check(false, "timed out waiting for the player to be free (frame %d)" % _frame)


func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	await _frames(2)


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless" or _shooting:
		return
	_shooting = true
	if _keys:
		RenderingServer.render_loop_enabled = true
		await get_tree().process_frame
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if _keys:
		RenderingServer.render_loop_enabled = false
	_shooting = false
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%02d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
