extends Node
## Renders one opening-movie shot at a few moments, to check its effects.
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 res://tests/shot_peek.tscn -- <out_dir> shot_15 0.5 4.4 6 10
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://"
	var id: String = a[1] if a.size() > 1 else "shot_15"
	var times: Array = a.slice(2) if a.size() > 2 else ["1", "4.5", "10"]
	var shot: Dictionary = {}
	for s in OpeningMovie.SHOTS:
		if s.id == id:
			shot = s
	var view := OpeningMovie.ShotView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	var still := OpeningMovie._still_path(id)
	view.show_shot(shot, load(still) if still != "" else null, 1)
	view.modulate.a = 1.0
	for t in times:
		view._t = float(t)
		view.set_process(false)
		view.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [id, t]))
	get_tree().quit()
