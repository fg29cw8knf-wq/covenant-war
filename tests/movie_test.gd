extends Node
## Screenshots of the opening movie at a few moments (runs at 10x speed after the first).

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var m := OpeningMovie.new()
	m.shots_only = true   # (the shot-by-shot path; tests/movie_shot.tscn -- <dir> cut plays the finished cut)
	add_child(m)
	await get_tree().create_timer(3.0).timeout
	await _shot(out + "/movie_a.png")
	# a second argument sets the speed; 1 plays it in real time, printing when each line starts
	Engine.time_scale = float(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else 10.0
	# shot 7a starts at 50 s; Ironvault (12b) at 108 s; the title at 134 s; the end at 144 s
	await get_tree().create_timer(48.5).timeout
	await _shot(out + "/movie_b.png")
	await get_tree().create_timer(60.0).timeout
	await _shot(out + "/movie_c.png")
	# at 10x the movie clock runs a few seconds behind the timers; at 1x it doesn't
	await get_tree().create_timer(34.0 if Engine.time_scale > 1.0 else 27.0).timeout
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
