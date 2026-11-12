extends Node3D
## Birds on Ashford's green (12 November: Birds). By day the flocks are down
## on open ground, clear of the player and the walls; someone stood well off
## leaves them be; the player run at one sends it up before he's on it, the
## wings are heard once, every bird climbs away from him and is gone inside
## a few seconds; it comes down again later somewhere clear; a walker has to
## come nearer than a runner; rain and the evening send them up and keep
## them up; and there is a sound for it, in more than one take.
## Run: godot --headless --path . --fixed-fps 30 res://tests/birds_test.tscn [-- list]
## Ends "BIRDS: ok" or the problems.

var _bad: Array = []
var _show := false


func _ready() -> void:
	_show = "list" in OS.get_cmdline_user_args()
	Sfx.listen = true
	if not Sfx.has_file("birds_up") or not Sfx.has_file("birds_up_2"):
		_bad.append("no sound of wings (or only one take): assets/sfx/birds_up.wav (tools/make_ambience.py birds_up)")
	if Birds.reach_for(0.0) >= Birds.reach_for(1.2) or Birds.reach_for(1.2) >= Birds.reach_for(5.0):
		_bad.append("a runner doesn't send them up from further off than a walker, or a walker than someone stood still")
	Gfx.force_level = 2
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
	var birds := Birds.of(w)
	if birds == null:
		_bad.append("Ashford has no birds")
		_end()
		return
	v.set_daylight(1.0)
	w.busy = false
	w.cine = false
	var wx := Weather.of(w)
	if wx != null:
		wx.set_process(false)   # (no shower of the day's own in the middle of this)
	await get_tree().create_timer(1.5).timeout
	# down, by day, where they should be
	var down: Array = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state == "ground")
	if _show:
		print("%d flocks, %d of them down at the start; the day is one for birds: %s" % [birds.flocks.size(), down.size(), birds.about()])
	if birds.flocks.size() != 3 or down.is_empty():
		_bad.append("%d flocks on a Mac, %d down on the green at the start of a day" % [birds.flocks.size(), down.size()])
		_end()
		return
	var from := w.player.global_position
	for f: Birds.Flock in down:
		_placed_right(v, f, from, "at the start")
		if f.at.distance_to(from) < Birds.CLEAR_PLAYER:
			_bad.append("a flock %.1f m from the player at the start" % f.at.distance_to(from))
	# left alone, they stay (anyone walking by may send one up: only the one watched counts)
	var f0: Birds.Flock = down[0]
	for f: Birds.Flock in down:
		if f.at.distance_to(from) > f0.at.distance_to(from):
			f0 = f   # (the furthest from everyone at the start)
	var stood := w.player.global_position
	await get_tree().create_timer(2.0).timeout
	if w.player.global_position.distance_to(stood) > 0.05:
		_bad.append("the player moved while stood still")
	var moved := 0
	for b: Birds.Bird in f0.birds:
		if not b.visible or absf(b.global_position.y - v.ground_y(b.global_position.x, b.global_position.z)) > 0.08:
			moved += 1
	if f0.state == "ground" and moved > 0:
		_bad.append("%d birds of a flock on the ground aren't on it" % moved)
	# the player put down a way off and run at them
	var f1: Birds.Flock = null
	for f: Birds.Flock in birds.flocks:
		if f.state == "ground":
			f1 = f
	if f1 == null:
		_bad.append("no flock left down to run at")
		_end()
		return
	var start := _stand_off(w, v, f1, 9.0)
	w.player.global_position = start
	await get_tree().create_timer(0.5).timeout
	if f1.state != "ground":
		_bad.append("the player put down 9 m off sent them up")
		_end()
		return
	Sfx.heard.clear()
	var was_up := birds.went_up
	w._move_target = f1.at
	var gone_at := -1.0
	var t := 0.0
	while t < 4.0 and gone_at < 0.0:
		await get_tree().process_frame
		t += 1.0 / 30.0
		if f1.state == "up":
			gone_at = w.player.global_position.distance_to(f1.at)
	var wings: int = Sfx.heard.filter(func(h): return String(h[1]) == "birds_up").size()
	if _show:
		print("the player run at a flock from 9 m: it went up with him %.1f m off, after %.1f s; wings heard %d time(s)" % [gone_at, t, wings])
	if gone_at < 0.0:
		_bad.append("the player run at a flock didn't send it up")
		_end()
		return
	if gone_at < 2.0 or gone_at > Birds.REACH_RUN + Birds.SPREAD + 0.6:
		_bad.append("the flock went up with the runner %.1f m off" % gone_at)
	if wings != 1:
		_bad.append("a flock going up was heard %d times" % wings)
	w._move_target = null
	var who := w.player.global_position
	await get_tree().create_timer(1.3).timeout
	var low := 0
	var toward := 0
	var still := 0
	for b: Birds.Bird in f1.birds:
		var up := b.global_position.y - b.home.y
		if up < 1.2:
			low += 1
		if b.global_position.distance_to(who) < b.home.distance_to(who) + 1.0:
			toward += 1
		if not (b.wings[0] as Node3D).visible:
			still += 1
	if low > 0 or toward > 0 or still > 0:
		_bad.append("1.3 s after going up: %d birds under 1.2 m, %d no further from the runner, %d with wings shut" % [low, toward, still])
	await get_tree().create_timer(Birds.UP_SECS).timeout
	var seen := f1.birds.filter(func(b: Birds.Bird) -> bool: return b.visible).size()
	if f1.state != "away" or seen > 0:
		_bad.append("%.1f s after going up the flock is '%s' with %d birds still showing" % [Birds.UP_SECS + 1.3, f1.state, seen])
	if birds.went_up < was_up + 1:
		_bad.append("the count of flocks gone up didn't move")
	# and comes down again, somewhere clear
	if f1.back_in < float(Birds.BACK[0]) - Birds.UP_SECS - 2.0 or f1.back_in > float(Birds.BACK[1]):
		_bad.append("a flock gone up is due back in %.0f s" % f1.back_in)
	f1.back_in = 0.05
	var landed := birds.came_down
	await get_tree().create_timer(0.3).timeout
	if f1.state != "down":
		_bad.append("a flock due back is '%s', not coming down" % f1.state)
	else:
		_placed_right(v, f1, w.player.global_position, "coming down")
		if f1.at.distance_to(w.player.global_position) < Birds.CLEAR_PLAYER - 0.01:
			_bad.append("a flock coming down %.1f m from the player" % f1.at.distance_to(w.player.global_position))
		await get_tree().create_timer(1.0).timeout
		var flying := 0
		for b: Birds.Bird in f1.birds:
			if b.visible and b.global_position.y > b.home.y + 0.5:
				flying += 1
		if flying == 0:
			_bad.append("a second into coming down, no bird is in the air")
		await get_tree().create_timer(Birds.DOWN_SECS + 0.8).timeout
		var off := 0
		for b: Birds.Bird in f1.birds:
			if not b.visible or (b.wings[0] as Node3D).visible or b.global_position.distance_to(b.home) > 0.5:
				off += 1
		if f1.state != "ground" or off > 0 or birds.came_down != landed + 1:
			_bad.append("after coming down the flock is '%s', %d birds not stood at their places" % [f1.state, off])
		if _show:
			print("it came down again %.1f m from the player and stands" % f1.at.distance_to(w.player.global_position))
	# a walker has to come nearer: walked past at 3.3 m they stay, at 1.6 m they go
	if f1.state == "ground":
		var walker: Figure3D = Figure3D.make("corin", "corin")
		w.add_child(walker)
		var side := Vector3(1, 0, 0)
		for pass_at: float in [3.6, 1.2]:
			var a := f1.at + side * pass_at + Vector3(0, 0, -4.0)
			var b2 := f1.at + side * pass_at + Vector3(0, 0, 4.0)
			walker.global_position = a
			await get_tree().create_timer(0.4).timeout
			var steps := 0
			while steps < 180 and f1.state == "ground":
				walker.global_position = a.lerp(b2, steps / 180.0)   # (8 m in 6 s: a walk)
				await get_tree().process_frame
				steps += 1
			if pass_at > 3.0 and f1.state != "ground":
				_bad.append("someone walking by %.1f m off sent the flock up" % pass_at)
			if pass_at < 2.0 and f1.state == "ground":
				_bad.append("someone walking through the flock didn't send it up")
			if f1.state != "ground":
				break
		walker.queue_free()
		if _show:
			print("a walker 3.6 m off left them; one through the flock sent them up")
	# rain sends up whatever is down and keeps it up; so does the evening
	await get_tree().create_timer(Birds.UP_SECS + 0.6).timeout
	for f: Birds.Flock in birds.flocks:
		if f.state == "away":
			f.back_in = 0.05
	await get_tree().create_timer(Birds.DOWN_SECS + 1.5).timeout
	var before: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state == "ground").size()
	if before == 0:
		_bad.append("no flock down again before the rain")
	if wx != null:
		wx.amount = 1.0
		await get_tree().create_timer(0.3).timeout
		var wet: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state == "ground" or f.state == "down").size()
		if wet > 0 or birds.about():
			_bad.append("%d flocks stay down in the rain" % wet)
		for f: Birds.Flock in birds.flocks:
			f.back_in = 0.05
		await get_tree().create_timer(Birds.UP_SECS + 1.0).timeout
		var back: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state != "away").size()
		if back > 0:
			_bad.append("%d flocks came down in the rain" % back)
		wx.amount = 0.0
		await get_tree().create_timer(Birds.DOWN_SECS + 1.5).timeout
		var dry: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state == "ground").size()
		if dry == 0:
			_bad.append("no flock came down once the rain was over")
		if _show:
			print("%d flocks down before the rain, none in it, %d after" % [before, dry])
	v.set_daylight(0.0)
	await get_tree().create_timer(0.3).timeout
	for f: Birds.Flock in birds.flocks:
		f.back_in = 0.05
	await get_tree().create_timer(Birds.UP_SECS + 1.0).timeout
	var night: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state != "away").size()
	var showing := 0
	for f: Birds.Flock in birds.flocks:
		showing += f.birds.filter(func(b: Birds.Bird) -> bool: return b.visible).size()
	if night > 0 or showing > 0:
		_bad.append("%d flocks about after dark (%d birds showing)" % [night, showing])
	# a staged scene by day: none come down into it
	v.set_daylight(1.0)
	w.cine = true
	for f: Birds.Flock in birds.flocks:
		f.back_in = 0.05
	await get_tree().create_timer(1.0).timeout
	var staged: int = birds.flocks.filter(func(f: Birds.Flock) -> bool: return f.state != "away").size()
	if staged > 0:
		_bad.append("%d flocks came down into a staged scene" % staged)
	w.cine = false
	_end()


