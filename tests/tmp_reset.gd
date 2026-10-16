extends SceneTree
## TEMP: does a figure stand up again after a borrowed fall / lift?

var stage: Node3D


func _initialize() -> void:
	stage = Node3D.new()
	get_root().add_child(stage)
	_run.call_deferred()


func _hips(f: Figure3D) -> String:
	var sk := f.model.find_child("Skeleton3D", true, false) as Skeleton3D
	var h := sk.get_bone_global_pose(sk.find_bone("Hips"))
	var r := sk.get_bone_pose(sk.find_bone("Root"))
	return "hips y %.3f up %.2f | root %s | clip %s playing %s det %s" % [h.origin.y, h.basis.y.y, r.origin, f.anim.current_animation, f.anim.is_playing(), f.anim.deterministic]


func _run() -> void:
	for id in ["player", "tilly", "tam"]:
		var b := Node3D.new()
		stage.add_child(b)
		var f := Figure3D.make(id, id) as Figure3D
		b.add_child(f)
		if "det" in OS.get_cmdline_user_args():
			f.anim.deterministic = true
		await create_timer(0.3).timeout
		print(id, " idle    ", _hips(f))
		f.act("fall")
		await create_timer(1.6).timeout
		print(id, " fallen  ", _hips(f))
		f.release(0.2)
		await create_timer(0.8).timeout
		print(id, " release ", _hips(f))
		f.pose("look_up", 0.5)
		await create_timer(0.6).timeout
		print(id, " lookup  ", _hips(f))
		f.hold("lift", 0.9)
		await create_timer(1.6).timeout
		print(id, " lift    ", _hips(f))
		f.release()
		await create_timer(0.8).timeout
		print(id, " release ", _hips(f))
		f.gait = "run"
		f.walking = true
		await create_timer(0.5).timeout
		print(id, " run     ", _hips(f))
		f.walking = false
		b.queue_free()
	quit()
