extends Node
## Stills of the attic mirror with the player at it, the frost wiped: the
## over-the-shoulder shot from a few places (the glass showing him, mirrored,
## MirrorGlass) and the close-up in the oval (AshfordP1._glass_shot and the
## mask), for checking nothing cuts into him and his face isn't stretched.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/mirror_shot.tscn -- <out_dir> [look a|b|c|d]

var out := "/tmp/mirror"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	if args.size() > 1:
		Game.set_flag("look", String(args[1]))
	Game.settings["first_steps"] = 0
	# (past the opening, so it doesn't run and take the player off to bed)
	for f in ["ash_started", "ash_won_lantern", "first_deck", "corin_met"]:
		Game.set_flag(f)
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await get_tree().create_timer(4.0).timeout   # (whatever the area starts with, settled)
	var v: AshfordVillage = AshfordP1.village(world)
	var a := InnRooms.attic(v)
	AshfordP1.go_inside(v)
	world.cine = true
	world.hud.visible = false
	Cine.overlay(world).visible = false   # (the opening's black and its title card)
	var glass_at: Vector3 = a.mirror
	var stand: Vector3 = a.mirror_stand
	Cine.place(world, "player", stand, glass_at)
	Cine.look(world, "player", glass_at)
	if world.player_doll is Figure3D:
		(world.player_doll as Figure3D).stand(0.0)
	(a.fog_mat as StandardMaterial3D).albedo_color.a = 0.12
	print("MIRROR SHOT: glass ", glass_at, " stand ", stand, " player ", world.player.global_position)
	var g := MirrorGlass.start(world, a.mirror_node, Vector3(-0.036, 0, 0), 0.27, 0.27 * 1.32)
	await get_tree().create_timer(1.0).timeout
	var away := world.player.global_position - glass_at
	away.y = 0.0
	away = away.normalized()
	var aside := Vector3.UP.cross(away).normalized()
	var p := world.player.global_position
	var shots := {
		"over_now": [p + away * 0.95 + aside * 0.34 + Vector3(0, 1.74, 0), 36.0],
		"right_close": [p + away * 0.7 + aside * 0.55 + Vector3(0, 1.8, 0), 40.0],
		"left_close": [p + away * 0.7 - aside * 0.55 + Vector3(0, 1.8, 0), 40.0],
		"right_far": [p + away * 1.2 + aside * 0.5 + Vector3(0, 1.85, 0), 34.0],
		"left_far": [p + away * 1.2 - aside * 0.5 + Vector3(0, 1.85, 0), 34.0],
	}
	print("MIRROR SHOT: away ", away, " aside ", aside)
	for k in shots:
		Cine.shot(world, shots[k][0], glass_at + Vector3(0, -0.02, 0), shots[k][1])
		for i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, k])
		g.vp.get_texture().get_image().save_png("%s/%s_glass.png" % [out, k])
		print("  %s: mirror cam %s near %.3f size %.3f offset %s" % [k, g.cam.global_position, g.cam.near, g.cam.size, g.cam.frustum_offset])
	if OS.get_cmdline_user_args().has("debug"):
		g.set_process(false)
		g.cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		g.cam.near = 0.05
		g.cam.global_transform = world.cam.global_transform
		g.cam.fov = world.cam.fov
		for i in 4:
			await RenderingServer.frame_post_draw
		g.vp.get_texture().get_image().save_png("%s/debug_same_view.png" % out)
		g.cam.far = world.cam.far
		for i in 4:
			await RenderingServer.frame_post_draw
		g.vp.get_texture().get_image().save_png("%s/debug_far.png" % out)
		g.cam.attributes = world.cam.attributes
		for i in 4:
			await RenderingServer.frame_post_draw
		g.vp.get_texture().get_image().save_png("%s/debug_attrs.png" % out)
		var env: Environment = world.get_world_3d().environment
		print("  env fog ", env.fog_enabled, " ", env.fog_density, " vol ", env.volumetric_fog_enabled, " bg ", env.background_mode, " amb ", env.ambient_light_source, " ", env.ambient_light_color)
		print("  main cam env ", world.cam.environment, " attrs ", world.cam.attributes, " world env ", world.get_world_3d().environment, " vp world same ", g.vp.find_world_3d() == world.get_world_3d())
		g.set_process(true)
	var face := Cine.head(world, "player") - Vector3(0, 0.08, 0)
	AshfordP1.mirror_mask(world, true)
	AshfordP1._glass_shot(world, glass_at, face)
	await get_tree().create_timer(0.6).timeout
	for i in 3:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/in_glass.png" % out)
	g.stop()
	print("MIRROR SHOT: done")
	get_tree().quit()
