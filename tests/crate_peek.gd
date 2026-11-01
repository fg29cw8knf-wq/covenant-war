extends Node
## The lantern crate on the green from the front, the side and above, with
## its lid cut off by the lidless shader and, for comparison, as Gary's model
## comes (2 November, Gary: "lanterns in the crate show through the crate").
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       res://tests/crate_peek.tscn -- <out_dir>

var out := "/tmp/crate"


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	if world.hud != null:
		world.hud.visible = false
	var v: AshfordVillage = AshfordP1.village(world)
	world.busy = true
	var at := world.player.global_position + Vector3(0, 0, 1.2)
	world.player.global_position += Vector3(4, 0, 0)
	var c := AshfordP1.crate(v)
	world.add_child(c)
	c.global_position = at
	await _frames(5)
	var shots := {"front": at + Vector3(0, 0.9, 2.2), "side": at + Vector3(2.2, 0.9, 0.0), "high": at + Vector3(1.2, 2.2, 1.2), "low": at + Vector3(0.6, 0.35, 2.0)}
	for k in shots:
		await world.cine_to(shots[k], at + Vector3(0, 0.25, 0), 0.05)
		await _frames(4)
		await _shot("lidless_%s" % k)
	# the model's own materials back, for comparison
	for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			mi.set_surface_override_material(s, null)
	await _frames(3)
	for k in shots:
		await world.cine_to(shots[k], at + Vector3(0, 0.25, 0), 0.05)
		await _frames(4)
		await _shot("plain_%s" % k)
	print("CRATE PEEK: done in ", out)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
