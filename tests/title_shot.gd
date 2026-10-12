extends Node
## One screenshot of the title screen after it has settled.
func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/title.png")
	# press the first menu button and catch the push-in halfway
	for b in main.find_children("*", "Button", true, false):
		if b.is_visible_in_tree():
			b.pressed.emit()
			break
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/title_leave.png")
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/title_after.png")
	print("TITLE SHOT: saved")
	get_tree().quit()
