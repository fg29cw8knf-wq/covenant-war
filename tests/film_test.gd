extends Node
## Plays the Prologue's film (or part of it) by itself, tapping through every
## line and choice, and saves a screenshot every so often. Duels are played
## out by the computer on both sides.
##
##   godot --headless --fixed-fps 10 res://tests/film_test.tscn -- <out_dir> <part> [every_n_frames]
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       --fixed-fps 4 res://tests/film_test.tscn -- <out_dir> <part> 8
##
## part: corin (Corin to midnight, with Bram's deck), midnight, dawn, taproom,
## burning, cellar (Ashford), or river, camp, morning, road, ridge (the
## Thornwood). Add "only" after the part to stop at the end of that part,
## "read=<frames>" to leave each dialogue-box line up that long (as a player
## reading it would) instead of tapping on at once, "choice=<n>" to answer
## every choice with its nth answer (from 0), "box=<n>" for which of Bram's
## four boxes to choose at the campfire, and flag=<name> to set a story flag
## first (flag=tam_told, flag=want_solhaven). "qa" watches the film for
## glitches as it plays (QAMonitor: jumps, slides, pops after cuts, two lines
## at once, music, hitches); "notap" leaves the subtitles to go by themselves,
## as they do for a player who just watches; "frames=a-b" (or
## "frames_list=a-b,c-d") keeps the every-n stills to those frames, for a
## close look at a moment the watch pointed at. "ui=1.3" plays it at the
## biggest Text and buttons size. "scale3d=0.5" draws the 3D at half size,
## for a quicker reference video recorded with Movie Maker (24 fps).

var out_dir := "user://"
var every := 0
var world: World
var _frame := 0
var _shots := 0
var _wait := 0
var _only := false
var _part := ""
var _keys := false       # draw only the frames that are kept (fast)
var _was_waiting := false
var _shooting := false
var _line_frames := 0
var _start_part := ""
var _ending := false
var _read := 3
var _choice := 0
var _box := 1
var _qa = null   # QA monitor (tests/qa_monitor.gd)
var _notap := false
var _from := -1
var _to := -1
var _windows: Array = []


