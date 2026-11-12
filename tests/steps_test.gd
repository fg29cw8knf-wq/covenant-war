extends Node3D
## Footsteps (12 November): a figure that walks or runs is heard each time a
## foot comes down, left then right, at a walker's and a runner's rate; one
## standing still, or marked "none", isn't; the world says what's underfoot
## (boards in the rooms, dirt on a path, grass off it, flags in the cellar);
## and there is a sound for every kind of ground.
## Run: godot --headless --path . --fixed-fps 30 res://tests/steps_test.tscn [-- list]
## Ends "STEPS: ok" or the problems.

var _bad: Array = []
var _show := false


func _ready() -> void:
	_show = "list" in OS.get_cmdline_user_args()
	Sfx.listen = true
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 3, 6)
	cam.current = true
	for ground: String in ["snow", "grass", "dirt", "wood", "stone"]:
		if not Sfx.has_file("step_" + ground):
			_bad.append("no sound for %s (assets/sfx/step_%s.wav: tools/make_steps.py)" % [ground, ground])
		elif not Sfx.has_file("step_%s_2" % ground):
			_bad.append("only one take of step_%s" % ground)
	# who, gait, pace (m/s; 0 the clip's own), steps a second wanted (least, most)
	for row: Array in [["player", "run", 5.4, 2.4, 5.2], ["player", "walk", 0.0, 1.2, 2.6],
			["bram_coat" if Figure3D.has_model("bram_coat") else "bram", "walk", 1.1, 0.8, 2.4], ["corin", "run", 0.0, 2.2, 4.8]]:
		await _walk(String(row[0]), String(row[1]), float(row[2]), float(row[3]), float(row[4]))
	await _still()
	_grounds()
	await _village()
	for b in _bad:
		print("  problem: ", b)
	print("STEPS: ok" if _bad.is_empty() else "STEPS: %d problem(s)" % _bad.size())
	get_tree().quit(0 if _bad.is_empty() else 1)


func _walk(who: String, gait: String, pace: float, least: float, most: float) -> void:
	var f: Figure3D = Figure3D.make(who, who)
	add_child(f)
	f.step_on = "snow"
	var sides: Array = []
	f.footfall.connect(func(side: String, _surface: String) -> void: sides.append(side))
	Sfx.heard.clear()
	f.gait = gait
	f.pace = pace
	f.walking = true
	var secs := 4.0
	await get_tree().create_timer(secs).timeout
	var rate := sides.size() / secs
	var same := 0
	for i in range(1, sides.size()):
		if sides[i] == sides[i - 1]:
			same += 1
	var heard := Sfx.heard.filter(func(h): return String(h[1]).begins_with("step_snow")).size()
	if _show:
		print("%s %s at %.1f m/s: %d footfalls in %.0f s (%.1f a second), %d the same foot twice, %d heard" % [who, gait, pace, sides.size(), secs, rate, same, heard])
	if rate < least or rate > most:
		_bad.append("%s's %s: %.1f footfalls a second (wanted %.1f to %.1f)" % [who, gait, rate, least, most])
	if same > 1:
		_bad.append("%s's %s: the same foot twice running %d times" % [who, gait, same])
	if heard != sides.size():
		_bad.append("%s's %s: %d footfalls but %d sounds" % [who, gait, sides.size(), heard])
	f.walking = false
	f.queue_free()
	await get_tree().process_frame


func _still() -> void:
	var f: Figure3D = Figure3D.make("player", "player")
	add_child(f)
	f.step_on = "grass"
	var n := [0]
	f.footfall.connect(func(_s: String, _g: String) -> void: n[0] += 1)
	await get_tree().create_timer(1.5).timeout
	if n[0] > 0:
		_bad.append("a figure standing still made %d footfalls" % n[0])
	f.step_on = "none"
	f.gait = "run"
	f.walking = true
	await get_tree().create_timer(1.5).timeout
	if n[0] > 0:
		_bad.append("a figure marked \"none\" made %d footfalls" % n[0])
	# too far from the camera to be heard
	f.step_on = "grass"
	f.position = Vector3(0, 0, -400)
	Sfx.heard.clear()
	await get_tree().create_timer(1.5).timeout
	if Sfx.heard.size() > 0:
		_bad.append("a runner 400 m off was heard")
	f.queue_free()


## What the world says is underfoot (World.surface_at and Ashford's own).
func _grounds() -> void:
	var w := World.new().setup("ashford", "green")
	var A: GDScript = w.area
	for row: Array in [[InnRooms.TAPROOM_AT + Vector3(1, 0, 1), "wood"], [InnRooms.ATTIC_AT, "wood"], [InnRooms.EVE_AT, "wood"],
			[InnRooms.CELLAR_AT + Vector3(-1, 0, 0.5), "stone"], [AshfordNight.TUNNEL_AT, "dirt"], [MillSet.AT, "wood"]]:
		var got := String(A.call("surface_at", w, row[0]))
		if got != String(row[1]):
			_bad.append("at %s the ground is '%s', not '%s'" % [row[0], got, row[1]])
	# (the green and its paths need the village built: World.surface_at falls
	# to AshfordVillage.path_at there, and to stone where there is no village)
	if w.surface_at(Vector3(0, 0, 0)) != "stone":
		_bad.append("a world with no village isn't stone underfoot: '%s'" % w.surface_at(Vector3.ZERO))
	w.attract = true
	if w.surface_at(Vector3.ZERO) != "":
		_bad.append("the world behind the title screen has footsteps")
	w.free()


## The player run across Ashford's green by a tap, as a player would: heard
## on the grass and on the path, and the ground named right under each.
func _village() -> void:
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met", "first_deck"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	var w := World.new().setup("ashford", "green")
	add_child(w)
	for k in 20:
		await get_tree().process_frame
	var v := w.get_meta("village") as AshfordVillage
	# a spot of grass and a spot of path near the player
	var from := w.player.global_position
	var grass := Vector3.INF
	var path := Vector3.INF
	for r: float in [3.0, 5.0, 7.0, 9.0]:
		for k in 16:
			var p := from + Vector3(cos(k * TAU / 16.0), 0, sin(k * TAU / 16.0)) * r
			var on := v.path_at(p.x, p.z)
			if on > 0.6 and path == Vector3.INF:
				path = p
			elif on < 0.05 and grass == Vector3.INF:
				grass = p
	if grass == Vector3.INF or path == Vector3.INF:
		_bad.append("no grass or no path found near the player on the green")
	else:
		if w.surface_at(grass) != "grass":
			_bad.append("on the green's grass the ground is '%s'" % w.surface_at(grass))
		if w.surface_at(path) != "dirt":
			_bad.append("on the green's path the ground is '%s'" % w.surface_at(path))
	Sfx.heard.clear()
	w.busy = false
	w.cine = false
	w._move_target = from + Vector3(6, 0, 4)
	await get_tree().create_timer(2.5).timeout
	var steps: Array = Sfx.heard.filter(func(h): return String(h[1]).begins_with("step_"))
	var kinds := {}
	for h in steps:
		kinds[String(h[1]).get_slice("_", 1)] = true
	if _show:
		print("the player run 7 m across the green: moved %.1f m, %d footsteps (%s)" % [w.player.global_position.distance_to(from), steps.size(), ", ".join(kinds.keys())])
	if steps.size() < 4:
		_bad.append("the player run across the green made %d footsteps" % steps.size())
	for k: String in kinds:
		if k != "grass" and k != "dirt":
			_bad.append("on the green a footstep on '%s'" % k)
	w.queue_free()
	await get_tree().process_frame
