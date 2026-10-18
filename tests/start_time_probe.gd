extends Node
## How long New Game takes to reach the attic. Main is run as the player
## sees it: the title screen (Ashford is built under it, a piece a frame),
## New Game, the opening movie skipped at once, and the time from Skip to
## the world being let go and its first frames drawn. Ends with the times.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/start_time_probe.tscn [-- skip_at=<seconds into the movie>]

var skip_at := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("skip_at="):
			skip_at = float(String(a).substr(8))
	var t0 := Time.get_ticks_msec()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("title up after %d ms" % (Time.get_ticks_msec() - t0))
	var tp := Time.get_ticks_msec()
	while main._prepared == null or not main._prepared.prepared:
		await get_tree().process_frame
		if Time.get_ticks_msec() - tp > 120000:
			print("PROBE: the world was never prepared")
			get_tree().quit(1)
			return
	print("Ashford prepared under the title in %d ms" % (Time.get_ticks_msec() - tp))
	await get_tree().create_timer(0.5).timeout
	main._on_new_game()
	var movie: OpeningMovie = null
	while movie == null:
		await get_tree().process_frame
		for c in main.get_children():
			if c is OpeningMovie:
				movie = c
	print("movie up")
	if skip_at > 0.0:
		await get_tree().create_timer(skip_at).timeout
	var ts := Time.get_ticks_msec()
	var w: World = main._prepared
	movie._finish()
	await w.released
	print("released %d ms after Skip" % (Time.get_ticks_msec() - ts))
	for i in 3:
		var tf := Time.get_ticks_msec()
		await get_tree().process_frame
		print("frame %d after release: %d ms" % [i, Time.get_ticks_msec() - tf])
	print("attic drawing %d ms after Skip" % (Time.get_ticks_msec() - ts))
	for secs in [1.5, 4.0, 7.0]:
		await get_tree().create_timer(secs).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/probe_%s.png" % str(secs))
	get_tree().quit()
