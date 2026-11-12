extends Node3D
## The places' beds of sound (12 November): every bed a place can ask for is
## there, loads and goes round; Ashford asks for the right one by where the
## camera looks (the taprooms, the cellar, the attic, the mill), by the hour
## (day, dusk, the festival night, the dark night, the dawn after) and when
## a house burns; the Thornwood by the river and by its part; Solhaven its
## streets; a world hidden behind a duel, waiting, behind the title screen
## or under a black screen is silent, and so is everything while a film plays; and the player eases
## from one bed to the next. Also the two new grounds (the inn's stairs and
## the river's shallows) and the weather: a shower on the green in its time,
## and what sees one off.
## Run: godot --headless --path . --fixed-fps 30 res://tests/ambience_test.tscn [-- list]
## Ends "AMBIENCE: ok" or the problems.

var _bad: Array = []
var _show := false
const BEDS := ["amb_rain", "amb_attic", "amb_fire_rain", "amb_attic_rain", "amb_fire", "amb_cellar", "amb_green_day", "amb_dusk", "amb_night", "amb_festival", "amb_burning", "amb_wood_day", "amb_river", "amb_camp", "amb_city"]


func _ready() -> void:
	_show = "list" in OS.get_cmdline_user_args()
	get_tree().root.theme = UITheme.make()
	for b: String in BEDS:
		var s := Ambience.loop_of(b)
		if s == null:
			_bad.append("no bed %s (assets/sfx/%s.ogg: tools/make_ambience.py)" % [b, b])
		elif s.get_length() < 10.0:
			_bad.append("%s is only %.1f s long" % [b, s.get_length()])
		elif s is AudioStreamOggVorbis and not (s as AudioStreamOggVorbis).loop:
			_bad.append("%s doesn't go round" % b)
	for g: String in ["stairs", "water"]:
		if not Sfx.has_file("step_" + g) or not Sfx.has_file("step_%s_2" % g):
			_bad.append("no footstep (or only one take) for %s" % g)
	await _ashford()
	await _thornwood()
	await _solhaven()
	for b in _bad:
		print("  problem: ", b)
	print("AMBIENCE: ok" if _bad.is_empty() else "AMBIENCE: %d problem(s)" % _bad.size())
	get_tree().quit(0 if _bad.is_empty() else 1)


func _want(w: World, what: String, bed: String) -> void:
	var got := w.ambience()
	if _show:
		print("%-44s %s" % [what, got if got != "" else "(silence)"])
	if got != bed:
		_bad.append("%s: '%s', not '%s'" % [what, got, bed])


## The world's camera put over a spot, looking down at it as the game's does.
func _look(w: World, at: Vector3) -> void:
	w.cam.global_position = at + Vector3(0, 6.0, 8.0)
	w.cam.look_at(at + Vector3(0, 1.0, 0))


