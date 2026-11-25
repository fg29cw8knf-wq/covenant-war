extends Node
## The Lantern Duel against Corin, computer against computer, with screenshots.
##   xvfb-run -a godot --resolution 1280x720 res://tests/lantern_duel_test.tscn -- <out_dir>
## (25 November) Without the stills, at a battle speed of your choosing, which
## a headless run with --fixed-fps 30 gets through in a minute or two (at 1 or
## 2 its attacks are staged in three shots, DuelScreen.staged_strikes):
##   godot --headless --fixed-fps 30 res://tests/lantern_duel_test.tscn -- --checks [--speed=2]

var out_dir := "user://"
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var checks := args.has("--checks")
	if args.size() > 0 and not String(args[0]).begins_with("--"):
		out_dir = args[0]
	var spd := 4.0
	for a in args:
		if String(a).begins_with("--speed="):
			spd = float(String(a).trim_prefix("--speed="))
	Game.new_game("Sprout", "emberstorm")
	var area = load("res://scripts/world/areas/ashford.gd")
	var spec: Dictionary = area.duel_spec({"difficulty": 0.3})
	spec.ai = [true, true]
	spec.speed = spd
	var layer := CanvasLayer.new()
	add_child(layer)
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	if not checks:
		_snap_loop()
	else:
		_tap_on(ds)
	var r: String = await ds.finished
	print("lantern duel result: ", r)
	if checks:
		print("lantern duel: turn %d, %d attacks staged, %d crossings; the clock %.2f, lunging %d" % [ds.game.turn, ds.staged_attacks,
			ds.staged_crossings, Engine.time_scale, ds.field.lunging if ds.field != null else 0])
		if absf(Engine.time_scale - 1.0) > 0.001:
			print("lantern duel: PROBLEM: the clock was left at %.2f" % Engine.time_scale)
	else:
		await _shot()
	get_tree().quit()


## The taps the duel waits for when nobody is there: a banner read at the
## player's pace, and Continue on the result (without it `finished` never
## comes, and the run with stills sits on "Sprout wins" until it's stopped).
func _tap_on(ds: DuelScreen) -> void:
	while is_instance_valid(ds) and ds.is_inside_tree():
		await get_tree().create_timer(0.3).timeout
		if not is_instance_valid(ds):
			return
		if ds.banner_waiting:
			ds.tap_banner()
		elif ds.mode == "over":
			for b in _buttons(ds.overlay):
				if b.text.to_lower().begins_with("continue") or b.text == "Back to the Lab":
					b.pressed.emit()
					return


func _buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _snap_loop() -> void:
	while true:
		await get_tree().create_timer(6.0).timeout
		await _shot()


func _shot() -> void:
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("duel_%02d.png" % n))
