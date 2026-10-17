extends SceneTree
## Every 3D character can play every clip the story asks for, its own or
## borrowed (marked *), and the pace its walk and run are matched to.
##   godot --headless --script res://tests/clips_check.gd
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clips := ["idle", "walk", "run", "talk", "cheer", "victory", "defeat", "play_card", "look_up", "fall", "lift", "wave", "duel_idle"]
	var bad := 0
	for id in ["player", "bram", "corin", "tam", "tilly"]:
		var f := Figure3D.make(id, id) as Figure3D
		root.add_child(f)
		await process_frame
		var line: String = id + " (" + f._model_name + ", hips %.3f):" % f._hips
		for c in clips:
			var own: bool = f.anim.has_animation(c)
			var ok: bool = f._ensure(c)
			if not ok: bad += 1
			line += " %s%s" % [c, "" if own else ("*" if ok else "!MISSING")]
		print(line)
		print("   walk pace %.2f run pace %.2f" % [f._gait_pace("walk"), f._gait_pace("run")])
		f.queue_free()
	print("CLIPS CHECK: ", bad, " missing")
	quit()
