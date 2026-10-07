extends Node
## The Lantern Duel against Corin, computer against computer, with screenshots.
##   xvfb-run -a godot --resolution 1280x720 res://tests/lantern_duel_test.tscn -- <out_dir>

var out_dir := "user://"
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	var area = load("res://scripts/world/areas/ashford.gd")
	var spec: Dictionary = area.duel_spec({"difficulty": 0.3})
	spec.ai = [true, true]
	spec.speed = 4.0
	var layer := CanvasLayer.new()
	add_child(layer)
	var ds := DuelScreen.new().configure(spec)
	layer.add_child(ds)
	_snap_loop()
	var r: String = await ds.finished
	print("lantern duel result: ", r)
	await _shot()
	get_tree().quit()


func _snap_loop() -> void:
	while true:
		await get_tree().create_timer(6.0).timeout
		await _shot()


func _shot() -> void:
	await RenderingServer.frame_post_draw
	n += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("duel_%02d.png" % n))
