extends SceneTree
## TEMP: Figure3D.reach() and borrowed clips on Tam and Tilly.
##   xvfb-run ... godot --rendering-driver opengl3 --resolution 960x540 --script res://tests/tmp_hands.gd -- <out dir>

var out := "/tmp"
var stage: Node3D
var cam: Camera3D


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	stage = Node3D.new()
	get_root().add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.11, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.7)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.3, 0.22)
	floor.material_override = fm
	stage.add_child(floor)
	cam = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 40
	_run.call_deferred()


func _fig(id: String, pos: Vector3, face: Vector3) -> Figure3D:
	var b := Node3D.new()
	stage.add_child(b)
	b.global_position = pos
	var f := Figure3D.make(id, id) as Figure3D
	b.add_child(f)
	f.snap_face(face)
	return f


func _ball(at: Vector3, col: Color, r := 0.03) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	stage.add_child(m)
	m.global_position = at
	return m


func _shot(name: String, pos: Vector3, look: Vector3) -> void:
	cam.global_position = pos
	cam.look_at(look)
	for k in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	# 1. Tam and the player with a barrel on its side between them
	var tam := _fig("tam", Vector3(-0.8, 0, 0), Vector3(1, 0, 0))
	var pl := _fig("player", Vector3(0.8, 0, 0), Vector3(-1, 0, 0))
	var barrel := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.26
	cm.bottom_radius = 0.26
	cm.height = 0.7
	barrel.mesh = cm
	stage.add_child(barrel)
	barrel.global_position = Vector3(0, 0.95, 0)
	barrel.rotation = Vector3(0, 0, PI * 0.5)
	# hands on the two ends' rims, a little forward and back
	var hands := {}
	for k in [["tl", Vector3(-0.36, 0.95, 0.2)], ["tr", Vector3(-0.36, 0.95, -0.2)], ["pl", Vector3(0.36, 0.95, -0.2)], ["pr", Vector3(0.36, 0.95, 0.2)]]:
		hands[k[0]] = _ball(k[1], Color(1, 0.2, 0.2), 0.02)
	await process_frame
	await process_frame
	tam.reach(hands.tl, hands.tr, 0.01)
	pl.reach(hands.pl, hands.pr, 0.01)
	for k in 8:
		await process_frame
	await _shot("barrel_front", Vector3(0.2, 1.4, 3.2), Vector3(0, 1.0, 0))
	await _shot("barrel_top", Vector3(0.0, 3.2, 1.2), Vector3(0, 0.9, 0))
	tam.get_parent().queue_free()
	pl.get_parent().queue_free()
	barrel.queue_free()
	for h in hands.values():
		h.queue_free()
	# 2. Tilly holding a card out in both hands
	var tilly := _fig("tilly", Vector3(0, 0, 0), Vector3(0, 0, 1))
	var card := _ball(Vector3(0, 0.78, 0.3), Color(1, 0.8, 0.3), 0.05)
	var cl := Node3D.new()
	card.add_child(cl)
	cl.position = Vector3(0.06, 0, 0)
	var cr := Node3D.new()
	card.add_child(cr)
	cr.position = Vector3(-0.06, 0, 0)
	await process_frame
	tilly.reach(cl, cr, 0.01)
	for k in 8:
		await process_frame
	await _shot("tilly_card", Vector3(0.9, 1.0, 1.6), Vector3(0, 0.75, 0.15))
	await _shot("tilly_card_side", Vector3(1.8, 0.9, 0.3), Vector3(0, 0.75, 0.15))
	tilly.let_go(0.01)
	card.queue_free()
	# 3. borrowed clips on Tilly and Tam: lift, duel_idle, play_card
	tilly.get_parent().global_position = Vector3(0.6, 0, 0)
	var tam2 := _fig("tam", Vector3(-0.6, 0, 0), Vector3(0, 0, 1))
	var bram := _fig("bram", Vector3(-1.8, 0, 0), Vector3(0, 0, 1))
	for clip in ["lift", "play_card", "duel_idle", "fall", "look_up"]:
		tilly.pose(clip, 0.5)
		tam2.pose(clip, 0.5)
		bram.pose(clip, 0.5)
		await create_timer(0.6).timeout
		await _shot("borrow_" + clip, Vector3(0.2, 1.0, 4.4), Vector3(-0.6, 0.75, 0))
	tilly.release(0.0)
	tam2.get_parent().queue_free()
	bram.get_parent().queue_free()
	# 4. Corin and Tilly hand in hand
	var corin := _fig("corin", Vector3(-0.3, 0, 0), Vector3(0, 0, 1))
	tilly.get_parent().global_position = Vector3(0.3, 0, 0)
	var meet := Node3D.new()
	stage.add_child(meet)
	meet.global_position = Vector3(0.0, 0.68, 0.06)
	await process_frame
	# Corin's left hand is on Tilly's side (facing +Z, left is +X)
	corin.reach(meet, null, 0.01)
	tilly.reach(null, meet, 0.01)
	for k in 8:
		await process_frame
	await _shot("hand_in_hand", Vector3(0.6, 1.2, 2.6), Vector3(0, 0.8, 0))
	await _shot("hand_in_hand_back", Vector3(-0.4, 1.3, -2.6), Vector3(0, 0.8, 0))
	print("HANDS done")
	quit()