func _ashford() -> void:
	Game.new_game("Sprout", "tidegrove")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met", "first_deck"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	var w := World.new().setup("ashford", "green")
	add_child(w)
	for k in 20:
		await get_tree().process_frame
	w.cine = true   # (the camera stays where the test puts it)
	var v := w.get_meta("village") as AshfordVillage
	var green := w.player.global_position
	_look(w, green)
	v.set_daylight(1.0)
	_want(w, "Ashford's green by day", "amb_green_day")
	v.set_daylight(0.3)
	_want(w, "the green as the sun goes", "amb_dusk")
	v.set_daylight(0.0)
	v.time_kind = "festival"
	_want(w, "the green on the festival night", "amb_festival")
	v.time_kind = "burning"
	_want(w, "the green on the dark night after", "amb_night")
	v.time_kind = "dawn"
	_want(w, "the green the morning the fires are out", "")
	v.time_kind = "festival"
	if v.houses.size() > 0:
		(v.houses[0] as Dictionary)["burning"] = true
		_want(w, "the green with a house on fire", "amb_burning")
		(v.houses[0] as Dictionary)["burning"] = false
	for row: Array in [[InnRooms.TAPROOM_AT + Vector3(1, 0, 0.5), "the taproom", "amb_fire"], [InnRooms.EVE_AT + Vector3(-1, 0, 1), "the taproom of an evening", "amb_fire"],
			[InnRooms.CELLAR_AT + Vector3(0, 0, 1), "the cellar", "amb_cellar"], [AshfordNight.TUNNEL_AT + Vector3(2, 0, 0), "the smugglers' tunnel", "amb_cellar"],
			[InnRooms.ATTIC_AT + Vector3(0.5, 0, 0), "the attic", "amb_attic"], [MillSet.AT + Vector3(2, 0, 3), "the mill", "amb_river"]]:
		_look(w, row[0])
		_want(w, String(row[1]), String(row[2]))
	# the grounds: the stairs in the cellar, three treads up
	if w.surface_at(InnRooms.CELLAR_AT + Vector3(3.0, 0.9, 1.0)) != "stairs":
		_bad.append("three treads up the cellar stairs the ground is '%s'" % w.surface_at(InnRooms.CELLAR_AT + Vector3(3.0, 0.9, 1.0)))
	if w.surface_at(InnRooms.CELLAR_AT + Vector3(-1.0, 0.0, 0.5)) != "stone":
		_bad.append("the cellar's floor is '%s'" % w.surface_at(InnRooms.CELLAR_AT + Vector3(-1.0, 0.0, 0.5)))
	if w.surface_at(InnRooms.EVE_AT + Vector3(-2.0, 1.4, 2.9)) != "stairs":
		_bad.append("halfway up the attic stairs the ground is '%s'" % w.surface_at(InnRooms.EVE_AT + Vector3(-2.0, 1.4, 2.9)))
	_look(w, green)
	v.set_daylight(1.0)
	_weather(w, v)
	# the player easing from one bed to the next, and to silence when the world is put away
	await get_tree().create_timer(Ambience.FADE + Ambience.CHECK + 0.4).timeout
	if Ambience.bed() != "amb_green_day" or Ambience.gain_of("amb_green_day") < 0.95:
		_bad.append("the green's bed isn't playing in full (%s, %.2f)" % [Ambience.bed(), Ambience.gain_of("amb_green_day")])
	_look(w, InnRooms.TAPROOM_AT)
	await get_tree().create_timer(Ambience.CHECK + Ambience.FADE * 0.5).timeout
	var a := Ambience.gain_of("amb_green_day")
	var b := Ambience.gain_of("amb_fire")
	if _show:
		print("half-way from the green to the taproom: the green %.2f, the hearth %.2f" % [a, b])
	if Ambience.bed() != "amb_fire" or a <= 0.05 or a >= 0.95 or b <= 0.05 or b >= 0.95:
		_bad.append("half-way from the green's bed to the hearth's: %s, %.2f and %.2f" % [Ambience.bed(), a, b])
	# a film: its own soundtrack
	Ambience.hush += 1
	await get_tree().create_timer(Ambience.CHECK + 0.1).timeout
	if Ambience.bed() != "":
		_bad.append("a bed plays under a film: %s" % Ambience.bed())
	Ambience.hush -= 1
	# behind a duel: hidden and stopped, as Main does it
	w.visible = false
	w.process_mode = Node.PROCESS_MODE_DISABLED
	_want(w, "the world behind a duel", "")
	await get_tree().create_timer(Ambience.FADE + Ambience.CHECK + 0.4).timeout
	if Ambience.bed() != "" or Ambience.gain_of("amb_fire") > 0.0:
		_bad.append("a bed is still playing behind a duel (%s, %.2f)" % [Ambience.bed(), Ambience.gain_of("amb_fire")])
	w.visible = true
	w.process_mode = Node.PROCESS_MODE_INHERIT
	w.attract = true
	_want(w, "the world behind the title screen", "")
	w.attract = false
	w.held = true
	_want(w, "a world waiting to start", "")
	w.held = false
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## The weather (Weather). The shower: none before its time, one within FIRST
## of a free day on the green, heard as rain, gone within LAST, none again
## inside GAP; none at dusk, in a staged scene on the green, during a film or
## with a house on fire, and one that's falling is seen off in a few seconds
## by any of those; indoors it carries on, heard on the roof from the
## taproom and the attic and not drawn. The rainbow: there as a shower ends,
## its foot in the walking camera's sight, gone in its time or seen off. The
## mist, and everyone's breath: on the morning after the fires only.
## Thunder: once in a shower that has it. Puddles: on the paths, full after
## PUDDLE_FILL of rain, dry PUDDLE_DRY after, or at once when a shower is
## seen off. Its clock is run by hand here, a second at a time.
func _weather(w: World, v: AshfordVillage) -> void:
	var wx := Weather.of(w)
	if wx == null:
		_bad.append("Ashford has no weather")
		return
	wx.set_process(false)
	w.cine = false
	if not wx.may_rain():
		_bad.append("no shower may fall on a free day on the green")
	var began := -1.0
	var ended := -1.0
	var again := -1.0
	var t := 0.0
	while t < float(Weather.FIRST[1]) + float(Weather.LAST[1]) + float(Weather.GAP[1]) + 20.0:
		wx._process(1.0)
		t += 1.0
		if began < 0.0 and wx.raining():
			began = t
			if w.ambience() != "amb_rain":
				_bad.append("it's raining and the green sounds of '%s'" % w.ambience())
		elif began >= 0.0 and ended < 0.0 and wx.amount <= 0.0:
			ended = t
			if w.ambience() != "amb_green_day":
				_bad.append("the shower's over and the green sounds of '%s'" % w.ambience())
		elif ended >= 0.0 and again < 0.0 and wx.amount > 0.0:
			again = t
	if _show:
		print("a day on the green, a second at a time: the first shower heard at %.0f s, over by %.0f s, the next %s" % [began, ended, ("at %.0f s" % again) if again >= 0.0 else "not yet"])
	if began < float(Weather.FIRST[0]) or began > float(Weather.FIRST[1]) + Weather.EASE_IN:
		_bad.append("the first shower came at %.0f s" % began)
	if ended < 0.0 or ended - began > float(Weather.LAST[1]) + Weather.EASE_OUT + 2.0 or ended - began < float(Weather.LAST[0]) - Weather.EASE_IN:
		_bad.append("the shower lasted %.0f s" % (ended - began))
	if again >= 0.0 and again - ended < float(Weather.GAP[0]) - 5.0:
		_bad.append("a second shower only %.0f s after the first ended" % (again - ended))
	# seen off: each thing that stops one, with a shower falling
	for why: String in ["a staged scene", "the sun going down", "a film", "a house on fire"]:
		wx._left = 60.0
		wx.amount = 1.0
		match why:
			"a staged scene":
				w.cine = true
			"the sun going down":
				v.set_daylight(0.5)
			"a film":
				Ambience.hush += 1
			"a house on fire":
				(v.houses[0] as Dictionary)["burning"] = true
		if wx.may_rain():
			_bad.append("a shower may fall with %s" % why)
		for k in int(Weather.EASE_OUT) + 1:
			wx._process(1.0)
		if wx.amount > 0.0 or wx._left > 0.0:
			_bad.append("%s didn't see the shower off (%.2f, %.0f s left)" % [why, wx.amount, wx._left])
		w.cine = false
		v.set_daylight(1.0)
		Ambience.hush = 0
		(v.houses[0] as Dictionary)["burning"] = false
		_look(w, w.player.global_position)
	# indoors a shower carries on, heard on the roof and not drawn; under
	# the ground it isn't heard at all
	wx._left = 60.0
	wx.amount = 1.0
	for row: Array in [[InnRooms.TAPROOM_AT, "the taproom in a shower", "amb_fire_rain"], [InnRooms.ATTIC_AT, "the attic in a shower", "amb_attic_rain"],
			[InnRooms.CELLAR_AT, "the cellar in a shower", "amb_cellar"]]:
		_look(w, row[0])
		w.cine = true   # (a staged scene indoors doesn't see it off either)
		wx._process(1.0)
		_want(w, String(row[1]), String(row[2]))
		if wx._left <= 0.0 or wx.amount < 1.0:
			_bad.append("%s: going indoors saw the shower off" % row[1])
		if wx._rain.emitting:
			_bad.append("%s: rain is drawn indoors" % row[1])
		w.cine = false
	_look(w, w.player.global_position)
	wx._process(1.0)
	if not wx._rain.emitting or w.ambience() != "amb_rain":
		_bad.append("back out on the green the shower isn't falling (%s)" % w.ambience())
	wx._left = 0.0
	wx.amount = 0.0
	# the rainbow: there within BOW_IN of a shower's end, gone again after
	# BOW_HOLD, and seen off by a staged scene
	wx.force_bow()
	for k in int(Weather.BOW_IN) + 1:
		wx._process(1.0)
	if wx.bow < 0.99 or not wx._bow.visible:
		_bad.append("no rainbow %.0f s after one was due (%.2f)" % [Weather.BOW_IN + 1.0, wx.bow])
	var foot: Vector3 = wx._bow.global_transform * Vector3(-Weather.BOW_RADIUS, 0, 0)
	if _show:
		print("the rainbow's foot stands %.1f m from the player" % Vector2(foot.x - w.player.global_position.x, foot.z - w.player.global_position.z).length())
	if Vector2(foot.x - w.player.global_position.x, foot.z - w.player.global_position.z).length() > 12.0:
		_bad.append("the rainbow's foot is %.0f m from the player: out of the walking camera's sight" % foot.distance_to(w.player.global_position))
	for k in int(Weather.BOW_HOLD + Weather.BOW_OUT) + 2:
		wx._process(1.0)
	if wx.bow > 0.0 or wx._bow.visible:
		_bad.append("the rainbow is still there %.0f s on (%.2f)" % [Weather.BOW_HOLD + Weather.BOW_OUT, wx.bow])
	wx.force_bow()
	for k in int(Weather.BOW_IN) + 1:
		wx._process(1.0)
	w.cine = true
	for k in int(Weather.EASE_OUT) + 1:
		wx._process(1.0)
	if wx.bow > 0.0:
		_bad.append("a staged scene didn't see the rainbow off (%.2f)" % wx.bow)
	w.cine = false
	# thunder: once, part-way through a shower that has one
	Sfx.listen = true
	Sfx.heard.clear()
	wx._left = 30.0
	wx.amount = 1.0
	wx._thunder_in = 2.5
	for k in 6:
		wx._process(1.0)
	var rolls: int = Sfx.heard.filter(func(h): return String(h[1]) == "thunder_far").size()
	if rolls != 1:
		_bad.append("a shower with thunder in it thundered %d times" % rolls)
	if not Sfx.has_file("thunder_far") or not Sfx.has_file("thunder_far_2"):
		_bad.append("no thunder (or only one take): assets/sfx/thunder_far.wav")
	# puddles: filled by PUDDLE_FILL of rain, on the paths; dry PUDDLE_DRY
	# after it; dried in a few seconds by what sees a shower off
	var n := 0
	var off_path := 0
	for mm: MultiMeshInstance3D in wx._puddles.find_children("*", "MultiMeshInstance3D", true, false):
		for i in mm.multimesh.instance_count:
			var o := mm.multimesh.get_instance_transform(i).origin
			n += 1
			if v.path_at(o.x, o.z) < 0.5 or absf(o.y - v.ground_y(o.x, o.z)) > 0.05:
				off_path += 1
	if _show:
		print("%d puddles, %d of them off a path or off the ground" % [n, off_path])
	if n < 10 or off_path > 0:
		_bad.append("%d puddles, %d off a path or off the ground" % [n, off_path])
	wx.wet = 0.0
	wx._left = 60.0
	wx._thunder_in = -1.0
	for k in int(Weather.PUDDLE_FILL) + 2:
		wx._process(1.0)
	if wx.wet < 0.99 or not wx._puddles.visible:
		_bad.append("the puddles aren't full after %.0f s of rain (%.2f)" % [Weather.PUDDLE_FILL + 2.0, wx.wet])
	wx._left = 0.0
	wx._bow_left = 0.0
	for k in int(Weather.EASE_OUT + Weather.PUDDLE_DRY * 0.5):
		wx._process(1.0)
	if wx.wet < 0.3 or not wx._puddles.visible:
		_bad.append("the puddles are gone half-way through their drying (%.2f)" % wx.wet)
	for k in int(Weather.PUDDLE_DRY * 0.5) + 6:
		wx._process(1.0)
	if wx.wet > 0.0 or wx._puddles.visible:
		_bad.append("the puddles are still there %.0f s after the rain (%.2f)" % [Weather.PUDDLE_DRY + 6.0, wx.wet])
	wx.wet = 1.0
	w.cine = true
	for k in int(Weather.EASE_OUT) + 1:
		wx._process(1.0)
	if wx.wet > 0.0:
		_bad.append("a staged scene didn't dry the puddles (%.2f)" % wx.wet)
	w.cine = false
	wx.bow = 0.0
	wx._bow_left = 0.0
	_splashes(w, v, wx, n)
	_fireflies(w, v, wx)
	_leaves(w, v, wx)
	# the mist: on the morning after the fires, and only then
	wx._process(1.0)
	if wx.mist > 0.0 or wx._mist.emitting:
		_bad.append("mist on the green on a festival day")
	v.time_kind = "dawn"
	wx._process(1.0)
	if wx.mist < 1.0 or not wx._mist.emitting or not wx._banks.emitting:
		_bad.append("no mist on the green on the morning after the fires")
	if not wx._breath.on:
		_bad.append("no breath shows on the morning after the fires")
	if wx.may_rain():
		_bad.append("a shower may fall on the morning after the fires")
	v.time_kind = "festival"
	wx._process(1.0)
	if wx._mist.emitting or wx._banks.emitting:
		_bad.append("the mist stays when the morning is over")
	if wx._breath.on:
		_bad.append("breath shows on a festival day")
	w.cine = true
	wx.set_process(true)