func _ready() -> void:
	# the pack pauses the game while it's open (23 October): a driver that
	# goes through it must keep running under the pause (its _process
	# stopped with the tree and the run sat paused for good)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	_part = args[1] if args.size() > 1 else "midnight"
	every = int(args[2]) if args.size() > 2 else 0
	_only = "only" in args
	_keys = "keys" in args
	_notap = "notap" in args
	for a in args:
		if String(a).begins_with("read="):
			_read = int(String(a).substr(5))
		elif String(a).begins_with("choice="):
			_choice = int(String(a).substr(7))
		elif String(a).begins_with("box="):
			_box = int(String(a).substr(4))
		elif String(a).begins_with("frames="):
			# frames=a-b: the stills every_n_frames only between those frames
			# (a close look at a moment the QA watch pointed at)
			var ab := String(a).substr(7).split("-")
			_from = int(ab[0])
			_to = int(ab[1]) if ab.size() > 1 else _from + 60
		elif String(a).begins_with("frames_list="):
			for s in String(a).substr(12).split(","):
				var ab2 := s.split("-")
				_windows.append([int(ab2[0]), int(ab2[1]) if ab2.size() > 1 else int(ab2[0]) + 30])
	if _keys:
		RenderingServer.render_loop_enabled = false
	Game.new_game("Sprout", "")
	for f in ["arrived_ashford", "ash_started", "ash_tam", "ash_tilly", "ash_nell", "ash_ready"]:
		Game.set_flag(f)
	var thorn := _part in ["river", "camp", "shelter", "morning", "road", "ridge"]
	if _part != "corin":
		for f in ["first_deck", "ash_lantern_duel", "ash_won_lantern", "has_lantern_moth", "moth_given"]:
			Game.set_flag(f)
	if _part in ["awakening", "dawn", "that_day", "reckoning", "look_back", "taproom", "burning", "cellar"] or thorn:
		Game.set_flag("ash_marked")
		Game.set_flag("pro_part", _part if not thorn else "look_back")
	if _part in ["midnight", "awakening", "dawn", "that_day", "reckoning", "look_back"]:
		Game.set_flag("ash_evening")
		Game.player_name = "Rowan"
	if thorn:
		if _part in ["river", "camp", "shelter"]:
			Game.player_name = "Ash"   # Bram's decks are opened at the campfire
		else:
			Game.new_game("Ash", "tidegrove", true)
			for f in ["bram_deck", "hob_gift"]:
				Game.set_flag(f)
		for f in ["ash_marked", "pro_tunnel_done", "arrived_thornwood", "arrived_thornwood_film"]:
			Game.set_flag(f)
		Game.set_flag("thorn_part", _part)
	for a in args:
		if String(a).begins_with("flag="):
			Game.set_flag(String(a).substr(5))
		elif String(a).begins_with("ui="):
			Game.settings["ui_scale"] = float(String(a).substr(3))   # Options > Text and buttons size
		elif String(a).begins_with("scale3d="):
			# the 3D drawn smaller and scaled up, for a quicker reference
			# video recorded with Movie Maker: scale3d=0.5
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			get_viewport().scaling_3d_scale = float(String(a).substr(8))
	world = World.new().setup("thornwood" if thorn else "ashford", "river" if thorn else "green")
	world.story_next.connect(func(what: String) -> void:
		print("FILM: story_next ", what, " after ", _frame, " frames, flags thorn_part=", Game.flag("thorn_part"), " pro_part=", Game.flag("pro_part"), " deck=", Game.unlocked("deck"), " codex=", Game.unlocked("codex"), " collection=", Game.v2.get("collection", {}), " lessons=", Game.lessons().size())
		await _shot("end")
		print("FILM: done")
		if _qa != null:
			print(_qa.summary())
		get_tree().quit())
	add_child(world)
	if "qa" in args:
		_qa = preload("res://tests/qa_monitor.gd").watch(world)
	await _frames(20)
	if _part == "corin":
		var c = world._npc_by_id("corin")
		world.player.global_position = c.body.global_position + Vector3(1.4, 0, 1.4)
		await _frames(4)
		world._talk(c)
	# midnight and the later parts start by themselves: World resumes a
	# Prologue film part-way on arrival
	_start_part = str(Game.flag("pro_part")) + str(Game.flag("thorn_part"))
	print("FILM: started ", _part)


func _use_later(u) -> void:
	for i in 8:
		await get_tree().process_frame
	if is_instance_valid(u) and not u._done:
		# E does it (headless, the card may sit off the screen for a tap)
		var down := InputEventAction.new()
		down.action = "interact"
		down.pressed = true
		Input.parse_input_event(down)
		await get_tree().process_frame
		var up := InputEventAction.new()
		up.action = "interact"
		up.pressed = false
		Input.parse_input_event(up)