## A flock's place: on the green's ground, level, clear of every wall.
func _placed_right(v: AshfordVillage, f: Birds.Flock, _player: Vector3, when: String) -> void:
	if absf(f.at.y - v.ground_y(f.at.x, f.at.z)) > 0.02:
		_bad.append("%s a flock is %.2f m off the ground" % [when, f.at.y - v.ground_y(f.at.x, f.at.z)])
	for fp in v.footprints:
		if Vector2(f.at.x, f.at.z).distance_to(fp[0]) < float(fp[1]) + Birds.CLEAR_WALL - 0.01:
			_bad.append("%s a flock is %.1f m from a building's middle (its reach %.1f)" % [when, Vector2(f.at.x, f.at.z).distance_to(fp[0]), float(fp[1])])
	if v.path_at(f.at.x, f.at.z) < Birds.ON_PATH - 0.01:
		_bad.append("%s a flock is in the grass (%.2f of a path)" % [when, v.path_at(f.at.x, f.at.z)])
	for b: Birds.Bird in f.birds:
		if Vector2(b.home.x - f.at.x, b.home.z - f.at.z).length() > Birds.SPREAD + 0.01:
			_bad.append("%s a bird stands %.1f m from its flock's middle" % [when, Vector2(b.home.x - f.at.x, b.home.z - f.at.z).length()])


## A spot `far` m from the flock with open ground between (tried round the compass).
func _stand_off(w: World, v: AshfordVillage, f: Birds.Flock, far: float) -> Vector3:
	var space := w.get_world_3d().direct_space_state
	for k in 16:
		var d := Vector3(cos(k * TAU / 16.0), 0, sin(k * TAU / 16.0))
		var at := f.at + d * far
		var clear := true
		for fp in v.footprints:
			if Vector2(at.x, at.z).distance_to(fp[0]) < float(fp[1]) + 1.5:
				clear = false
		if not clear:
			continue
		var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.9, f.at + Vector3.UP * 0.9)
		q.exclude = [w.player.get_rid()]
		if space.intersect_ray(q).is_empty():
			return Vector3(at.x, v.ground_y(at.x, at.z), at.z)
	return f.at + Vector3(far, 0, 0)


func _end() -> void:
	for b in _bad:
		print("  problem: ", b)
	print("BIRDS: ok" if _bad.is_empty() else "BIRDS: %d problem(s)" % _bad.size())
	get_tree().quit(0 if _bad.is_empty() else 1)
