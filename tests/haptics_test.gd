extends Node
## The phone shaking in the hand in an ordinary duel (14 November, Gary's yes
## to "the phone shake in every duel, not just the opening"): DuelScreen._buzz
## and Haptics. A duel on the flat field with a board set by hand, as
## tests/duel_cine_shot.gd sets one: a big blow on a Totem (a weakness
## struck), the Totem broken, and the blow that ends the duel, and what was
## asked of the phone at each (Haptics.count and .last: there's no motor
## here, and none on a Mac). Then the same blow with Vibration switched off
## in Options, and with the duel run at a watcher's speed: nothing asked.
##   godot --headless --fixed-fps 30 --path . res://tests/haptics_test.tscn
## Ends "HAPTICS: ok" or the problems.

var ds: DuelScreen
var problems: Array = []


func _ready() -> void:
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = false
	Game.settings["vibration"] = true
	Game.settings[SummonVideo.SETTING] = "off"   # (not set_mode: that saves it to this machine's Options)
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": false})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	await _run()
	if problems.is_empty():
		print("HAPTICS: ok")
	else:
		for p in problems:
			print("HAPTICS: FAIL: ", p)
	Engine.time_scale = 1.0
	get_tree().quit(0 if problems.is_empty() else 1)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _board(mine: String, theirs: String) -> Array:
	var g := ds.game
	var made := []
	for side in 2:
		g.players[side].slots = [null, null, null]
		var tt := g._new_totem(DuelCard.new(9700 + side, mine if side == 0 else theirs, side), side, 1, 0)
		g.players[side].slots[1] = tt
		made.append(tt)
	g._changed()
	ds._refresh()
	await _wait(0.6)
	return made


## What the phone was asked for by `what`, against what it should have been.
func _asked(what: String, before: int, want: Array) -> void:
	var n := Haptics.count - before
	print("HAPTICS: %s: %d asked for, the last %s" % [what, n, str(Haptics.last)])
	if want.is_empty():
		if n != 0:
			problems.append("%s: %d buzzes asked for, wanted none" % [what, n])
	elif n < 1 or int(Haptics.last[0]) != int(want[0]):
		problems.append("%s: %d buzzes, the last %s; wanted %s" % [what, n, str(Haptics.last), str(want)])


func _run() -> void:
	var made: Array = await _board("cinderpup", "mossling")
	var att: DuelTotem = made[0]
	var tg: DuelTotem = made[1]
	ds.mode = "busy"
	ds._set_hint("")
	# a big blow (fire on a weakness)
	await ds.fx_attack(att, 0, tg)
	var n := Haptics.count
	ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
	await _wait(1.2)
	_asked("a big blow on a Totem", n, Haptics.BLOW)
	# a small one: nothing
	n = Haptics.count
	ds.fx_totem_hit(tg, 10, {"source": "burn"})
	await _wait(0.8)
	_asked("a small blow", n, [])
	# the Totem broken
	ds._strike = {}
	tg.damage = tg.max_hp()
	ds.game.players[1].slots[1] = null
	n = Haptics.count
	ds.fx_ko(tg)
	await _wait(2.7)
	_asked("a Totem broken", n, Haptics.HEAVY)
	# Vibration off in Options: nothing
	made = await _board("cinderpup", "mossling")
	att = made[0]
	tg = made[1]
	Game.settings["vibration"] = false
	n = Haptics.count
	ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
	await _wait(1.2)
	_asked("a big blow with Vibration off", n, [])
	Game.settings["vibration"] = true
	# a duel run at a watcher's speed: nothing
	var was := ds.speed
	ds.speed = 50.0
	n = Haptics.count
	ds.fx_totem_hit(tg, 60, {"attacker": att, "element": att.element()})
	await _wait(0.6)
	_asked("a big blow at a watcher's speed", n, [])
	ds.speed = was
	# the blow that ends it
	ds.game.players[1].life = 0
	await ds.fx_attack(att, 0, DuelGame.LIFE)
	n = Haptics.count
	ds.fx_life_hit(1, 40, {"attacker": att})
	await _wait(1.5)
	_asked("the blow that ends the duel", n, Haptics.LONG)
	# (its slow motion is timed by a watch, and this runs faster than one:
	# whether the clock is put back is tests/duel_cine_shot's to check)
