extends Node3D
## Renders every creature model face-on (camera on +Z) and from its left side,
## so a model whose "forward" isn't +Z stands out.
##   xvfb-run ... godot --rendering-driver opengl3 res://tests/model_views.tscn -- <out.png>

const CELL := 256

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://model_views.png"
	var ids: Array = []
	for sub in ["creatures", "summons"]:
		var dir := DirAccess.open("res://assets/models/%s" % sub)
		for f in dir.get_files():
			if f.ends_with(".glb"):
				ids.append("res://assets/models/%s/%s" % [sub, f])
	ids.sort()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.7)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(cam)
	cam.current = true
	get_window().size = Vector2i(CELL, CELL)
	var cols := 6
	var rows := ceili(ids.size() / float(cols))
	var sheet := Image.create(cols * CELL * 2, rows * (CELL + 24), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.03, 0.03, 0.05))
	var font := ThemeDB.fallback_font
	for i in ids.size():
		var scene: PackedScene = load(ids[i])
		var inst := scene.instantiate() as Node3D
		add_child(inst)
		var aabb := DuelField3D._merged_aabb(inst)
		var c := aabb.get_center()
		var size := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z)) * 1.15
		cam.size = size
		for view in 2:
			if view == 0:
				cam.position = c + Vector3(0, 0, size * 4)      # front: camera on +Z
			else:
				cam.position = c + Vector3(-size * 4, 0, 0)     # left side
			cam.look_at(c, Vector3.UP)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			var x := (i % cols) * CELL * 2 + view * CELL
			var y := int(i / cols) * (CELL + 24)
			sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i(x, y))
		inst.queue_free()
		await _label(sheet, (i % cols) * CELL * 2 + 6, int(i / cols) * (CELL + 24) + CELL + 4, ids[i].get_file().get_basename())
	sheet.save_png(out)
	print("saved ", out)
	get_tree().quit()


func _label(img: Image, x: int, y: int, text: String) -> void:
	# a crude label: draw the name with a Label into a tiny viewport is overkill; use pixel text
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	var vp := SubViewport.new()
	vp.size = Vector2i(CELL * 2 - 12, 22)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	vp.add_child(lbl)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var t := vp.get_texture().get_image()
	t.convert(Image.FORMAT_RGB8)
	img.blit_rect(t, Rect2i(0, 0, t.get_width(), t.get_height()), Vector2i(x, y))
	vp.queue_free()
