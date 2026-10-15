extends Node3D
## Renders a head-and-shoulders portrait of each 3D character for the
## dialogue box, from their model, into assets/art/characters/<id>_portrait.png
## (DollArt.portrait picks those up in place of the drawn cut-out faces).
##
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 \
##       --resolution 512x512 res://tools/render_portraits.tscn -- [ids...]

const MODELS := {"bram": "bram", "corin": "corin", "player": "player_a"}
const OUT := "res://assets/art/characters/"
const SIZE := 512

var _cam: Camera3D


func _ready() -> void:
	get_window().size = Vector2i(SIZE, SIZE)
	var ids: Array = OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = MODELS.keys()
	_stage()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id in ids:
		await _render(String(id))
	get_tree().quit()


func _stage() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("1a1f33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.72)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	# a warm key from the front left, like lantern light
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.82, 0.62)
	key.light_energy = 1.5
	key.rotation_degrees = Vector3(-24, -32, 0)
	add_child(key)
	# a cool rim from behind on the right, to lift them off the background
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.6, 0.72, 1.0)
	rim.light_energy = 1.3
	rim.rotation_degrees = Vector3(-12, 150, 0)
	add_child(rim)
	_cam = Camera3D.new()
	_cam.fov = 24.0
	add_child(_cam)
	_cam.make_current()


func _render(id: String) -> void:
	var path := "res://assets/models/characters/%s.glb" % MODELS.get(id, id)
	if not ResourceLoader.exists(path):
		push_warning("no model for " + id)
		return
	var model: Node3D = load(path).instantiate()
	add_child(model)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null:
		var clip := "idle" if ap.has_animation("idle") else ""
		if clip != "":
			ap.play(clip)
			ap.seek(0.35, true)
			ap.pause()
	for i in 4:
		await get_tree().process_frame
	var head := Vector3(0, 1.6, 0)
	var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk != null:
		var hb := sk.find_bone("Head")
		if hb >= 0:
			head = sk.global_transform * sk.get_bone_global_pose(hb).origin
	var aim := head + Vector3(0, -0.06, 0)
	_cam.global_position = aim + Vector3(0.42, 0.06, 1.25)
	_cam.look_at(aim, Vector3.UP)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT + id + "_portrait.png"))
	print("PORTRAIT ", id, " head at ", head)
	model.queue_free()
	await get_tree().process_frame
