extends Node
## Stills of the hero's mark where it sits on each of the four looks (15
## November, Gary: "the glowing mark is meant to be on his neck not chest").
## Each look's model stood on its own in a plain light, the mark shown
## (SealMark.mark_on), ash-grey and then blazing, from close in on its side,
## from the front and from half way down the room; and lying on his back
## as he sleeps in the attic, from above. Saved as <dir>/<look>_<view>.png.
##
##   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" godot \
##       --rendering-driver vulkan --rendering-method forward_plus --resolution 960x540 \
##       --path . res://tests/mark_neck_look.tscn -- <dir> [a b c d]

var out := "/tmp/mark_neck"
var cam: Camera3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var looks: Array = []
	for a in args.slice(1):
		if String(a) in ["a", "b", "c", "d"]:
			looks.append(String(a))
	if looks.is_empty():
		looks = ["a", "b", "c", "d"]
	get_window().size = Vector2i(960, 540)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	for look in looks:
		await _look(look)
	print("mark_neck_look: done")
	get_tree().quit()


func _look(look: String) -> void:
	var f := Figure3D.new().setup("player_" + look) as Figure3D
	add_child(f)
	f.position = Vector3.ZERO
	await _frames(4)
	var mi := SealMark.mark_on(f)
	if mi == null:
		print("mark_neck_look: %s has no mark (no Neck bone?)" % look)
		f.queue_free()
		return
	mi.visible = true
	var m := mi.material_override as StandardMaterial3D
	if "xray" in OS.get_cmdline_user_args():
		# (drawn through whatever's over it, to see where it is)
		m.no_depth_test = true
		m.render_priority = 2
	await _frames(2)
	var at := mi.global_position
	var n := mi.global_transform.basis.z.normalized()
	var neck := f.bone_pos("Neck")
	var head := f.bone_pos("Head")
	print("mark_neck_look: %s the mark at %s, %.3f m out from the Neck bone, %.3f m up it, its face %s" % [
		look, str(at), Vector2(at.x - neck.x, at.z - neck.z).length(), at.y - neck.y, str(n)])
	for state in ["ash", "blaze"]:
		if state == "blaze":
			m.albedo_color = SealMark.WHITE
			m.emission = SealMark.WHITE * 6.0
		else:
			m.albedo_color = SealMark.ASH
			m.emission = Color.BLACK
		# close in, square on to it; from in front; half the body
		_shot(at + n * 0.42 + Vector3(0, 0.02, 0), at, 30.0)
		await _still("%s_%s_close" % [look, state])
		if state == "ash":
			_shot(neck + Vector3(0, 0.05, 0.75), (neck + head) * 0.5, 34.0)
			await _still("%s_%s_front" % [look, state])
			_shot(at + Vector3(n.x, 0.0, n.z).normalized() * 1.0 + Vector3(0, 0.05, 0), at + Vector3(0, -0.05, 0), 30.0)
			await _still("%s_%s_side" % [look, state])
		_shot(neck + Vector3(0.9, -0.1, 1.9), neck + Vector3(0, -0.35, 0), 34.0)
		await _still("%s_%s_mid" % [look, state])
	f.queue_free()
	await _frames(2)


func _shot(pos: Vector3, look: Vector3, fov: float) -> void:
	cam.global_position = pos
	cam.look_at(look, Vector3.UP)
	cam.fov = fov


func _still(nm: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(nm + ".png"))
	print("mark_neck_look: still ", nm)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
