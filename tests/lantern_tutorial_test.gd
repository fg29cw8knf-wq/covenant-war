extends Node
## Plays the Lantern Duel's tutorial the way a new player would: reads every
## line, taps exactly what Bram asks, and first tries a wrong tap at each
## instruction to check the lesson won't move on until the right thing is done.
## Saves a screenshot of every lesson step and prints the result.
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/lantern_tutorial_test.tscn -- <out_dir> [ui=1.3]

var out_dir := "user://"
var n := 0
var ds: DuelScreen
var problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	for a in args:
		if a.begins_with("ui="):
			Game.settings["ui_scale"] = float(a.trim_prefix("ui="))   # Options > Text and buttons size
	Game.settings["duel_speed"] = 4.0
	var area = load("res://scripts/world/areas/ashford.gd")
	var spec: Dictionary = area.duel_spec({"difficulty": 0.25})
	spec.speed = 4.0
	var layer := CanvasLayer.new()
	add_child(layer)
	ds = DuelScreen.new().configure(spec)
	layer.add_child(ds)
	_drive()
	var r: String = await ds.finished
	print("lantern tutorial result: ", r)
	get_tree().quit()


func _drive() -> void:
	var last := ""
	var t0 := Time.get_ticks_msec()
	while is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		if Time.get_ticks_msec() - t0 > 600000:   # (a slow software renderer takes a while)
			print("TIMEOUT")
			get_tree().quit(1)
			return
		if ds.game != null and ds.game.over:
			await get_tree().create_timer(2.0).timeout
			await _shot("result")
			print("winner: %d (turn %d)  life %d / %d" % [ds.game.winner, ds.game.turn, ds.game.players[0].life, ds.game.players[1].life])
			print("PROBLEMS: ", problems if not problems.is_empty() else "none")
			ds.finished.emit("won" if ds.game.winner == 0 else "lost")
			return
		var tu: DuelTutor = ds.tutor
		if tu == null:
			continue
		if not tu.event_step.is_empty():
			# an instruction inside an event: tap the die for who goes first
			var key0 := "event:" + String(tu.event_step.do)
			if key0 != last:
				last = key0
				await get_tree().create_timer(0.6).timeout
				await _shot("do")
				print("  [do %s] %s" % [tu.event_step.do, String(tu.event_step.say).left(60)])
				ds._on_end_turn()           # a wrong tap first: nothing may happen
				ds._on_die_tapped(false)    # and a tap beside the die
				await get_tree().create_timer(0.2).timeout
				if tu.event_step.is_empty():
					problems.append("wrong tap moved the lesson on at %s" % key0)
				ds._on_die_tapped(true)
			continue
		if tu.blocking:
			var key := "info:" + tu.text_label.text
			if key != last:
				last = key
				await get_tree().create_timer(0.5).timeout
				await _shot("info")
				print("  [info] ", tu.text_label.text.left(70))
				# everything else must be locked while a line is up
				if ds.mode == "main":
					var before := tu.queue.size()
					ds._on_end_turn()
					if tu.queue.size() != before or ds.mode != "main":
						problems.append("End Turn worked during an explanation")
				tu.tap()
			continue
		if ds.mode != "main" or tu.queue.is_empty() or not (tu.queue[0] as Dictionary).has("do"):
			continue
		var step: Dictionary = tu.queue[0]
		var key2 := "do:%d:%s" % [tu.my_turn, step.do]
		if key2 == last:
			continue
		last = key2
		await get_tree().create_timer(0.6).timeout
		await _shot("do")
		print("  [do %s] %s" % [step.do, String(step.say).left(60)])
		# a wrong tap first: the step must not advance
		var size_before := tu.queue.size()
		if String(step.do) != "end":
			ds._on_end_turn()
		else:
			ds._cancel_pending()
		await get_tree().create_timer(0.2).timeout
		if tu.queue.size() != size_before or ds.mode != "main":
			problems.append("wrong tap moved the lesson on at %s" % step.do)
		_do(String(step.do))


func _do(d: String) -> void:
	var kind := d.get_slice(":", 0)
	var arg := d.get_slice(":", 1) if d.contains(":") else ""
	match kind:
		"card":
			for hv in ds.hand_views:
				if hv.card.id == arg:
					ds._on_hand_tapped(hv)
					return
		"slot":
			ds._on_slot_tapped(ds.views[ds.me][int(arg)])
			return
		"totem", "target":
			if arg == "life":
				ds._on_panel_tapped(ds.panels[ds.rival])
				return
			for side in [ds.me, ds.rival]:
				for v in ds.views[side]:
					if v.totem != null and v.totem.id() == arg:
						ds._on_slot_tapped(v)
						return
		"move":
			for b in ds.actions.get_children():
				var k := String(b.get_meta("key", ""))
				if k.begins_with("move:") and (arg == "any" or k == "move:" + arg):
					b.pressed.emit()
					return
		"end":
			ds._on_end_turn()
			return
	problems.append("couldn't find %s" % d)


func _shot(tag: String) -> void:
	n += 1
	if DisplayServer.get_name() == "headless":
		return   # (nothing is drawn: run for the order of the lines only)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:   # (none when run headless, just for the order of the lines)
		img.save_png(out_dir.path_join("tut_%02d_%s.png" % [n, tag]))
