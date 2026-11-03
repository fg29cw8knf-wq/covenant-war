extends Node
## Sigilfall shards in Solhaven (3 November): none in the Prologue, there once
## it's over and the Codex is open, each on open ground (no solid thing on
## its spot, the way Cine.blockers reads the set), picked up by walking onto
## it ("+N Shards"), gone for the rest of the day, and hidden while a film
## has the camera.
##   godot --headless res://tests/sigilfall_test.tscn
## Ends with "SIGILFALL TEST: ok" or the problems.

var problems: Array = []


func _ready() -> void:
	Game.new_game("Ash", "emberstorm")
	Game.flags["arrived_solhaven"] = true   # no arrival film
	var w := World.new().setup("solhaven", "gate")
	add_child(w)
	for i in 30:
		await get_tree().process_frame
	var ss: SigilShards = w.get_node_or_null("SigilShards")
	_check(ss != null, "Solhaven has its Sigilfall shards")
	if ss == null:
		return _end()
	await get_tree().create_timer(1.2).timeout
	_check(ss._items.all(func(it): return not (it.node as Node3D).visible), "none show in the Prologue")
	Game.flags["beat_hunter"] = true
	Game.unlock("codex")
	ss._check_t = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	_check(ss._items.all(func(it): return (it.node as Node3D).visible), "all %d show after the Prologue" % ss._items.size())
	# open ground: nothing solid where each one lies
	var bl := Cine.blockers(w)
	for it in ss._items:
		var p: Vector3 = (it.node as Node3D).global_position
		for b in bl:
			if (b[0] as Vector2).distance_to(Vector2(p.x, p.z)) < float(b[1]) + 0.35:
				problems.append("%s lies in something solid at %s" % [it.key, b[0]])
		var r: Rect2 = w.area.BOUNDS
		_check(r.has_point(Vector2(p.x, p.z)), "%s is inside the walkable square" % it.key)
	# walking onto one picks it up
	var first: Dictionary = ss._items[0]
	var before := Game.shards()
	var toast := [""]
	w.hud._toast.text = ""
	w.player.global_position = (first.node as Node3D).global_position * Vector3(1, 0, 1)
	for i in 6:
		await get_tree().process_frame
	_check(Game.shards() == before + int(first.amount), "walking onto %s gives %d Shards (%d -> %d)" % [first.key, first.amount, before, Game.shards()])
	_check(w.hud._toast.text.begins_with("+%d Shard" % int(first.amount)), "the HUD says so ('%s')" % w.hud._toast.text)
	await get_tree().create_timer(0.8).timeout
	_check(not (first.node as Node3D).visible, "and it's gone")
	ss._check_t = 0.0
	await get_tree().process_frame
	_check(not (first.node as Node3D).visible, "for the rest of the day")
	# a film hides the rest
	w.cine = true
	ss._check_t = 0.0
	await get_tree().process_frame
	_check(ss._items.all(func(it): return not (it.node as Node3D).visible), "a film hides them")
	w.cine = false
	_end()


func _end() -> void:
	print("SIGILFALL TEST: %s" % ("ok" if problems.is_empty() else "PROBLEMS"))
	for p in problems:
		print("  - ", p)
	get_tree().quit(0 if problems.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		problems.append(what)
