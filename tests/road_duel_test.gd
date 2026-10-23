extends Node
## Dask's road duel on the real duel screen, the way Main plays a story duel:
## lost on purpose twice (his line for winning, Morrowen taking the story back,
## the page turning, Again; then only the page and Change deck first, with the
## Deck page), then won. Checks the blank card's slot beside the deck (and its
## flicker when Life runs low) and his barks, and takes screenshots.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/road_duel_test.tscn -- <out_dir>
##   godot --headless res://tests/road_duel_test.tscn -- <out_dir>     # just the checks

var out := "user://"
var layer: CanvasLayer
var fails := 0
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	Game.new_game("Rowan", "tidegrove")
	for f in ["ash_marked", "first_deck", "bram_deck"]:
		Game.set_flag(f)
	Game.area = "thornwood"
	Game.set_flag("morrowen_last", 2)
	layer = CanvasLayer.new()
	add_child(layer)
	var spec := Prologue.road_duel_spec()
	# 1: lose; his line, Morrowen's, the page, then Again
	var ds := await _duel(spec)
	_check(ds.has_node("BlankCardSlot") or ds.stage.has_node("BlankCardSlot"), "the blank card has its slot")
	await _shot("1_my_turn")
	ds.story_bark("rival_poisons")
	await _wait(0.6)
	await _shot("1_bark")
	var p: DuelPlayer = ds.game.players[0]
	p.life = int(p.max_life * 0.2)
	await _wait(1.6)
	await _shot("1_low_life_flicker")
	_lose(ds)
	await _wait(2.4)
	await _shot("1_his_line")
	await _wait(4.2)
	await _shot("1_morrowen")
	var r1 := await _press(ds, "Again", "1_buttons")
	_check(r1 == "again", "the first loss plays again (got %s)" % r1)
	_check(int(Game.flag("morrowen_last", -1)) != 2, "Morrowen doesn't repeat her last line")
	# 2: lose again; only the page turning, then Change deck first
	ds = await _duel(spec)
	_lose(ds)
	await _wait(2.0)
	await _shot("2_page_only")
	var r2 := await _press(ds, "Change deck first", "2_buttons")
	_check(r2 == "again", "Change deck first plays again (got %s)" % r2)
	_check(int(spec.get("_losses", 0)) == 2, "two losses counted (%d)" % int(spec.get("_losses", 0)))
	# 3: win
	ds = await _duel(spec)
	ds.game._finish(0, "Dask's Life is empty.")
	ds.human.responded.emit({"type": "end"})
	await _wait(2.5)
	await _shot("3_won")
	var r3 := await _press(ds, "Continue", "")
	_check(r3 == "won", "a win carries on (got %s)" % r3)
	print("ROAD DUEL: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## Starts a duel screen and waits for the player's turn (tapping on through
## any of Bram's lines on the way).
func _duel(spec: Dictionary) -> DuelScreen:
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	var t := 0.0
	while t < 90.0 and ds.mode != "main":
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
		if ds.tutor != null and ds.tutor.blocking:
			ds.tutor._tapped.emit()
	_check(ds.mode == "main", "the duel reached the player's turn")
	return ds


func _lose(ds: DuelScreen) -> void:
	ds.game._finish(1, "Your Life is empty.")
	ds.human.responded.emit({"type": "end"})


## Waits for a button with this text, presses it, and returns what the duel
## screen finished with.
func _press(ds: DuelScreen, text: String, shot: String) -> String:
	var got := [""]
	ds.finished.connect(func(r: String) -> void: got[0] = r)
	var t := 0.0
	var pressed := false
	while got[0] == "" and t < 60.0:
		await _wait(0.2)
		t += 0.2
		if pressed:
			# the Deck page: look, then close it
			for pm in ds.find_children("*", "PauseMenu", true, false):
				if (pm as PauseMenu).visible:
					await _wait(0.8)
					await _shot("2_deck_page")
					(pm as PauseMenu).request_close()
			continue
		for b in ds.find_children("*", "Button", true, false):
			var bt := b as Button
			if bt.is_visible_in_tree() and bt.text == text:
				await _wait(0.6)
				if shot != "":
					await _shot(shot)
				bt.pressed.emit()
				pressed = true
				break
	ds.queue_free()
	return got[0]


func _check(ok: bool, what: String) -> void:
	print("ROAD DUEL %s: %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		fails += 1


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [n, label]))
