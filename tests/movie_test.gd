extends Node
## Screenshots of the opening movie at a few moments (runs at 10x speed after the first).

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var m := OpeningMovie.new()
	add_child(m)
	await get_tree().create_timer(3.0).timeout
	await _shot(out + "/movie_a.png")
	Engine.time_scale = 10.0
	# shot 7a starts at 50 s; Ironvault (12b) at 108 s; the title at 134 s; the end at 144 s
	await get_tree().create_timer(48.5).timeout
	await _shot(out + "/movie_b.png")
	await get_tree().create_timer(60.0).timeout
	await _shot(out + "/movie_c.png")
	await get_tree().create_timer(34.0).timeout
	await _shot(out + "/movie_d.png")
	var ok := is_instance_valid(m) and not m._done
	# at 10x speed the movie runs a few seconds behind the timers, so allow a wide margin
	await get_tree().create_timer(19.0).timeout
	var ended := not is_instance_valid(m) or m._done
	print("MOVIE TEST: %s (title shown while playing=%s, finished by 2:45=%s)" % ["PASS" if ok and ended else "FAIL", ok, ended])
	get_tree().quit()


func _shot(p: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(p)
	print("saved ", p)