## A foot down in a puddle: water underfoot while there is water in it,
## the path's dirt once it has dried; and a splash goes up from it.
func _splashes(w: World, v: AshfordVillage, wx: Weather, puddles: int) -> void:
	if wx._puddle_at.size() != puddles:
		_bad.append("%d puddles drawn and %d known for stepping in" % [puddles, wx._puddle_at.size()])
		return
	var widest: Array = wx._puddle_at[0]
	for row: Array in wx._puddle_at:
		if float(row[1]) > float(widest[1]):
			widest = row
		if float(row[1]) < 0.15 or float(row[1]) > 0.7:
			_bad.append("a puddle to be stepped in from %.2f m off" % float(row[1]))
	var c: Vector2 = widest[0]
	var mid := Vector3(c.x, v.ground_y(c.x, c.y), c.y)
	var beside := mid + Vector3(float(widest[1]) + 0.25, 0.0, 0.0)
	wx.wet = 1.0
	if w.surface_at(mid) != "water":
		_bad.append("in a full puddle the ground is '%s'" % w.surface_at(mid))
	if w.surface_at(beside) == "water":
		_bad.append("a step beside a puddle is in the water")
	var was := wx.splashes
	w.stepped_at(mid, w.surface_at(mid))
	w.stepped_at(beside, w.surface_at(beside))
	if wx.splashes != was + 1:
		_bad.append("a step in a puddle and one beside it made %d splashes" % (wx.splashes - was))
	var ring := (wx._splash_pool[(wx._splash_turn + wx._splash_pool.size() - 1) % wx._splash_pool.size()] as Node3D)
	if ring.global_position.distance_to(mid) > 0.1 or not (ring.get_node("Ring") as MeshInstance3D).visible:
		_bad.append("the splash isn't where the foot came down")
	wx.wet = Weather.SPLASH_FROM * 0.5
	if w.surface_at(mid) != "dirt":
		_bad.append("in a puddle all but dry the ground is '%s'" % w.surface_at(mid))
	was = wx.splashes
	w.stepped_at(mid, "water")
	if wx.splashes != was:
		_bad.append("a puddle all but dry splashed")
	wx.wet = 0.0
	if _show:
		print("%d puddles to step in; the widest takes a foot from %.2f m" % [wx._puddle_at.size(), float(widest[1])])


