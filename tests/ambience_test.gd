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
## mist: on the morning after the fires only. Its clock is run by hand here,
## a second at a time.
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
	# the mist: on the morning after the fires, and only then
	wx._process(1.0)
	if wx.mist > 0.0 or wx._mist.emitting:
		_bad.append("mist on the green on a festival day")
	v.time_kind = "dawn"
	wx._process(1.0)
	if wx.mist < 1.0 or not wx._mist.emitting or not wx._banks.emitting:
		_bad.append("no mist on the green on the morning after the fires")
	if wx.may_rain():
		_bad.append("a shower may fall on the morning after the fires")
	v.time_kind = "festival"
	wx._process(1.0)
	if wx._mist.emitting or wx._banks.emitting:
		_bad.append("the mist stays when the morning is over")
	w.cine = true
	wx.set_process(true)


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
