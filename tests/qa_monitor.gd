extends Node
## Watches a World while a test plays the story, frame by frame, and prints
## anything that would look like a glitch to a player (lines start "QA:"):
##   cut      the camera jumps (a cut); listed so the rest can be read against it
##   pop      someone or something on screen jumps more than a stride in one
##            frame without a cut (teleport), or just after a cut (a frame of
##            the new shot with them in the wrong place)
##   slide    someone on screen moves along the ground without a walking clip
##   float    someone on screen stands well above or below the ground
##   vis      someone on screen appears or vanishes without a cut
##   lines    a subtitle and the dialogue box up at the same time
##   control  the player could walk during a film (busy off while cine is on)
##   stuck    nothing on (no film, no line, no menu) but the player can't move
##   music    the music changes track, stops, or starts a track from the top
##   hitch    a frame that took far longer than those around it (with what
##            was happening): a load, many nodes at once, a shader compiling
## Add it with preload("res://tests/qa_monitor.gd").watch(world); it reports as it goes and sums up when
## the test quits (summary()).

var w: World
var frame := 0
var events: Array = []
var counts := {}
var _cam_xf := Transform3D()
var _cam_ok := false
var _last_cut := -100
var _prev := {}            # body instance id -> {pos, vis, on}
var _slide := {}           # id -> frames sliding
var _float := {}           # id -> frames off the ground
var _t_prev := 0
var _dts: Array = []
var _music := ""
var _stuck_frames := 0
var _last_line := ""
var quiet_kinds: Array = []


static func watch(world: World) -> Node:
	var m = load("res://tests/qa_monitor.gd").new()
	m.w = world
	m.name = "QAMonitor"
	world.add_child(m)
	return m


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# sampled as each frame begins: what the last frame drew, after every
	# script and tween had moved things
	get_tree().process_frame.connect(_sample)
	_t_prev = Time.get_ticks_usec()


func _exit_tree() -> void:
	if get_tree().process_frame.is_connected(_sample):
		get_tree().process_frame.disconnect(_sample)


func _note(kind: String, text: String) -> void:
	counts[kind] = int(counts.get(kind, 0)) + 1
	var line := "QA: %-7s f%-6d %s  [%s]" % [kind, frame, text, _context()]
	events.append(line)
	if not kind in quiet_kinds:
		print(line)


## What's on screen now, to find the moment again: the line up, if any.
func _context() -> String:
	var s := ""
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		if is_instance_valid(ov) and ov._line.modulate.a > 0.01:
			s = ov._line.get_parsed_text().strip_edges()
	if s == "" and w.hud != null and w.hud.dialogue.visible:
		s = String(w.hud.dialogue._name.text) + ": " + w.hud.dialogue._text.get_parsed_text()
	if s == "":
		s = "(%s)" % _last_line.left(50) if _last_line != "" else "-"
	return s.left(70)


func _sample() -> void:
	if not is_instance_valid(w) or w.cam == null or not w.is_inside_tree():
		return
	frame += 1
	var now := Time.get_ticks_usec()
	var dt := float(now - _t_prev) / 1000.0
	_t_prev = now
	_check_hitch(dt)
	var cut := _check_cam()
	if cut:
		_last_cut = frame
	_check_people(cut)
	_check_lines()
	_check_control()
	_check_music()


# ------------------------------------------------------------------ frames ---

func _check_hitch(ms: float) -> void:
	if frame < 30:
		_dts.append(ms)
		return
	var sorted_dts := _dts.duplicate()
	sorted_dts.sort()
	var med: float = sorted_dts[sorted_dts.size() / 2]
	if ms > maxf(med * 3.0, 45.0):
		_note("hitch", "%.0f ms (usual %.0f)" % [ms, med])
	_dts.append(ms)
	if _dts.size() > 90:
		_dts.pop_front()


# ------------------------------------------------------------------ camera ---

func _check_cam() -> bool:
	var xf := w.cam.global_transform
	var cut := false
	if _cam_ok:
		var moved := xf.origin.distance_to(_cam_xf.origin)
		var turned := rad_to_deg((-xf.basis.z).angle_to(-_cam_xf.basis.z))
		if moved > 0.6 or turned > 14.0:
			cut = true
			_note("cut", "camera %.1f m, %.0f deg" % [moved, turned])
	_cam_xf = xf
	_cam_ok = true
	return cut


# ------------------------------------------------------------------ people ---

func _people() -> Array:
	var out := []
	if w.player != null:
		out.append(["player", w.player, w.player_doll])
	for n in w.npcs:
		out.append([String(n.def.get("id", "?")), n.body, n.doll])
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	for id in ex:
		out.append([String(id), ex[id].get("body"), ex[id].get("doll")])
	return out


func _on_screen(p: Vector3) -> bool:
	if not w.cam.is_position_in_frustum(p):
		return false
	# not hidden by black (a fade) or behind the camera
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		if is_instance_valid(ov) and ov._black.modulate.a > 0.9:
			return false
	return true


const GAITS := ["walk", "run", "sneak", "strafe_left", "roll", "flying_kick", "jump", "punch_combo", "death", "lift", "fall"]