func _process(_d: float) -> void:
	_frame += 1
	if world == null:
		return
	# tap through the world's dialogue box
	if world.hud != null and world.hud.dialogue._waiting:
		if _wait == 0 and "trace" in OS.get_cmdline_user_args():
			_trace()
		_wait += 1
		if _wait > _read:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud != null and world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	# things to tap on in the world on the way (Tilly's moth to wake, the
	# last lantern's hook), as ashford_test taps them
	for u in world.get_children():
		if u is AshfordP1.Use and not u.has_meta("film_tapped") and not u._done:
			u.set_meta("film_tapped", true)
			_use_later(u)
	# and the film's subtitles, choices, name and deck
	if world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		# lines are tapped on by game time (frames), so a slow render still
		# sees each one on screen
		if ov._waiting:
			_line_frames += 1
			if _line_frames > 12 and not _notap:
				_line_frames = 0
				ov._next.emit()
		else:
			_line_frames = 0
		if ov._choices.visible and ov._choices.get_child_count() > 0:
			ov._chosen.emit(mini(_choice, ov._choices.get_child_count() - 1))
		for b in ov.find_children("*", "Button", true, false):
			var bt := b as Button
			if bt.is_visible_in_tree() and (bt.text == "That's me" or bt.text.begins_with("Choose ")):
				bt.pressed.emit()
				break
		if ov._chart != null:
			ov._chart.call("tap")
	# the cart off Corin (v7): heave, heave, then pull in the gold
	for q in get_tree().root.find_children("*", "CartHeave", true, false):
		var qh := q as CartHeave
		if qh.phase == "heave" and _frame % 2 == 0:
			qh.heave()
		elif qh.phase == "pull":
			var g := qh.gold()
			if qh.marker > g.x + 0.03 and qh.marker < g.y - 0.03:
				qh.pull()
	# walked parts (the tunnel): a tap on the way on now and then
	if world.hud != null and String(Game.flag("objective", "")) == "Follow Bram through the tunnel." and _frame % 6 == 0 and world.has_meta("village"):
		var tv = world.get_meta("village")
		if tv.has_meta("tunnel"):
			var tend: Vector3 = tv.get_meta("tunnel").end
			if not world.cam.is_position_behind(tend):
				world.hud.tapped.emit(world.cam.unproject_position(tend))
	# Bram's four boxes at the campfire: tap one, then the same one again
	if world.has_meta("deck_boxes"):
		var picker = world.get_meta("deck_boxes")
		if is_instance_valid(picker) and picker.listening:
			_box_frames += 1
			if _box_frames > 10:
				_box_frames = 0
				var bi := clampi(_box, 0, picker.boxes.size() - 1)
				# where a tap on that box's place on screen lands
				var at: Vector2 = picker.cam.unproject_position((picker.boxes[bi] as Node3D).global_position)
				print("FILM: deck box %d is at %s on screen; a tap there picks box %d" % [bi, at, picker.box_at(at)])
				picker.tap(bi)
	# Bram's tour of the pack: tap on, or do what he asks
	for t in get_tree().root.find_children("*", "PackTour", true, false):
		_drive_tour(t as PackTour)
	for r in get_tree().root.find_children("*", "DeckReveal", true, false):
		if (r as DeckReveal)._ready_to_close:
			(r as DeckReveal)._close()
	if _keys and world.has_meta("cine_overlay"):
		var ov2: CineOverlay = world.get_meta("cine_overlay")
		if ov2._waiting and _line_frames == 4:
			_shot("line_%04d" % _frame)
		_was_waiting = ov2._waiting
	if every > 0 and _frame % every == 0 and _in_window():
		_shot("f%04d" % _frame)
	# "only": stop when the film moves on to its next part
	if _only and _start_part != "" and not _ending and _frame > 30:
		var now := str(Game.flag("pro_part")) + str(Game.flag("thorn_part"))
		if now != _start_part:
			_ending = true
			print("FILM: part over after ", _frame, " frames (", now, ")")
			await _shot("end")
			get_tree().quit()


func _in_window() -> bool:
	if _from < 0 and _windows.is_empty():
		return true
	if _from >= 0 and _frame >= _from and _frame <= _to:
		return true
	for wnd in _windows:
		if _frame >= int(wnd[0]) and _frame <= int(wnd[1]):
			return true
	return false


## "trace": each dialogue-box line as it comes up, with where Bram is.
var _last_line := ""


func _trace() -> void:
	var t: String = world.hud.dialogue._text.get_parsed_text()
	if t == _last_line:
		return
	_last_line = t
	var b = world._npc_by_id("bram")
	var bp: Vector3 = b.body.global_position if b != null else Vector3.ZERO
	var to := ""
	if world.has_meta("bram_stop"):
		to = " %.1fm from his mark" % Vector2(bp.x, bp.z).distance_to(Vector2(world.get_meta("bram_stop").x, world.get_meta("bram_stop").z))
	print("LINE frame %4d  Bram at (%.1f, %.1f)%s  | %s" % [_frame, bp.x, bp.z, to, t.left(60)])


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
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


var _tour_frames := 0
var _box_frames := 0


func _drive_tour(t: PackTour) -> void:
	if not t.running:
		return
	_tour_frames += 1
	if _tour_frames < 8:
		return
	_tour_frames = 0
	var menu := t.menu
	if t.blocking:
		t._tapped.emit()
		return
	var d := t.waiting_for()
	match d:
		"menu":
			world.hud.open_menu()
		"resume":
			menu.request_close()
		"close":
			menu.close_card()
		"card":
			menu._open_card(String(Game.v2.deck[0]))
		_:
			if d.begins_with("tab:"):
				menu.show_tab(d.substr(4))
			elif d.begins_with("card:"):
				menu._open_card(d.substr(5))

