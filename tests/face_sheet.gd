extends Node
## Each model's face square on and from its side, at a known size, for
## reading off where its lips are (18 November, Gary's yes: mouths moving
## when anyone talks; Figure3D.MOUTHS). The model stands as it was made (no
## clip), the camera straight (no perspective) and 34 cm of it from top to
## bottom, its middle 8 cm over the Head bone (and, from the side, 10 cm
## ahead of it): tools/face_grid.py rules the stills in centimetres from the
## bone. With `open` after the names, each model's mouth is opened as
## Figure3D opens it (its MOUTHS entry), shut and open side by side.
##   xvfb-run -a -s "-screen 0 800x400x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 720x360 --path . res://tests/face_sheet.tscn -- <dir> [open] [smile] [model ...]

const SPAN := 0.34
const MID_UP := 0.08
const MID_AHEAD := 0.1


func _ready() -> void:
	var a := Array(OS.get_cmdline_user_args())
	var out := String(a[0]) if a.size() > 0 else "/tmp/faces"
	DirAccess.make_dir_recursive_absolute(out)
	var open := a.has("open")
	var smile := a.has("smile")
	var names: Array = a.slice(1).filter(func(x): return String(x) != "open" and String(x) != "smile")
	if names.is_empty():
		var d := DirAccess.open("res://assets/models/characters")
		for f in d.get_files():
			if f.ends_with(".glb"):
				names.append(f.get_basename())
		names.sort()
	get_window().size = Vector2i(720, 360)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.37, 0.4)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, 160, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = SPAN
	cam.near = 0.05
	cam.far = 5.0
	add_child(cam)
	cam.make_current()
	for nm: String in names:
		var fig: Figure3D = Figure3D.new().setup(nm) as Figure3D
		add_child(fig)
		for k in 4:
			await get_tree().process_frame
		var sk: Skeleton3D = fig._skel
		if sk == null or sk.find_bone("Head") < 0:
			print("face_sheet: %s has no head" % nm)
			fig.queue_free()
			continue
		if fig.anim != null:
			fig.anim.stop()
		sk.reset_bone_poses()
		for k in 3:
			await get_tree().process_frame
		var hb := sk.find_bone("Head")
		var head := sk.global_transform * sk.get_bone_global_pose(hb)
		var up := head.basis.y.normalized()
		var fwd := head.basis.z.normalized()
		var side := head.basis.x.normalized()
		var shots: Array = [["shut", 0.0, 0.0]]
		if open:
			shots = [["shut", 0.0, 0.0], ["open", Figure3D.TALK_OPEN, 0.0], ["wide", 1.0, 0.0]]
		if smile:
			shots = [["shut", 0.0, 0.0], ["smile", 0.0, 1.0], ["gasp", 0.7, 0.0]]
		for sh: Array in shots:
			if open or smile:
				fig.jaw(float(sh[1]))
				fig.smile(float(sh[2]))
				# (stood as made, no clip moves its bones: told by hand, as
				# its bones' pass tells it in the game)
				fig._set_jaw()
				if float(sh[1]) <= 0.0 and float(sh[2]) <= 0.0:
					for pair: Array in fig._jaw_mats:
						(pair[1] as ShaderMaterial).set_shader_parameter("jaw_open", 0.0)
						(pair[1] as ShaderMaterial).set_shader_parameter("smile", 0.0)
			for view in ["front", "side"]:
				var mid := head.origin + up * MID_UP + (fwd * MID_AHEAD if view == "side" else Vector3.ZERO)
				var from := mid + (fwd if view == "front" else side) * 1.2
				cam.look_at_from_position(from, mid, up)
				for k in 3:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				var sq := img.get_region(Rect2i((img.get_width() - img.get_height()) / 2, 0, img.get_height(), img.get_height()))
				sq.save_png(out.path_join("%s_%s_%s.png" % [nm, sh[0], view]))
		print("face_sheet: %s stature %.2f, a mouth %s, %d of its materials wear the shader" % [nm, fig.stature(), str(fig.has_mouth()), fig._jaw_mats.size()])
		fig.queue_free()
		await get_tree().process_frame
	print("FACE SHEET: done in ", out)
	get_tree().quit()