## Fireflies: over the green on the festival night, and not by day, on the
## morning after, or once a house is alight.
func _fireflies(w: World, v: AshfordVillage, wx: Weather) -> void:
	var day := v.daylight
	var kind := v.time_kind
	wx._process(1.0)
	if wx.flies > 0.0 or wx._flies.emitting:
		_bad.append("fireflies by day")
	v.daylight = 0.0
	v.time_kind = "festival"
	wx._process(1.0)
	if wx.flies < 1.0 or not wx._flies.emitting or not wx._flies.visible:
		_bad.append("no fireflies on the green on the festival night")
	# where they come out: over the green's ground, clear of the walls
	var low := 0
	var walled := 0
	for spot: Vector3 in wx.fly_spots:
		var over := spot.y - v.ground_y(spot.x, spot.z)
		if over < float(Weather.FIREFLY_UP[0]) - 0.01 or over > float(Weather.FIREFLY_UP[1]) + 0.01:
			low += 1
		for f in v.footprints:
			if Vector2(spot.x, spot.z).distance_to(f[0]) < float(f[1]) + 0.5:
				walled += 1
				break
	if wx.fly_spots.size() < 200 or low > 0 or walled > 0:
		_bad.append("%d places for a firefly to come out: %d not over the grass, %d in a wall" % [wx.fly_spots.size(), low, walled])
	if _show:
		print("%d places for a firefly to come out, %d on screen at once" % [wx.fly_spots.size(), wx._flies.amount])
	if not v.houses.is_empty():
		var h: Dictionary = v.houses[0]
		var lit: bool = h.get("burning", false)
		h["burning"] = true
		wx._process(1.0)
		if wx.flies > 0.0 or wx._flies.emitting:
			_bad.append("fireflies with a house on fire")
		h["burning"] = lit
		wx._process(1.0)
	v.sigil_on = true
	wx._process(1.0)
	if wx.flies > 0.0:
		_bad.append("fireflies under the torn sky")
	v.sigil_on = false
	wx._process(1.0)
	w.cine = true   # (a staged scene on the festival night keeps them: they are part of the night)
	wx._process(1.0)
	if wx.flies < 1.0:
		_bad.append("a staged scene on the festival night has no fireflies")
	w.cine = false
	v.time_kind = "dawn"
	wx._process(1.0)
	if wx.flies > 0.0 or wx._flies.emitting:
		_bad.append("fireflies on the morning after the fires")
	v.time_kind = "burning"
	wx._process(1.0)
	if wx.flies > 0.0:
		_bad.append("fireflies on the night of the fires")
	# out on the festival night, then the day comes (the village is built as
	# the night and dressed for the day a moment later): none left showing
	v.time_kind = "festival"
	v.daylight = 0.0
	wx._process(1.0)
	if not wx._flies.visible or not wx._flies.emitting:
		_bad.append("no fireflies back on the festival night")
	v.daylight = 1.0
	wx._process(0.1)
	if wx._flies.visible or wx._flies.emitting:
		_bad.append("fireflies still showing the moment it's day")
	# and none in the village's first half-second, whatever the hour
	wx._fly_age = 0.0
	v.daylight = 0.0
	wx._process(0.1)
	if wx.flies > 0.0 or wx._flies.visible:
		_bad.append("fireflies in the village's first moments")
	wx._fly_age = Weather.FIREFLY_SETTLE + 1.0
	v.time_kind = kind
	v.daylight = day
	wx._process(1.0)


