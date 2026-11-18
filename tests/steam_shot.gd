extends Node
## The porridge's steam by itself over a bowl-sized drum, against a dark
## wall and a light one (18 November): a still to judge how thick it is.
##   xvfb-run -a godot --rendering-driver opengl3 --rendering-method gl_compatibility --resolution 960x540 --fixed-fps 30 \
##       --path . res://tests/steam_shot.tscn -- <file.png>

func _ready() -> void:
	var out := "/tmp/steam.png"
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.12, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.95, 0.85)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.28, 0.95), Vector3(0, 0.14, 0))
	for x in [-0.22, 0.22]:
		var bowl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.06
		cm.height = 0.06
		bowl.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.45, 0.3, 0.18)
		bowl.material_override = m
		bowl.position = Vector3(x, 0.03, 0)
		add_child(bowl)
		var st := AshfordP1.porridge_steam()
		bowl.add_child(st)
		st.position = Vector3(0, 0.04, 0)
	# (a pale wall behind the right-hand one)
	var wall := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.44, 0.8)
	wall.mesh = qm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.78, 0.72, 0.6)
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall.material_override = wm
	wall.position = Vector3(0.22, 0.3, -0.3)
	add_child(wall)
	for k in 100:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("STEAM SHOT: ", out)
	get_tree().quit()
