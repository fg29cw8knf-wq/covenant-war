extends Node
## Frame times round the end of Morrowen's line in the Night of the White Sky
## (8 November, Gary: "After Morrowen speaks at the beginning it glitches for
## a bit"). Plays the memory's opening as the game does (the caption on black,
## the walk, her line, then the tear and the Sigils), her recording stubbed
## short, and logs how long each frame really took (ms of wall-clock time,
## whatever --fixed-fps says the game time is) from two seconds before her
## line ends to eight after, with what was first put in the set that frame;
## then prints the spikes (frames over twice the median of the walk's) and the
## sum of the time lost to them. With "stills" a still is taken every frame
## for the first four seconds after the line instead (the timing then counts
## the PNGs' saving, so read only the pictures). "nowarm" leaves the warm-up
## under the caption out (WhiteSky.warm_sigils = false), for the before.
##
## "stand" has him stand through her line and set off a second after it (into
## his look up at the tear); it logs his clip each frame then, to see the walk
## take over from the look.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/white_sky_hitch.tscn -- <dir> [stills] [nowarm] [line=<s>] [stand] [peekwarm]

var out := "/tmp/ws_hitch"
var m: WhiteSky
var _t := 0.0
var _last_us := 0
var _t0 := -1.0          # game time her line ended
var _rows: Array = []    # [game t, real ms, what came]
var _came: Array = []    # what entered the set this frame
var _walk_ms: Array = [] # frames of the walk under her line (the baseline)
var _stills := false
var _stand := false
var _peekwarm := false
var _n := 0
var _done := false
var _line_secs := 3.0
var _mats := {}          # material instance id -> true once seen


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_stills = a.has("stills")
	_stand = a.has("stand")
	_peekwarm = a.has("peekwarm")
	for s in a:
		if String(s).begins_with("line="):
			_line_secs = float(String(s).substr(5))
	DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	VoiceLines.stub["morrowen_attic"] = _line_secs
	m = WhiteSky.new()
	if a.has("nowarm"):
		m.warm_sigils = false
	add_child(m)
	m._set.child_entered_tree.connect(_entered)
	_last_us = Time.get_ticks_usec()
	_run()


func _entered(n: Node) -> void:
	var what := n.get_class()
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := mi.material_override
		if mat != null:
			var fresh: bool = not _mats.has(mat.get_instance_id())
			_mats[mat.get_instance_id()] = true
			what = "%s(%s%s)" % [what, mat.get_class() if not (mat is ShaderMaterial) else _shader_name((mat as ShaderMaterial).shader), " NEW-MAT" if fresh else ""]
	elif n is GPUParticles3D:
		var pm := (n as GPUParticles3D).process_material
		if pm != null:
			var fresh: bool = not _mats.has(pm.get_instance_id())
			_mats[pm.get_instance_id()] = true
			what += "(particles%s)" % (" NEW-MAT" if fresh else "")
	_came.append(what)


func _shader_name(sh: Shader) -> String:
	if sh == null:
		return "noshader"
	if sh.resource_path != "":
		return sh.resource_path.get_file()
	var code := sh.code
	for k in ["ICE_LAYERS", "back_tex", "crater_r", "depth_draw_never, fog_disabled", "hem ="]:
		if code.contains(k):
			return {"ICE_LAYERS": "ICE", "back_tex": "CARD", "crater_r": "SNOW", "depth_draw_never, fog_disabled": "POOL", "hem =": "COAT"}[k]
	return "shader"


func _run() -> void:
	await get_tree().process_frame
	m._ov = m._own_overlay()
	await m.play()
	_finish()


func _process(delta: float) -> void:
	_t += delta
	var now := Time.get_ticks_usec()
	var ms := (now - _last_us) / 1000.0
	_last_us = now
	if m == null or _done:
		return
	# (walking from the first moment; or, "stand", standing through her line
	# and setting off a second after it ends, into his look up at the tear)
	if m._roam and not (_stand and (_t0 < 0.0 or _t - _t0 < 1.0)):
		Input.action_press("move_up")
	else:
		Input.action_release("move_up")
	# her line's end: the first frame _line_over is true
	if _t0 < 0.0 and m._line_over:
		_t0 = _t
		print("HITCH: her line ended at game time %.1f s" % _t)
	if _t0 < 0.0 and m._roam and m._black.modulate.a < 0.05:
		_walk_ms.append(ms)
	# the warm-up's pit: is it in the camera's view, and ("peekwarm") what
	# does it look like with the black lifted
	var pit := m._set.get_node_or_null("Warm") as Node3D
	if pit != null:
		print("HITCH: warm pit at game %.1f s: %d things, in the camera's view %s, %.1f ms this frame" % [
			_t, pit.get_child_count(), str(m._cam.is_position_in_frustum(pit.global_position)), ms])
		if _peekwarm:
			m._black.modulate.a = 0.0
			_still("warm_%04.1f" % _t)
	if _t0 < 0.0 or _t - _t0 > 8.0:
		_came.clear()
		if _t0 >= 0.0 and _t - _t0 > 8.0:
			_finish()
		return
	if _stand and m._bram is Figure3D:
		var fig := m._bram as Figure3D
		_came.append("clip=%s%s pace=%.2f" % [fig._clip, " action=" + fig._action if fig._action != "" else "", fig.pace])
	_rows.append([_t - _t0, ms, _came.duplicate()])
	_came.clear()
	if _stills and _t - _t0 <= 4.0:
		_still("after_%04.1f" % (_t - _t0))


func _still(label: String) -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%03d_%s.png" % [_n, label]))


func _finish() -> void:
	if _done:
		return
	_done = true
	var base := _walk_ms.duplicate()
	base.sort()
	var median: float = base[base.size() / 2] if not base.is_empty() else 0.0
	print("HITCH: %d frames of the walk under her line, median %.1f ms a frame" % [base.size(), median])
	print("HITCH: frames from her line's end (game s, real ms, what entered the set):")
	var lost := 0.0
	var spikes := 0
	var worst := 0.0
	for r in _rows:
		var t: float = r[0]
		var ms: float = r[1]
		var came: Array = r[2]
		var spike: bool = median > 0.0 and ms > median * 2.0
		if spike:
			spikes += 1
			lost += ms - median
			worst = maxf(worst, ms)
		if spike or not came.is_empty() or t < 4.0:
			print("  %5.1f  %7.1f ms %s %s" % [t, ms, "SPIKE" if spike else "     ", ", ".join(came)])
	print("HITCH SUMMARY: %d spikes in the 8 s after her line, worst %.0f ms, %.0f ms lost to them over the median (warm_sigils %s)" % [spikes, worst, lost, str(m.warm_sigils)])
	get_tree().quit()
