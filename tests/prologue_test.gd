extends Node
## Plays the Prologue from the Pale Herald to the road east (Master Script v2,
## P3 to P5) automatically, with the computer playing Dask's road duel for
## the player, and checks the save afterwards: the chosen deck, the wager's
## winnings and the Resonance from the duel. Takes screenshots.
##   xvfb-run -a godot --rendering-driver opengl3 res://tests/prologue_test.tscn -- <out_dir> [deck]

var out := "user://"
var main: Node
var _done := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var want: String = args[1] if args.size() > 1 else "veilwild"
	if FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))
	Game.settings["debug_autoplay"] = true
	Game.settings["seen_opening"] = true
	Game.new_game("Sprout", "emberstorm")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(2.0)
	_run(want)
	var t := 0.0
	var shots := 0
	while not _done and t < 600.0:
		await _wait(0.2)
		t += 0.2
		_auto_advance(want)
		if int(t * 5) % 75 == 0 and shots < 12:
			await _shot("prologue_%02d" % shots)
			shots += 1
	var v: Dictionary = Game.v2
	var owned := 0
	for id in v.collection:
		owned += int(v.collection[id])
	print("PROLOGUE TEST: done=%s starter=%s name=%s cards owned=%d codex=%d rank=%d xp=%d target=%s beat_hunter=%s" % [
		_done, Game.starter, Game.player_name, owned, v.codex.size(), v.rank, v.xp, v.target, Game.flag("beat_hunter")])
	var ok: bool = _done and Game.starter == want and owned >= 60 and Game.flag("beat_hunter") and int(v.xp) + int(v.rank) > 1
	print("PROLOGUE TEST: %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _run(_want: String) -> void:
	await main._after_marking()
	_done = true


func _auto_advance(want: String) -> void:
	for n in _all(main):
		if n is DialogueBox and n.visible and not n._choices.visible:
			n._tap()
		elif n is LineEdit and n.is_visible_in_tree():
			n.text = "Rowan"
			n.text_submitted.emit(n.text)
		elif n is Button and n.is_visible_in_tree() and (n.text == "Choose " + DuelCards.DECKS[want].name or n.text == "Continue"):
			n.pressed.emit()
			return


func _all(n: Node) -> Array:
	var out_nodes := [n]
	for c in n.get_children():
		out_nodes.append_array(_all(c))
	return out_nodes


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, label])
