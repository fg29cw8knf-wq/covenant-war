extends Node3D
## Temporary: does the oak's automatic LOD kick in on this renderer? (deleted before committing)

func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 50.0
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = "shadows" in OS.get_cmdline_user_args()
	add_child(sun)
	var scene: PackedScene = load("res://assets/models/ashford/oak_a.glb")
	var oak: Node3D = scene.instantiate()
	add_child(oak)
	print("renderer ", RenderingServer.get_current_rendering_method())
	for d in [6.0, 15.0, 30.0, 60.0, 120.0, 240.0]:
		cam.position = Vector3(0, 4.0, d)
		cam.look_at(Vector3(0, 4.5, 0))
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		print("single oak at %5.0f m: %7d primitives, %3d draw calls" % [d,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	oak.queue_free()
	# twelve of them in a row going away, as separate nodes
	var nodes: Array = []
	for i in 12:
		var o: Node3D = scene.instantiate()
		o.position = Vector3(0, 0, -i * 14.0)
		add_child(o)
		nodes.append(o)
	cam.position = Vector3(0, 4.0, 12.0)
	cam.look_at(Vector3(0, 4.0, -40.0))
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print("12 oaks as nodes from 12 m: %7d primitives, %3d draw calls" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	get_tree().quit()