## Leaves: a few come down over the spot on screen every so often by day,
## from the side the nearest oak stands on; none at night or in a staged scene.
func _leaves(w: World, v: AshfordVillage, wx: Weather) -> void:
	var day := v.daylight
	var at := w.cam_ground()
	if v.oaks.is_empty():
		_bad.append("no oaks in Ashford for leaves to come from")
		return
	v.daylight = 1.0
	var was := wx.leaf_falls
	var secs := int(float(Weather.LEAF_EVERY[1]) * 3.0)
	for k in secs:
		wx._process(1.0)
	var falls := wx.leaf_falls - was
	if falls < 2 or falls > int(secs / float(Weather.LEAF_EVERY[0])) + 1:
		_bad.append("%d falls of leaves in %d s of day" % [falls, secs])
	# the last one: over the spot on screen, towards the nearest oak
	var last := wx._leaf_pool[(wx._leaf_turn + wx._leaf_pool.size() - 1) % wx._leaf_pool.size()] as CPUParticles3D
	var off := last.global_position - at
	var wind := wx.leaf_wind(at)
	var up := last.global_position.y - maxf(at.y, v.ground_y(last.global_position.x, last.global_position.z))
	var back := -Vector3(off.x, 0, off.z).dot(wind)
	var aside := absf(Vector3(off.x, 0, off.z).dot(wind.cross(Vector3.UP)))
	if up < float(Weather.LEAF_UP[0]) - 0.01 or up > float(Weather.LEAF_UP[1]) + 0.01 or absf(back - Weather.LEAF_UPWIND) > 0.05 or aside > Weather.LEAF_ASIDE + 0.05:
		_bad.append("leaves let go %.1f m up, %.1f m upwind and %.1f m aside of the spot on screen" % [up, back, aside])
	if last.direction.y > -0.7 or Vector3(last.direction.x, 0, last.direction.z).dot(wind) < 0.2:
		_bad.append("leaves sent off %s with the air going %s" % [last.direction, wind])
	if _show:
		print("%d oaks; %d falls of leaves in %d s; the last %.1f m up, %.1f m upwind, %.1f m aside; the air goes %s" % [v.oaks.size(), falls, secs, up, back, aside, wind])
	w.cine = true
	was = wx.leaf_falls
	for k in secs:
		wx._process(1.0)
	if wx.leaf_falls != was:
		_bad.append("%d falls of leaves in a staged scene" % (wx.leaf_falls - was))
	w.cine = false
	v.daylight = 0.0
	was = wx.leaf_falls
	for k in secs:
		wx._process(1.0)
	if wx.leaf_falls != was:
		_bad.append("%d falls of leaves at night" % (wx.leaf_falls - was))
	v.daylight = day
	wx._process(1.0)


