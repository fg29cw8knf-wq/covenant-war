extends Node
## The speed test (SpeedTest, 18 November): that it times every case, says
## which aren't on here, puts everything back exactly as it was, keeps what
## it found and gives the game back as it took it.
##   godot --headless --path . res://tests/speed_test_test.tscn
## Drawn, it also shows the report's own screen: add `-- shot=<file.png>`.

var _fails := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		print("SPEED TEST: FAIL ", what)


func _state(env: Environment, things: Array) -> Array:
	var vp := get_viewport()
	var out: Array = [vp.scaling_3d_mode, vp.scaling_3d_scale, vp.msaa_3d, vp.positional_shadow_atlas_size, DisplayServer.window_get_vsync_mode(), Engine.max_fps, get_tree().paused]
	for p in ["sdfgi_enabled", "ssil_enabled", "ssao_enabled", "volumetric_fog_enabled", "glow_enabled", "ssr_enabled"]:
		out.append(env.get(p))
	for n: Node3D in things:
		out.append(n.visible)
		if n is Light3D:
			out.append((n as Light3D).shadow_enabled)
	return out


func _ready() -> void:
	get_tree().root.theme = UITheme.make()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.sdfgi_enabled = true
	env.ssil_enabled = true
	env.ssao_enabled = true
	env.volumetric_fog_enabled = true
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2, 6)
	add_child(cam)
	cam.look_at(Vector3.ZERO)
	var things: Array = []
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-50, 30, 0)
	var lamp := OmniLight3D.new()
	lamp.shadow_enabled = true
	lamp.position = Vector3(1, 2, 1)
	var plain_lamp := OmniLight3D.new()
	plain_lamp.position = Vector3(-2, 1, 0)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor_mesh.mesh = pm
	var crowd := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 20
	for i in 20:
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.3), Vector3(i % 5 - 2, 0.2, -i / 5)))
	crowd.multimesh = mm
	var smoke := GPUParticles3D.new()
	smoke.amount = 16
	smoke.process_material = ParticleProcessMaterial.new()
	smoke.draw_pass_1 = QuadMesh.new()
	var hidden_lamp := OmniLight3D.new()
	hidden_lamp.visible = false
	for n: Node3D in [sun, lamp, plain_lamp, floor_mesh, crowd, smoke, hidden_lamp]:
		add_child(n)
		things.append(n)
	for k in 3:
		await get_tree().process_frame
	SpeedTest.settle = 0.05
	SpeedTest.measure = 0.12
	var before := _state(env, things)
	var st := SpeedTest.run(get_tree(), null, "The test's own room")
	_expect(SpeedTest.running, "it isn't running once started")
	_expect(get_tree().paused, "the game isn't stopped while it's timed")
	var text: String = await st.done
	_expect(not SpeedTest.running, "it's still running when it says it's done")
	var after := _state(env, things)
	# (it leaves the game stopped until Close, as it found the menu)
	before[6] = true
	_expect(before == after, "something wasn't put back: %s then %s" % [str(before), str(after)])
	var lines := text.split("\n")
	var cases := st._cases().size()
	_expect(lines.size() == 6 + cases + 2, "the report has %d lines for %d cases" % [lines.size(), cases])
	for want: String in ["As it is now", "3D at half size", "No bounce light (SDFGI)", "No sun or moon shadows", "No lamps at all", "All of the above at once", "Rebuilt from 67%", "As it is now, again", "The test's own room"]:
		_expect(text.contains(want), "the report doesn't say \"%s\"" % want)
	_expect(text.contains("No people or creatures") and lines[6 + 13].contains("not on here"), "people, with none here, aren't said to be not on here: %s" % lines[6 + 13])
	_expect(not lines[6 + 3].contains("not on here"), "the bounce light, on here, is said not to be")
	_expect(FileAccess.file_exists(SpeedTest.FILE) and FileAccess.get_file_as_string(SpeedTest.FILE) == text, "the report isn't kept in %s" % SpeedTest.FILE)
	_expect(SpeedTest.last == text, "SpeedTest.last isn't the report")
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("shot="):
			for k in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.substr(5))
	print(text)
	st._close()
	await get_tree().process_frame
	_expect(not get_tree().paused, "the game is left stopped after Close")
	_expect(not is_instance_valid(st) or st.is_queued_for_deletion(), "its screen is still there after Close")
	# the guard: on under Best picture now, and it keeps the light there
	Game.settings["smooth_auto"] = true
	Game.settings["best_picture"] = true
	_expect(Gfx.Guard.on(), "the guard stands down under Best picture")
	Game.settings["best_picture"] = false
	Game.settings["smooth_auto"] = false
	_expect(not Gfx.Guard.on(), "the guard's on with its switch off")
	Game.settings["smooth_auto"] = true
	print("SPEED TEST: %s" % ("ok" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)
