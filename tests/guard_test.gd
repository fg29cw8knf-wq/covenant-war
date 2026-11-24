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
	# 5. Best picture (18 November: the guard works under it, and leaves
	# the light be; before, it stood down and the Mac drew at 17)
	Game.settings["best_picture"] = true
	_expect(G.on(), "the guard stands down under Best picture")
	G.step = 0
	G.lean = false
	for k in 40:
		g.judge(17.0)
	_expect(G.step == last, "Best picture at 17 fps wasn't brought down to the smallest size (step %d)" % G.step)
	_expect(not G.lean, "the bounce light was taken away under Best picture")
	_expect(not G.told_best, "something was said with the guard doing its work")
	Game.settings["best_picture"] = false
	# 6. the guard switched off: every pixel held, and said so once
	Game.settings["smooth_auto"] = false
	_expect(not G.on(), "the guard's on with its switch off")
	G.step = 0
	for k in 8:
		g.judge(17.0)
	_expect(G.step == 0, "switched off, it still stepped down")
	_expect(G.told_best and Gfx.Told.last.contains("Keep the frame rate smooth"), "nothing was said about the full picture at 17 fps")
	print("guard_test: switched off: \"%s\"" % Gfx.Told.last)
	Game.settings["smooth_auto"] = true
	Game.settings.erase(G.STEP_KEY)
	G.step = 0
	G.lean = false
	G.told_best = false
	# (24 November, Gary: "running slow when Morrowen is talking", "sluggish
	# ... after Bram's bit", at 60 to 120 frames a second)
	# 7. a light place (the title) can't talk the size up
	Game.settings.erase(G.PLACES_KEY)
	G.active = true
	g.queue_free()
	g = G.new()
	add_child(g)
	g.set_process(false)
	G.place("")
	G.step = 4
	G.place("title")
	for k in 200:
		g.judge(120.0)
	_expect(G.step == 4, "a title screen at 120 fps talked the 3D up from step 4 to step %d" % G.step)
	# 8. each place keeps its own step, taken up as the place begins
	G.step = 0
	G.place("snow: the opening")
	n = 0
	g.judge(60.0)   # (its first window is left out)
	while G.step == 0 and n < 20:
		g.judge(17.0)
		n += 1
	var snow_step: int = G.step
	print("guard_test: the snow at 17 fps: to step %d in %d windows (%.1f s)" % [snow_step, n, n * G.WINDOW])
	_expect(snow_step >= 4 and n <= 2, "the snow at 17 fps: step %d after %d windows (wanted step 4 or 5 within 2)" % [snow_step, n])
	_expect(G.kept_step("snow") == snow_step, "the snow's step wasn't kept (%d)" % G.kept_step("snow"))
	G.place("snow: the walk")
	_expect(G.step == snow_step, "the walk isn't the same place as the opening")
	G.place("title")
	G.step = 0   # (as if something had it at the full size again)
	G.place("ashford morning: the attic")
	_expect(G.step == snow_step, "a place never seen didn't begin at the smallest size any place has needed (step %d, wanted %d)" % [G.step, snow_step])
	G.step = 0
	G.place("snow: the opening")
	_expect(G.step == snow_step, "back in the snow, its step wasn't taken up at once (step %d, wanted %d)" % [G.step, snow_step])
	# 9. a step up that doesn't hold is undone in the next window, and not tried again there
	G.place("ashford morning: the attic")
	G.step = 3
	g.judge(60.0)
	n = 0
	while G.step == 3 and n < 400:
		g.judge(60.0)
		n += 1
	_expect(G.step == 2, "holding 60 in the attic never tried a step up")
	print("guard_test: a step up tried after %d windows (%.0f s) at the screen's rate" % [n, n * G.WINDOW])
	_expect(n >= G.UP_AFTER, "a step up was tried after only %d windows" % n)
	g.judge(30.0)
	_expect(G.step == 3, "a step up that fell to 30 fps wasn't undone in the next window (step %d)" % G.step)
	_expect(G.ceiling("ashford morning: the attic") == 3, "the attic's ceiling wasn't kept (%d)" % G.ceiling("ashford morning: the attic"))
	for k in 600:
		g.judge(60.0)
	_expect(G.step == 3, "the step up that failed was tried again in the same place (step %d)" % G.step)
	G.place("thornwood")
	for k in 300:
		g.judge(60.0)
	_expect(G.step < 3, "another place was held to the attic's ceiling (step %d)" % G.step)
	G.place("")
	G.active = false
	Game.settings.erase(G.PLACES_KEY)
	Game.settings.erase(G.STEP_KEY)
	G.step = 0
	G.lean = false
	# (the guard keeps its step with the Options as it goes: what this test
	# put there is taken out again, so the next test starts from none of it)
	Game.save_settings()
	print("GUARD: ok" if problems.is_empty() else "GUARD: %d problems\n  %s" % [problems.size(), "\n  ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