func _thornwood() -> void:
	var w := World.new().setup("thornwood", "river")
	add_child(w)
	for k in 20:
		await get_tree().process_frame
	w.cine = true
	# (the wood opens on a black screen, and a place isn't heard under one)
	_want(w, "the Thornwood under its opening's black", "")
	Cine.overlay(w).black(false)
	var v := w.get_meta("village") as ThornwoodSet
	var S: Dictionary = ThornwoodSet.SPOTS
	_look(w, S.near_bank)
	_want(w, "the Thornwood's river bank", "amb_river")
	v.set_scene("camp")
	_look(w, S.camp)
	_want(w, "the camp on the first night", "amb_camp")
	v.set_scene("morning")
	_want(w, "the camp by morning", "amb_wood_day")
	v.set_scene("road")
	_look(w, S.road)
	_want(w, "the road at night", "amb_night")
	v.set_scene("ridge")
	_look(w, S.ridge)
	_want(w, "the ridge at dawn", "amb_wood_day")
	_look(w, ThornwoodShelter.ROOM_AT + Vector3(0.5, 0, 0.5))
	_want(w, "Bram's shelter", "")
	# the grounds: in the river, on its bank
	var mid := Vector3(S.near_bank.x, 0, ThornwoodSet.RIVER_Z + 3.0 * sin(S.near_bank.x / 25.0))
	var in_water := v.height(mid.x, mid.z) < ThornwoodSet.WATER_Y
	if _show:
		print("the river's bed at its middle: %.2f (the water at %.2f)" % [v.height(mid.x, mid.z), ThornwoodSet.WATER_Y])
	if in_water and w.surface_at(Vector3(mid.x, v.height(mid.x, mid.z), mid.z)) != "water":
		_bad.append("in the river the ground is '%s'" % w.surface_at(mid))
	if not in_water:
		_bad.append("the river's bed isn't under its water at its middle")
	var bank := Vector3(S.camp.x + 3.0, 0, S.camp.z)
	if w.surface_at(bank) == "water":
		_bad.append("the camp is under water")
	w.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _solhaven() -> void:
	var w := World.new().setup("solhaven", "gate")
	add_child(w)
	for k in 20:
		await get_tree().process_frame
	Cine.overlay(w).black(false)
	_want(w, "Solhaven's gate", "amb_city")
	Cine.overlay(w).black(true)
	_want(w, "Solhaven under a black screen", "")
	w.queue_free()
	await get_tree().process_frame
