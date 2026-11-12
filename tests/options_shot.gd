extends Node
## The Options page, to look at (12 November: the Background sounds slider,
## the Summon videos' four choices and the line under them): a still of its
## top and one scrolled to the Summon videos, at a computer's size and a
## phone's.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/options_shot.tscn -- <dir> [WxH]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := String(args[0]) if args.size() > 0 else "/tmp/options"
	DirAccess.make_dir_recursive_absolute(out)
	if args.size() > 1 and String(args[1]).contains("x"):
		var wh := String(args[1]).split("x")
		get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	var menu := PauseMenu.new()
	add_child(menu)
	for k in 3:
		await get_tree().process_frame
	if menu.has_method("open"):
		menu.call("open")
	menu.visible = true
	menu.show_tab("options")
	for k in 6:
		await get_tree().process_frame
	await _still(out + "/1_top.png")
	# down to the Summon videos
	var todo: Array = [menu]
	var found := false
	while not todo.is_empty():
		var n: Node = todo.pop_front()
		todo.append_array(n.get_children())
		if n is Label and (n as Label).text == "Summon videos":
			var p := n.get_parent()
			while p != null and not (p is ScrollContainer):
				p = p.get_parent()
			if p is ScrollContainer:
				(p as ScrollContainer).ensure_control_visible(n as Control)
				(p as ScrollContainer).scroll_vertical += 260
				found = true
			break
	print("OPTIONS SHOT: the Summon videos row %s" % ("found" if found else "NOT found"))
	for k in 6:
		await get_tree().process_frame
	await _still(out + "/2_summons.png")
	print("OPTIONS SHOT: done")
	get_tree().quit()


func _still(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
