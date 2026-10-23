extends Node
## Corin's rematch after the Lantern Duel, on the real duel screen, played by
## the computer on both sides (debug autoplay) until it has been both won and
## lost: the result stands either way (no "Try again" on the result screen),
## Showboat is named as it starts, and Corin's Cinderpup never lets a turn go
## by without attacking when it could. Saves the opening banner and a won and
## a lost result. Then one coached Lantern Duel start, to see the banner and
## Bram's first line together. Ends with "REMATCH TEST: ok" or the problems.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/lantern_rematch_test.tscn -- <out_dir> [max duels]

var out_dir := "user://"
var problems: Array = []
var seen := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var most := int(args[1]) if args.size() > 1 else 12
	Game.new_game("Sprout", "")
	Game.settings["debug_autoplay"] = true
	var area = load("res://scripts/world/areas/ashford.gd")
	var layer := CanvasLayer.new()
	add_child(layer)
	for i in most:
		var spec: Dictionary = area.duel_spec({"rematch": true})
		spec["seed"] = 1000 + i
		var ds := DuelScreen.new().configure(spec)
		layer.add_child(ds)
		var refused := [0]
		_watch(ds, refused)
		if i == 0:
			await _until(func() -> bool: return ds.game != null and ds.game.turn == 0 and _banner_up(ds), 20.0)
			await _shot("rematch_banner")
		await _until(func() -> bool: return ds.game != null and ds.game.over, 240.0)
		await get_tree().create_timer(1.6).timeout
		var r := "won" if ds.game.winner == 0 else ("lost" if ds.game.winner == 1 else "draw")
		var again := _button(ds, "Try again")
		var cont := _button(ds, "Continue")
		print("rematch %d: %s in %d turns (Life %d / %d)%s" % [i, r, ds.game.turn, ds.game.players[0].life, ds.game.players[1].life,
			"" if refused[0] == 0 else ", Showboat refused %d actions" % refused[0]])
		if again != null and again.visible:
			problems.append("the rematch offers Try again after a %s" % r)
		if not seen.has(r):
			seen[r] = true
			await _shot("rematch_" + r)
		if cont != null:
			cont.pressed.emit()
		var res: String = await ds.finished
		if res == "again":
			problems.append("the rematch restarted")
		ds.queue_free()
		await get_tree().process_frame
		if seen.has("won") and seen.has("lost"):
			break
	if not (seen.has("won") and seen.has("lost")):
		problems.append("in %d rematches the result was only %s" % [most, seen.keys()])
	# the coached Lantern Duel: the rule's banner, then Bram's first line
	Game.settings["debug_autoplay"] = false
	var spec2: Dictionary = area.duel_spec({"difficulty": 0.25})
	var ds2 := DuelScreen.new().configure(spec2)
	layer.add_child(ds2)
	await _until(func() -> bool: return _banner_up(ds2), 20.0)
	await get_tree().create_timer(0.4).timeout
	await _shot("lantern_showboat")
	# the rule stays up to be read until it's tapped (23 October)
	await _until(func() -> bool: return ds2.banner_waiting, 20.0)
	if not ds2.banner_waiting:
		problems.append("the Showboat banner didn't wait for a tap")
	ds2.tap_banner()
	await _until(func() -> bool: return ds2.tutor != null and ds2.tutor.blocking, 20.0)
	await get_tree().create_timer(0.5).timeout
	await _shot("lantern_bram_first")
	print("REMATCH TEST: ", "ok" if problems.is_empty() else "; ".join(problems))
	get_tree().quit(0 if problems.is_empty() else 1)


## Counts actions the rules refused because of Showboat (the computer should
## never try one).
func _watch(ds: DuelScreen, refused: Array) -> void:
	while ds.game == null:
		await get_tree().process_frame
	ds.game.logged.connect(func(text: String, _who: int) -> void:
		if text.begins_with("(Not allowed: Showboat"):
			refused[0] += 1)


func _banner_up(ds: DuelScreen) -> bool:
	for c in ds.fx_layer.get_children():
		if str(c.get("text")) == "SHOWBOAT":
			return true
	return false


func _button(ds: DuelScreen, text: String) -> Button:
	for b in ds.overlay.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func _until(cond: Callable, secs: float) -> void:
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > secs:
			return


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % tag))
