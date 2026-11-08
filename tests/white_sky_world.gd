extends Node
## The Night of the White Sky as New Game plays it, over the Ashford world
## (the attic and the inn's rooms built under it, the world's own view
## switched off), for what's seen and heard round the cut to the filmed duel
## (6 November, Gary: "When Bram's battle happens in the beginning it stays on
## a white screen for ages in the kitchen"). Walks on, picks the child up,
## reads each line; from the hunter's raised cards a still every half second
## (and how long each frame really took), the duel watched for a few seconds
## and skipped, then stills on until the attic. Prints what the world's own
## viewport and the inn are doing at the cut.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/white_sky_world.tscn -- <dir>

var out := "/tmp/ws_world"
var world: World
var m: WhiteSky
var _n := 0
var _t := 0.0
var _line_t := 0.0
var _phase := ""
var _cut_at := -1.0
var _next := 0.0
var _last_ms := 0
var _done_at := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	AshfordP1.test_memory = true
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	Game.settings["seen_white_sky"] = false
	world = World.new().setup("ashford", "green")
	add_child(world)
	_last_ms = Time.get_ticks_msec()


func _shot(nm: String) -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%03d_%05.1f_%s.png" % [_n, _t, nm]))


func _process(delta: float) -> void:
	_t += delta
	if m == null:
		for c in world.get_children():
			if c is WhiteSky:
				m = c
				print("[%.1f] memory begins" % _t)
		return
	if not is_instance_valid(m) or m._done:
		if _done_at < 0.0:
			_done_at = _t
			print("[%.1f] memory over" % _t)
		if _t - _done_at < 8.0 and _t >= _next:
			_next = _t + 0.5
			_shot("after")
		if _t - _done_at > 8.0:
			print("WHITE SKY WORLD: done")
			get_tree().quit()
		return
	if m._roam:
		Input.action_press("move_up")
	else:
		Input.action_release("move_up")
	var ov := m._ov
	if ov != null and ov._waiting:
		_line_t += delta
		if _line_t > 1.6:
			_line_t = 0.0
			ov._next.emit()
	if m._hint.modulate.a > 0.9 and m._hint.text.contains("pick up"):
		m._tapped = true
	# from the hunter's cards (the white begins) to a few seconds into the duel
	var hunting := m._hunter != null and is_instance_valid(m._hunter) and not m._hunter._cards.is_empty()
	if (hunting or m._white.modulate.a > 0.05 or is_instance_valid(m._screen)) and _cut_at < 0.0 and m._t > 30.0:
		_cut_at = _t
		print("[%.1f] the hunter's cards: the cut begins" % _t)
		_report()
	if _cut_at >= 0.0 and not m._skipping:
		if _t >= _next:
			_next = _t + 0.5
			var now := Time.get_ticks_msec()
			print("  [%.1f] white %.2f, duel %s, real %d ms since the last still" % [_t, m._white.modulate.a,
				"on" if is_instance_valid(m._screen) and m._screen.game != null else "-", now - _last_ms])
			_last_ms = now
			_shot("cut_w%.2f" % m._white.modulate.a)
		if is_instance_valid(m._screen) and m._screen.game != null and m._white.modulate.a < 0.01 and _phase == "":
			_phase = "duel"
			_report()
			get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
				print("[%.1f] skipping the duel" % _t)
				m.skip())


func _report() -> void:
	var vp := world.get_viewport()
	print("  world viewport 3D off: ", vp.disable_3d, "; its camera: ", vp.get_camera_3d().get_path() if vp.get_camera_3d() != null else "none")
	var cam := vp.get_camera_3d()
	if cam != null:
		print("  camera at ", cam.global_position)
	print("  audio buses: ", AudioServer.bus_count, "; players playing:")
	for p in world.find_children("*", "AudioStreamPlayer*", true, false):
		if p.get("playing"):
			print("    ", world.get_path_to(p), " ", (p.get("stream") as AudioStream).resource_path if p.get("stream") != null else "")
	for p in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		if p.get("playing") and not world.is_ancestor_of(p):
			print("    (outside the world) ", p.get_path(), " ", (p.get("stream") as AudioStream).resource_path if p.get("stream") != null else "")
