extends Node
## The memory's end handed on to the attic (15 November, Gary's yes to "the
## mark links the two times" and "the title after the memory"). A new game
## with the Night of the White Sky skipped to its end, as a player who has
## seen it can: the child's mark comes up on the black (SealMark.Held),
## Morrowen's last line under it, the game's title under it, the attic's
## caption under it; then the attic's first picture, the hero's own mark
## where the child's was (AshfordP1._wake_on_the_mark), the camera a little
## way back from it as it goes out, and through the dark to the bed's own
## shot, where he wakes.
##
## Checks: the held mark came up and was let go; the title was shown; the
## attic opened on the mark, with the hero's own within a fiftieth of the
## screen of where the held one was and the same size to a fifth; the child's
## he gets up and the walk is handed to the player (the washbasin's lesson).
## Stills of each moment in <dir> when it's drawn:
##
##   godot --headless --fixed-fps 10 --path . res://tests/mark_wake_test.tscn
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/mark_wake_test.tscn -- <dir>

var out := ""
var world: World
var _t := 0.0
var _n := 0
var _m: WhiteSky
var _skipped := false
var _line_t := 0.0
var _title_t := 0.0
var _held_at := Vector2.ZERO
var _held_size := 0.0
var _held_seen := false
var _held_gone := false
var _title := false
var _wake_t := -1.0
var _off := -1.0
var _size_k := -1.0
var _done := false
var _taken := {}
var _lesson := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
		DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	Game.settings["seen_white_sky"] = true   # (so it can be skipped)
	AshfordP1.test_memory = true
	AshfordP1.mark_wakes = 0
	world = World.new().setup("ashford", "green")
	add_child(world)


func _still(nm: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless" or _taken.has(nm):
		return
	_taken[nm] = true
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("mark_wake_test: still ", nm)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _m == null:
		for c in world.get_children():
			if c is WhiteSky:
				_m = c
	# (and the walk is handed to the player after it: the washbasin's lesson)
	if _wake_t >= 0.0 and String(Game.flag("objective_key", "")) == "basin":
		_lesson = true
	# the memory, skipped a moment in
	if _m != null and is_instance_valid(_m) and not _skipped and _m._roam:
		_skipped = true
		_m.skip()
	# its last line, and the attic's lines: read a moment, then tapped on
	var ov := Cine.overlay(world)
	if ov._waiting:
		_line_t += delta
		if _line_t > 0.7 and _held_seen and not _title:
			_still("1_the_line")
		if _line_t > 1.4:
			_line_t = 0.0
			ov._next.emit()
	else:
		_line_t = 0.0
	if _m != null and is_instance_valid(_m) and _m.title_shown:
		_title = true
		_title_t += delta
		if _title_t > 2.6:
			_still("2_the_title")
		if _title_t > 3.4:
			_m._tapped = true
	var held := SealMark.held(get_tree())
	if held != null:
		_held_seen = true
		_held_at = held.at
		_held_size = held.size
		if _title and (_m == null or not is_instance_valid(_m) or _m._done) and ov._cap != null and ov._cap.visible and ov._cap.modulate.a > 0.9:
			_still("3_the_caption")
	elif _held_seen:
		_held_gone = true
	if AshfordP1.mark_wakes > 0 and _wake_t < 0.0:
		_wake_t = _t
		# where his own mark is on the picture, against where the held one was
		var mi := SealMark.on_hero(world)
		var view := world.get_viewport().get_visible_rect().size
		if mi != null and world.cam != null and view.y > 0.0:
			var px := world.cam.unproject_position(mi.global_position)
			_off = (Vector2(px.x / view.x, px.y / view.y) - _held_at).length()
			var d := world.cam.global_position.distance_to(mi.global_position)
			var tall := 2.0 * d * tan(deg_to_rad(world.cam.fov) * 0.5)
			_size_k = (SealMark.SIZE / tall) / maxf(_held_size, 0.001)
	if _wake_t >= 0.0:
		var since := _t - _wake_t
		for pair in [["4_attic_coming_up", 0.5], ["5_his_own_mark", 1.7], ["6_drawing_back", 3.5], ["7_the_bed", 5.8], ["8_waking", 8.4]]:
			if since > float(pair[1]):
				_still(String(pair[0]))
		if _lesson or since > 40.0:
			_finish()


func _finish() -> void:
	_done = true
	var fails: Array = []
	if not _held_seen:
		fails.append("the mark never came up on the black")
	if not _held_gone:
		fails.append("the held mark was never let go")
	if not _title:
		fails.append("the title wasn't shown")
	if AshfordP1.mark_wakes != 1:
		fails.append("the attic opened on the mark %d times" % AshfordP1.mark_wakes)
	if _off < 0.0 or _off > 0.02:
		fails.append("his own mark was %.3f of the screen from the held one" % _off)
	if _size_k < 0.8 or _size_k > 1.2:
		fails.append("his own mark was %.2f of the held one's size" % _size_k)
	var a := InnRooms.attic(AshfordP1.village(world))
	var wide: Vector3 = (a.root as Node3D).to_global(Vector3(2.45, 1.6, 1.3))
	var cam_off := world.cam.global_position.distance_to(wide)
	if not _lesson:
		fails.append("he never got up to be walked to the washbasin")
	print("mark_wake_test: the held mark at (%.2f, %.2f), %.2f of the screen tall; his own %.3f of the screen from it, %.2f of its size; the walk his at the washbasin's lesson %s, %.1f s after the attic came up (the camera %.1f m from the bed's shot by then)" % [
		_held_at.x, _held_at.y, _held_size, _off, _size_k, str(_lesson), _t - _wake_t, cam_off])
	if fails.is_empty():
		print("mark_wake_test: PASS")
	else:
		for f in fails:
			print("mark_wake_test: FAIL: ", f)
	get_tree().quit(0 if fails.is_empty() else 1)
