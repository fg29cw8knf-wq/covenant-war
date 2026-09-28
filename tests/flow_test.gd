extends Node
## Plays the opening of the game automatically and takes screenshots:
## title -> new game -> prologue -> first duel (AI plays for you) -> Solhaven.
##   xvfb-run ... godot --rendering-driver opengl3 res://tests/flow_test.tscn -- <out_dir>

var out := "user://"
var main: Node
var _n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))
	Game.settings["debug_autoplay"] = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(5.0)
	await _shot("title")
	main._on_new_game()
	var shots_at := [3.0, 9.0, 16.0, 30.0, 45.0, 70.0, 100.0, 130.0]
	var t := 0.0
	var next := 0
	while t < 150.0 and next < shots_at.size():
		await _wait(0.25)
		t += 0.25
		_auto_advance()
		if t >= shots_at[next]:
			await _shot("flow_%d" % next)
			next += 1
	get_tree().quit()


func _auto_advance() -> void:
	for n in _all(main):
		if n is DialogueBox and n.visible and not n._choices.visible:
			n._tap()
		elif n is LineEdit and n.is_visible_in_tree():
			n.text_submitted.emit(n.text)
		elif n is Button and n.is_visible_in_tree() and (n.text.begins_with("Choose ") or n.text == "Continue"):
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
	print("saved ", label)
