extends SceneTree
## TEMP: clip lengths, and the hips' height through Bram's lift.

func _initialize() -> void:
	for id in ["bram", "tam", "tilly", "player_a"]:
		var inst: Node = (load("res://assets/models/characters/%s.glb" % id) as PackedScene).instantiate()
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var s := ""
		for c in ap.get_animation_list():
			s += "%s %.2f  " % [c, ap.get_animation(c).length]
		print(id, ": ", s)
		if id == "bram":
			var a := ap.get_animation("lift")
			var t := a.find_track(NodePath("Skeleton3D:Hips"), Animation.TYPE_POSITION_3D)
			var line := ""
			for i in 13:
				var tt := a.length * i / 12.0
				line += "%.2f:%.3f " % [tt, a.position_track_interpolate(t, tt).y]
			print("  lift hips ", line)
		inst.free()
	quit()
