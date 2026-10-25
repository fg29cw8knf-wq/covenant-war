extends Node3D
## Stills of Corin's props as the green has them (25 October): his strapped
## card boxes at his hip and the clerkship letter tucked into his coat, from
## the front and from his left side, standing and mid-walk.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x720 \
##       res://tests/corin_props_shot.tscn -- <out_dir>

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	var v := AshfordVillage.new()   # (only for its box/cyl helpers and materials)
	v.spread = true   # (not built: no village here)
	add_child(v)
	v.make_materials()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var fig := Figure3D.new().setup("corin")
	add_child(fig)
	fig.snap_face(Vector3.FORWARD)
	await get_tree().process_frame
	await get_tree().process_frame
	AshfordP1.attach(fig, "Hips", AshfordP1.card_boxes(v), AshfordP1.HIP_BOXES, AshfordP1.HIP_BOXES_ROT)
	AshfordP1.attach(fig, "Spine2", AshfordP1.letter(v), AshfordP1.COAT_LETTER, AshfordP1.COAT_LETTER_ROT)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 30.0
	await get_tree().create_timer(0.6).timeout
	var shots := {"front": [Vector3(0, 1.1, -3.2), Vector3(0, 1.0, 0)], "left": [Vector3(3.0, 1.1, -0.6), Vector3(0, 1.0, 0)],
		"right": [Vector3(-3.0, 1.1, -0.6), Vector3(0, 1.0, 0)], "chest": [Vector3(-0.6, 1.4, -1.5), Vector3(0, 1.2, 0)]}
	for k in shots:
		cam.global_position = shots[k][0]
		cam.look_at(shots[k][1], Vector3.UP)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/corin_%s.png" % [out, k])
	fig.walking = true
	await get_tree().create_timer(0.5).timeout
	cam.global_position = shots["left"][0]
	cam.look_at(shots["left"][1], Vector3.UP)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/corin_walk.png" % out)
	print("CORIN PROPS SHOT: done")
	get_tree().quit()
