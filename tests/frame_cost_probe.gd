extends Node
## What a frame costs the processor, apart from drawing it (18 November, Gary:
## "Game not running smoothly frame rate is between 15-19fps"). A place built
## as a Mac builds it (Gfx.level() 2), its people stood where a time of day
## has them, and left to run with nobody touching it: how long each frame's
## scripts, animation and bones take, by the clock, with nothing drawn
## (headless). The mean and the slowest tenth. On a machine with no graphics
## card this is the only part of a frame that can be measured, and it's the
## part a smaller picture (the frame-rate guard) can't help.
## (Performance.TIME_PROCESS isn't a frame's time under --fixed-fps: it gave
## 700 ms for frames that took 1 ms by the clock. Not printed.)
##
##   godot --headless --fixed-fps 60 --path . res://tests/frame_cost_probe.tscn -- [morning|afternoon|evening|snow] [frames=600]
## Prints "FRAME COST: <place> <mean> ms a frame (...)".

var world: World
var when := "evening"
var frames := 600


func _ready() -> void:
	Gfx.force_level = 2
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("frames="):
			frames = int(s.substr(7))
		elif s in ["morning", "afternoon", "evening", "snow"]:
			when = s
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 2
	var node: Node = null
	if when == "snow":
		Game.settings["seen_white_sky"] = false
		var m := WhiteSky.new()
		add_child(m)
		m.play()
		node = m
	else:
		Game.set_flag("arrived_ashford")
		var flags := ["ash_started", "p1_crate_down", "corin_met", "first_deck"]
		if when != "morning":
			flags.append_array(["ash_won_lantern", "ash_tam", "tam_letter_seen"])
		if when == "evening":
			flags.append_array(["ash_tilly", "ash_nell", "ash_evening", "tilly_thanks", "has_lantern_moth"])
		for f: String in flags:
			Game.set_flag(f)
		Game.set_flag("p1_stage", "done")
		world = World.new().setup("ashford", "green")
		add_child(world)
		for k in 30:
			await get_tree().process_frame
		AshfordP1.dress(world)
		AshfordDay.stage(world)
		world.busy = false
		node = world
	# (settled: whatever the place starts with)
	for k in 120:
		await get_tree().process_frame
	var ms: Array = []
	var last := Time.get_ticks_usec()
	for k in frames:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
	ms.sort()
	var sum := 0.0
	for v: float in ms:
		sum += v
	var figs := 0
	var mods := 0
	var todo: Array = [node]
	var nodes := 0
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		nodes += 1
		todo.append_array(n.get_children())
		if n is Figure3D:
			figs += 1
		if n is SkeletonModifier3D:
			mods += 1
	print("FRAME COST: %s: %.2f ms a frame by the clock (the middle one %.2f, the slowest tenth from %.2f, the slowest %.2f); %d things in it, %d of them figures, %d things on their bones" % [
		when, sum / ms.size(), float(ms[ms.size() / 2]), float(ms[int(ms.size() * 0.9)]), float(ms[ms.size() - 1]), nodes, figs, mods])
	get_tree().quit()
