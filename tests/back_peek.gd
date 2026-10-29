extends Node3D
## A character from behind and round the back, close, in a few clips (29
## October, Gary: "there is still a hole in the back of Corin at the top when
## he turns around"): a sheet of views from behind, behind-left,
## behind-right and above, at rest and in the clips given, under a plain
## light, so a hole or an inside-out patch in the model shows.
##
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 \
##       res://tests/back_peek.tscn -- <out.png> <id> [clips, comma separated]

const CELL := 384

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "/tmp/back.png"
	var id: String = a[1] if a.size() > 1 else "corin"
	var clips: Array = (a[2] if a.size() > 2 else "idle,walk,talk").split(",")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.36, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var fig := Figure3D.new().setup(id)
	add_child(fig)
	await get_tree().process_frame
	var cam := Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	cam.current = true
	get_window().size = Vector2i(CELL, CELL)
	var head := 1.5
	var views := [
		["back", Vector3(0, head, -1.6)], ["back left", Vector3(1.0, head + 0.1, -1.3)],
		["back right", Vector3(-1.0, head + 0.1, -1.3)], ["above", Vector3(0, head + 0.9, -0.9)]]
	var sheet := Image.create(views.size() * CELL, clips.size() * CELL, false, Image.FORMAT_RGB8)
	for ci in clips.size():
		var c := String(clips[ci])
		if c == "rest":
			fig.release(0.0)
		else:
			fig.pose(c, 0.35, 0.0)
		for k in 8:
			await get_tree().process_frame
		var hy := fig.bone_pos("Neck").y if fig.bone_pos("Neck").y > 0.5 else head
		for vi in views.size():
			var v: Vector3 = views[vi][1]
			cam.global_position = Vector3(v.x, v.y - head + hy, v.z)
			cam.look_at(Vector3(0, hy - 0.15, 0))
			for k in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.resize(CELL, CELL)
			img.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i(vi * CELL, ci * CELL))
	sheet.save_png(out)
	print("BACK PEEK: ", out)
	get_tree().quit()
