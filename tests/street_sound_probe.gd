extends Node
## What's heard as the player steps out of the inn into the street (24
## November, Gary: "When you step outside there is a shuffling wound which
## sounds out of place"): AshfordP1's street played on its own with every
## sound noted (Sfx.listen), for its first SECS seconds: each sound's name,
## how many times, when first, and whose steps they are.
##   godot --headless --fixed-fps 30 --path . res://tests/street_sound_probe.tscn [-- secs=10]

var secs := 10.0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("secs="):
			secs = float(a.substr(5))
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	Game.settings["first_steps"] = 2
	var world := World.new().setup("ashford", "green")
	add_child(world)
	for k in 40:
		await get_tree().process_frame
	Sfx.listen = true
	Sfx.heard.clear()
	var f0 := Engine.get_process_frames()
	var walkers := {}
	# whose steps: every Figure3D's footfall, by its model's name
	for n in world.find_children("*", "Figure3D", true, false):
		var fig := n as Figure3D
		fig.footfall.connect(func(_side: String, surface: String) -> void:
			var key := "%s on %s" % [fig._model_name, surface]
			walkers[key] = int(walkers.get(key, 0)) + 1)
	AshfordP1._street(world)
	var t := 0.0
	var hooked := {}
	while t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()
		# (people the street brings on after it starts)
		for n in world.find_children("*", "Figure3D", true, false):
			if hooked.has(n) or (n as Figure3D).footfall.get_connections().size() > 1:
				continue
			hooked[n] = true
	var counts := {}
	var first := {}
	for h in Sfx.heard:
		var nm := String(h[1])
		counts[nm] = int(counts.get(nm, 0)) + 1
		if not first.has(nm):
			first[nm] = (int(h[0]) - f0) / 30.0
	var names := counts.keys()
	names.sort_custom(func(a, b): return float(first[a]) < float(first[b]))
	print("street_sound_probe: in the first %.0f s outside:" % secs)
	for nm in names:
		print("   %-18s x%-3d first at %.1f s" % [nm, counts[nm], first[nm]])
	print("street_sound_probe: footfalls by walker: ", walkers)
	print("street_sound_probe: the bed of sound: ", Ambience.bed())
	get_tree().quit()
