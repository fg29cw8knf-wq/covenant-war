extends SceneTree
## Every 3D character can play every clip the story asks for, its own or
## borrowed (marked *), and the pace its walk and run are matched to; and
## each can sit on a bench (Figure3D.sit), talking too, with their hips on
## the seat and their feet on the ground (or swinging, for Tilly).
##   godot --headless --script res://tests/clips_check.gd
const BENCH := 0.45

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clips := ["idle", "walk", "run", "talk", "cheer", "dance", "victory", "defeat", "play_card", "look_up", "fall", "lift", "wave", "duel_idle"]
	var bad := 0
	for id in ["player", "player_b", "player_c", "player_d", "bram", "corin", "tam", "tilly", "nell", "hob", "farmer", "merchant", "trader"]:
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
		# sitting, then sitting and talking
		for talk in [false, true]:
			f.talking = talk
			f.sit(BENCH, 0.0)
			for i in 3: await process_frame
			var hips := f.bone_pos("Hips").y
			var want := BENCH + Figure3D.SEAT_PAD * f.stature()
			var foot := minf(f.bone_pos("LeftFoot").y, f.bone_pos("RightFoot").y)
			var sk := f._skel
			var ankle := sk.get_bone_global_rest(sk.find_bone("LeftFoot")).origin.y
			var ok: bool = absf(hips - want) < 0.03 and (foot < ankle + 0.03 or id == "tilly")
			if not ok: bad += 1
			print("   sitting%s (%s): hips %.3f (seat wants %.3f), feet %.3f (ankles stand at %.3f)%s"
				% [" and talking" if talk else "", f._clip, hips, want, foot, ankle, "" if ok else "  !WRONG"])
		f.stand(0.0)
		f.queue_free()
	print("CLIPS CHECK: ", bad, " missing or wrong")
	quit()