func _check_people(cut: bool) -> void:
	var seen := {}
	for row in _people():
		var id: String = row[0]
		var b = row[1]
		var d = row[2]
		if b == null or not is_instance_valid(b) or not (b as Node3D).is_inside_tree():
			continue
		var body := b as Node3D
		var key := body.get_instance_id()
		seen[key] = true
		var pos := body.global_position
		var vis: bool = body.is_visible_in_tree() and (d == null or not is_instance_valid(d) or (d as Node3D).is_visible_in_tree())
		var on := vis and (_on_screen(pos + Vector3(0, 1.0, 0)) or _on_screen(pos + Vector3(0, 0.2, 0)))
		var p = _prev.get(key)
		_prev[key] = {"pos": pos, "vis": vis, "on": on, "id": id}
		if p == null:
			if on and not cut and frame > 5:
				_note("vis", "%s appears on screen at %s" % [id, _v(pos)])
			continue
		var was_on: bool = p.on
		var step := Vector2(pos.x - p.pos.x, pos.z - p.pos.z).length()
		var dy := absf(pos.y - p.pos.y)
		# a jump
		if (step > 0.7 or dy > 0.6) and (on or was_on):
			if cut:
				pass   # put on their mark as the shot changed: fine
			elif frame - _last_cut <= 3:
				_note("pop", "%s jumps %.1f m %d frame(s) after a cut (%s -> %s)" % [id, maxf(step, dy), frame - _last_cut, _v(p.pos), _v(pos)])
			else:
				_note("pop", "%s jumps %.1f m on screen (%s -> %s)" % [id, maxf(step, dy), _v(p.pos), _v(pos)])
		# appearing / vanishing
		if vis != bool(p.vis) and (on or was_on) and not cut:
			_note("vis", "%s %s on screen" % [id, "appears" if vis else "vanishes"])
		# sliding: moving without a walking clip
		var fig3 := d as Figure3D if d is Figure3D else null
		var moving := step > 0.012 and step <= 0.7
		var gait := false
		if fig3 != null:
			gait = fig3._clip in GAITS or fig3.walking or fig3._lying > 0.01
		elif d is PaperDoll:
			gait = (d as PaperDoll).walking
		if moving and on and not gait and fig3 != null and fig3.seat < 0.0:
			_slide[key] = int(_slide.get(key, 0)) + 1
			if _slide[key] == 6:
				_note("slide", "%s moves without walking (clip %s) at %s" % [id, fig3._clip, _v(pos)])
		else:
			_slide[key] = 0
		# off the ground
		if on and fig3 != null and fig3.seat < 0.0 and fig3._lying < 0.01 and Cine._on_terrain(w, body):
			var g := Cine.ground(w, pos)
			var off := pos.y - g
			if absf(off) > 0.15:
				_float[key] = int(_float.get(key, 0)) + 1
				if _float[key] == 8:
					_note("float", "%s stands %.2f m %s the ground at %s (clip %s)" % [id, absf(off), "above" if off > 0 else "below", _v(pos), fig3._clip])
			else:
				_float[key] = 0
	for key in _prev.keys():
		if not seen.has(key):
			var p = _prev[key]
			if p.on and not cut:
				_note("vis", "%s removed while on screen" % p.id)
			_prev.erase(key)


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


# ------------------------------------------------------------------- lines ---

func _check_lines() -> void:
	var sub := false
	var txt := ""
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		if is_instance_valid(ov) and ov._line.modulate.a > 0.5:
			sub = true
			txt = ov._line.get_parsed_text().strip_edges()
	var box: bool = w.hud != null and w.hud.dialogue.visible and w.hud.dialogue.modulate.a > 0.5
	if box:
		txt = w.hud.dialogue._text.get_parsed_text()
	if txt != "":
		_last_line = txt
	if sub and box:
		_note("lines", "a subtitle and the dialogue box at once")


# ----------------------------------------------------------------- control ---

func _check_control() -> void:
	var ov_choice := false
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		ov_choice = is_instance_valid(ov) and (ov._choices.visible or ov._bars_on)
	if w.cine and not w.busy:
		counts["control"] = int(counts.get("control", 0)) + 1
		if int(counts.control) % 60 == 1:
			_note("control", "a film has the camera but the player can walk")
	# stuck: nothing going on, and still no walking
	var talking: bool = w.hud != null and (w.hud.dialogue.visible or w.hud.menu_open())
	if w.busy and not w.cine and not talking and not ov_choice and not get_tree().paused:
		_stuck_frames += 1
		if _stuck_frames == 90:
			_note("stuck", "3 s with no film, no line and no menu, and the player can't move")
	else:
		_stuck_frames = 0


# ------------------------------------------------------------------- music ---

func _check_music() -> void:
	var cur: String = Music.current
	if cur == _music:
		return
	var pos := -1.0
	if cur != "" and Music._players.size() > 0:
		var p: AudioStreamPlayer = Music._players[Music._active]
		if p.playing:
			pos = p.get_playback_position()
	_note("music", "%s -> %s%s" % [_music if _music != "" else "(none)", cur if cur != "" else "(stopped)",
		(" at %.1f s" % pos) if pos >= 0.0 else ""])
	_music = cur


func summary() -> String:
	var parts := []
	for k in counts:
		parts.append("%s %d" % [k, counts[k]])
	return "QA SUMMARY (%d frames): %s" % [frame, ", ".join(parts) if not parts.is_empty() else "nothing"]
