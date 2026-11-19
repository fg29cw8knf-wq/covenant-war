extends Node
## The hero's hands closing (18 November, Gary's yes: "let the hero's
## fingers bend"; Figure3D.close_hand, jaw.gdshaderinc's hand_curl): each
## hand open, half closed and closed, from the side its palm faces and from
## in front, the figure stood in its idle clip; and its hand held out palm
## up (the reach and the palm turned), closed on nothing. Headless it checks
## the shader's numbers are set; drawn, the stills.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --path . res://tests/hand_close_shot.tscn -- <dir>

var out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = String(args[0])
		DirAccess.make_dir_recursive_absolute(out)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.37, 0.42)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.75)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var fig: Figure3D = Figure3D.new().setup("player_a") as Figure3D
	add_child(fig)
	for k in 10:
		await get_tree().process_frame
	var fails := 0
	var n := 0
	for side in ["right", "left"]:
		for k in [0.0, 0.5, Figure3D.HAND_MOST]:
			fig.close_hand(side, k, 0.01)
			for i in 6:
				await get_tree().process_frame
			var m: ShaderMaterial = (fig._jaw_mats[0][1] as ShaderMaterial) if not fig._jaw_mats.is_empty() else null
			var suf := "_r" if side == "right" else "_l"
			var gv = m.get_shader_parameter("grip" + suf) if m != null else null
			var g := float(gv) if gv != null else fig.hand_closed(side)
			if absf(g - k) > 0.01:
				print("hand_close_shot: FAIL the %s hand's grip in the shader %.2f, wanted %.2f" % [side, g, k])
				fails += 1
			if out != "":
				# from the side its palm faces, and from in front, at the hand
				var got := [Transform3D()]
				fig._skel.skeleton_updated.connect(func() -> void: got[0] = fig.palm_frame(side), CONNECT_ONE_SHOT)
				await get_tree().process_frame
				await get_tree().process_frame
				var pf: Transform3D = got[0]
				for view in ["palm", "front"]:
					var dir: Vector3 = pf.basis.y if view == "palm" else fig.facing()
					cam.global_position = pf.origin + dir.normalized() * 0.32 + Vector3(0, 0.02, 0)
					cam.look_at(pf.origin, Vector3.UP if absf(dir.normalized().y) < 0.9 else Vector3.FORWARD)
					cam.fov = 40.0
					await get_tree().process_frame
					await RenderingServer.frame_post_draw
					n += 1
					get_viewport().get_texture().get_image().save_png("%s/%02d_%s_%s_%.1f.png" % [out, n, side, view, k])
		fig.close_hand(side, 0.0, 0.01)
	print("HAND CLOSE: %s" % ("ok" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(0 if fails == 0 else 1)
