extends Node
## The Great Lantern before and after it's lit at midnight (two screenshots).
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 960x540 res://tests/lantern_peek.tscn -- <out_dir>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://"
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var w := World.new().setup("ashford", "green")
	add_child(w)
	for i in 20:
		await get_tree().process_frame
	var v: AshfordVillage = w.get_meta("village")
	w.cine = true
	w.cam.global_position = Vector3(7.5, 2.0, 10.5)
	w.cam.look_at(v.great_lantern_top - Vector3(0, 0.6, 0), Vector3.UP)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("lantern_unlit.png"))
	v.light_great_lantern()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("lantern_flare.png"))
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("lantern_lit.png"))
	get_tree().quit()
