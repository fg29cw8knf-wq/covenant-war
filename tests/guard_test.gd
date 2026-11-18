extends Node
## The frame-rate guard's judging (18 November, Gary: "Game not running
## smoothly frame rate is between 15-19fps"), with made-up frame rates, a
## window at a time (Gfx.Guard.judge):
##   1. a Mac drawing 17 frames a second is at the smallest size within six
##      windows (nine seconds; it took fifteen windows, 22 s), and the bounce
##      light goes after that;
##   2. one a little under (38) comes down a step every three windows, as
##      before;
##   3. the step it came to is kept with the Options, and a new session
##      starts from it;
##   4. holding its own rate, it tries a step back up;
##   5. with "Best picture" on nothing is stepped, and a line says so once.
##
##   godot --headless --path . res://tests/guard_test.tscn
## Ends "GUARD: ok" or the problems.

var problems: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var G := Gfx.Guard
	Game.settings["smooth_auto"] = true
	Game.settings["best_picture"] = false
	Game.settings.erase(G.STEP_KEY)
	G.step = 0
	G.lean = false
	G.told_best = false
	var g := G.new()
	add_child(g)
	g.set_process(false)
	var last: int = G.STEPS.size() - 1
	# 1. far under
	var n := 0
	while G.step < last and n < 40:
		g.judge(17.0)
		n += 1
	print("guard_test: at 17 frames a second, the smallest size after %d windows (%.1f s)" % [n, n * G.WINDOW])
	_expect(G.step == last, "17 fps never came to the smallest size")
	_expect(n <= 6, "17 fps took %d windows to come to the smallest size" % n)
	_expect(not G.lean, "the bounce light went before the smallest size was tried")
	for k in 4:
		g.judge(17.0)
	_expect(G.lean, "still 17 fps at the smallest size, and the bounce light stayed")
	_expect(int(Game.settings.get(G.STEP_KEY, 0)) == last, "the step wasn't kept with the Options (%s)" % str(Game.settings.get(G.STEP_KEY, 0)))
	# 2. a little under
	G.step = 0
	G.lean = false
	g.queue_free()
	g = G.new()
	add_child(g)
	g.set_process(false)
	n = 0
	while G.step < 1 and n < 20:
		g.judge(38.0)
		n += 1
	print("guard_test: at 38 frames a second, a step down after %d windows" % n)
	_expect(n == G.DOWN_AFTER and G.step == 1, "38 fps: %d windows, step %d (wanted %d, 1)" % [n, G.step, G.DOWN_AFTER])
	# 4. holding its rate: a step up, once it's waited
	n = 0
	while G.step > 0 and n < 400:
		g.judge(60.0)
		n += 1
	print("guard_test: at 60, back up after %d windows" % n)
	_expect(G.step == 0, "60 fps never tried the full size again")
	_expect(int(Game.settings.get(G.STEP_KEY, 0)) == 0, "the step back up wasn't kept")
	# 3. a new session starts where the last came to
	Game.settings[G.STEP_KEY] = 3
	G.step = 0
	G.start(get_tree())   # (headless: nothing started, so as start() does it)
	if G.step == 0:
		G.step = clampi(int(Game.settings.get(G.STEP_KEY, 0)), 0, last) if G.on() else 0
	_expect(G.step == 3, "a new session didn't start from the kept step")
	# 5. Best picture
	Game.settings["best_picture"] = true
	_expect(not G.on(), "the guard's on under Best picture")
	G.step = 0
	for k in 8:
		g.judge(17.0)
	_expect(G.step == 0, "Best picture was stepped down")
	_expect(G.told_best and Gfx.Told.last.contains("Best picture"), "nothing was said about Best picture at 17 fps")
	print("guard_test: under Best picture: \"%s\"" % Gfx.Told.last)
	Game.settings["best_picture"] = false
	Game.settings.erase(G.STEP_KEY)
	G.step = 0
	G.lean = false
	G.told_best = false
	print("GUARD: ok" if problems.is_empty() else "GUARD: %d problems\n  %s" % [problems.size(), "\n  ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
